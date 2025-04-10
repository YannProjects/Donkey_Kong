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

entity dkong_core_top is
port (
    -- System clock (61.44 MHz)
    i_clk                 : in  std_logic;
    i_clk_audio_6M        : in  std_logic; -- Clock audio
    i_core_reset          : in  std_logic; -- actif niveau haut

    -- Video
    o_core_red            : out std_logic_vector(2 downto 0);
    o_core_green          : out std_logic_vector(2 downto 0);
    o_core_blue           : out std_logic_vector(1 downto 0);
    o_core_blank          : out std_logic;
    o_core_vsync_l        : out std_logic;
    
    -- Entrees
    i_config_reg          : in std_logic_vector(7 downto 0);
    o_in1_cs_l            : out std_logic;
    o_in2_cs_l            : out std_logic;
    o_in3_cs_l            : out std_logic;
    o_dipsw_cs_l          : out std_logic;
    
    -- Sorties
    o_boom_1              : out std_logic;
    o_boom_2              : out std_logic;
    o_boom                : out std_logic;    
    o_dac_vref            : out std_logic;
    o_walk                : out std_logic;
    o_jump                : out std_logic;
    
    -- Z80    
    i_cpu_a               : in std_logic_vector(15 downto 0);  -- Z80 adresse bus
    o_cpu_di              : out std_logic_vector(7 downto 0);  -- Z80 data input
    i_cpu_do              : in std_logic_vector(7 downto 0);  -- Z80 data output
    
    o_cpu_rst_l           : out std_logic; -- Z80 reset
    o_cpu_clk             : out std_logic; -- Z80 clk
    o_cpu_wait_l          : out std_logic; -- Z80 wait
    o_cpu_nmi_l           : out std_logic; -- Z80 NMI
    o_cpu_busrq           : out std_logic; -- Z80 BUSRQn
    i_cpu_m1_l            : in std_logic; -- Z80 M1
    i_cpu_mreq_l          : in std_logic; -- Z80 MREQ
    i_cpu_rd_l            : in std_logic; -- Z80 RD
    i_cpu_wr_l            : in std_logic; -- Z80 WR
    i_cpu_rfsh_l          : in std_logic; -- Z80 RFRSH
    i_cpu_busack_l        : in std_logic; -- Z80 BUSACKn
    
    o_rom_cs_l            : out std_logic; -- Lecture ROM programme
    o_uart_cs_l           : out std_logic; -- UART
    o_pixel_clk           : out std_logic
    
    );
end dkong_core_top;

architecture Behavioral of dkong_core_top is

-- CPU_RST_P = Nombre de pulse Phi34 entre le d�but de i_core_reset et le d�but du pulse de reset CPU/DMA
-- CPU_RST_W = Nombre de pulse Phi34 pour la dur�e du pulse de reset CPU/DMA
constant CPU_RST_P : unsigned(15 downto 0) := to_unsigned(1000, 16);
constant CPU_RST_W : unsigned(15 downto 0) := to_unsigned(10000, 16);

signal cnt_reset : unsigned(15 downto 0);
signal v_blkn, h_1, vf_2 : std_logic;
signal vram_busy_l, vram_wr_l, vram_rd_l, psl_2, obj_wr_l, obj_rd_l, obj_rq_l : std_logic;
signal video_data_out, ram_data_in_34_A, ram_data_in_34_B, ram_data_in_34_C : std_logic_vector(7 downto 0);
signal ram_data_out_34_A, ram_data_out_34_B, ram_data_out_34_C, data_5A, data_5B, data_5C, data_5E : std_logic_vector(7 downto 0);
signal rom_5E_sel_l, rom_5A_sel_l, rom_5B_sel_l, rom_5C_sel_l, ram_sel_l, sprite_vid_ram_sel_l : std_logic;
signal ram_3C4C_sel_l, ram_3B4B_sel_l, ram_3A4A_sel_l, dma_cs_l, vram_wait_l : std_logic;
signal nmi_int_en_l, hsync_l, cmpblk2n, cpu_wait, dma_aen, drq0, dma_adstb : std_logic;
signal dma_iord_l, dma_iowr_l, dma_mem_read_l, dma_mem_write_l, final_mreq_l, dma_busrq : std_logic;
signal dma_ack : std_logic_vector(3 downto 0);
signal dma_master_addr, dma_data_in, dma_data_out, dma_addr_high, dma_data : std_logic_vector(7 downto 0);
signal dma_data_latch, final_bus_data, Q_6H : std_logic_vector(7 downto 0);
signal final_addr : std_logic_vector(15 downto 0);
signal U5H_cs_l, U6H_cs_l, U3D_cs_l, vid_board_mux_en_l : std_logic;
signal ram_34A_cs_l, ram_34B_cs_l, ram_34C_cs_l, objrq_l, final_rd_l, final_wr_l, pb4, final_rfsh_l : std_logic;
signal clear_nmi_l, flip, play_death_music : std_logic;
signal sound_data : std_logic_vector(3 downto 0);
signal bank_palette : std_logic_vector(1 downto 0);
signal in1_cs, in2_cs, in3_cs, dipsw_cs : std_logic; 
signal in1 : r_IN1;
signal in2 : r_IN2;
signal in3 : r_IN3;

begin

    -- CPU reset (�quivalent de U1N)
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
    
    -- DMA i8257
    u_DMA : entity work.i8257
    port map (
        i_clk => not h_1,
        i_reset => i_core_reset,
        i_ready => cpu_wait,
        o_aen => dma_aen,
        i_hdla => not i_cpu_busack_l,
        o_hrq => dma_busrq,
        i_drq => ('0', '0', drq0, drq0),
        o_dackn => dma_ack,
        o_adstb => dma_adstb,
        i_As => final_addr(3 downto 0),
        o_Am => dma_master_addr,
        i_iorsn => i_cpu_rd_l,
        i_iowsn => i_cpu_wr_l,
        o_iormn => dma_iord_l,
        o_iowmn => dma_iowr_l,
        i_Din => final_bus_data,
        o_Dout => dma_data_out,
        i_csn => dma_cs_l,
        o_memrn => dma_mem_read_l,
        o_memwn => dma_mem_write_l,
        o_mark => open,
        o_tc => open
    );
    
    -- U6B (DMA addresses latch)
    U6B : process(h_1)
	begin
        if falling_edge(h_1) then
            if dma_adstb = '1' then
                dma_addr_high <= dma_data_out;
            end if;
        end if;
	end process;
	
	-- U2N (DMA data latch)
    U2N : process(h_1)
	begin
        if falling_edge(h_1) then
            if ((not dma_ack(0)) and not(dma_mem_write_l)) = '1' then
                dma_data_latch <= final_bus_data;
            end if;
        end if;
	end process;

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
        i_psl_2 => psl_2,
        i_addr => final_addr(9 downto 0),
        i_vid_data_in => final_bus_data,
        o_vid_data_out => video_data_out,
        i_game_palette => bank_palette,
        i_objwrn => obj_wr_l,
        i_objrdn => obj_rd_l,
        i_objrqn => obj_rq_l,
        i_flipn => not flip,
        i_invert_colors_n => '0'
    );
    
    u_Dkong_Audio : entity work.dkong_audio
     port map (
        i_rst_l => not i_core_reset,
        i_sound_cpu_clk => i_clk_audio_6M,
    
        -- CPU son
        i_audio_effects => (walk => Q_6H(0), jump => Q_6H(1), boom => Q_6H(2), 
                            spring => Q_6H(3), gorilla_fall => Q_6H(4), barrel => Q_6H(5)),
        
        i_sound_int_n => not play_death_music,  -- An external interrupt will play the death music.      
        i_sound_data => sound_data,
    
        i_2_VF => vf_2,
        
        o_sound_boom_1 => o_boom_1,
        o_sound_boom_2 => o_boom_2,
        o_dac_vref => o_dac_vref,
        o_io_sound => pb4,
        o_sound_walk => o_walk,
        o_sound_jump => o_jump
     );
    
    u_DKong_Adec : entity work.dkong_adec
    port map (
        i_rst => i_core_reset,
        i_addr => final_addr,
        i_vblk_l => v_blkn,
        i_vram_busy_l => vram_busy_l,
        i_rfrsh_l => final_rfsh_l,
        i_mreq_comb_l => final_mreq_l,
        i_rd_l => final_rd_l,
        i_wr_l => final_wr_l,
        i_h_1 => h_1,
        
        o_objrd_l => obj_rd_l,
        o_objwr_l => obj_wr_l,
        o_objrq_l => objrq_l,
        o_vram_wr_l => vram_wr_l,
        o_vram_rd_l => vram_rd_l,
        o_cpu_wait_l => cpu_wait,
        o_ram_34A_cs_l => ram_34A_cs_l,
        o_ram_34B_cs_l => ram_34B_cs_l,
        o_ram_34C_cs_l => ram_34C_cs_l,
        
        o_rom_cs_l => o_rom_cs_l,
        o_uart_cs_l => o_uart_cs_l,
        o_dma_cs_l => dma_cs_l,
        o_in1_cs_l => in1_cs,
        o_in2_cs_l => in2_cs,
        o_in3_cs_l => in3_cs,
        o_dipsw_cs_l => dipsw_cs,
        o_5H_cs_l => U5H_cs_l,
        o_6H_cs_l => U6H_cs_l,
        o_3D_cs_l => U3D_cs_l
    );

    -- U5H
    U5H : process(i_clk, i_core_reset)
	begin
		if i_core_reset = '1' then
			play_death_music <= '0';
			flip <= '0';
			psl_2 <= '0';
			clear_nmi_l <= '0';
			drq0 <= '0';
			bank_palette <= "00";
		elsif rising_edge(i_clk) then
			if U5H_cs_l = '0' then
				case final_addr(2 downto 0) is
					when "000" => play_death_music <= i_cpu_do(0); -- INTn CPU audio
					when "010" => flip <= i_cpu_do(0); -- Flip
					when "011" => psl_2 <= i_cpu_do(0); -- 2 PSL
					when "100" => clear_nmi_l <= i_cpu_do(0); -- Clear NMIn
					when "101" => drq0 <= i_cpu_do(0); -- DMA request
					when "110" => bank_palette(0) <= i_cpu_do(0); -- Palette bank selection
					when "111" => bank_palette(1) <= i_cpu_do(0); -- Palette bank selection
					when others => null;
				end case;
			end if;
		end if;
	end process;

    -- U6H
    U6H : process(i_clk, i_core_reset)
	begin
		if i_core_reset = '1' then
			Q_6H <= (others => '0');
		elsif rising_edge(i_clk) then
			if U6H_cs_l = '0' then
				case final_addr(2 downto 0) is
					when "000" => Q_6H(0) <= i_cpu_do(0);
					when "001" => Q_6H(1) <= i_cpu_do(0);
					when "010" => Q_6H(2) <= i_cpu_do(0);
					when "011" => Q_6H(3) <= i_cpu_do(0);
					when "100" => Q_6H(4) <= i_cpu_do(0);
					when "101" => Q_6H(5) <= i_cpu_do(0);
					when "110" => Q_6H(6) <= i_cpu_do(0);
					when "111" => Q_6H(7) <= i_cpu_do(0);
					when others => null;
				end case;
			end if;
		end if;
	end process;    
  
    -- U3D
    U3D : process(i_clk, i_core_reset)
	begin
		if i_core_reset = '1' then
			sound_data <= (others => '0');
		elsif rising_edge(i_clk) then
		  if U3D_cs_l = '0' then
			sound_data <= i_cpu_do(3 downto 0);
	      end if;
		end if;
	end process;
	
    -- U8F 
    U8F : process(h_1, v_blkn, i_core_reset)
    begin
        if (clear_nmi_l = '0') then
            o_cpu_nmi_l <= '1';
        elsif (i_core_reset = '1') then
            o_cpu_nmi_l <= '0';
        elsif falling_edge(v_blkn) then
            o_cpu_nmi_l <= '0';
        end if;
    end process;
    
    -- RAMs 3A, 4A, 3B, 4B, 3C, 4C
    u_ram_34_A : entity work.blk_mem_gen_34A port map (clka => i_clk, wea(0) => not (final_wr_l or ram_34A_cs_l), addra => final_addr(9 downto 0), dina => final_bus_data, douta => ram_data_out_34_A);
    u_ram_34_B : entity work.blk_mem_gen_34B port map (clka => i_clk, wea(0) => not (final_wr_l or ram_34B_cs_l), addra => final_addr(9 downto 0), dina => final_bus_data, douta => ram_data_out_34_B);
    u_ram_34_C : entity work.blk_mem_gen_34C port map (clka => i_clk, wea(0) => not (final_wr_l or ram_34C_cs_l), addra => final_addr(9 downto 0), dina => final_bus_data, douta => ram_data_out_34_C);
    
    -- Data/Addresses CPU, RAM,...
    final_mreq_l <= i_cpu_mreq_l when dma_aen = '0' else ((not dma_ack(1)) and (not dma_ack(0)));
    -- Utilise pour simuler le niveau 1 sur l'entree G1 de U4D quand le CPU est en HighZ. Il n'y a pas de pull-up
    -- sur ce signal. Mais, quand le DMA contr�le le bus il est en High Z. peut-�tre est-ce que le 74LS138 a une pull-up en interne ???
    final_rfsh_l <= i_cpu_rfsh_l when dma_aen = '0' else '1';
    final_rd_l <= i_cpu_rd_l when dma_aen = '0' else dma_iord_l;
    final_wr_l <= i_cpu_wr_l when dma_aen = '0' else dma_iowr_l;

    final_addr <= (dma_addr_high & dma_master_addr) when dma_aen = '1' else i_cpu_a;    
	final_bus_data <= ram_data_out_34_A when ((ram_34A_cs_l = '0') and (final_wr_l = '1')) else
	                  ram_data_out_34_B when ((ram_34B_cs_l = '0') and (final_wr_l = '1')) else
	                  ram_data_out_34_C when ((ram_34C_cs_l = '0') and (final_wr_l = '1')) else
                      video_data_out when ((vid_board_mux_en_l = '0') and (final_rd_l = '0')) else
                      dma_data_latch when ((not dma_ack(1)) and not(dma_mem_read_l)) = '1' else
                      dma_data_out when ((dma_cs_l = '0') and (final_rd_l = '0')) else
                       -- Les LS240 2P, 4P, 3P, 4N inverses les bits
                      ("000" & not(in1.jump) & not(in1.down) & not(in1.up) & not(in1.left) & not(in1.right) ) when in1_cs = '0' else
                      ("000" & not(in2.jump) & not(in2.down) & not(in2.up) & not(in2.left) & not(in2.right) ) when in2_cs = '0' else 
                      (not(in3.coin) & pb4 & "00" & not(in3.two_players) & not(in3.one_player) & "00") when in3_cs = '0' else
                      (not i_config_reg) when dipsw_cs = '0' else
                      i_cpu_do;

    in1.right <= i_config_reg(0);
    in1.left <= i_config_reg(1);
    in1.up <= i_config_reg(2);
    in1.down <= i_config_reg(3);
    in1.jump <= i_config_reg(5);
    
    in2.right <= i_config_reg(0);
    in2.left <= i_config_reg(1);
    in2.up <= i_config_reg(2);
    in2.down <= i_config_reg(3);
    in2.jump <= i_config_reg(5);

    in3.coin <= i_config_reg(7);
    in3.two_players <= i_config_reg(3);
    in3.one_player <= i_config_reg(2);
    
    o_in1_cs_l <= in1_cs;
    o_in2_cs_l <= in2_cs;
    o_in3_cs_l <= in3_cs;
    o_dipsw_cs_l <= dipsw_cs;    
    
    -- Signaux CPU
    o_cpu_rst_l <= '0' when (cnt_reset >= CPU_RST_P) and (cnt_reset < CPU_RST_W) else '1';
    o_cpu_wait_l <= cpu_wait;
    o_cpu_clk <= h_1;
    o_cpu_busrq <= not dma_busrq;
    o_cpu_di <= final_bus_data;
    

end Behavioral;
