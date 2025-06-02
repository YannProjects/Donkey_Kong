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

entity DKong_Main is
  generic (
    g_Dkong_Debug      : natural := 1        -- 0 = no debug, 1 = Ajout UART et ROM pour le code de debug
  );
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
    i_cpu_busack_l        : in std_logic;
    o_cpu_busrq_l         : out std_logic;
    i_cpu_rfrsh_l_core    : in std_logic;
    o_cpu_waitn           : out std_logic;
    o_cpu_nmi_l           : out std_logic;
    o_cpu_int_l           : out std_logic;
        
    -- Z80 pacman code en memoire flash
    o_rom_cs_l            : out std_logic; -- Flash CS
    
    -- VGA
    o_vga                 : out r_Core_to_VGA;

    -- Entrees joystick, coin,...
    -- i_config_dipsw : in std_logic_vector(7 downto 0);
    -- i_in1_joystick_buttons : in std_logic_vector(7 downto 0);
    -- i_in2_joystick_buttons : in std_logic_vector(7 downto 0);
    -- o_in1_cs_l : out std_logic;
    -- o_in2_cs_l : out std_logic;
    -- o_in3_cs_l : out std_logic;
    -- o_dipsw_l : out std_logic;

    -- Son
    -- o_boom1_driver        : out std_logic;
    -- o_boom2_driver        : out std_logic;
    -- o_boom_driver         : out std_logic;
    o_walk_driver         : out std_logic;
    -- o_jump_driver         : out std_logic;
    -- o_reset_vol_decay     : out std_logic;
    -- o_music_data          : out std_logic_vector(7 downto 0); -- Entrée DAC
    
    -- UART
    o_uart_tx : out std_logic;
    i_uart_rx : in std_logic
  );
end DKong_Main;

architecture Behavioral of DKong_Main is

signal in0_cs, in1_cs, dip_sw_cs, uart_cs, uart_clk : std_logic;
signal uart_data, uart_reg, core_data, rom_data : std_logic_vector(7 downto 0);
signal pacman_core_vol, pacman_core_wav : std_logic_vector(3 downto 0);
signal cpu_mreq_0, z80_rst_n : std_logic;

type wb_state is (wb_idle, wb_wait_for_ack, wb_wait_for_rd_or_wr_cycle, wb_wait_for_ack_next_cycle, wb_for_end_of_z80_cycle);
signal uart_wb_stb, uart_wb_cyc, uart_wb_ack, uart_wb_we : std_logic;
signal wb_current_state : wb_state;

signal cpu_to_core_data, core_to_cpu_data : std_logic_vector(7 downto 0);

signal vga_clock : std_logic;
signal pll_locked, flash_cs_l, uart_cs_l, sync_bus_cs_l : std_logic;
signal core_to_cpu_en_l, cpu_to_core_en_l, core_to_cpu_n, cpu_to_core_n : std_logic;
signal core_rst, blank_vga : std_logic;
signal video_rgb : std_logic_vector(23 downto 0);
signal o_audio_vol_out, o_audio_wav_out : std_logic_vector(3 downto 0);
signal vga : r_Core_to_VGA;
signal vga_control_init_done, clk_dkong : std_logic;
signal video_r, video_g, vga_r, vga_g, vga_b : std_logic_vector(2 downto 0);
signal video_b : std_logic_vector(1 downto 0);
signal core_vsync_l, core_blank, pixel_write, clk_audio, rom_cs_l : std_logic;
signal config_dipsw_temp, in1_joystick_buttons_temp, in2_joystick_buttons_temp : std_logic_vector(7 downto 0);
signal o_dipsw_l : std_logic;

-- attribute dont_touch : string;
-- attribute dont_touch of i_cpu_m1_l_core : signal is "true";

-- attribute MARK_DEBUG : string;
-- attribute MARK_DEBUG of i_cpu_a_core, io_cpu_data_bidir, i_cpu_mreq_l_core, i_cpu_rd_l_core, i_cpu_wr_l_core : signal is "true";
-- attribute MARK_DEBUG of i_cpu_busack_l, o_cpu_busrq_l, i_cpu_rfrsh_l_core, o_cpu_waitn, o_cpu_nmi_l, o_rom_cs_l : signal is "true"; 

begin

  --
  -- Single clock domain used for system / video and audio
  --
  clk_gen_0 : entity work.clk_dkong_gen
  port map (
      i_clk_main => i_clk_sys, -- 100 MHz
      reset => not i_rst_sysn,
      o_clk_dkong_main => clk_dkong, -- 61.44 MHz
      o_sound_cpu_clk => clk_audio, -- 6 MHz
      o_clk_vga => vga_clock, -- 25 MHz
      locked => pll_locked
  );
  
  uart_clk <= clk_dkong;
    
  ---------------------
  -- Donkey Kong core --
  ---------------------
  u_Core : entity work.dkong_core_top
  port map (
    -- System clock (61.44 MHz)
    i_clk => clk_dkong,
    i_clk_audio_6M => clk_audio,
    i_core_reset => core_rst,
    
    -- Entrees
    -- o_in1_cs_l => o_in1_l,
    -- o_in2_cs_l => o_in2_l,
    -- o_in3_cs_l =>  o_in3_l,
    o_dipsw_cs_l => o_dipsw_l,
    i_config_dipsw => config_dipsw_temp,
    i_ins1 => in1_joystick_buttons_temp,
    i_ins2 => in2_joystick_buttons_temp,

    -- Video
    o_core_red => video_r,
    o_core_green => video_g,
    o_core_blue => video_b,
    o_core_blank => core_blank,
    o_core_vsync_l => core_vsync_l,
    
    -- Son
    -- o_boom_1 => o_boom1_driver,
    -- o_boom_2 => o_boom2_driver,
    -- o_boom => o_boom_driver, 
    -- o_dac_vref => o_dac_vref_driver,
    o_walk => o_walk_driver,
    -- o_jump => o_jump_driver,
    
    -- Z80    
    i_cpu_a => i_cpu_a_core,
    o_cpu_di => core_data,
    i_cpu_do => cpu_to_core_data,
    i_cpu_busack_l => i_cpu_busack_l,
    
    o_cpu_rst_l => o_cpu_rst_core,
    o_cpu_clk => o_cpu_clk_core,
    o_cpu_wait_l => o_cpu_waitn,
    i_cpu_m1_l => i_cpu_m1_l_core,
    i_cpu_mreq_l => i_cpu_mreq_l_core,
    i_cpu_rd_l => i_cpu_rd_l_core,
    i_cpu_wr_l => i_cpu_wr_l_core,
    i_cpu_rfsh_l => i_cpu_rfrsh_l_core,
    o_cpu_nmi_l => o_cpu_nmi_l,
    o_cpu_busrq => o_cpu_busrq_l,
    
    o_rom_cs_l => rom_cs_l,
    o_uart_cs_l => uart_cs_l,
    o_pixel_wr => pixel_write
  );
  
  -- DIP siwtch:
 --   bit 7 : COCKTAIL or UPRIGHT cabinet (1 = UPRIGHT)
 --   bit 6 : \ 000 = 1 coin 1 play   001 = 2 coins 1 play  010 = 1 coin 2 plays
 --   bit 5 : | 011 = 3 coins 1 play  100 = 1 coin 3 plays  101 = 4 coins 1 play
 --   bit 4 : / 110 = 1 coin 4 plays  111 = 5 coins 1 play
 --   bit 3 : \bonus at
 --   bit 2 : / 00 = 7000  01 = 10000  10 = 15000  11 = 20000
 --   bit 1 : \ 00 = 3 lives  01 = 4 lives
 --   bit 0 : / 10 = 5 lives  11 = 6 lives
  config_dipsw_temp <= "10000100" when o_dipsw_l = '0' else (others => '1');
  in1_joystick_buttons_temp <= (others => '1');
  in2_joystick_buttons_temp <= (others => '1');

  o_buffer_enable_n <= core_to_cpu_en_l and cpu_to_core_en_l;
  o_buffer_dir <= '1' when cpu_to_core_en_l = '0' else '0';
  io_cpu_data_bidir <= core_to_cpu_data when core_to_cpu_en_l = '0' else (others => 'Z');
  cpu_to_core_data <= io_cpu_data_bidir when cpu_to_core_en_l = '0' else (others => 'Z');  
  
  -- Pour faire un essai avec le HW Pacmacn (INTn n'est pas utilise dans le cas de DKong).
  o_cpu_int_l <= '1';
   
  -- Controlleur VGA
  u_vga_ctrl : entity work.vga_control_top
  port map ( 
     i_reset => not pll_locked,
     i_clk => clk_dkong,
     i_vga_clk => vga_clock,
     i_pixel_write => pixel_write,
    
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

  --------------------
  --------------------
  --    Debug
  --------------------
  --------------------
  g_Dkong_Add_Debug : if g_Dkong_Debug = 1 generate
  
      -- Gestion buffer bidir
      -- Cas de la memoire ROM de test HW dans le FPGA
      core_to_cpu_en_l <= '0' when (i_cpu_rd_l_core = '0') and (i_cpu_rfrsh_l_core = '1') and (i_cpu_mreq_l_core = '0') else '1';
      cpu_to_core_en_l <= '0' when (i_cpu_wr_l_core = '0') and (i_cpu_rfrsh_l_core = '1') and (i_cpu_mreq_l_core = '0') else '1';
      
      core_to_cpu_data <= rom_data when (rom_cs_l = '0' and i_cpu_rd_l_core = '0') 
                          else uart_reg when (uart_cs_l = '0' and i_cpu_rd_l_core = '0')
                          else core_data;
    
      -- Pas de selection de la memoire Flash en mode debug, c'est la ROM de test qui est utilisee dans ce cas
      o_rom_cs_l <= '1';
        
      ---------------------------------------------------
      -- ROM de test contenant le code de debug du HW
      ---------------------------------------------------
      u_rom : entity work.dist_mem_gen_test_HW
      port map (a => i_cpu_a_core(13 downto 0), spo => rom_data);
      
      ------------ 
      -- UART
      ------------
      p_wb_manager : process(core_rst, uart_clk)
      begin
        if (core_rst = '1') then
            uart_wb_stb <= '0';
            uart_wb_we <= '0';
            uart_wb_cyc <= '0';	       
            wb_current_state <= wb_idle;
        elsif rising_edge(uart_clk) then
            -- Default values to provide the synthesis tool with a default value to assign the signal if the signal was not assigned in the CASE statement
            uart_wb_stb <= '0';
            uart_wb_we <= '0';
            uart_wb_cyc <= '0';
            
            case wb_current_state is
                when wb_idle =>
                    -- Declenchement d'un cycle WB sur validation MREQn
                    if (uart_cs_l = '0' and i_cpu_mreq_l_core = '0' and i_cpu_m1_l_core = '1') then
                         wb_current_state <= wb_wait_for_rd_or_wr_cycle;
                    end if;
                when wb_wait_for_rd_or_wr_cycle =>
                    -- Debut cycle lecture ou ecriture WB
                    if i_cpu_rd_l_core = '0' then
                        uart_wb_stb <= '1';
                        uart_wb_cyc <= '1';
                        wb_current_state <= wb_wait_for_ack;
                     elsif i_cpu_wr_l_core = '0' then
                        uart_wb_stb <= '1';
                        uart_wb_cyc <= '1';
                        uart_wb_we <= '1';
                        wb_current_state <= wb_wait_for_ack;
                     else
                        wb_current_state <= wb_wait_for_rd_or_wr_cycle;
                     end if;
                when wb_wait_for_ack =>
                     -- Attente acquittement lecture/ecriture
                     if uart_wb_ack = '0' then
                         uart_wb_stb <= '1';
                         uart_wb_cyc <= '1';
                         if i_cpu_wr_l_core = '0' then
                             uart_wb_we <= '1';
                         end if;
                     else
                         uart_reg <= uart_data;
                         wb_current_state <= wb_for_end_of_z80_cycle;
                     end if;
                when wb_for_end_of_z80_cycle =>
                    if (i_cpu_mreq_l_core = '1') then
                        wb_current_state <= wb_idle;
                    end if;
                when others =>
                    wb_current_state <= wb_idle;
                end case;
            end if; 
      end process;
      
      -- 
      -- UART
      -- 
      uart : entity work.uart_top
      port map (
        wb_clk_i =>  uart_clk,
        -- Wishbone signals
        wb_rst_i => core_rst,
        wb_adr_i => i_cpu_a_core(2 downto 0),
        wb_dat_i => cpu_to_core_data,
        wb_dat_o => uart_data,
        wb_we_i => uart_wb_we,
        wb_stb_i => uart_wb_stb, 
        wb_cyc_i => uart_wb_cyc,
        wb_ack_o => uart_wb_ack,
        wb_sel_i => "1111",
        -- int_o -- interrupt request
    
        -- UART	signals
        -- serial input/output
        stx_pad_o => o_uart_tx,
        srx_pad_i => i_uart_rx,
    
        -- modem signals
        -- rts_pad_o
        cts_pad_i => '0',
        -- dtr_pad_o
        dsr_pad_i => '0',
        ri_pad_i => '0',
        dcd_pad_i => '0'
      );
           
      -- o_uart_tx <= '1';

  end generate g_Dkong_Add_Debug;

  --------------------
  --------------------
  --    NO Debug
  --------------------
  --------------------
    
  g_Dkong_No_Debug : if g_Dkong_Debug = 0 generate
    
      -- Gestion buffer bidir entre le FPGA et le bus Z80
      core_to_cpu_en_l <= '0' when (i_cpu_rd_l_core = '0') and (i_cpu_rfrsh_l_core = '1') and (i_cpu_mreq_l_core = '0') and (rom_cs_l = '1') else '1';
      cpu_to_core_en_l <= '0' when (i_cpu_wr_l_core = '0') and (i_cpu_rfrsh_l_core = '1') and (i_cpu_mreq_l_core = '0') and (rom_cs_l = '1') else '1';
      core_to_cpu_data <= core_data;
      
      o_rom_cs_l <= rom_cs_l;

  end generate g_Dkong_No_Debug;

end Behavioral;