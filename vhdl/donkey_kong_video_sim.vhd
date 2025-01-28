----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.10.2024 20:28:28
-- Design Name: 
-- Module Name: donkey_kong_video_sim - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity donkey_kong_video_sim is
--  Port ( );
end donkey_kong_video_sim;

architecture Behavioral of donkey_kong_video_sim is

constant clk_period : time := 10 ns;

signal main_clk, rst_sys : std_logic;

begin

    clk_process :process
    begin
        main_clk <= '0';
        wait for clk_period / 2;
        main_clk <= '1';
        wait for clk_period / 2;
    end process;

   dkong_hw_tester : entity work.DKong_HW_Tester 
   port map (
        -- System clock
        i_clk_sys => main_clk,
        -- Core reset
        i_rst_sysn => not rst_sys,
        
        i_cpu_a_core => (others => '0'),
        
        i_cpu_m1_l_core => '1',
        i_cpu_mreq_l_core => '1',
        i_cpu_rd_l_core => '1',
        i_cpu_wr_l_core => '1',
        i_cpu_rfrsh_l_core => '1',
        i_cpu_iorq_l => '1'
    );

    rst_sys <= '1', '0' after 100 us;

end Behavioral;
