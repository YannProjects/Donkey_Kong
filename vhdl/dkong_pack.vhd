----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.10.2024 20:30:09
-- Design Name: 
-- Module Name: dkong_pack - Behavioral
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

Package DKong_Pack is

type r_Core_to_VGA is record
    hsync : std_logic;
    vsync : std_logic;
    r_vga : std_logic_vector(2 downto 0);
    g_vga : std_logic_vector(2 downto 0);
    b_vga : std_logic_vector(2 downto 0);
end record;

end;
