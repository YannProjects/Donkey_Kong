----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.10.2024
-- Design Name: 
-- Module Name: flash_programmer - Behavioral
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.DKong_Pack.all;

entity DKong_HW_Tester is
  port (

    -- System clock
    i_clk_sys             : in  std_logic;
    -- Core reset
    i_rst_sysn            : in  std_logic;
    
    i_cpu_a_core          : in std_logic_vector(15 downto 0);
    
    -- CPU data
    -- Port bidirectionnel sur DI_Core et DO_Core
    io_cpu_data_bidir        : inout std_logic_vector(7 downto 0);
    -- Data dir
    o_buffer_dir             : out std_logic;
    -- Tri-state buffer enable
    o_buffer_enable_n        : out std_logic;
    
    o_cpu_rst_core        : out std_logic;
    o_cpu_clk_core        : out std_logic;
    i_cpu_m1_l_core       : in std_logic;
    i_cpu_mreq_l_core     : in std_logic;
    i_cpu_rd_l_core       : in std_logic;
    i_cpu_wr_l_core       : in std_logic;
    i_cpu_rfrsh_l_core    : in std_logic;
    i_cpu_iorq_l          : in std_logic;
    o_cpu_waitn           : out std_logic;
    o_cpu_intn            : out std_logic;
        
    -- Z80 pacman code en memoire flash
    o_flash_cs_l_core       : out std_logic; -- Flash CS
    
    -- VGA
    o_vga                 : out r_Core_to_VGA;
    
    -- Son
    o_vol : out std_logic_vector(3 downto 0); 
    o_wav : out std_logic_vector(3 downto 0)
    
    -- UART
    -- o_uart_tx : out std_logic;
    -- i_uart_rx : in std_logic
  );
end DKong_HW_Tester;

architecture Behavioral of DKong_HW_Tester is

signal in0_cs, in1_cs, dip_sw_cs, uart_cs, uart_clk : std_logic;
signal uart_data, uart_reg : std_logic_vector(7 downto 0);
signal pacman_core_vol, pacman_core_wav : std_logic_vector(3 downto 0);
signal cpu_mreq_0, z80_rst_n : std_logic;

type wb_state is (wb_idle, wb_wait_for_ack, wb_wait_for_rd_or_wr_cycle);
signal uart_wb_we, uart_wb_stb, uart_wb_cyc, uart_wb_ack : std_logic;
signal wb_bus_state : wb_state;

signal cpu_to_core_data, core_to_cpu_data, regs_data, rom_data : std_logic_vector(7 downto 0);

signal vga_clock : std_logic;
signal pll_locked, flash_cs_l, uart_cs_l, rom_cs_l, sync_bus_cs_l : std_logic;
signal core_to_cpu_en_l, cpu_to_core_en_l, core_to_cpu_n, cpu_to_core_n : std_logic;
signal core_rst, blank_vga : std_logic;
signal video_rgb : std_logic_vector(23 downto 0);
signal o_audio_vol_out, o_audio_wav_out : std_logic_vector(3 downto 0);
signal vga : r_Core_to_VGA;
signal vga_control_init_done, clk_dkong, clk_52m : std_logic;
signal video_r, video_g, vga_r, vga_g, vga_b : std_logic_vector(2 downto 0);
signal video_b : std_logic_vector(1 downto 0);
signal core_vsync_l, core_blank, pixel_clk, clk_audio, clk_audio_shifter : std_logic;

begin

  --
  -- Single clock domain used for system / video and audio
  --
  clk_gen_0 : entity work.clk_dkong_gen
  port map (
      -- 12 MHz CMOD S7
      i_clk_main => i_clk_sys,
      reset => not i_rst_sysn,
      o_clk_dkong_main => clk_dkong,
      o_sound_cpu_clk => clk_audio,
      o_sound_cpu_clk_shifter => clk_audio_shifter,
      o_clk_52m => clk_52m,
      o_clk_vga => vga_clock,

      locked => pll_locked
  );
  
  --
  -- primary addr decode
  --
  -- Memory mapping:
  -- Gere par le core PacMan
  -- 0x0000 - 0x3FFF : Code programme du programmeur de flash (execute par le Z80) (16 K).
  -- 0x4000 - 0x43FF : RAM video tile (via pacman core et sync_bus_cs_l)
  -- 0x4400 - 0x47FF : RAM video palette (via pacman core et sync_bus_cs_l)
  -- 0x4800 - 0x4FEF : RAM Z80 (via pacman core et sync_bus_cs_l)
  -- 0x4FF0 - 0x4FFF : Registres de sprites (via pacman core et sync_bus_cs_l)
  -- 0x5000 - 0x50FF : Mapped registers (via pacman core et sync_bus_cs_l)
  --
  -- 0x6000 - 0x6005 : UART
  -- 0x8000 - 0xFFFF : Memoire flash
  -- Les adresses avec A15 = 0 sont prises en charge par le core PacMan
   p_data_decoder : process(i_cpu_a_core, i_cpu_mreq_l_core, i_cpu_rfrsh_l_core, regs_data, uart_reg, rom_data)
   begin
      flash_cs_l <= '1';
      uart_cs_l <= '1';
      rom_cs_l <= '1';
      sync_bus_cs_l <= '1';
      if ((i_cpu_mreq_l_core = '0') and (i_cpu_rfrsh_l_core = '1')) then
         case i_cpu_a_core(15 downto 13) is
            -- UART (0x6)
            -- when "011" =>
            --     uart_cs_l <= '0';
            --     core_to_cpu_data <= uart_reg;
            -- Test rom
            when "000" =>
                rom_cs_l <= '0';
                core_to_cpu_data <= rom_data;
            -- PacMan core
            when "001"|"010" =>
                sync_bus_cs_l <= '0';
                core_to_cpu_data <= regs_data;
            -- Flash memory
            when "100" => flash_cs_l <= '0';
            when others => core_to_cpu_data <= (others => 'X');
         end case;
      end if;
   end process;
   
  -- Gestion buffer bidir
  -- core_to_cpu_en_l <= '0' when ((core_to_cpu_n = '0') or (((uart_cs_l = '0') or (rom_cs_l = '0')) and (i_cpu_rd_l_core = '0'))) else '1';
  -- cpu_to_core_en_l <= '0' when ((cpu_to_core_n = '0') or (uart_cs_l = '0' and i_cpu_wr_l_core = '0')) else '1';
  core_to_cpu_en_l <= '0' when ((core_to_cpu_n = '0') or ((rom_cs_l = '0') and (i_cpu_rd_l_core = '0'))) else '1';
  cpu_to_core_en_l <= '0' when ((cpu_to_core_n = '0')) else '1';
  
  io_cpu_data_bidir <= core_to_cpu_data when core_to_cpu_en_l = '0' else (others => 'Z');
  cpu_to_core_data <= io_cpu_data_bidir when cpu_to_core_en_l = '0' else (others => 'Z');
  
  o_buffer_enable_n <= core_to_cpu_en_l and cpu_to_core_en_l;
  o_buffer_dir <= '1' when cpu_to_core_en_l = '0' else '0';  
    
  ---------------------
  -- PacMan core --
  ---------------------
  u_Core : entity work.dkong_top
  port map (
    -- System clock (61.44 MHz)
    i_clk => clk_dkong,
    i_clk_audio_6M => clk_audio,
    i_clk_audio_12M => clk_audio_shifter,
    i_core_reset => core_rst,

    -- Video
    o_core_red => video_r,
    o_core_green => video_g,
    o_core_blue => video_b,
    o_core_blank => core_blank,
    o_core_vsync_l => core_vsync_l,
    
    -- Z80    
    i_cpu_a => i_cpu_a_core,
    o_cpu_di => core_to_cpu_data,
    i_cpu_do => cpu_to_core_data,
    
    o_cpu_rst_l => o_cpu_rst_core,
    o_cpu_clk => o_cpu_clk_core,
    o_cpu_wait_l => o_cpu_waitn,
    o_cpu_int_l => o_cpu_intn,
    i_cpu_m1_l => i_cpu_m1_l_core,
    i_cpu_mreq_l => i_cpu_mreq_l_core,
    i_cpu_iorq_l => i_cpu_iorq_l,
    i_cpu_rd_l => i_cpu_rd_l_core,
    i_cpu_wr_l => i_cpu_wr_l_core,
    i_cpu_rfsh_l => i_cpu_rfrsh_l_core,    
    
    o_core_to_cpu_en_l => core_to_cpu_n,
    o_cpu_to_core_en_l => cpu_to_core_n,
    
    o_rom_cs_l => rom_cs_l,
    o_pixel_clk => pixel_clk
  );
   
  -- Controlleur VGA
  u_vga_ctrl : entity work.vga_control_top
  port map ( 
     -- i_reset => not i_rst_sys_n,
     i_reset => not pll_locked,
     i_clk_52m => clk_52m,
     i_vga_clk => vga_clock,
     i_sys_clk => pixel_clk,
    
     -- Signaux video core DKong
     i_vsyncn => core_vsync_l,
     i_blank => core_blank,
     i_rgb => video_rgb,
        
     -- Signaux video VGA
     o_hsync => o_vga.hsync,
     o_vsync => o_vga.vsync,
     o_blank => blank_vga,
     o_r => vga_r,
     o_g => vga_g,
     o_b => vga_b,         
    
     o_vga_control_init_done => vga_control_init_done
  );

  video_rgb(23 downto 16) <= video_r & "00000";
  video_rgb(15 downto  8) <= video_g & "00000";
  video_rgb( 7 downto  0) <= video_b & "000000";
  
  o_vga.r_vga <= vga_r when blank_vga = '0' else (others => '0');
  o_vga.g_vga <= vga_g when blank_vga = '0' else (others => '0');
  o_vga.b_vga <= vga_b when blank_vga = '0' else (others => '0');
    
  core_rst <= '1' when i_rst_sysn = '0' or  vga_control_init_done = '0' else '0';

end Behavioral;

