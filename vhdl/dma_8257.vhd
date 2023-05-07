----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.05.2023 21:45:03
-- Design Name: 
-- Module Name: dma_8257 - Behavioral
-- Project Name: Donkey Kong
-- Target Devices: Artyx 7
-- Tool Versions: 
-- Description: i8257 DMA light pour Donkey Kong
-- Only 1 DMA channel
-- Not handling TC and MARK
-- sources: https://github.com/MiSTer-devel/Arcade-DonkeyKong_MiSTer mais en VHDL, MAME i8257.h, Intel 8257 datasheet
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--                            _____   _____
--                 _I/OR   1 |*    \_/     | 40  A7
--                 _I/OW   2 |             | 39  A6
--                 _MEMR   3 |             | 38  A5
--                 _MEMW   4 |             | 37  A4
--                  MARK   5 |             | 36  TC
--                 READY   6 |             | 35  A3
--                  HLDA   7 |             | 34  A2
--                 ADSTB   8 |             | 33  A1
--                   AEN   9 |             | 32  A0
--                   HRQ  10 |     8257    | 31  Vcc
--                   _CS  11 |             | 30  D0
--                   CLK  12 |             | 29  D1
--                 RESET  13 |             | 28  D2
--                _DACK2  14 |             | 27  D3
--                _DACK3  15 |             | 26  D4
--                  DRQ3  16 |             | 25  _DACK0
--                  DRQ2  17 |             | 24  _DACK1
--                  DRQ1  18 |             | 23  D5
--                  DRQ0  19 |             | 22  D6
--                   GND  20 |_____________| 21  D7
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dkong_dma is
port (
    i_clk       : in std_logic;
    i_reset     : in std_logic;
    i_ready     : in std_logic;
    o_aen       : out std_logic;
    i_hdla      : in std_logic;
    o_hrq       : out std_logic;
    i_drq0      : in std_logic; -- Just one channel here
    i_dack0     : out std_logic; -- Just one channel here
    o_adstb     : out std_logic;
    i_As        : in std_logic_vector(3 downto 0); -- Low addresses bus is input in slave mode
    o_Am        : out std_logic_vector(7 downto 0); -- Address bus is output in master mode
    i_iorsn     : in std_logic; -- IORn is input in slave mode
    i_iowsn     : in std_logic; -- IOWn is input in slave mode
    o_iormn     : out std_logic; -- IORn is output in master mode
    o_iowmn     : out std_logic; -- IOWn is output in master mode
    i_Din       : in std_logic_vector(7 downto 0);
    o_Dout      : out std_logic_vector(7 downto 0);
    i_csn       : in std_logic;
    o_memrn     : out std_logic;
    o_memwn     : out std_logic
);
end dkong_dma;

architecture Behavioral of dkong_dma is

type dma_register_type is 
record
    dma_addr_lsb   : std_logic_vector(7 downto 0);
    dma_addr_msb   : std_logic_vector(7 downto 0);
    dma_tc_lsb     : unsigned(7 downto 0);
    dma_tc_msb     : unsigned(7 downto 0);
end record;
type dma_states is (SI, S0, S1, S2, S3, S4);
type dma_registers_type is array (0 to 3) of dma_register_type;

signal dma_registers : dma_registers_type;
signal dma_state : dma_states;
signal dma_mode : std_logic_vector(7 downto 0);
signal tc : std_logic_vector(3 downto 0);
signal update : std_logic;
signal dma_address : unsigned(15 downto 0);

begin

p_dma : process(i_clk)
begin
    if i_reset = '1' then
        for i in 0 to 3 loop
            dma_registers(i).dma_addr_lsb <= (others => '0');
            dma_registers(i).dma_addr_msb <= (others => '0');
        end loop;
        dma_mode <= (others => '0');
        dma_state <= SI;
    
    elsif rising_edge(i_clk) then
        -- Configuration DMA
        if i_csn = '0' then
            if i_iowsn = '0' then
                if i_As(3) = '0' then
                    if i_As(0) = '0' then
                        dma_registers(to_integer(unsigned(i_As(3 downto 1)))).dma_addr_lsb <= i_Din;
                    else
                        dma_registers(to_integer(unsigned(i_As(3 downto 1)))).dma_addr_msb <= i_Din;
                    end if;
                else
                    dma_mode <= i_Din;
                end if;
            elsif i_iorsn = '0' then
                o_Dout <= "000" & update & tc(2 downto 0);
            end if;
        else
            case dma_state is
                when SI =>
                    dma_state <= S0;
                    if i_drq0 = '1' then
                        o_hrq <= '1';
                    end if;
                when S0 =>
                    if i_hdla = '1' then
                        dma_state <= S1;
                        dma_address <= unsigned(dma_registers(0).dma_addr_msb & dma_registers(0).dma_addr_lsb);
                    end if;
                when S1 =>
                    o_Dout <= std_logic_vector(dma_address(15 downto 8));
                    o_adstb <= '1';
                    o_Am <=  std_logic_vector(dma_address(7 downto 0));
                    dma_state <= S2;
                when S2 =>
                    -- Canal DRQ0 (le plus prioritaire). Dans ce cas (Si Mode TC : RD=0, WR=1 ?):
                    -- IORDn = 0 + MEMWn = 0 : Lecture la mémoire OBJ RAM et ecriture dans le latch 2N
                    -- Dans ce cas, le buffer bi-dir LS245 6A présente les données sur le latch LS 273 2N
                    -- car IORDn = 0 (B -> A) et MEMWn = 0 (G = 1)
                    --
                    -- On passe ensuite au canal DRQ1 (le suivant dans l'ordre de priorité). Dans ce cas:
                    -- IOWRn = 0 + MEMRn = 0 : Le contenu du latch est presente sur le bus de donnees et les donnees
                    -- sont ecrites dans la RAM CPU.
                    -- On recommence ensuite avec le canal 0, puis 1,...
                    -- A priori on peut faire le transfert inverse en configurant le registre TC du DMA avec RD ou WR (?)
                    -- Dans ce cas ou l'autre le fonctionnement du latch mémorise la donnée de la RAM OBJ ou de la RAM CPU.  
                    
                    dma_address <= 

                    
                    
           end case;
        end if;
    end if;
end process;

end Behavioral;
