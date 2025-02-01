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
use ieee.numeric_std.all;
use work.DKong_Pack.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dkong_audio is
port (
    i_rst_l : in std_logic;
    i_sound_cpu_clk : in std_logic; -- 6 MHz
    i_sound_cpu_clk_shifter : in std_logic; -- 12 MHz

    -- CPU son
    i_audio_effects : in r_AudioEffectsTrigger;
    
    i_sound_data : in std_logic_vector(3 downto 0);

    i_sound_int_n : in std_logic;
    i_sound_PB5 : in std_logic;
    i_2_VF : in std_logic; -- Horloge 4K, 5K, 6K
    
    o_sound_boom_1 : out std_logic; -- Pilotage transisotr Q2 = i_sound_boom_1
    o_sound_boom_2 : out std_logic; -- Pilotage transisotr Q1
    o_dac_vref : out std_logic;
    o_io_sound : out std_logic;
    o_sound_walk : out std_logic;
    o_sound_jump : out std_logic
);
    
end dkong_audio;

architecture Behavioral of dkong_audio is

signal Q_4K, Q_5K, Q_6K, sound_cpu_data_in, sound_cpu_data_out : std_logic_vector(7 downto 0);
signal sound_cpu_pb, dac_input, Q_4HF, cpu_data_3f, cpu_data_3h : std_logic_vector(7 downto 0);
signal t48_ram_addr, t48_ram_di, t48_ram_do : std_logic_vector(7 downto 0);
signal addr_roms : std_logic_vector(10 downto 0);
signal cnt_u3j : unsigned(3 downto 0);
signal clk_u3j, sound_cpu_rd_l, rom_3H_cs_l, sound_cpu_ale : std_logic;
signal sound_data_en_l, sound_data_en_delayed, rom_3F_cs_l, u456k_clk : std_logic;
signal t48_ram_we, xtal3_s : std_logic;
 

begin

    -- U4K, U5K, U6K (SIPO shift register)
    u456k_clk <= not i_2_VF;
    U6K : process(i_rst_l, u456k_clk)
    begin
        if i_rst_l = '0' then
            Q_6K <= X"00";
        elsif rising_edge(i_2_VF) then
            Q_6K <= Q_6K(6 downto 0) & (not clk_u3j);
        end if;
    end process;

    U5K : process(i_rst_l, u456k_clk)
    begin
        if i_rst_l = '0' then
            Q_5K <= X"00";
        elsif rising_edge(i_2_VF) then
            Q_5K <= Q_5K(6 downto 0) & Q_6K(7);
        end if;
    end process; 
    
    U4K : process(i_rst_l, u456k_clk)
    begin
        if i_rst_l = '0' then
            Q_4K <= X"00";
        elsif rising_edge(i_2_VF) then
            Q_4K <= Q_4K(6 downto 0) & Q_5K(7);
        end if;
    end process;

    clk_u3j <= Q_5K(2) xor Q_4K(7);
    
    -- U3J (Synchronous presettable 4-bit binary counter)    
    U3J : process(i_rst_l, clk_u3j)
    begin
        if i_rst_l = '0' then
            cnt_u3j <= X"0";
        elsif rising_edge(clk_u3j) then
            cnt_u3j <= cnt_u3j + 1;
        end if;
    end process;
    o_sound_boom_2 <= cnt_u3j(2);
    
    -- U7H (processeur son)
	-- RAM externe du core CPU T48 (64 Byte)
	U7H_RAM : entity work.blk_mem_gen_7h port map (clka => i_sound_cpu_clk, wea(0) => t48_ram_we, 
                                addra => t48_ram_addr(5 downto 0), dina => t48_ram_di, douta => t48_ram_do); 
    
    U7H : entity work.t48_core
    port map (
        xtal_i => i_sound_cpu_clk,
        xtal_en_i => '1',
        reset_i => i_rst_l,
        t0_i => not i_audio_effects.barrel,
        t0_o => open,
        t0_dir_o => open,
        int_n_i => i_sound_int_n,
        ea_i => '1',
        rd_n_o => sound_cpu_rd_l,
        psen_n_o => rom_3H_cs_l,
        ale_o => sound_cpu_ale,
        db_i => sound_cpu_data_in,
        db_o => sound_cpu_data_out,
        db_dir_o => open,
        t1_i => not i_audio_effects.gorilla_fall,
        p2_i => "00" & (not i_audio_effects.spring) & "00000",
        p2_o => sound_cpu_pb,
        p1_i => (others => '0'),
        p1_o => dac_input,
        p1_low_imp_o => open,
        prog_n_o => open,
        
        -- Voir doc core µT48
        clk_i => i_sound_cpu_clk,
        en_clk_i => xtal3_s,
        xtal3_o => xtal3_s,
        -- RAM externe
		dmem_addr_o		=> t48_ram_addr,
		dmem_we_o		=> t48_ram_we,
		dmem_data_i		=> t48_ram_do,
		dmem_data_o		=> t48_ram_di,
		-- ROM externe (pas utilise)
		pmem_addr_o		=> open,
		pmem_data_i		=> x"00"
   );

   o_dac_vref <= sound_cpu_pb(7);
   sound_data_en_l <= sound_cpu_pb(6);
   o_io_sound <= sound_cpu_pb(4);
   
   addr_roms <= sound_cpu_pb(2 downto 0) & Q_4HF;
   
   process(sound_cpu_ale)
   begin
       if falling_edge(sound_cpu_ale) then
           Q_4HF <= sound_cpu_data_out;
       end if;
   end process;
   
   -- U3F, U3H
   -- Code et data CPU son
   U3F : entity work.dist_mem_gen_sound_1 port map(a => addr_roms, spo => cpu_data_3f);
   U3H : entity work.dist_mem_gen_sound_2 port map(a => addr_roms, spo => cpu_data_3h);

   -- Utilise en remplacement de 5J, R19, C37 pour retarder le signal RDn du CPU son
   process(i_sound_cpu_clk_shifter)
   begin
        if rising_edge(i_sound_cpu_clk_shifter) then
            sound_data_en_delayed <= not (sound_data_en_l and (not sound_cpu_rd_l));
        end if;
   end process;
   
   -- U4J, U4E
   -- Selection des données CPU son
   rom_3F_cs_l <= not ((not sound_cpu_rd_l) and (not sound_data_en_l));
   
   process (rom_3F_cs_l, rom_3H_cs_l, sound_data_en_delayed, cpu_data_3f, cpu_data_3h, i_sound_data)
    begin
        if sound_data_en_delayed = '0' then
            sound_cpu_data_in <=  "0000" & (not i_sound_data);
        elsif rom_3H_cs_l = '0' then
            sound_cpu_data_in <= cpu_data_3h;
        elsif rom_3F_cs_l = '0' then
            sound_cpu_data_in <= cpu_data_3f;
        else 
            sound_cpu_data_in <= (others => '0');
        end if;
   end process;
   
   -- Sert juste d'interface entre la partie main CPU et la partie audio
   o_sound_walk <= i_audio_effects.walk;
   o_sound_jump <= i_audio_effects.jump;
   o_sound_boom_1 <= i_audio_effects.boom;  

end Behavioral;
