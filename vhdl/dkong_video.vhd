----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.11.2023 12:37:56
-- Design Name: 
-- Module Name: dkong_video - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- Mapping adresses:
-- A15 A14 A13 A12 A11 A10
-- 0   0   0   0   0   0 => 0x00 CSn ROM 5E
-- 0   0   0   1   0   0 => 0x10 CSn ROM 5C
-- 0   0   1   0   0   0 => 0x20 CSn ROM 5B
-- 0   0   1   1   0   0 => 0x30 CSn ROM 5A
--
-- 0   1   0   0   0   0 => 0x40
-- 0   1   0   1   0   0 => 0x50
-- 0   1   1   0   0   0 => 0x6000 (RAM)
-- 0   1   1   0   0   1 => 0x6100 (RAM)
-- 0   1   1   0   1   0 => 0x6200 (RAM)
-- 0   1   1   1   0   0 => 0x7000 (OBJWRn ou OBJRDn contrôle par les signaux CPU WRn/RDn)
-- 0   1   1   1   0   1 => 0x7400 (VRAMWRn ou VRAMRDn contrôle par les signaux CPU WRn/RDn)

entity dk_tg4_video is
    Port (  i_clk : in std_logic;
            i_rst : in std_logic;
            o_vblkn : out std_logic;
            o_vsyncn : out std_logic;
            o_hsyncn : out std_logic;
            o_r : out std_logic_vector(2 downto 0);
            o_g : out std_logic_vector(2 downto 0);
            o_b : out std_logic_vector(1 downto 0); 
            o_cmpblk2_l : out std_logic;
            o_pixel_core_clock : out std_logic;
            o_1_hb : out std_logic;
            o_vf_2 : out std_logic;
            o_esblkn : out std_logic;
            o_vram_busyn : out std_logic;
            i_vram_wrn : in std_logic;
            i_vram_rdn : in std_logic;
            i_game_palette : in std_logic_vector(1 downto 0);
            i_psl_2 : in std_logic;
            i_addr : in std_logic_vector(9 downto 0);
            i_vid_data_in : in std_logic_vector(7 downto 0);
            o_vid_data_out : out std_logic_vector(7 downto 0);
            i_objwrn : in std_logic;
            i_objrdn : in std_logic;
            i_objrqn : in std_logic;
            i_flipn : in std_logic;
            i_invert_colors_n : in std_logic
        );
    
end dk_tg4_video;

architecture Behavioral of dk_tg4_video is

signal Phi34, Phi34n, g_3K : std_logic;
signal h, hpo, vfc, S_7_8_J, S_78R, S_78P : unsigned(7 downto 0);
signal h_128, h_128n, h_256, h_256n : std_logic;
signal cnt : unsigned(3 downto 0);
signal dc, da : std_logic_vector(5 downto 0);
signal cd, db, data_2N, A_4M, B_4M, Y_4M : std_logic_vector(3 downto 0);
signal mb7074_addr, hd, Q_6H, data_7C, data_7D, data_7E, data_7F, U2PR_tile_id_in, Q_6J : std_logic_vector(7 downto 0);
signal data_6N, din_6PR, dout_6PR, datain_7M, data_tile_1, data_tile_2, U2PR_tile_id_out : std_logic_vector(7 downto 0);
signal shift_reg_U4N, shift_reg_U4P  : std_logic_vector(0 to 7);
signal addr_6PR: std_logic_vector(9 downto 0);
signal mb7074_do_2E, mb7074_do_2H, col : std_logic_vector(3 downto 0);
signal s2, vblk : std_logic;
signal v : unsigned(8 downto 0);
signal Q2_3A, Q1_3A, v_clk : std_logic;
signal Q1_3B, Q2_3B : std_logic;
signal vf : std_logic_vector(7 downto 0);
signal Q7_6K, Q5_6K, Q4_6K, G_5F, O1A_5F : std_logic;
signal O3A_5F : std_logic;
signal O2B_5F : std_logic;
signal O1B_5F, O0B_5F, u8h_O0B_5F_0 : std_logic;
signal I1C_I0D_8B, Q7_8H, Q1_8H, Q0_8H, Q6_8H, Q1_8N  : std_logic;
signal clk_u3E4E, mb7074_wr, csn_6PR : std_logic;
signal Q_5KL : unsigned(7 downto 0);
signal scanline_wr_l, scanline_wr_l_0 : std_logic;
signal Q0_4P, Q0_4N, Q7_4P, Q7_4N : std_logic;
signal DI0_7M, Q_4L, u1ef_clr_l, rom_u2F_cs_l : std_logic;
signal addr_7M : std_logic_vector(5 downto 0);
signal dataout_7M : std_logic_vector(8 downto 0);
signal addr_7CDEF, addr_tiles_data_3PN, Y_6_7_8_S, A_6_7_8_S, B_6_7_8_S : std_logic_vector(10 downto 0);
signal vid_0, vid_1, S0_U4PN, S1_U4PN : std_logic;

signal vram_busy, esblk, tile_shift_reg_reload_l, sprite_reload_S1, sprite_reload_S0 : std_logic;
signal do_draw_l, u6pr_ram_wr : std_logic;
signal U8B_sprite_data, sprite_shifter : std_logic_vector(1 downto 0);
signal addr_ram_tiles : std_logic_vector(9 downto 0);
signal addr_tiles_ram_cs_l, char_tile_reload, U234S_S, clk_color_latch : std_logic;
signal scanline_wr, clk_4KL, clk_4KL_0, clr_u3E4E_l, load_u3E4E_l, cmpblk2_l : std_logic;
signal final_vid, S_U4PN : std_logic_vector(1 downto 0);
signal final_col, A_U8B, B_U8B, Y_U8B : std_logic_vector(3 downto 0);
signal addr_2EF, data_2E, data_2F, U6K_D, U6K_Q : std_logic_vector(7 downto 0);
signal cnt_vsync, cnt_hsync, Q_3_4_E : unsigned(7 downto 0);
signal hsyncn, vsyncn, flip_1, flip_2, flip_3, flip_4, flip_5 : std_logic;
signal Q0_8CD, Q15_8CD, Q0_8EF, Q15_8EF : std_logic;
signal U8CD_reg, U8CD_sprite_data, U8EF_reg, U8EF_sprite_data : std_logic_vector(15 downto 0);
signal h_cnt : unsigned(11 downto 0);
signal h_256_0, v_4_0, v_clk_0 : std_logic;
signal h_256n_0, u8n_O0B_5F_0, u1e_h_0_0, u6j_O2B_5F_0 : std_logic;

-- VSYNC_P = Nombre de pulse Phi34 entre le début de VBLK et le début du pulse signal VSYNCn
-- VSYNC_W = Nombre de pulse Phi34 pour la durée de VSYNCn
constant VSYNC_P : unsigned(7 downto 0) := X"F2";
constant VSYNC_W : unsigned(7 downto 0) := X"08";

-- HSYNC_P = Nombre de pulse Phi34 entre le début de h_256 et le début du pulse signal HSYNCn
-- HSYNC_W = Nombre de pulse Phi34 pour la durée de VSYNCn
constant HSYNC_P : unsigned(7 downto 0) := X"E7";
constant HSYNC_W : unsigned(7 downto 0) := X"10";

attribute DONT_TOUCH : string;
attribute DONT_TOUCH of h, Phi34n, Phi34 : signal is "true";

-- Debug
-- attribute MARK_DEBUG : string;
-- attribute MARK_DEBUG of o_vblkn, o_vsyncn, o_hblkn, o_hsyncn, o_r, o_g, o_b, o_cmpsyncn, o_1_2_hb, o_1_hb, o_vf_2, o_esblkn, vf : signal is "true";    

begin

    -- 1E, 1F, 1H - Video sheet schematic
    p_mc10136 : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            cnt <= X"0";
        elsif rising_edge(i_clk) then
            if (s2 = '0') then
                cnt <= (others => '0');
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process;
    
    s2 <= not cnt(2);
    g_3K <= not(cnt(1) or cnt(2));
    Phi34n <= not cnt(1);
    Phi34 <= cnt(1);

    -- U1L, U1M, U1N                       
    p_u1lmn : process(Phi34n, i_rst)
    begin
        if i_rst = '1' then
            h_cnt <= X"D00";
        elsif rising_edge(Phi34n) then
            if (h_cnt = X"FFF") then
                h_cnt <= X"D00";
            else
                h_cnt <= h_cnt + 1;
            end if;
        end if;
    end process;
    h <= h_cnt(7 downto 0);
    h_128n <= h_cnt(9);
    h_256n <= h_cnt(8);
                                           
    -- U1L, U1M, U1N 
    -- h_128n <= h_256;
    h_128 <= not h_128n;
    -- h_256n <= h_128;
    h_256 <= not h_256n;
    
    -- U3A
    -- U3A : entity work.SN74123N
    -- generic map (
    --  W1 => 1359ns,
    --  W2 => 12516ns
    -- ) 
    -- port map(
    --     X_1 => Q2_3A,
    --     X_2 => '1',
    --     X_3 => not i_rst,
    --     X_5 => Q2_3A,
    --     X_9 => '0',
    --     X_10 => h_256,
    --     X_11 => not i_rst,
    --     X_13 => Q1_3A
    -- );
    
    -- hsyncn <= not Q1_3A;

    -- Equivalent U3A synthetisable
    p_u3a : process(h(1), h_256, i_rst)
    begin
        if (h_256 = '0') or (i_rst = '1') then
            cnt_hsync <= HSYNC_P;
        elsif rising_edge(h(1)) then
            cnt_hsync <= cnt_hsync + 1;
        end if;
    end process;
    
    hsyncn <= '0' when (cnt_hsync < HSYNC_W) else '1';    
    
    -- U3B
    -- Equivalent U3B synthetisable
    p_u3b : process(Phi34, vblk, i_rst)
    begin
        if (vblk = '0') or (i_rst = '1') then
            cnt_vsync <= VSYNC_P;
        elsif rising_edge(Phi34) then
            -- Detection front montant h_256
            h_256_0 <= h_256;
            if (h_256 = '1') and (h_256_0 = '0') then  
                cnt_vsync <= cnt_vsync + 1;
            end if;
        end if;
    end process;
    
    vsyncn <= '0' when (cnt_vsync < VSYNC_W) else '1';
    
    -- U6B
    o_hsyncn <= hsyncn;
    o_vsyncn <= vsyncn;
    o_cmpblk2_l <= cmpblk2_l;
    
    -- U4A, U4B, U5D, U6D   
    U4A : process(h(5), h_256)
    begin
        if (h_256 = '0') then
            v_clk <= '0';
        elsif rising_edge(h(5)) then
            if (not((not(h(7))) and h(6))) = '1' then
                v_clk <= '0';
            else
                v_clk <= '1';
            end if;
        end if;
    end process;

    U4B : process(v(4))
    begin
        if rising_edge(v(4)) then
            if (v(7 downto 5) = "111") then
                vblk <='1';
            else
                vblk <='0';
            end if;
        end if;
    end process;
    o_vblkn <= not vblk;
    
    U56D : process(i_rst, v_clk)
    begin
         if (i_rst = '1') then
            v <= (others => '0');
         elsif rising_edge(v_clk) then
            if (v = "1" & X"FF") then
                v <= "011111000";
            else 
                v <= v + 1;
            end if;
         end if;
    end process;  

    -- U5E, U6E
    vf <= (flip_3 & flip_3 & flip_3 & flip_3 & flip_3 & flip_3 & flip_3 & flip_3) xor std_logic_vector(v(7 downto 0));

    U56E : process(Phi34)
    begin
        if rising_edge(Phi34) then
            h_256n_0 <= h_256n;
            -- Detection front montant h_256n
            if (h_256n = '1') and (h_256n_0 = '0') then  
                vfc <= unsigned(vf);
            end if;
        end if;
    end process;
    
    -- U3J, U4J
    -- Les sortie de 3J/4J sont a zero dans le cas du LS157 si Q5_6K (G) =1
    dc <= (others => '0') when Q5_6K = '1' else da when U8B_sprite_data = "00" else (cd & U8B_sprite_data(1 downto 0));  
    
    -- U5F
    G_5F <= not (h(0) and h(1) and h(2) and h(3));
    U5F : entity work.SN74LS139N(SYNTH) port map (X_1 => G_5F, X_2 => h(3), X_3 => h_256n, X_5 => O1A_5F, X_7 => O3A_5F,
                                    X_13 => h(3), X_14 => h(2), X_15 => '0', X_10 => O2B_5F, X_11 => O1B_5F, X_12 => O0B_5F);
    -- U3E, U4E
    clr_u3E4E_l <= (O3A_5F or Q5_6K);
    load_u3E4E_l <= O1A_5F;

	clk_u3E4E <= not ((not(((not h(0)) and Q5_6K))) and Phi34);
	
	U3E4E : process(clk_u3E4E)
	begin
	   if rising_edge(clk_u3E4E) then	
         if(load_u3E4E_l = '0') then
             Q_3_4_E <= hpo;
         elsif (clr_u3E4E_l = '0') then
             Q_3_4_E <= (others => '0');
         else
             Q_3_4_E <= Q_3_4_E + 1;
         end if;
       end if;
    end process;    

    mb7074_wr <= not clk_u3E4E;
    mb7074_addr <= (Q_3_4_E(7) & Q_3_4_E(6) & Q_3_4_E(5) & Q_3_4_E(4) & Q_3_4_E(3) & Q_3_4_E(2) & Q_3_4_E(1) & Q_3_4_E(0))
         xor (Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K);
        
    -- 2E, 2H, 3K
    U2E : entity work.blk_mem_gen_2E port map (clka => i_clk, wea(0) => mb7074_wr, addra => mb7074_addr , dina => dc(5 downto 3) & '0', douta => mb7074_do_2E);
    U2H : entity work.blk_mem_gen_2H port map (clka => i_clk, wea(0) => mb7074_wr, addra => mb7074_addr , dina => dc(2 downto 0) & '0', douta => mb7074_do_2H);
    
    U3K : process (g_3K)
    begin
        if falling_edge(g_3K) then
            da <= mb7074_do_2E(3 downto 1) & mb7074_do_2H(3 downto 1);
        end if;
    end process;

    -- 6J, 6K
    -- U6J
    process(O2B_5F) is
    begin
        if rising_edge(O2B_5F) then
            Q_6J <= hd;
        end if;
    end process;
    
    -- U6K
    U6K_D <= (Q_6J(7), not (h_256 or vblk), h_256n, not (h_256 or flip_2), Q_6J(3), Q_6J(2), Q_6J(1), Q_6J(0));
    (Q7_6K, cmpblk2_l, Q5_6K, Q4_6K, cd(3), cd(2), cd(1), cd(0)) <= U6K_Q;
	process(Phi34n)
	begin
		if rising_edge(Phi34n) then
			if (G_5F = '0') then
				U6K_Q <= U6K_D;
			end if;
		end if;
	end process;
    
    -- U6H
    U6H : process (Phi34n)
    begin
        if rising_edge(Phi34n) then
            if O1B_5F = '0' then
                Q_6H <= hd(7 downto 0);
            end if;
        end if;
    end process;

    -- U7C, U7D, U7E, U7F
    addr_7CDEF <= Q_6H(6 downto 0) & (db(3 downto 0) xor (Q_6H(7) & Q_6H(7) & Q_6H(7) & Q_6H(7)));
    U7C_sprite_bank_1 : entity work.dist_mem_gen_7C port map(a => addr_7CDEF, spo => data_7C);
    U7D_sprite_bank_2 : entity work.dist_mem_gen_7D port map(a => addr_7CDEF, spo => data_7D);
    U7E_sprite_bank_3 : entity work.dist_mem_gen_7E port map(a => addr_7CDEF, spo => data_7E);
    U7F_sprite_bank_4 : entity work.dist_mem_gen_7F port map(a => addr_7CDEF, spo => data_7F);
    
    -- 8B
    (U8B_sprite_data(0), U8B_sprite_data(1), sprite_reload_S1, sprite_reload_S0) <= Y_U8B;
    A_U8B <= (Q0_8CD, Q0_8EF, '1', I1C_I0D_8B);
    B_U8B <= (Q15_8CD, Q15_8EF, I1C_I0D_8B, '1');                            
    Y_U8B <= A_U8B when Q7_6K = '0' else B_U8B;
    I1C_I0D_8B <= not (((not (Q7_8H and Q0_8H and Q1_8H and Q6_8H)) or Q1_8N) or G_5F);
    
	-- U8C, U8D
	sprite_shifter <= sprite_reload_S1 & sprite_reload_S0;
    -- Les données en entrée des registres a decalage 8C, 8D, 8E, 8F sont inversees par rapport
    -- a la sortie des mémoires 7C, 7D, 7E, 7F.
	U8CD_sprite_data <= data_7C & data_7D;
	                    
	process(Phi34n)
	begin
		if rising_edge(Phi34n) then
			case sprite_shifter is
			    -- Shift left
				when "10" => U8CD_reg <= U8CD_reg(14 downto 0) & '0';
				-- Shift right
				when "01" => U8CD_reg <= '0' & U8CD_reg(15 downto 1);
				-- Parallel load
				when "11" => U8CD_reg <= U8CD_sprite_data;
				when others => null;
			end case;
		end if;
	end process;
	Q15_8CD	<= U8CD_reg(0);
	Q0_8CD	<= U8CD_reg(15);	                          
                            
    -- Les données en entrée des registres a decalage 8C, 8D, 8E, 8F sont inversees par rapport
    -- a la sortie des mémoires 7C, 7D, 7E, 7F.
	U8EF_sprite_data <= data_7E & data_7F;
	
	process(Phi34n)
	begin
		if rising_edge(Phi34n) then
			case sprite_shifter is
				when "10" => U8EF_reg <= U8EF_reg(14 downto 0) & '0';
				when "01" => U8EF_reg <= '0' & U8EF_reg(15 downto 1);
				when "11" => U8EF_reg <= U8EF_sprite_data;
				when others => null;
			end case;
		end if;
	end process;
    Q15_8EF	<= U8EF_reg(0);
	Q0_8EF	<= U8EF_reg(15);
    
    -- U7K, U8K, U7J, U8J
    hpo	<= unsigned(hd) + ("1111" & flip_5 & flip_4 & flip_4 & '1') + 1;
	S_7_8_J	<= vfc + hpo;
                          
    -- U8H
    U8H : process(O0B_5F)
    begin
        if rising_edge(O0B_5F) then
            db <= std_logic_vector(S_7_8_J(3 downto 0));
            (Q6_8H, Q1_8H, Q0_8H, Q7_8H) <= S_7_8_J(7 downto 4);
        end if;
    end process;
    
    -- U8N
    U8N : process(O0B_5F, h_256)
        variable q_tmp : std_logic;
	begin
        if h_256 = '0' then
		  q_tmp := '0';
		elsif rising_edge(O0B_5F) then
          -- La memoire 93419 est a collector ouvert en sortie, les bits sont donc inversés, ce qui n'est pas
          -- le cas avec une memoire classique comme avec l'Artyx 7, on inverse donc la valeur de dataout_7M(0) par rapport au schema
          -- dataout_7M(0) = '0' => J=1, K=1 avec l'inversion memoire du schema original
          if dataout_7M(0) = '0' then
              -- Flip-flop toggle		      
              q_tmp := not q_tmp;
          -- J=0, K=1
          else
              q_tmp := '0';
          end if;
		end if;
		
		Q1_8N <= q_tmp;
	end process;	                                     
    
    -- Zone A-J 1-9
    -- U3L, U3M
    final_col <= col when da(1 downto 0) = "00" else da(5 downto 2);
    final_vid <= (vid_1 & vid_0) when da(1 downto 0) = "00" else da(1 downto 0);
    U1EF: process(h(0), cmpblk2_l, u1ef_clr_l) is
    begin
        if (cmpblk2_l = '0') or (u1ef_clr_l = '0') then
            addr_2EF <= (others => '0');
            rom_u2F_cs_l <= '1';
            u1ef_clr_l <= '1';
        elsif rising_edge(h(0)) then
            addr_2EF <= i_game_palette & final_col & final_vid;
            rom_u2F_cs_l <= not (final_vid(0) or final_vid(1));
            u1ef_clr_l <= cmpblk2_l;
        end if;
    end process;        
                                                  
    -- U2E, U2F (sur la carte CPU)
    U2E_COL : entity work.dist_mem_gen_2E port map (a => addr_2EF, spo => data_2E);
    U2F_COL : entity work.dist_mem_gen_2F port map (a => addr_2EF, spo => data_2F);

    o_r <= data_2E(3 downto 1) when rom_u2F_cs_l = '0' else (others => '1');
    o_g <= data_2E(0) & data_2F(3 downto 2) when rom_u2F_cs_l = '0' else (others => '1');
    o_b <= data_2F(1 downto 0) when rom_u2F_cs_l = '0' else (others => '1');
                                   
    -- U6S, U7S, U8S
    (csn_6PR, addr_6PR) <= Y_6_7_8_S;
    A_6_7_8_S <= ((i_objwrn and i_objrdn), addr_6PR(9 downto 0));
    B_6_7_8_S <= ('0', i_psl_2, h_128, h(7), h(6), h(5), h(4), h(3), h(2), h(1), h(0));
    Y_6_7_8_S <= A_6_7_8_S when (i_objwrn and i_objrdn and i_objrqn) = '0' else B_6_7_8_S;

    -- U5S                  
    din_6PR <= i_vid_data_in when (i_objwrn = '0') and ((i_objrdn and i_objwrn) = '0') else (others => 'X');
                                   
    -- 6P, 6R
    u6pr_ram_wr <= not i_objwrn;
    U6PR : entity work.blk_mem_gen_6PR port map(clka => Phi34, ena => not csn_6PR, wea(0) => u6pr_ram_wr, addra => addr_6PR, dina => din_6PR, douta => dout_6PR);
    
    -- U6N, U6M
    U6N : process(Phi34n)
    begin
        if rising_edge(Phi34n) then
            data_6N <= dout_6PR;
        end if;
    end process;
                                       
    -- U6M
    U6M : process(Phi34n)
    begin
        if rising_edge(Phi34n) then
            datain_7M <= data_6N;
        end if;
    end process;

    -- U7R, U8R
    S_78R <= unsigned(data_6N) + ("1111" & i_flipn & flip_1 & flip_1 & '1') + 1;

	-- U7P, U8P
    S_78P <= unsigned(vf) + S_78R;
                                   
    DI0_7M <= not ((not(Q_5KL(6) or Q_5KL(7))) and h(2) and h(3) and h(4) and h(5) and h(6) and h(7) and h_128);
    do_draw_l <= not(S_78P(7) and S_78P(6) and S_78P(5) and S_78P(4));
    
    -- U5L, U5K
    scanline_wr_l <= not((not(Q_5KL(6) or Q_5KL(7))) and Q_4L and h_256n and Phi34);
 
    p_u5kl : process(scanline_wr_l, h_256n)
    begin
        if (h_256n = '0') then
            Q_5KL <= (others => '0');
        elsif rising_edge(scanline_wr_l) then
            Q_5KL <= Q_5KL + 1;
        end if;
    end process;
                                                         
    -- U4L
    clk_4KL <= not ((not h(1)) and h(0));
    U4L : process(clk_4KL, h_256n)
    begin
        if (h_256n = '0') then
            Q_4L <= '0';
        elsif rising_edge(clk_4KL) then
            if (not (do_draw_l and DI0_7M)) = '1' then
                Q_4L <='1';
            else
                Q_4L <='0';
            end if;
        end if;
    end process;
                               
    -- U5N, U5M                       
    addr_7M <= (h(7) & h(6) & h(5) & h(4) & h(3) & h(2)) when h_256n = '0' else (Q_5KL(5) & Q_5KL(4) & Q_5KL(3) & Q_5KL(2) & Q_5KL(1) & Q_5KL(0));    
    
    -- Scanline buffer (64 x 9 bits)
    scanline_wr <= not scanline_wr_l;
    U7M : entity work.blk_mem_gen_7M port map (clka => Phi34n, wea(0) => scanline_wr, addra => addr_7M , dina => datain_7M & DI0_7M , douta => dataout_7M);
    -- La memoire 93419 est a collector ouvert en sortie, les bits sont donc inversés, ce qui n'est pas
    -- le cas avec une memoire classique comme avec l'Artyx 7, on n'inverse donc pas dataout_7M contrairement au schema
    -- L'ordre des bits n'est pas inverse entre dataout_7M et hd car il y a déjà une inversion entre l'entree et la sortie de U6M => Ca ne change rien
    hd <= dataout_7M(8 downto 1);
    
    -- U2K
    -- U2K part 1
    U2K_1 : process(h(5), h_256)
    begin
        if (h_256 = '0') then
           esblk  <= '1';
        elsif rising_edge(h(5)) then
            if (h(6) = '1') then
                esblk <='0';
            else
                esblk <='1';
            end if;
        end if;
    end process; 
  
    -- U2K part 2
    U2K_2 : process(h(2), h_256)
    begin
        if (h_256 = '0') then
           vram_busy <= '1';
        elsif rising_edge(h(2)) then
            if (h(7 downto 4) = "1111") then
                vram_busy <='0';
            else
                vram_busy <='1';
            end if;
        end if;
    end process;

    o_vram_busyn <= not vram_busy;
    o_esblkn <= not esblk;
    -- Dephasage de h(0) pour resoudre des problemes de timing dans l'ecriture de la RAM du controlleur VGA 
    o_pixel_core_clock <= h(0);
    o_1_hb <= h(1);
    o_vf_2 <= vf(1);

    -- U2S, U3S, U4S
    U234S_S <= not (vblk or h_256);
    addr_ram_tiles <= i_addr(9 downto 0) when U234S_S = '0' else 
                        vf(7) & vf(6) & vf(5) & vf(4) & vf(3) & 
                        (h_128 xor flip_1) & (h(7) xor flip_1) &
                        (h(6) xor flip_1) & (h(5) xor flip_1) & (h(4) xor flip_1);
                        
    addr_tiles_ram_cs_l <= (not i_vram_wrn) and (not i_vram_rdn) when U234S_S = '0' else '0';
    char_tile_reload <= '1' when U234S_S = '0' else '0';
                  
    -- U1S
    U2PR_tile_id_in <= i_vid_data_in when i_vram_wrn = '0' else (others => '0');
    
    p_video_data_sel : process(i_objrdn, i_vram_rdn, U2PR_tile_id_out, dout_6PR)
    begin
        o_vid_data_out <= (others => '0');
        if (i_objrdn = '0') then
            o_vid_data_out <= dout_6PR;
        elsif (i_vram_rdn = '0') then
            o_vid_data_out <= U2PR_tile_id_out;
        end if;
    end process;
    
    U2PR : entity work.blk_mem_gen_2PR port map (clka => Phi34, wea(0) => not(i_vram_wrn), 
                                addra => addr_ram_tiles, dina => U2PR_tile_id_in, douta => U2PR_tile_id_out, ena => not addr_tiles_ram_cs_l);

    U2N : entity work.dist_mem_gen_2N port map (a => addr_ram_tiles(9 downto 7)& addr_ram_tiles(4 downto 0), spo => data_2N);
    
    clk_color_latch <= not(h(3) and h(2) and h(1));

    -- U2M
    U2M: process(clk_color_latch)
    begin
        if rising_edge(clk_color_latch) then
            col <= data_2N;
        end if;
    end process;                                         

    addr_tiles_data_3PN <= U2PR_tile_id_out & vf(2 downto 0);
    U3P_tile_bank_1 : entity work.dist_mem_gen_3P port map (a => addr_tiles_data_3PN, spo => data_tile_1);
    U3N_tile_bank_2 : entity work.dist_mem_gen_3N port map (a => addr_tiles_data_3PN, spo => data_tile_2);

    -- U4P                               
	U4P : process(h(0))
	begin
        if falling_edge(h(0)) then
            case S_U4PN is
                when "10" => shift_reg_U4P <= shift_reg_U4P(1 to 7) & '0'; -- Shift left
                when "01" => shift_reg_U4P <= '0' & shift_reg_U4P(0 to 6); -- Shift right
                when "11" => shift_reg_U4P <= data_tile_1;                     -- Parallel load
                when others => null;
            end case;
		end if;
	end process;
	Q7_4P	<= shift_reg_U4P(7);
	Q0_4P	<= shift_reg_U4P(0);	                                   

    -- U4N                               
	process(h(0))
	begin
      if falling_edge(h(0)) then
        case S_U4PN is
            when "10" => shift_reg_U4N <= shift_reg_U4N(1 to 7) & '0'; -- Shift left
            when "01" => shift_reg_U4N <= '0' & shift_reg_U4N(0 to 6); -- Shift right
            when "11" => shift_reg_U4N <= data_tile_2;                 -- Parallel load
            when others => null;
        end case;
      end if;
	end process;
	Q7_4N	<= shift_reg_U4N(7);
	Q0_4N	<= shift_reg_U4N(0);	                                                                      
	
	S_U4PN <= S1_U4PN & S0_U4PN;
	    
    tile_shift_reg_reload_l <= (not clk_color_latch) and (not char_tile_reload);
    -- U4M
    A_4M <= (Q0_4P, Q0_4N, '1', tile_shift_reg_reload_l);
    B_4M <= (Q7_4P, Q7_4N, '1', tile_shift_reg_reload_l);
    (vid_1, vid_0, S1_U4PN, S0_U4PN) <= Y_4M;
    Y_4M <= A_4M when flip_1 = '0' else B_4M;
    
    flip_1 <= not i_flipn;
    -- flip_2 <= flip_1 xor '0'; -- 3R
    flip_2 <= not flip_1; -- 3R
    flip_3 <= not flip_2;
    -- flip_4 <= (not flip_3) and (not O0B_5F);
    flip_4 <= flip_3 or O0B_5F;
    flip_5 <= not flip_4;

end Behavioral;