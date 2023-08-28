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
-- TODO:
-- 20 August 2023:
--   - Rotating priority mode not yet managed
--   - Extended write not handled => EXT WR should start in S2 and normal write in S3
--   - How to handle WRITE_VERIFY, not clear. 
--   - UPDATE flag bit inside status register not handled (TODO: Find a proper location to reset the update flag).
--   - Not clear was is done or not on rising or falling edge clock (a NOT gate should be added compared to CPU clock...)
--     All code below is working on rising edge i8257 CLK (i.e.: each falling edge CPU clk).
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

entity dma_i8257 is
port (
    i_clk       : in std_logic;
    i_reset     : in std_logic;
    i_ready     : in std_logic;
    o_aen       : out std_logic;
    i_hdla      : in std_logic;
    o_hrq       : out std_logic;
    i_drq       : in std_logic_vector(3 downto 0); -- Just one channel here
    o_dackn     : out std_logic_vector(3 downto 0); -- Just one channel here
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
    o_memwn     : out std_logic;
    o_mark      : out std_logic;
    o_tc        : out std_logic
);
end;

architecture Behavioral of dma_i8257 is

type dma_register_t is record
    dma_addr_lsb   : unsigned(7 downto 0);
    dma_addr_msb   : unsigned(7 downto 0);
    dma_tc_lsb     : unsigned(7 downto 0);
    dma_tc_msb     : unsigned(7 downto 0);
    num_bytes      : unsigned(13 downto 0);
end record;

type dma_states_t is (SI, S0, S1, S2, S3, S4);
type dma_registers_t is array (0 to 3) of dma_register_t;

signal dma_registers : dma_registers_t;
signal dma_state : dma_states_t;
signal dma_mode : unsigned(7 downto 0);
signal tc : std_logic_vector(3 downto 0);
signal msb_lsb_toogle : std_logic;
signal refresh_update : std_logic_vector(1 downto 0);
signal dma_address : unsigned(15 downto 0);
signal dma_request : unsigned(3 downto 0);
signal current_channel : integer;

constant AUTOLOAD : unsigned(7 downto 0) := X"80";
constant TC_STOP : unsigned(7 downto 0) := X"40";
constant EXTENDED_WRITE : unsigned(7 downto 0) := X"20";
constant RP : unsigned(7 downto 0) := X"10";
constant CH3_EN : unsigned(7 downto 0) := X"08";
constant CH2_EN : unsigned(7 downto 0) := X"04";
constant CH1_EN : unsigned(7 downto 0) := X"02";
constant CH0_EN : unsigned(7 downto 0) := X"01";

constant DMA_READ : unsigned(7 downto 0) := X"80";
constant DMA_WRITE : unsigned(7 downto 0) := X"40";
begin

p_dma : process(i_clk, i_reset)

variable reg_index : integer;

begin
    if i_reset = '1' then
        for i in 0 to 3 loop
            dma_registers(i).dma_addr_lsb <= (others => '0');
            dma_registers(i).dma_addr_msb <= (others => '0');
            dma_registers(i).dma_tc_lsb <= (others => '0');
            dma_registers(i).dma_tc_msb <= (others => '0');
            dma_registers(i).num_bytes <= (others => '0');
        end loop;
        dma_mode <= (others => '0');
        tc <= (others => '0');
        o_dackn <= (others => '0');
        dma_state <= SI;
        o_aen <= '1';
        o_hrq <= '0';
        o_adstb <= '0';
        o_iormn <= '1';
        o_iowmn <= '1';
        o_memrn <= '1';
        o_memwn <= '1';
        o_mark <= '0';
        o_tc <= '0';
        msb_lsb_toogle <= '0';
        refresh_update <= "00";

    elsif rising_edge(i_clk) then
        -- DMA configuration
        if i_csn = '0' then
            if i_iowsn = '0' then
                -- CH-X DMA addresses and CH-X Terminal count
                if i_As(3) = '0' then
                    reg_index := to_integer(unsigned(i_As(3 downto 1)));
                    -- DMA addresses
                    if i_As(0) = '0' then
                        -- DMA adress LSB
                        if msb_lsb_toogle = '0' then
                            dma_registers(reg_index).dma_addr_lsb <= unsigned(i_Din);
                            -- In case of autoload and DMA channel is 2, load automatically channel 3
                            -- with channel 2 data
                            if (dma_mode & AUTOLOAD = AUTOLOAD) and reg_index = 2 then
                                dma_registers(3).dma_addr_lsb <= unsigned(i_Din);
                            end if;
                            msb_lsb_toogle <= '1';
                        -- DMA adress MSB
                        else
                            dma_registers(reg_index).dma_addr_msb <= unsigned(i_Din);
                            if (dma_mode & AUTOLOAD = AUTOLOAD) and reg_index = 2 then
                                dma_registers(3).dma_addr_msb <= unsigned(i_Din);
                            end if;                            
                            msb_lsb_toogle <= '0';
                        end if;
                    -- TC
                    else
                        -- TC adress LSB
                        if msb_lsb_toogle = '0' then
                            dma_registers(reg_index).dma_tc_lsb <= unsigned(i_Din);
                            if (dma_mode & AUTOLOAD = AUTOLOAD) and reg_index = 2 then
                                dma_registers(3).dma_tc_lsb <= unsigned(i_Din);
                            end if;                            
                            msb_lsb_toogle <= '1';
                        -- TC adress MSB
                        else
                            dma_registers(reg_index).dma_tc_msb <= unsigned(i_Din);
                            -- In case of autoload and DMA channel is 2, load automatically channel 3
                            -- with channel 2 data                                                         
                            if (dma_mode & AUTOLOAD = AUTOLOAD) and reg_index = 2 then
                                dma_registers(3).dma_tc_msb <= unsigned(i_Din);                              
                            end if;                             
                            msb_lsb_toogle <= '0';
                        end if;
                    end if;
                else
                    dma_mode <= unsigned(i_Din);
                end if;
            elsif i_iorsn = '0' then
                if i_As(3) = '0' then
                    if msb_lsb_toogle = '0' then
                        if i_As(0) = '0' then
                            o_Dout <= std_logic_vector(dma_registers(to_integer(unsigned(i_As(3 downto 1)))).dma_addr_lsb);
                        else
                            o_Dout <= std_logic_vector(dma_registers(to_integer(unsigned(i_As(3 downto 1)))).dma_tc_lsb);
                        end if;
                        msb_lsb_toogle <= '1';
                    else
                        if i_As(0) = '0' then
                            o_Dout <= std_logic_vector(dma_registers(to_integer(unsigned(i_As(3 downto 1)))).dma_addr_msb);
                        else
                            o_Dout <= std_logic_vector(dma_registers(to_integer(unsigned(i_As(3 downto 1)))).dma_tc_msb);
                        end if;                   
                        msb_lsb_toogle <= '0';
                    end if;
                else
                    o_Dout <= "000" & refresh_update(0) & tc(3 downto 0);
                    -- Reset channels status when status register is read.
                    tc <= (others => '0');                
                end if;
            end if;
        else
            case dma_state is
                when SI =>
                    -- Is there a DMA request pending and is it enabled ?
                    dma_request <= unsigned(i_drq) and dma_mode(3 downto 0);
                    if dma_request /= X"0" then
                        o_hrq <= '1';
                        dma_state <= S0;
                        if dma_request = X"1" then
                            current_channel <= 0;
                        elsif dma_request = X"2" then
                            current_channel <= 1;
                        elsif dma_request = X"4" then
                            current_channel <= 2;
                        elsif dma_request = X"8" then
                            current_channel <= 3;
                        end if;
                    end if;
                when S0 =>
                    if i_hdla = '1' then
                        dma_state <= S1;
                        dma_address <= dma_registers(current_channel).dma_addr_msb & dma_registers(current_channel).dma_addr_lsb;
                        dma_registers(current_channel).num_bytes <= (dma_registers(current_channel).dma_tc_msb(5 downto 0) & dma_registers(current_channel).dma_tc_lsb) + 1;
                        -- In case of autoload and DMA channel is 2, load automatically channel 3
                        -- with channel 2 data
                        if (dma_mode & AUTOLOAD = AUTOLOAD) and current_channel = 2 then
                            dma_registers(3).num_bytes <= (dma_registers(2).dma_tc_msb(5 downto 0) & dma_registers(2).dma_tc_lsb) + 1;
                        end if;                            
                        o_aen <= '1';
                    end if;
                    
                when S1 =>
                    o_Dout <= std_logic_vector(dma_address(15 downto 8));
                    o_Am <=  std_logic_vector(dma_address(7 downto 0));
                    o_adstb <= '1';
                    dma_state <= S2;
                    
                when S2 => 
                    o_adstb <= '0';
                    -- Enable I/O device
                    o_dackn(current_channel) <= '0';
                    dma_address <= dma_address + 1;
                    dma_registers(current_channel).num_bytes <= dma_registers(current_channel).num_bytes - 1;      
                    -- DMA write cycle (from IO device to memory)
                    if (dma_registers(current_channel).dma_tc_msb and DMA_WRITE) = DMA_WRITE then
                        o_iormn <= '0';
                    -- DMA read cycle (from memory to IO device)
                    elsif (dma_registers(current_channel).dma_tc_msb and DMA_READ) = DMA_READ then
                        o_memrn <= '0';
                    end if;
                    dma_state <= S3; 
                                       
                when S3 =>
                    if i_ready = '1' then
                        -- DMA write cycle (from IO device to memory)
                        if (dma_registers(current_channel).dma_tc_msb and DMA_WRITE) = DMA_WRITE then
                            o_memwn <= '0';
                        -- DMA read cycle (from memory to IO device)
                        elsif (dma_registers(current_channel).dma_tc_msb and DMA_READ) = DMA_READ then
                            o_iowmn <= '0';
                        end if;                    
                        if ((dma_registers(current_channel).num_bytes) and ("00"&X"07F")) = 0 then
                            o_mark <= '1';
                        end if;
                        if (dma_registers(current_channel).num_bytes = 0) then
                            o_tc <= '1';
                            tc(current_channel) <= '1';
                            if ((dma_mode and AUTOLOAD) = AUTOLOAD) and (current_channel = 2) then
                                -- In case of autoload and channel 2, update flag is set to 1 until
                                -- the completion of the next CH2 DMA cycle. This prevent the CPU
                                -- to update CH3 as CH2 data is reloading
                                -- (see description of Autoloadbit 7 inside datasheet and autoload timing
                                -- figure).
                                refresh_update <= "01";
                                dma_registers(2).dma_addr_lsb <= dma_registers(3).dma_addr_lsb;
                                dma_registers(2).dma_addr_msb <= dma_registers(3).dma_addr_msb;
                                dma_registers(2).num_bytes <= dma_registers(3).num_bytes;
                            end if;   
                        end if;                        
                        dma_state <= S4;
                    end if;
                    
                when S4 =>
                    o_tc <= '0';
                    o_mark <= '0';
                    o_iormn <= '1';
                    o_iowmn <= '1';
                    o_memrn <= '1';
                    o_memwn <= '1';
                    o_dackn(current_channel) <= '1';
                    -- Update flag is updated at the end of the next DMA cycle following the reload operation
                    -- (only in case of AUTOLOAD and channel 2 as per my understanding...)
                    if refresh_update = "01" then
                        refresh_update <= "11";
                    elsif refresh_update = "11" then
                        refresh_update <= "00";
                    end if;

                    if (dma_registers(current_channel).num_bytes = 0) and (dma_mode & TC_STOP = TC_STOP) then
                        -- TC stop is not taken into account in case of autoload and channel 2
                        if ((dma_mode and AUTOLOAD) /= AUTOLOAD) or (current_channel /= 2) then
                            dma_mode(3 downto 0) <= dma_mode(3 downto 0) and (not to_unsigned(current_channel, 4));
                            o_hrq <= '0';
                        end if;
                    end if;
                    -- Is there a DMA request pending and is bus still available ?
                    if dma_request /= "0" and i_hdla = '1' then
                        dma_state <= S1;
                        if dma_request = X"1" then
                            current_channel <= 0;
                        elsif dma_request = X"2" then
                            current_channel <= 1;
                        elsif dma_request = X"4" then
                            current_channel <= 2;
                        elsif dma_request = X"8" then
                            current_channel <= 3;
                        end if;
                    else
                        o_hrq <= '0';
                        dma_state <= SI;
                        o_aen <= '0';
                    end if;
           end case;
        end if;
    end if;
end process;

end Behavioral;
