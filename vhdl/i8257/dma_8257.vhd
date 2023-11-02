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
--     Input "READY" ?
--     To be checked: Nb bytes counters, when TC et MARK are setted
-- 01 Nov 2023:
--    Rotating priority is now ok
--    Unitary tests performed with Test_DMA.c + Z80  
--    Nothing to do for WRITE_VERIFY mode
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
    i_drq       : in std_logic_vector(3 downto 0);
    o_dackn     : out std_logic_vector(3 downto 0);
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
    dma_tc_lsb     : unsigned(7 downto 0);
    dma_tc_msb     : unsigned(7 downto 0);
    num_bytes      : unsigned(13 downto 0);
    num_cycles     : unsigned(13 downto 0);
    cycle_sel      : unsigned(1 downto 0);
    dma_address    : unsigned(15 downto 0);
end record;

type dma_states_t is (SI, S0, S1, S2, S3, S4);
type dma_registers_t is array (0 to 3) of dma_register_t;
type channel_priorities_t is array (0 to 3) of unsigned(3 downto 0);
type channel_priorities_idx_t is array (0 to 3) of integer;

signal dma_state : dma_states_t;
signal tc : std_logic_vector(3 downto 0);
signal msb_lsb_toogle : std_logic;
signal refresh_update : std_logic_vector(1 downto 0);
signal channel_priorities : channel_priorities_t;
signal channel_priorities_idx : channel_priorities_idx_t;
signal dma_registers_debug : dma_registers_t;
signal dma_mode_debug : unsigned(7 downto 0);

signal current_channel : integer range 0 to 3;

constant AUTOLOAD : unsigned(7 downto 0) := X"80";
constant TC_STOP : unsigned(7 downto 0) := X"40";
constant EXTENDED_WRITE : unsigned(7 downto 0) := X"20";
constant RP : unsigned(7 downto 0) := X"10";
constant CH3_EN : unsigned(7 downto 0) := X"08";
constant CH2_EN : unsigned(7 downto 0) := X"04";
constant CH1_EN : unsigned(7 downto 0) := X"02";
constant CH0_EN : unsigned(7 downto 0) := X"01";

constant DMA_READ : unsigned(1 downto 0) := "10";
constant DMA_WRITE : unsigned(1 downto 0) := "01";

begin

p_dma : process(i_clk, i_reset)

variable reg_index : integer;
variable dma_registers : dma_registers_t;
variable dma_mode : unsigned(7 downto 0);


begin
    if i_reset = '1' then
        for i in 0 to 3 loop
            dma_registers(i).dma_tc_lsb := (others => '0');
            dma_registers(i).dma_tc_msb := (others => '0');
            dma_registers(i).num_bytes := (others => '0');
            dma_registers(i).num_cycles := (others => '0');
            dma_registers(i).cycle_sel := (others => '0');
        end loop;
        -- dma_mode(0) : Channel 0 enabled
        -- dma_mode(1) : Channel 1 enabled
        -- dma_mode(2) : Channel 2 enabled
        -- dma_mode(3) : Channel 3 enabled
        -- dma_mode(4) : RP (Rotating priority)
        -- dma_mode(5) : EW (Extended Write)
        -- dma_mode(6) : TCS (TC Stop)
        -- dma_mode(7) : AL (Autoload)
        dma_mode := (others => '0');
        tc <= (others => '0');
        o_dackn <= (others => '1');
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
        current_channel <= 0;
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
                            dma_registers(reg_index).dma_address := (dma_registers(reg_index).dma_address(15 downto 8)) & unsigned(i_Din);
                            -- In case of autoload and DMA channel is 2, load automatically channel 3
                            -- with channel 2 data
                            if (dma_mode & AUTOLOAD = AUTOLOAD) and reg_index = 2 then
                                dma_registers(3).dma_address := (dma_registers(3).dma_address(15 downto 8)) & unsigned(i_Din);
                            end if;
                            msb_lsb_toogle <= '1';
                        -- DMA adress MSB
                        else
                            dma_registers(reg_index).dma_address := unsigned(i_Din) & dma_registers(reg_index).dma_address(7 downto 0);
                            if (dma_mode & AUTOLOAD = AUTOLOAD) and reg_index = 2 then
                                dma_registers(3).dma_address := unsigned(i_Din) & dma_registers(3).dma_address(7 downto 0);
                            end if;                            
                            msb_lsb_toogle <= '0';
                        end if;
                    -- TC
                    else
                        -- TC adress LSB
                        if msb_lsb_toogle = '0' then
                            dma_registers(reg_index).num_bytes := (dma_registers(reg_index).num_bytes(5 downto 0)) & unsigned(i_Din);
                            -- Reset number of tranferred bytes
                            dma_registers(reg_index).num_cycles := (others => '0');
                            if (dma_mode & AUTOLOAD = AUTOLOAD) and reg_index = 2 then
                                dma_registers(3).num_bytes := dma_registers(3).num_bytes(5 downto 0) & unsigned(i_Din);
                                dma_registers(3).num_cycles := (others => '0');
                            end if;
                            msb_lsb_toogle <= '1';
                        -- TC adress MSB
                        else
                            dma_registers(reg_index).num_bytes := unsigned(i_Din(5 downto 0)) & dma_registers(reg_index).num_bytes(7 downto 0);
                            dma_registers(reg_index).cycle_sel := unsigned(i_Din(7 downto 6));                            
                            -- In case of autoload and DMA channel is 2, load automatically channel 3
                            -- with channel 2 data                                                         
                            if (dma_mode & AUTOLOAD = AUTOLOAD) and reg_index = 2 then
                                dma_registers(3).num_bytes := unsigned(i_Din(5 downto 0)) & dma_registers(3).num_bytes(7 downto 0);
                                dma_registers(3).cycle_sel := unsigned(i_Din(7 downto 6));
                            end if;                             
                            msb_lsb_toogle <= '0';
                        end if;
                    end if;
                else
                    dma_mode := unsigned(i_Din);
                end if;
            elsif i_iorsn = '0' then
                if i_As(3) = '0' then
                    if msb_lsb_toogle = '0' then
                        if i_As(0) = '0' then
                            o_Dout <= std_logic_vector(dma_registers(to_integer(unsigned(i_As(3 downto 1)))).dma_address(7 downto 0));
                        else
                            o_Dout <= std_logic_vector(dma_registers(to_integer(unsigned(i_As(3 downto 1)))).num_bytes(7 downto 0));
                        end if;
                        msb_lsb_toogle <= '1';
                    else
                        if i_As(0) = '0' then
                            o_Dout <= std_logic_vector(dma_registers(to_integer(unsigned(i_As(3 downto 1)))).dma_address(15 downto 8));
                        else
                            o_Dout <= std_logic_vector(dma_registers(to_integer(unsigned(i_As(3 downto 1)))).cycle_sel)
                                 & std_logic_vector(dma_registers(to_integer(unsigned(i_As(3 downto 1)))).num_bytes(13 downto 8));
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
                    o_hrq <= '0';
                    o_aen <= '0';
                    -- Is there a DMA request pending and is it enabled ?
                    if (unsigned(i_drq) and dma_mode(3 downto 0) and dma_mode(3 downto 0)) /= X"0" then
                        o_hrq <= '1';
                        dma_state <= S0;
                        channel_priorities <= (X"1", X"2", X"4", X"8");
                        channel_priorities_idx <= (0, 1, 2, 3);
                    end if;
                when S0 =>                  
                    if i_hdla = '1' then
                        -- Fixed or rotating priority ?
                        if (dma_mode and RP) = X"0" then
                           if (unsigned(i_drq) and dma_mode(3 downto 0) and X"1") = X"1" then
                               current_channel <= 0;
                           elsif (unsigned(i_drq) and dma_mode(3 downto 0) and X"2") = X"2" then
                               current_channel <= 1;
                           elsif (unsigned(i_drq) and dma_mode(3 downto 0) and X"4") = X"4" then
                               current_channel <= 2;
                           elsif (unsigned(i_drq) and dma_mode(3 downto 0) and X"8") = X"8" then
                               current_channel <= 3;
                           end if;
                        else
                           if (channel_priorities(0) and unsigned(i_drq) and dma_mode(3 downto 0)) = channel_priorities(0) then
                               current_channel <= channel_priorities_idx(0);
                               channel_priorities <= (channel_priorities(1),  channel_priorities(2),  channel_priorities(3),  channel_priorities(0));
                               channel_priorities_idx <= (channel_priorities_idx(1), channel_priorities_idx(2), channel_priorities_idx(3), channel_priorities_idx(0));
                           elsif (channel_priorities(1) and unsigned(i_drq) and dma_mode(3 downto 0)) = channel_priorities(1) then
                               current_channel <= channel_priorities_idx(1);
                               channel_priorities <= (channel_priorities(2), channel_priorities(3), channel_priorities(0), channel_priorities(1));
                               channel_priorities_idx <= (channel_priorities_idx(2), channel_priorities_idx(3), channel_priorities_idx(0), channel_priorities_idx(1));
                           elsif (channel_priorities(2) and unsigned(i_drq) and dma_mode(3 downto 0)) = channel_priorities(2) then
                               current_channel <= channel_priorities_idx(2);
                               channel_priorities <= (channel_priorities(3), channel_priorities(0), channel_priorities(1), channel_priorities(2));
                               channel_priorities_idx <= (channel_priorities_idx(3), channel_priorities_idx(0), channel_priorities_idx(1), channel_priorities_idx(2));
                           elsif (channel_priorities(0) and unsigned(i_drq) and dma_mode(3 downto 0)) = channel_priorities(0) then
                               current_channel <= channel_priorities_idx(3);
                           end if;
                        end if;                    
                        dma_state <= S1;
                        o_aen <= '1';
                    end if;
                    
                when S1 =>
                    o_Dout <= std_logic_vector(dma_registers(current_channel).dma_address(15 downto 8));
                    o_Am <=  std_logic_vector(dma_registers(current_channel).dma_address(7 downto 0));
                    o_adstb <= '1';
                    dma_state <= S2;
                    
                when S2 => 
                    o_adstb <= '0';
                    -- Enable I/O device
                    o_dackn(current_channel) <= '0';
                    -- DMA write cycle (from IO device to memory)
                    if (dma_registers(current_channel).cycle_sel and DMA_WRITE) = DMA_WRITE then
                        o_iormn <= '0';
                    -- DMA read cycle (from memory to IO device)
                    elsif (dma_registers(current_channel).cycle_sel and DMA_READ) = DMA_READ then
                        o_memrn <= '0';
                    end if;
                    dma_state <= S3; 
                                       
                when S3 =>
                    if i_ready = '1' then
                        -- DMA write cycle (from IO device to memory)
                        -- num_bytes contains Rd or Wr mode
                        if (dma_registers(current_channel).cycle_sel and DMA_WRITE) = DMA_WRITE then
                            o_memwn <= '0';
                        -- DMA read cycle (from memory to IO device)
                        elsif (dma_registers(current_channel).cycle_sel and DMA_READ) = DMA_READ then
                            o_iowmn <= '0';
                        end if;                    
                        if ((dma_registers(current_channel).num_bytes = 0) and tc(current_channel) = '0') then
                            o_tc <= '1';
                            tc(current_channel) <= '1';
                            if ((dma_mode and AUTOLOAD) = AUTOLOAD) and (current_channel = 2) then
                                -- In case of autoload and channel 2, update flag is set to 1 until
                                -- the completion of the next CH2 DMA cycle. This prevent the CPU
                                -- to update CH3 as CH2 data is reloading
                                -- (see description of Autoloadbit 7 inside datasheet and autoload timing
                                -- figure).
                                refresh_update <= "01";
                                dma_registers(2).dma_address := dma_registers(3).dma_address;
                                dma_registers(2).num_bytes := dma_registers(3).num_bytes;
                            end if;
                        -- Is it the right way to set TC as inside datasheet it's stated : "...MARK always occurs at 128 (and all mutiples of 128)
                        -- cycled FROM THE END of the data block...". I don't know if it's really "from the end" here. I think so, as num_bytes are decremented.
                        elsif ((dma_registers(current_channel).num_cycles + 1) and ("00" & X"07F")) = 0 then
                            o_mark <= '1';
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

                    if (dma_mode and TC_STOP) = TC_STOP then
                        if (dma_registers(current_channel).num_bytes = 0) then
                            -- TC stop is not taken into account in case of autoload and channel 2
                            if ((dma_mode and AUTOLOAD) = 0) or (current_channel /= 2) then
                                case current_channel is
                                    when 0 => dma_mode := dma_mode and X"FE"; 
                                    when 1 => dma_mode := dma_mode and X"FD";
                                    when 2 => dma_mode := dma_mode and X"FB";
                                    when 3 => dma_mode := dma_mode and X"F8";
                                    when others => dma_mode := X"00";
                                end case;
                            end if;
                        else
                            dma_registers(current_channel).dma_address := dma_registers(current_channel).dma_address + 1;
                            dma_registers(current_channel).num_bytes := dma_registers(current_channel).num_bytes - 1;
                            dma_registers(current_channel).num_cycles := dma_registers(current_channel).num_cycles + 1;
                        end if;
                    end if;
                    
                    dma_state <= SI;
                    -- Is there a DMA request pending and is bus still available ?
                    if (unsigned(i_drq) and dma_mode(3 downto 0)) /= "0" and i_hdla = '1' then
                        dma_state <= S1;
                        -- Fixed or rotating priority ?
                        if (dma_mode and RP) = X"0" then
                           if (unsigned(i_drq) and dma_mode(3 downto 0) and X"1") = X"1" then
                               current_channel <= 0;
                           elsif (unsigned(i_drq) and dma_mode(3 downto 0) and X"2") = X"2" then
                               current_channel <= 1;
                           elsif (unsigned(i_drq) and dma_mode(3 downto 0) and X"4") = X"4" then
                               current_channel <= 2;
                           elsif (unsigned(i_drq) and dma_mode(3 downto 0) and X"8") = X"8" then
                               current_channel <= 3;
                           end if;
                        else
                           if (channel_priorities(0) and unsigned(i_drq) and dma_mode(3 downto 0)) = channel_priorities(0) then
                               current_channel <= channel_priorities_idx(0);
                               channel_priorities <= (channel_priorities(1),  channel_priorities(2),  channel_priorities(3),  channel_priorities(0));
                               channel_priorities_idx <= (channel_priorities_idx(1), channel_priorities_idx(2), channel_priorities_idx(3), channel_priorities_idx(0));
                           elsif (channel_priorities(1) and unsigned(i_drq) and dma_mode(3 downto 0)) = channel_priorities(1) then
                               current_channel <= channel_priorities_idx(1);
                               channel_priorities <= (channel_priorities(2), channel_priorities(3), channel_priorities(0), channel_priorities(1));
                               channel_priorities_idx <= (channel_priorities_idx(2), channel_priorities_idx(3), channel_priorities_idx(0), channel_priorities_idx(1));
                           elsif (channel_priorities(2) and unsigned(i_drq) and dma_mode(3 downto 0)) = channel_priorities(2) then
                               current_channel <= channel_priorities_idx(2);
                               channel_priorities <= (channel_priorities(3), channel_priorities(0), channel_priorities(1), channel_priorities(2));
                               channel_priorities_idx <= (channel_priorities_idx(3), channel_priorities_idx(0), channel_priorities_idx(1), channel_priorities_idx(2));
                           elsif (channel_priorities(3) and unsigned(i_drq) and dma_mode(3 downto 0)) = channel_priorities(3) then
                               current_channel <= channel_priorities_idx(3);
                           end if;
                        end if; 
                    end if;
           end case;
        end if;
    end if;
    
    -- For debug
    dma_registers_debug <= dma_registers;
    dma_mode_debug <= dma_mode;
end process;


end Behavioral;
