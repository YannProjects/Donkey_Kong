----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.01.2025 20:43:18
-- Design Name: 
-- Module Name: dkong_audio - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Partie son de Donkey Kong
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--  
----------------------------------------------------------------------------------

-- write:
-- 7800-780F P8257 Control registers
-- 7c00      Background sound/music select:
--           00 - nothing
--           01 - Intro tune
--           02 - How High? (intermisson) tune
--           03 - Out of time
--           04 - Hammer
--           05 - Rivet level 2 completed (end tune)
--           06 - Hammer hit
--           07 - Standard level end
--           08 - Background 1 (barrels)
--           09 - Background 4 (pie factory)
--           0A - Background 3 (springs)
--           0B - Background 2 (rivets)
--           0C - Rivet level 1 completed (end tune)
--           0D - Rivet removed
--           0E - Rivet level completed
--           0F - Gorilla roar
-- 7c80      gfx bank select (Donkey Kong Jr. only)
-- 7d00      digital sound trigger - walk
-- 7d01      digital sound trigger - jump
-- 7d02      digital sound trigger - boom (gorilla stomps foot)
-- 7d03      digital sound trigger - coin input/spring
-- 7d04      digital sound trigger - gorilla fall
-- 7d05      digital sound trigger - barrel jump/prize
-- 7d06      ?
-- 7d07      ?
-- 7d80      digital sound trigger - dead
-- 7d82      flip screen
-- 7d83      ?
-- 7d84      interrupt enable
-- 7d85      0/1 toggle
-- 7d86-7d87 palette bank selector (only bit 0 is significant: 7d86 = bit 0 7d87 = bit 1)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dkong_audio is
port (
    i_rst : in std_logic;

    -- CPU son
    i_sound_T0 : in std_logic; -- Select sound for jump (Normal or Barrell?)
    i_sound_T1 : in std_logic; -- Active low when gorilla is falling
    i_sound_int_n : in std_logic;
    i_sound_jump_l : in std_logic;
    i_sound_boom_l : in std_logic;
    i_sound_spring_l : in std_logic;
    i_sound_gorilla_fall_l : in std_logic;
    i_sound_barrel_l : in std_logic;
    i_sound_data : in std_logic_vector(3 downto 0);


    i_sound_PB5 : in std_logic;
    i_2_VF : in std_logic;
    i_4K_clr_n : in std_logic
    
);
    
end dkong_audio;

architecture Behavioral of dkong_audio is

begin


end Behavioral;
