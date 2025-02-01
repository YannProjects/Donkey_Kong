----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.10.2024 17:47:11
-- Design Name: 
-- Module Name: dkong_top - Behavioral
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
use ieee.numeric_std.all;
use work.DKong_Pack.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dkong_top is
port (
    -- System clock (61.44 MHz)
    i_clk                 : in  std_logic;
    i_clk_audio_6M        : in  std_logic;
    i_clk_audio_12M       : in  std_logic;    
    i_core_reset          : in  std_logic; -- actif niveau haut

    -- Video
    o_core_red            : out std_logic_vector(2 downto 0);
    o_core_green          : out std_logic_vector(2 downto 0);
    o_core_blue           : out std_logic_vector(1 downto 0);
    o_core_blank          : out std_logic;
    o_core_vsync_l        : out std_logic;
    
    -- Z80    
    i_cpu_a               : in std_logic_vector(15 downto 0);  -- Z80 adresse bus
    o_cpu_di              : out std_logic_vector(7 downto 0);  -- Z80 data input
    i_cpu_do              : in std_logic_vector(7 downto 0);  -- Z80 data output
    
    o_cpu_rst_l           : out std_logic; -- Z80 reset
    o_cpu_clk             : out std_logic; -- Z80 clk
    o_cpu_wait_l          : out std_logic; -- Z80 wait
    o_cpu_int_l           : out std_logic; -- Z80 INT
    o_cpu_nmi_l           : out std_logic; -- Z80 NMI
    i_cpu_m1_l            : in std_logic; -- Z80 M1
    i_cpu_mreq_l          : in std_logic; -- Z80 MREQ
    i_cpu_iorq_l          : in std_logic; -- Z80 IORQ
    i_cpu_rd_l            : in std_logic; -- Z80 RD
    i_cpu_wr_l            : in std_logic; -- Z80 WR
    i_cpu_rfsh_l          : in std_logic; -- Z80 RFRSH    
    
    o_core_to_cpu_en_l   : out std_logic; -- CPU read interrupt reg or hold register (RAM, IN0, IN1,...)
    o_cpu_to_core_en_l   : out std_logic; -- Validation buffer CPU vers core (ecriture RAM,registres,...)
    
    o_rom_cs_l   : out std_logic; -- Lecture ROM programme
    o_pixel_clk  : out std_logic
    
    );
end dkong_top;

architecture Behavioral of dkong_top is

-- CPU_RST_P = Nombre de pulse Phi34 entre le début de i_core_reset et le début du pulse de reset CPU/DMA
-- CPU_RST_W = Nombre de pulse Phi34 pour la durée du pulse de reset CPU/DMA
constant CPU_RST_P : unsigned(15 downto 0) := to_unsigned(1000, 16);
constant CPU_RST_W : unsigned(15 downto 0) := to_unsigned(10000, 16);

signal cnt_reset : unsigned(15 downto 0);
signal v_blkn, h_1, vf_2 : std_logic;
signal vram_busy_l, vram_wr_l, vram_rd_l, psl_2, obj_wr_l, obj_rd_l, obj_rq_l : std_logic;
signal addr_bus : std_logic_vector(15 downto 0);
signal video_data_in, video_data_out, ram_data_in_34_A, ram_data_in_34_B, ram_data_in_34_C : std_logic_vector(7 downto 0);
signal ram_data_out_34_A, ram_data_out_34_B, ram_data_out_34_C, data_5A, data_5B, data_5C, data_5E : std_logic_vector(7 downto 0);
signal rom_5E_sel_l, rom_5A_sel_l, rom_5B_sel_l, rom_5C_sel_l, ram_sel_l, sprite_vid_ram_sel_l : std_logic;
signal ram_3C4C_sel_l, ram_3B4B_sel_l, ram_3A4A_sel_l, dma_cs_l, vram_wait_l : std_logic;
signal nmi_int_en_l, hsync_l, cmpblk2n : std_logic;

begin

    -- CPU reset (équivalent de U1N)
    p_cpu_reset : process(i_clk, i_core_reset, cnt_reset)
    begin
        if (i_core_reset = '1') or (cnt_reset = CPU_RST_W + 1) then
            cnt_reset <= (others => '0');
        elsif rising_edge(i_clk) then
            if (cnt_reset < CPU_RST_W) then
                cnt_reset <= cnt_reset + 1;
            end if;
        end if;
    end process;
    
    o_cpu_rst_l <= '0' when (cnt_reset >= CPU_RST_P) and (cnt_reset < CPU_RST_W) else '1'; 

    u_Dkong_Video : entity work.dk_tg4_video
    port map (
        i_clk => i_clk,
        i_rst => i_core_reset,
        o_vblkn => v_blkn,
        o_vsyncn => o_core_vsync_l,
        o_hsyncn => hsync_l,
        o_cmpblk2_l => cmpblk2n,
        o_pixel_core_clock => o_pixel_clk,
        o_1_hb => h_1,
        o_vf_2 => vf_2,
        o_r => o_core_red,
        o_g => o_core_green,
        o_b => o_core_blue,
        o_vram_busyn => vram_busy_l,
        i_vram_wrn => vram_wr_l,
        i_vram_rdn => vram_rd_l,
        i_psl_2 => '0',
        i_addr => addr_bus(9 downto 0),
        i_vid_data_in => video_data_in,
        o_vid_data_out => video_data_out,
        i_game_palette => "00",
        i_objwrn => obj_wr_l,
        i_objrdn => obj_rd_l,
        i_objrqn => obj_rq_l,
        i_flipn => '1',
        i_invert_colors_n => '0'
    );
    
     u_Dkong_Audio : entity work.dkong_audio
     port map (
        i_rst_l => not i_core_reset,
        i_sound_cpu_clk => i_clk_audio_6M,
        i_sound_cpu_clk_shifter => i_clk_audio_12M,
    
        -- CPU son
        i_audio_effects => (walk => '1', jump => '1', barrel => '1',
            boom => '1', spring => '1', gorilla_fall => '1'), 
        
        i_sound_int_n => '1',        
        i_sound_data => (others => '0'),
    
        i_sound_PB5 => '1',
        i_2_VF => '1'
        
        -- o_sound_boom_1 : out std_logic; -- Pilotage transisotr Q2 = i_sound_boom_1
        -- o_sound_boom_2 : out std_logic; -- Pilotage transisotr Q1
        -- o_dac_vref : out std_logic;
        -- o_io_sound : out std_logic;
        -- o_sound_walk : out std_logic;
        -- o_sound_jump : out std_logic;
        -- o_sound_boom : out std_logic
     );
    
    u_DKong_Adec : entity work.dkong_adec
    port map (
        i_rst => i_core_reset,
        i_clk_audio_12M => i_clk_audio_12M,
        i_addr => i_cpu_a,
        i_data => i_cpu_do(3 downto 0),
        i_vblk_l => v_blkn,
        i_vram_busy => vram_busy_l,
        i_rfrsh_l => i_cpu_rfsh_l,
        i_mreq_comb_l => i_cpu_mreq_l,
        i_rd_l => i_cpu_rd_l,
        i_wr_l => i_cpu_wr_l,
        i_h_1 => h_1,
        
        o_objrd_l => open,
        o_objwr_l => open,
        o_objrq_l => open,
        o_vram_wr_l => open,
        o_vram_rd_l => open,
        o_cpu_wait_l => open,
        o_nmi_l => open,
        o_ram_34A_cs_l => open,
        o_ram_34B_cs_l => open,
        o_ram_34C_cs_l => open,
        
        o_rom_cs_l => open,
        o_dma_cs_l => open,
        o_in1_cs_l => open,
        o_in2_cs_l => open,
        o_in3_cs_l => open,
        o_dipsw_cs_l => open,
        o_5H_cs_l => open,
        o_6H_cs_l => open,
        o_3D_cs_l => open
    );       
    
    -- ROMs 5A, 5B, 5C, 5E
    u_rom_5A : entity work.dist_mem_gen_5A port map(a => addr_bus(11 downto 0), spo => data_5A);
    u_rom_5B : entity work.dist_mem_gen_5B port map(a => addr_bus(11 downto 0), spo => data_5B);
    u_rom_5C : entity work.dist_mem_gen_5C port map(a => addr_bus(11 downto 0), spo => data_5C);
    u_rom_5E : entity work.dist_mem_gen_5E port map(a => addr_bus(11 downto 0), spo => data_5E);
    
    -- RAMs 3A, 4A, 3B, 4B, 3C, 4C
    u_ram_34_A : entity work.blk_mem_gen_34A port map (clka => i_clk, wea(0) => i_cpu_wr_l, addra => addr_bus(9 downto 0), dina => ram_data_in_34_A, douta => ram_data_out_34_A);
    u_ram_34_B : entity work.blk_mem_gen_34B port map (clka => i_clk, wea(0) => i_cpu_wr_l, addra => addr_bus(9 downto 0), dina => ram_data_in_34_B, douta => ram_data_out_34_B);
    u_ram_34_C : entity work.blk_mem_gen_34C port map (clka => i_clk, wea(0) => i_cpu_wr_l, addra => addr_bus(9 downto 0), dina => ram_data_in_34_C, douta => ram_data_out_34_C);

end Behavioral;
