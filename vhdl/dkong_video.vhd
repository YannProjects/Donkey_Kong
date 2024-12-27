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
            o_hblkn : out std_logic;
            o_hsyncn : out std_logic;
            o_r : out std_logic_vector(2 downto 0);
            o_g : out std_logic_vector(2 downto 0);
            o_b : out std_logic_vector(1 downto 0); 
            o_cmpsyncn : out std_logic;
            o_1_2_hb : out std_logic;
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
signal h, hpo, vfc, S_7_8_J : unsigned(7 downto 0);
signal h_128, h_128n, h_256, h_256n : std_logic;
signal cnt : unsigned(3 downto 0);
signal dc, da : std_logic_vector(5 downto 0);
signal cd, db, data_2N, S_7P, S_8P, S_7R, S_8R, A_4M, B_4M, Y_4M : std_logic_vector(3 downto 0);
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
signal O1B_5F, O0B_5F, u8h_O0B_5F_0, u8h_O0B_5F_1 : std_logic;
signal I1C_I0D_8B, Q7_8H, Q1_8H, Q0_8H, Q6_8H, Q1_8N  : std_logic;
signal mb7074_wr_l, mb7074_wr, csn_6PR : std_logic;
signal Q_5KL : unsigned(7 downto 0);
signal C4_8R, C4_8P, scanline_wr_l, scanline_wr_l_0, scanline_wr_l_1 : std_logic;
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
signal scanline_wr, clk_4KL, clk_4KL_0, clk_4KL_1, clr_u3E4E_l, load_u3E4E_l, cmpblk2_l : std_logic;
signal final_vid, S_U4PN : std_logic_vector(1 downto 0);
signal final_col, A_U8B, B_U8B, Y_U8B : std_logic_vector(3 downto 0);
signal addr_2EF, data_2E, data_2F, U6K_D, U6K_Q, U8CD_sprite_shifter  : std_logic_vector(7 downto 0);
signal cnt_vsync, cnt_hsync, Q_3_4_E : unsigned(7 downto 0);
signal hsyncn, vsyncn, flip_1, flip_2, flip_3, flip_4, flip_5 : std_logic;
signal Q0_8CD, Q15_8CD, Q0_8EF, Q15_8EF : std_logic;
signal U8CD_reg, U8CD_sprite_data, U8EF_reg, U8EF_sprite_data, reg_8CD, reg_8EF : std_logic_vector(15 downto 0);
signal h_cnt : unsigned(11 downto 0);
signal h_256_0, h_256_1, v_4_0, v_4_1, v_clk_0, v_clk_1 : std_logic;
signal h_256n_0, h_256n_1, u8n_O0B_5F_0, u8n_O0B_5F_1, u1e_h_0_0, u1e_h_0_1 : std_logic;
signal u2k_h_5_0, u2k_h_5_1, u4a_h_5_0, u4a_h_5_1, u2k_h_2_0, u2k_h_2_1, clk_color_latch_0, clk_color_latch_1 : std_logic;
signal u14p_h_0_0, u14p_h_0_1, u14n_h_0_0, u14n_h_0_1 : std_logic;

signal CA_1N, U1L_reload, CA_1M : std_logic;

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
    -- U1N : entity work.SN74LS161N(SYNTH) generic map(tPLHT => 0 ns, tPHLT => 0 ns, tPLHQ => 0 ns, tPHLQ => 0 ns)
    --                              port map (X_1 => not i_rst, X_2 => Phi34n, X_3 => '1', X_4 => '1', X_5 => '1', X_6 => '1', 
    --                                        X_7 => '1', X_10 => '1', X_9 => '1', X_15 => CA_1N, X_14 => h(0), X_13 => h(1), X_12 => h(2), X_11 => h(3)); 
    -- U1M : entity work.SN74LS161N(SYNTH) generic map(tPLHT => 0 ns, tPHLT => 0 ns, tPLHQ => 0 ns, tPHLQ => 0 ns)
    --                              port map (X_1 => not i_rst, X_2 => Phi34n, X_3 => '1', X_4 => '1', X_5 => '1', X_6 => '1', 
    --                                        X_7 => CA_1N, X_10 => CA_1N, X_9 => '1', X_15 => CA_1M, X_14 => h(4), X_13 => h(5), X_12 => h(6), X_11 => h(7)); 
    -- U1L : entity work.SN74LS161N(SYNTH) generic map(tPLHT => 0 ns, tPHLT => 0 ns, tPLHQ => 0 ns, tPHLQ => 0 ns)
    --                              port map (X_1 => not i_rst, X_2 => Phi34n, X_3 => '1', X_4 => '0', X_5 => '1', X_6 => '1', 
    --                                        X_7 => CA_1N, X_10 => CA_1M, X_9 => not U1L_reload, X_15 => U1L_reload, X_13 => h_128n, X_14 => h_256n);                              
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
    -- p_u1LMN : process(Phi34n, h)
    -- begin
    --     if (i_rst = '1') then
    --         h <= (others => '0');
    --     elsif rising_edge(Phi34n) then
    --         if h = X"FFF" then
    --             -- Reload U1L
    --             h(11 downto 8) <= X"D";
    --         else
    --             h <= h + 1;
    --         end if;
    --     end if;
    -- end process;
    -- A confirmer si h_128 = h_256 ou h_128 et h_256 = h_128 ou h_256   
    -- h_128n <= h_256;
    h_128 <= not h_128n;
    -- h_256n <= h_128;
    h_256 <= not h_256n;
    o_hblkn <= h_256n;
    
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

    -- U3B : entity work.SN74123N
    -- generic map (
    --     W1 => 500us,
    --     W2 => 1400us
    -- ) 
    -- port map(
    --     X_1 => Q2_3B,
    --     X_2 => '1',
    --     X_3 => not i_rst,
    --     X_5 => Q2_3B,
    --     X_9 => Q1_4B,
    --     X_10 => '1',
    --     X_11 => not i_rst,
    --     X_13 => Q1_3B
    -- );
    
    -- vsyncn <= not Q1_3B;
    
    -- Equivalent U3B synthetisable
    p_u3b : process(Phi34, vblk, i_rst)
    begin
        if (vblk = '0') or (i_rst = '1') then
            cnt_vsync <= VSYNC_P;
        elsif rising_edge(Phi34) then
            -- Detection front montant h_256
            h_256_0 <= h_256;
            h_256_1 <= h_256_0;
            if (h_256_0 = '1') and (h_256_1 = '0') then  
                cnt_vsync <= cnt_vsync + 1;
            end if;
        end if;
    end process;
    
    vsyncn <= '0' when (cnt_vsync < VSYNC_W) else '1';
    
    -- 6B
    o_hsyncn <= hsyncn;
    o_vsyncn <= vsyncn;
    o_cmpsyncn <= hsyncn and vsyncn;
    
    -- 4A, 4B, 5D, 6D
    -- U4A : entity work.SN74LS74N(SYNTH) port map (X_1 => not i_rst, X_2 => not ((not h(7)) and h(6)), X_3 => h(5), X_4 => h_256,
    --     X_6 => Q1n_4A, X_8 => Q2n_4A, X_9 => v(0), X_10 => not i_rst, X_11 => Q1n_4A, X_12 => Q2n_4A, X_13 => '1');
        
    -- o_vblkn <= not Q1n_4B;
        
    -- U4B : entity work.SN74LS74N(SYNTH) port map (X_1 => not i_rst, X_2 => not (v(5) and v(6) and v(7)), X_3 => v(4), X_4 => '1', X_5 => Q1_4B,
    --        X_6 => Q1n_4B, X_8 => Q2n_4B, X_10 => not i_rst, X_11 => Q3_6D, X_12 => Q2n_4B, X_13 => '1');        
    
    -- U5C : entity work.SN74LS161N(SYNTH) port map (X_1 => not i_rst, X_2 => Q1n_4A, X_3 => '0', X_4 => '0', X_5 => '1', X_6 => '1', X_7 => v(0), X_9 => not CA_6D,
    --     X_10 => v(0), X_11 => v(4), X_12 => v(3), X_13 => v(2), X_14 => v(1), X_15 => CA_5D);  
    
    -- U6C : entity work.SN74LS161N(SYNTH) port map (X_1 => not i_rst, X_2 => Q1n_4A, X_3 => '1', X_4 => '1', X_5 => '1', X_6 => '0', X_7 => CA_5D, X_9 => not CA_6D,
    --     X_10 => CA_5D, X_11 => Q3_6D, X_12 => v(7), X_13 => v(6), X_14 => v(5), X_15 => CA_6D);
    
    U4A : process(Phi34, h_256)
    begin
        if (h_256 = '0') then
            v_clk <= '0';
        elsif rising_edge(Phi34) then
            u4a_h_5_0 <= h(5);
            u4a_h_5_1 <= u4a_h_5_0;
            -- Detection front montant h(5)
            -- if (u4a_h_5_0 = '1') and (u4a_h_5_1 = '0') then
            if (h(5) = '1') then 
                if (not((not(h(7))) and h(6))) = '1' then
                    v_clk <='0';
                else
                    v_clk <='1';
                end if;
            end if;
        end if;
    end process;

    U4B : process(Phi34)
    begin
        if rising_edge(Phi34) then
            -- Detection front montant v(4)
            v_4_0 <= v(4);
            v_4_1 <= v_4_0;        
            if (v_4_0 = '1' and v_4_1 = '0') then  
                if (v(7 downto 5) = "111") then
                    vblk <='1';
                else
                    vblk <='0';
                end if;
            end if;                
        end if;
    end process;
    o_vblkn <= not vblk;
    
    U56D : process(i_rst, Phi34)
    begin
         if (i_rst = '1') then
            v <= (others => '0');
         elsif rising_edge(Phi34) then
            -- Detection front montant v_clk
            v_clk_0 <= v_clk;
            v_clk_1 <= v_clk_0;        
            if (v_clk_0 = '1' and v_clk_1 = '0') then          
                if (v = "1" & X"FF") then
                    v <= "011111000";
                else 
                    v <= v + 1;
                end if;
            end if;
         end if;
    end process;  

    -- 5E, 6E
    vf <= (flip_3 & flip_3 & flip_3 & flip_3 & flip_3 & flip_3 & flip_3 & flip_3) xor std_logic_vector(v(7 downto 0));

    -- U5E : entity work.SN74LS175N(SYNTH) port map (X_1 => not i_rst, X_9 => h_256n, X_4 => vf(0), X_5 => vf(1), X_12 => vf(2), X_13 => vf(3),
    --     X_2 => vfc(0), X_7 => vfc(1), X_10 => vfc(2), X_15 => vfc(3));    

    -- U6E : entity work.SN74LS175N(SYNTH) port map (X_1 => not i_rst, X_9 => i_rst, X_4 => vf(4), X_5 => vf(5), X_12 => vf(6), X_13 => vf(7),
    --     X_2 => vfc(4), X_7 => vfc(5), X_10 => vfc(6), X_15 => vfc(7));
    U56E : process(Phi34)
    begin
        if rising_edge(Phi34) then
            h_256n_0 <= h_256n;
            h_256n_1 <= h_256n_0;
            -- Detection front montant h_256n
            if (h_256n_0 = '1') and (h_256n_1 = '0') then  
                vfc <= unsigned(vf);
            end if;
        end if;
    end process;
    
    -- 3J, 4J
    dc <= da when (U8B_sprite_data(0) or U8B_sprite_data(1)) = '0' else (cd & U8B_sprite_data(1 downto 0));  
    -- U4J : entity work.SN74LS157N(SYNTH) port map (X_1 => (U8B_sprite_data(0) or U8B_sprite_data(1)), X_2 => '0', X_5 => '0', X_14 => da(5), X_11 => da(4),
    --     X_3 => '0', X_6 => '0', X_13 => cd(3), X_10 => cd(2), X_15 => Q7_6K,
    --     X_12 => dc(5), X_9 => dc(4)); 

    -- U3J : entity work.SN74LS157N(SYNTH) port map (X_1 => (U8B_sprite_data(0) or U8B_sprite_data(1)), X_2 => da(3), X_5 => da(2), X_14 => da(1), X_11 => da(0),
    --     X_3 => cd(1), X_6 => cd(0), X_13 => U8B_sprite_data(0), X_10 => U8B_sprite_data(1), X_15 => Q7_6K,
    --     X_4 => dc(3), X_7 => dc(2), X_12 => dc(1), X_9 => dc(0)); 
    
    -- 5F
    G_5F <= not (h(0) and h(1) and h(2) and h(3));
    U5F : entity work.SN74LS139N(SYNTH) port map (X_1 => G_5F, X_2 => h(3), X_3 => h_256n, X_5 => O1A_5F, X_7 => O3A_5F,
                                    X_13 => h(3), X_14 => h(2), X_15 => '0', X_10 => O2B_5F, X_11 => O1B_5F, X_12 => O0B_5F);
    -- 3E, 4E
    clr_u3E4E_l <= (O3A_5F or Q7_6K);
    load_u3E4E_l <= O1A_5F;
    -- clk_u3E4E <= mb7074_wr_l;
    
    -- Remplacement des portes logiques 5A, 5B par un process basé sur Phi34n
	UMB7074_WR : process(Phi34n)
	begin
	   mb7074_wr_l <= '1';
	   if rising_edge(Phi34n) then	
	       if not ((not ((not h(0)) and Q7_6K))) = '1' then
	            mb7074_wr_l <= '0';
	       end if;
	   end if;
	end process;
	
	U3E4E : process(Phi34n)
	begin
	   if rising_edge(Phi34n) then	
         if(load_u3E4E_l = '0') then
             Q_3_4_E <= hpo;
         elsif (clr_u3E4E_l = '0') then
             Q_3_4_E <= (others => '0');
         else
             Q_3_4_E <= Q_3_4_E + 1;
         end if;
       end if;
    end process;    
    
    -- U3E : entity work.SN74LS163N(SYNTH) port map (X_1 => clr_u3E4E_l, X_2 => mb7074_wr_l,
    --     X_3 => hpo(4), X_4 => hpo(5), X_5 => hpo(6), X_6 => hpo(7), X_9 => load_u3E4E_l,
    --     X_11 => Q3_3E, X_12 => Q2_3E, X_13 => Q1_3E, X_14 => Q0_3E, 
    --     X_7 => CA_4E, X_10 => CA_4E);
        
    -- U4E : entity work.SN74LS163N(SYNTH) port map (X_1 => clr_u3E4E_l, X_2 => mb7074_wr_l,
    --     X_3 => hpo(0), X_4 => hpo(1), X_5 => hpo(2), X_6 => hpo(3), X_9 => load_u3E4E_l,
    --     X_11 => Q3_4E, X_12 => Q2_4E, X_13 => Q1_4E, X_14 => Q0_4E, 
    --     X_7 => '1', X_10 => '1', X_15 => CA_4E);

    mb7074_wr <= not mb7074_wr_l;
    mb7074_addr <= (Q_3_4_E(7) & Q_3_4_E(6) & Q_3_4_E(5) & Q_3_4_E(4) & Q_3_4_E(3) & Q_3_4_E(2) & Q_3_4_E(1) & Q_3_4_E(0))
         xor (Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K);
        
    -- 2E, 2H, 3K
    U2E : entity work.blk_mem_gen_2E port map (clka => Phi34, wea(0) => mb7074_wr, addra => mb7074_addr , dina => dc(5 downto 3) & '0', douta => mb7074_do_2E);
    U2H : entity work.blk_mem_gen_2H port map (clka => Phi34, wea(0) => mb7074_wr, addra => mb7074_addr , dina => dc(2 downto 0) & '0', douta => mb7074_do_2H);
    
    U3K : process (g_3K)
    begin
        if rising_edge(g_3K) then
            da <= mb7074_do_2E(3 downto 1) & mb7074_do_2H(3 downto 1);
        end if;
    end process;

    -- entity work.SN74LS373N(SYNTH) port map (X_11 => g_3K, X_1 => '0',
    --     X_17 => mb7074_do_2E(3), X_7 => mb7074_do_2E(2), X_18 => mb7074_do_2E(1), X_8 => '1',
    --     X_4 => mb7074_do_2H(3), X_3 => mb7074_do_2H(2), X_14 => mb7074_do_2H(1), X_13 => '1',
    --     X_16 => da(5), X_6 => da(4), X_19 => da(3), X_5 => da(2), X_2 => da(1), X_15 => da(0));
        
    -- 6J, 6K
    -- U6J
    process(Phi34n) is
    begin
        if rising_edge(Phi34n) then
            Q_6J <= hd;
        end if;
    end process;
        
    -- U6K : entity work.SN74LS273N(SYNTH) port map (X_1 => G_5F, X_11 => Phi34n,
    --     X_8 => Q3_6J, X_14 => Q5_6J, X_7 => Q2_6J, X_13 => Q4_6J, X_17 => (not h_256) and (not i_flipn), X_18 => h_256n, X_3 => not (h_256 or vblk), X_4 => Q6_6J,
    --     X_9 => cd(0), X_15 => cd(1), X_6 => cd(2), X_12 => cd(3), X_16 => Q6_6K, X_19 => Q7_6K, X_2 => cmpblk2_l, X_5 => Q1_6K);
    -- U6K
    U6K_D <= (Q_6J(7), not (h_256 or vblk), h_256n, flip_2, Q_6J(3), Q_6J(2), Q_6J(1), Q_6J(0));
    (Q7_6K, cmpblk2_l, Q5_6K, Q4_6K, cd(3), cd(2), cd(1), cd(0)) <= U6K_Q;
	process(Phi34n)
	begin
		if rising_edge(Phi34n) then
			if (G_5F = '0') then
				U6K_Q <= U6K_D;
			end if;
		end if;
	end process;
    
    -- 6H
    U6H : process (Phi34, G_5F, hd)
    begin
        if rising_edge(Phi34) then
            if G_5F = '1' then
                Q_6H <= hd(7 downto 0);
            end if;
        end if;
    end process;
        
    -- U6H : entity work.SN74LS373N(SYNTH) port map (X_8 => hd(0), X_14 => hd(1), X_7 => hd(2), X_13 => hd(3), X_4 => hd(4), X_18 => hd(5), X_3 => hd(6), X_17 => hd(7),
    --                                 X_9 => Q_6H(0), X_15 => Q_6H(1), X_6 => Q_6H(2), X_12 => Q_6H(3), X_5 => Q_6H(4), X_19 => Q_6H(5), X_2 => Q_6H(6), X_16 => Q_6H(7),
    --                                 X_11 => not O1B_5F, X_1 => '0');
    -- U7C, U7D, U7E, U7F
    addr_7CDEF <= Q_6H(6 downto 0) & (db(3 downto 0) xor (Q_6H(7) & Q_6H(7) & Q_6H(7) & Q_6H(7)));
    U7C_sprite_bank_1 : entity work.dist_mem_gen_7C port map(a => addr_7CDEF, spo => data_7C);
    U7D_sprite_bank_2 : entity work.dist_mem_gen_7D port map(a => addr_7CDEF, spo => data_7D);
    U7E_sprite_bank_3 : entity work.dist_mem_gen_7E port map(a => addr_7CDEF, spo => data_7E);
    U7F_sprite_bank_4 : entity work.dist_mem_gen_7F port map(a => addr_7CDEF, spo => data_7F);
    
    -- 8B
    -- U8B : entity work.SN74LS157N(SYNTH) port map(X_1 => Q5_6K, X_15 => '0',
    --                                X_2 => Q0_8C, X_3 => Q7_8D, X_5 => Q0_8E, X_6 => Q7_8F,
    --                                X_11 => '1', X_10 => I1C_I0D_8B, X_14 => I1C_I0D_8B, X_13 => '1',
    --                                X_4 => U8B_sprite_data(0), X_7 => U8B_sprite_data(1), X_9 => U8B_sprite_reload_S1, X_12 => U8B_sprite_reload_S0);
    (U8B_sprite_data(0), U8B_sprite_data(1), sprite_reload_S1, sprite_reload_S0) <= Y_U8B;
    A_U8B <= (Q0_8CD, Q0_8EF, '1', I1C_I0D_8B);
    B_U8B <= (Q15_8CD, Q15_8EF, I1C_I0D_8B, '1');                            
    Y_U8B <= A_U8B when Q5_6K = '0' else B_U8B;
    I1C_I0D_8B <= not (((not (Q7_8H and Q0_8H and Q1_8H and Q6_8H)) or Q1_8N) or G_5F);
    
    -- U8C, U8D, U8E, U8F
    -- U8C_sprite_shift_reg : entity work.SN74LS299N(SYNTH) port map(X_8 => Q0_8C, X_11 => '0', X_17 => Q7_8C, X_18 => Q8_8D,
    --                                X_7 => data_7C(7), X_13 => data_7C(6), X_6 => data_7C(5), X_14 => data_7C(4), X_5 => data_7C(3), X_15 => data_7C(2), X_4 => data_7C(1), X_16 => data_7C(0),
    --                                X_12 => Phi34n, X_9 => '1', X_2 => '1', X_3 => '1', X_19 => U8B_sprite_reload_S1, X_1 => U8B_sprite_reload_S0);
    -- U8D_sprite_shift_reg : entity work.SN74LS299N(SYNTH) port map(X_8 => Q8_8D, X_11 => Q7_8C, X_17 => Q7_8D, X_18 => '0',
    --                                X_7 => data_7D(7), X_13 => data_7D(6), X_6 => data_7D(5), X_14 => data_7D(4), X_5 => data_7D(3), X_15 => data_7D(2), X_4 => data_7D(1), X_16 => data_7D(0),
    --                                X_12 => Phi34n, X_9 => '1', X_2 => '1', X_3 => '1', X_19 => U8B_sprite_reload_S1, X_1 => U8B_sprite_reload_S0);
	-- U8C, U8D
	sprite_shifter <= sprite_reload_S1 & sprite_reload_S0;
	U8CD_sprite_data <= data_7C & data_7D;
	process(Phi34n)
	begin
		if rising_edge(Phi34n) then
			case sprite_shifter is
				when "10" => U8CD_reg <= reg_8CD(14 downto 0) & '0';
				when "01" => U8CD_reg <= '0' & reg_8CD(15 downto 1);
				when "11" => U8CD_reg <= U8CD_sprite_data;
				when others => null;
			end case;
		end if;
	end process;	
	Q15_8CD	<= U8CD_reg(15);
	Q0_8CD	<= U8CD_reg(0);	                          
                            
    -- U8E_sprite_shift_reg : entity work.SN74LS299N(SYNTH) port map(X_8 => Q0_8E, X_11 => '0', X_17 => Q7_8E, X_18 => Q8_8F,
    --                                X_7 => data_7E(7), X_13 => data_7E(6), X_6 => data_7E(5), X_14 => data_7E(4), X_5 => data_7E(3), X_15 => data_7E(2), X_4 => data_7E(1), X_16 => data_7E(0),
    --                                X_12 => Phi34n, X_9 => '1', X_2 => '1', X_3 => '1', X_19 => U8B_sprite_reload_S1, X_1 => U8B_sprite_reload_S0);                                     
    -- U8F_sprite_shift_reg : entity work.SN74LS299N(SYNTH) port map(X_8 => Q8_8F, X_11 => Q7_8E, X_17 => Q7_8F, X_18 => '0',
    --                                X_7 => data_7F(7), X_13 => data_7F(6), X_6 => data_7F(5), X_14 => data_7F(4), X_5 => data_7F(3), X_15 => data_7F(2), X_4 => data_7F(1), X_16 => data_7F(0),
    --                                X_12 => Phi34n, X_9 => '1', X_2 => '1', X_3 => '1', X_19 => U8B_sprite_reload_S1, X_1 => U8B_sprite_reload_S0);
	U8EF_sprite_data <= data_7E & data_7F;
	process(Phi34n)
	begin
		if rising_edge(Phi34n) then
			case sprite_shifter is
				when "10" => U8EF_reg <= reg_8EF(14 downto 0) & '0';
				when "01" => U8EF_reg <= '0' & reg_8EF(15 downto 1);
				when "11" => U8EF_reg <= U8EF_sprite_data;
				when others => null;
			end case;
		end if;
	end process;
    Q15_8EF	<= U8EF_reg(15);
	Q0_8EF	<= U8EF_reg(0);	                     
    
    -- U7K : entity work.SN74LS283N(SYNTH) port map(X_5 => '1', X_3 => '1', X_14 => '1', X_12 => '1',
    --                                X_6 => hd(4), X_2 => hd(5), X_15 => hd(6), X_11 => hd(7),
    --                                X_4 => hpo(4), X_1 => hpo(5), X_13 => hpo(6), X_10 => hpo(7),
    --                                X_7 => C4_8K);
    -- U8K : entity work.SN74LS283N(SYNTH) port map(X_5 => '1', X_3 => flip_4, X_14 => flip_4, X_12 => flip_5,
    --                                X_6 => hd(3), X_2 => hd(2), X_15 => hd(1), X_11 => hd(0),
    --                                X_4 => hpo(3), X_1 => hpo(2), X_13 => hpo(1), X_10 => hpo(0),
    --                                X_7 => '1', X_9 => C4_8K);

    -- U7J : entity work.SN74LS283N(SYNTH) port map(X_5 => vfc(4), X_3 => vfc(5), X_14 => vfc(6), X_12 => vfc(7),
    --                                X_6 => hpo(4), X_2 => hpo(5), X_15 => hpo(6), X_11 => hpo(7),
    --                                X_4 => S_7J(0), X_1 => S_7J(1), X_13 => S_7J(2), X_10 => S_7J(3),
    --                                X_7 => C4_8J);
    -- U8J : entity work.SN74LS283N(SYNTH) port map(X_5 => vfc(0), X_3 => vfc(1), X_14 => vfc(2), X_12 => vfc(3),
    --                                X_6 => hpo(0), X_2 => hpo(1), X_15 => hpo(2), X_11 => hpo(3),
    --                                X_4 => S_8J(0), X_1 => S_8J(1), X_13 => S_8J(2), X_10 => S_8J(3),
    --                                X_7 => '0', X_9 => C4_8J);
    -- 7K, 8K, 7J, 8J
    hpo	<= unsigned(hd) + ("1111" & flip_5 & flip_4 & flip_4 & '1') + 1;
	S_7_8_J	<= vfc + hpo;
                          
    -- U8H : entity work.SN74LS273N(SYNTH) port map(X_14 => S_8J(0), X_7 => S_8J(1), X_8 => S_8J(2), X_13 => S_8J(3), X_18 => S_7J(3), X_3 => S_7J(2), X_4 => S_7J(1), X_17 => S_7J(0),
    --                                X_15 => db(0), X_6 => db(1), X_9 => db(2), X_12 => db(3), X_19 => Q7_8H, X_2 => Q0_8H, X_5 => Q1_8H, X_16 => Q6_8H,
    --                                X_11 => O0B_5F, X_1 => not i_rst);
    -- 8H
    U8H : process(Phi34)
    begin
        if falling_edge(Phi34) then
            u8h_O0B_5F_0 <= O0B_5F;
            u8h_O0B_5F_1 <= u8h_O0B_5F_0;
		    -- Detection front montant clk_u3E4E
		    if (u8h_O0B_5F_0 = '1' and u8h_O0B_5F_1 = '0') then
                db <= std_logic_vector(S_7_8_J(3 downto 0));
                (Q6_8H, Q1_8H, Q0_8H, Q7_8H) <= S_7_8_J(7 downto 4);
            end if;
        end if;
    end process;
    
    -- 8N
    -- U8N : entity work.SN74LS109N(SYNTH) port map(X_11 => '1', X_12 => '0', X_13 => '0', X_14 => '0', X_15 => '1',
    --                                       X_1 => h_256, X_2 => dataout_7M(0), X_3 => not i_rst, X_4 => O0B_5F, X_5 => not i_rst, X_6 => Q1_8N);
    --                                                                          
	U8N : process(Phi34, h_256)
	begin
		if h_256 = '0' then
			Q1_8N <= '0';
		elsif rising_edge(Phi34) then
		    u8n_O0B_5F_0 <= O0B_5F;
		    u8n_O0B_5F_1 <= u8n_O0B_5F_0;
		    -- Dectection front montant O0B_5F
		    if (u8n_O0B_5F_0 = '1') and (u8n_O0B_5F_1 = '0') and (dataout_7M(0) = '1') then		              
			     Q1_8N <= '1';
			end if;
		end if;
	end process;                                          
    
    -- Zone A-J 1-9
    -- 3L, 3M
    final_col <= da(5 downto 2) when not (da(0) or da(1)) = '0' else col;
    final_vid <= da(1 downto 0) when not (da(0) or da(1)) = '0' else (vid_1 & vid_0);
    -- U3M : entity work.SN74LS157N port map(X_11 => da(4), X_10 => col(2), X_14 => da(5), X_13 => col(3), X_5 => '0', X_6 => '0', X_2 => '0', X_3 => '0', 
    --                                X_12 => o_col(3), X_9 => o_col(2),
    --                                X_1 => not (da(0) or da(1)),
    --                               X_15 => '0');
    -- U3L : entity work.SN74LS157N port map(X_11 => da(0), X_10 => vid_0, X_14 => da(1), X_13 => vid_1, X_5 => da(2), X_6 => col(0), X_2 => da(3), X_3 => col(1), 
    --                                X_9 => o_vid(0), X_12 => o_vid(1), X_7 => o_col(0), X_4 => o_col(1),
    --                                X_1 => not (da(0) or da(1)),
    --                                X_15 => '0');

    -- 1E, 1F
    -- U1E : entity work.SN74LS174N(SYNTH) port map (X_1 => cmpblk2_l or u1ef_clr_l, X_9 => h(0),
    --                                        X_3 => '0', X_4 => '0', X_6 => cmpblk2_l, X_11 => final_vid(1), X_13 => final_vid(0), 
    --                                        X_14 => not (final_vid(0) or final_vid(1)),
    --                                        X_7 => u1ef_clr_l, X_12 => addr_2EF(0), X_10 => addr_2EF(1), X_15 => rom_u2F_cs_l);
    -- U1F : entity work.SN74LS174N(SYNTH) port map (X_1 => cmpblk2_l or u1ef_clr_l, X_9 => h(0),
    --                                        X_14 => i_game_palette(0), X_3 => i_game_palette(1), X_4 => final_col(3), X_13 => final_col(2), X_6 => final_col(1), X_11 => final_col(0), 
    --                                        X_15 => addr_2EF(7), X_2 => addr_2EF(6), X_5 => addr_2EF(5), X_12 => addr_2EF(4), X_7 => addr_2EF(3), X_10 => addr_2EF(2));
    U1EF: process(Phi34, cmpblk2_l, u1ef_clr_l) is
    begin
        if (cmpblk2_l = '0') or (u1ef_clr_l = '0') then
            addr_2EF <= (others => '0');
            rom_u2F_cs_l <= '1';
            u1ef_clr_l <= '1';
        elsif rising_edge(Phi34) then
            u1e_h_0_0 <= h(0);
            u1e_h_0_1 <= u1e_h_0_0;
		    -- Detection front montant h(0)
		    if (u1e_h_0_0 = '1' and u1e_h_0_1 = '0') then            
                addr_2EF <= i_game_palette & final_col & final_vid;
                rom_u2F_cs_l <= not (final_vid(0) or final_vid(1));
                u1ef_clr_l <= cmpblk2_l;
            end if;
        end if;
    end process;        
                                                  
    -- 2E, 2F (sur la carte CPU)
    U2E_COL : entity work.dist_mem_gen_2E port map (a => addr_2EF, spo => data_2E);
    U2F_COL : entity work.dist_mem_gen_2F port map (a => addr_2EF, spo => data_2F);
    
    
    -- final_color : process (i_invert_colors_n, rom_u2F_cs_l, data_2E, data_2F)
    -- begin
    --     o_r <= (others => '0');
    --     o_g <= (others => '0');
    --     o_b <= (others => '0');
    --     if rom_u2F_cs_l = '1' then
    --         if (i_invert_colors_n) = '0' then
    --             o_r <= not (data_2E(3 downto 1));
    --             o_g <= not (data_2E(0) & data_2E(3 downto 2));
    --             o_b <= not (data_2F(1 downto 0)) & '0';
    --         else
    --             o_r <= data_2E(3 downto 1);
    --             o_g <= data_2E(0) & data_2E(3 downto 2);
    --             o_b <= data_2F(1 downto 0) & '0';
    --         end if;
    --     end if;
    -- end process;

    o_r <= not (data_2E(3 downto 1)) when rom_u2F_cs_l = '0' else (others => '0');
    o_g <= not (data_2E(0) & data_2E(3 downto 2)) when rom_u2F_cs_l = '0' else (others => '0');
    o_b <= not (data_2F(1 downto 0)) when rom_u2F_cs_l = '0' else (others => '0');
                                   
    -- 6S, 7S, 8S
    -- U6S : entity work.SN74LS157N(SYNTH) port map(X_11 => i_addr(8), X_10 => h_128, X_14 => (i_objwrn and i_objrdn), X_13 => '0', X_5 => i_addr(9), X_6 => h_128, X_2 => '0', X_3 => '0', 
    --                                X_12 => csn_6PR, X_7 => addr_6PR(9), X_9 => addr_6PR(8),   
    --                                X_1 => (i_objwrn and i_objrdn and i_objrqn), X_15 => '0');
    -- U7S : entity work.SN74LS157N(SYNTH) port map(X_11 => i_addr(4), X_10 => h(4), X_5 => i_addr(5), X_6 => h(5), X_14 => i_addr(6), X_13 => h(6), X_2 => i_addr(7), X_3 => h(7), 
    --                                X_9 => addr_6PR(4), X_7 => addr_6PR(5), X_12 => addr_6PR(6), X_4 => addr_6PR(7),    
    --                                X_1 => (i_objwrn and i_objrdn and i_objrqn), X_15 => '0');                            
    -- U8S : entity work.SN74LS157N(SYNTH) port map(X_11 => i_addr(0), X_10 => h(0), X_5 => i_addr(1), X_6 => h(1), X_14 => i_addr(2), X_13 => h(2), X_2 => i_addr(3), X_3 => h(3), 
    --                                X_9 => addr_6PR(0), X_7 => addr_6PR(1), X_12 => addr_6PR(2), X_4 => addr_6PR(3),    
    --                                X_1 => (i_objwrn and i_objrdn and i_objrqn), X_15 => '0');
    (csn_6PR, addr_6PR) <= Y_6_7_8_S;
    A_6_7_8_S <= ((i_objwrn and i_objrdn), addr_6PR(9 downto 0));
    B_6_7_8_S <= ('0', i_psl_2, h_128, h(7), h(6), h(5), h(4), h(3), h(2), h(1), h(0));
    Y_6_7_8_S <= A_6_7_8_S when (i_objwrn and i_objrdn and i_objrqn) = '0' else B_6_7_8_S;

    -- U5S
    -- U5S : entity work.SN74LS245N port map(X_1 => i_objwrn, 
    --                                X_18 => i_vid_data_in(0), X_17 => i_vid_data_in(1), X_16 => i_vid_data_in(2), X_15 => i_vid_data_in(3),
    --                                X_14 => i_vid_data_in(4), X_13 => i_vid_data_in(5), X_12 => i_vid_data_in(6), X_11 => i_vid_data_in(7),
    --                                X_2 => din_6PR(0), X_3 => din_6PR(1), X_4 => din_6PR(2), X_5 => din_6PR(3), X_6 => din_6PR(4), X_7 => din_6PR(5), X_8 => din_6PR(6), X_9 => din_6PR(7),
    --                                X_19 => (i_objrdn and i_objwrn));                                   
    din_6PR <= i_vid_data_in when (i_objwrn = '0') and ((i_objrdn and i_objwrn) = '0') else (others => 'X');
                                   
    -- 6P, 6R
    u6pr_ram_wr <= not i_objwrn;
    U6PR : entity work.blk_mem_gen_6PR port map(clka => Phi34, ena => not csn_6PR, wea(0) => u6pr_ram_wr, addra => addr_6PR, dina => din_6PR, douta => dout_6PR);
    
    -- 6N, 6M
    -- U6N : entity work.SN74LS273N(SYNTH) port map(X_11 => Phi34n,
    --                                X_1 => '1',
    --                                X_7 => dout_6PR(0), X_14 => dout_6PR(1), X_8 => dout_6PR(2), X_13 => dout_6PR(3), X_3 => dout_6PR(4), X_18 => dout_6PR(5), X_4 => dout_6PR(6), X_17 => dout_6PR(7),
    --                                X_6 => data_6N(0), X_15 => data_6N(1), X_9 => data_6N(2), X_12 => data_6N(3), X_2 => data_6N(4), X_19 => data_6N(5), X_5 => data_6N(6), X_16 => data_6N(7));
    U6N : process(Phi34n)
    begin
        if rising_edge(Phi34n) then
            data_6N <= dout_6PR;
        end if;
    end process;
                                       
    -- U6M : entity work.SN74LS273N(SYNTH) port map(X_11 => Phi34n,
    --                                X_1 => '1',
    --                                X_7 => data_6N(0), X_14 => data_6N(1), X_8 => data_6N(2), X_13 => data_6N(3), X_3 => data_6N(4), X_18 => data_6N(5), X_4 => data_6N(6), X_17 => data_6N(7),
    --                                X_6 => datain_7M(0), X_15 => datain_7M(1), X_9 => datain_7M(2), X_12 => datain_7M(3), X_2 => datain_7M(4), X_19 => datain_7M(5), X_5 => datain_7M(6), X_16 => datain_7M(7));
    U6M : process(Phi34n)
    begin
        if rising_edge(Phi34n) then
            datain_7M <= data_6N;
        end if;
    end process;
                                   
    -- 7R, 8R, 7P, 8P
    U7R : entity work.SN74LS283N(SYNTH) port map(X_5 => '1', X_6 => data_6N(4), X_3 => '1', X_2 => data_6N(5), X_14 => '1', X_15 => data_6N(6), X_12 => '1', X_11 => data_6N(7),
                                   X_7 => C4_8R,
                                   X_4 => S_7R(0), X_1 => S_7R(1), X_13 => S_7R(2), X_10 => S_7R(3));
    U8R : entity work.SN74LS283N(SYNTH) port map(X_5 => data_6N(0), X_6 => '1', X_3 => data_6N(1), X_2 => flip_1, X_14 => data_6N(2), X_15 => flip_1, X_12 => data_6N(3), X_11 => i_flipn,
                                   X_7 => '1', X_9 => C4_8R,
                                   X_4 => S_8R(0), X_1 => S_8R(1), X_13 => S_8R(2), X_10 => S_8R(3));
    U7P : entity work.SN74LS283N(SYNTH) port map(X_6 => S_7R(0), X_5 => vf(4), X_2 => S_7R(1), X_3 => vf(5), X_14 => S_7R(2), X_15 => vf(6), X_12 => S_7R(3), X_11 => vf(7),
                                   X_7 => C4_8P,
                                   X_4 => S_7P(0), X_1 => S_7P(1), X_13 => S_7P(2), X_10 => S_7P(3));
    U8P : entity work.SN74LS283N(SYNTH) port map(X_6 => S_8R(0), X_5 => vf(0), X_2 => S_8R(1), X_3 => vf(1), X_14 => S_8R(2), X_15 => vf(2), X_12 => S_8R(3), X_11 => vf(3),
                                   X_7 => '0', X_9 => C4_8P,
                                   X_4 => S_8P(0), X_1 => S_8P(1), X_13 => S_8P(2), X_10 => S_8P(3));           
                                   
    DI0_7M <= not ((not(Q_5KL(6) or Q_5KL(7))) and h(2) and h(3) and h(4) and h(5) and h(6) and h(7) and h_128);
    do_draw_l <= not(S_7P(0) and S_7P(1) and S_7P(2) and S_7P(3));
    
    -- 5L, 5K
    scanline_wr_l <= not((not(Q_5KL(6) or Q_5KL(7))) and Q_4L and h_256n and Phi34);

    -- U5L : entity work.SN74LS161N(SYNTH) port map(X_3 => '1', X_4 => '1', X_5 => '1', X_6 => '1',
    --                                X_9 => '1', X_7 => '1', X_10 => '1',
    --                                X_14 => Q0_5L, X_13 => Q1_5L, X_12 => Q2_5L, X_11 => Q3_5L, 
    --                                X_2 => scanline_wr_l, X_1 => h_256n, X_15 => TC_5L);                            
    -- U5K : entity work.SN74LS161N(SYNTH) port map(X_3 => '1', X_4 => '1', X_5 => '1', X_6 => '1',
    --                                X_9 => '1', X_7 => TC_5L, X_10 => TC_5L,
    --                                X_14 => Q0_5K, X_13 => Q1_5K, X_12 => Q2_5K, X_11 => Q3_5K, 
    --                                X_2 => scanline_wr_l, X_1 => h_256n);    
    -- U5KL
    p_u5kl : process(Phi34, h_256n)
    begin
        if (h_256n = '0') then
            Q_5KL <= (others => '0');
        elsif rising_edge(Phi34) then
            scanline_wr_l_0 <= scanline_wr;
            scanline_wr_l_0 <= scanline_wr_l_1;
            -- Detection front montant scanline_wr
            if (scanline_wr_l_0 = '1') and (scanline_wr_l_1 = '0') then
                Q_5KL <= Q_5KL + 1;
            end if;
        end if;
    end process;
                                                         
    -- U4L
    clk_4KL <= not ((not h(1)) and h(0));
    -- U4L : entity work.SN74LS74N(SYNTH) port map(X_1 => '1', X_2 => '0', X_3 => '0', X_4 => '1',
    --                            X_11 => clk_4KL, X_12 => not (do_draw_l and DI0_7M), X_10 => not i_rst,
    --                            X_13 => h_256n, X_9 => Q2_4L);
    U4L : process(Phi34, h_256n)
    begin
        if (h_256n = '0') then
            Q_4L <= '0';
        elsif rising_edge(Phi34) then
            clk_4KL_0 <= clk_4KL;
            clk_4KL_1 <= clk_4KL_0;
            if (clk_4KL_0 = '1') and (clk_4KL_1 = '0') then
                if (not (do_draw_l and DI0_7M)) = '1' then
                    Q_4L <='1';
                else
                    Q_4L <='0';
                end if;
            end if;
        end if;
    end process;
                               
    -- 5N, 5M
    -- U5N : entity work.SN74LS157N port map (X_1 => h_256n,
    --                                 X_2 => h(6), X_5 => h(5), X_11 => h(7), X_13 => '0',
    --                                 X_3 => Q0_5K, X_6 => Q3_5L, X_10 => Q1_5K, X_14 => '0',
    --                                 X_9 => addr_7M(5), X_4 => addr_7M(4), X_7 => addr_7M(3),
    --                                 X_15 => '0');
    -- U5M : entity work.SN74LS157N port map (X_1 => h_256n,
    --                                 X_2 => h(3), X_5 => h(2), X_11 => h(4), X_13 => '0',
    --                                 X_3 => Q1_5L, X_6 => Q0_5L, X_10 => Q2_5L, X_14 => '0',
    --                                 X_9 => addr_7M(2), X_4 => addr_7M(1), X_7 => addr_7M(0),
    --                                 X_15 => '0');
                                    
    addr_7M <= (h(7) & h(6) & h(5) & h(4) & h(3) & h(2)) when h_256n = '0' else (Q_5KL(5) & Q_5KL(4) & Q_5KL(3) & Q_5KL(2) & Q_5KL(1) & Q_5KL(0));    
    
    -- Scanline buffer (64 x 9 bits)
    scanline_wr <= not scanline_wr_l;
    U7M : entity work.blk_mem_gen_7M port map (clka => Phi34, wea(0) => scanline_wr, addra => addr_7M , dina => DI0_7M & datain_7M, douta => dataout_7M);
    hd(7 downto 0) <= not dataout_7M(8 downto 1);
    
    -- U2K
    -- U2K : entity work.SN74LS74N(SYNTH) port map(X_3 => h(6), X_2 => h(7), X_4 => h_256,
    --                            X_1 => not i_rst, X_6 => esblk,
    --                            X_11 => h(2), X_12 => not(h(4) and h(5) and h(6) and h(7)), X_10 => not i_rst,
    --                            X_13 => h_256, X_8 => vram_busy);
    -- U2K part 1
    U2K_1 : process(Phi34, h_256)
    begin
        if (h_256 = '0') then
           esblk  <= '1';
        elsif rising_edge(Phi34) then
            u2k_h_5_0 <= h(5);
            u2k_h_5_1 <= u2k_h_5_0;
            if (u2k_h_5_0 = '1') and (u2k_h_5_1 = '0') then
                if (h(6) = '1') then
                    esblk <='0';
                else
                    esblk <='1';
                end if;
            end if;
        end if;
    end process; 
  
    -- U2K part 2
    U2K_2 : process(Phi34, h_256)
    begin
        if (h_256 = '0') then
           vram_busy <= '1';
        elsif rising_edge(Phi34) then
            u2k_h_2_0 <= h(2);
            u2k_h_2_1 <= u2k_h_2_0;
            -- Detection front montant h(2)
            if (u2k_h_2_0 = '1') and (u2k_h_2_1 = '0') then
                if (h(7 downto 4) = "1111") then
                    vram_busy <='0';
                else
                    vram_busy <='1';
                end if;
            end if;
        end if;
    end process;

    o_vram_busyn <= not vram_busy;
    o_esblkn <= not esblk;
    o_1_2_hb <= h(0);
    o_1_hb <= h(1);
    o_vf_2 <= vf(1);
                                
    -- U2S : entity work.SN74LS157N port map(X_2 => '1', X_5 => i_addr(9), X_14 => (not i_vram_wrn) and (not i_vram_rdn), X_11 => i_addr(8),
    --                                X_3 => '0', X_6 => vf_128, X_13 => '0', X_10 => vf_64,
    --                                X_4 => U2S_Y(3), X_7 => U2S_Y(1), X_12 => U2S_Y(2), X_9 => U2S_Y(0),
    --                               X_1 => not (Q1n_4B or h_256),
    --                                X_15 => '0');
                     
    -- U3S : entity work.SN74LS157N port map(X_2 => i_addr(7), X_5 => i_addr(6), X_14 => i_addr(5), X_11 => i_addr(4),
    --                                X_3 => vf_32, X_6 => vf_16, X_13 => vf_8, X_10 => (not i_flipn) xor h_128,
    --                                X_4 => U3S_Y(3), X_7 => U3S_Y(1), X_12 => U3S_Y(2), X_9 => U3S_Y(0),
    --                                X_1 => not (Q1n_4B or h_256),
    --                                X_15 => '0');
                                   
    -- U4S : entity work.SN74LS157N port map(X_2 => i_addr(3), X_5 => i_addr(2), X_14 => i_addr(1), X_11 => i_addr(0),
    --                                X_3 => (not i_flipn) xor h(7), X_6 => (not i_flipn) xor h(6), X_13 => (not i_flipn) xor h(5), X_10 => (not i_flipn) xor h(4),
    --                                X_4 => U4S_Y(3), X_7 => U4S_Y(1), X_12 => U4S_Y(2), X_9 => U4S_Y(0),
    --                                X_1 => not (Q1n_4B or h_256),
    --                                X_15 => '0');

    U234S_S <= not (vblk or h_256);
    addr_ram_tiles <= i_addr(9 downto 0) when U234S_S = '0' else 
                        vf(7) & vf(6) & vf(5) & vf(4) & vf(3) & 
                        (h_128 xor flip_1) & (h(7) xor flip_1) &
                        (h(6) xor flip_1) & (h(5) xor flip_1) & (h(4) xor flip_1);
                        
    addr_tiles_ram_cs_l <= (not i_vram_wrn) and (not i_vram_rdn) when U234S_S = '0' else '0';
    char_tile_reload <= '1' when U234S_S = '0' else '0';
                  
    -- U1S                 
    -- U1S : entity work.SN74LS245N port map(X_18 => i_vid_data_in(7), X_17 => i_vid_data_in(6), X_16 => i_vid_data_in(5), X_15 => i_vid_data_in(4), 
    --                                 X_14 => i_vid_data_in(3), X_13 => i_vid_data_in(2), X_12 => i_vid_data_in(1), X_11 => i_vid_data_in(0), 
    --                                 X_2 => U2PR_tile_id_in(7), X_3 => U2PR_tile_id_in(6), X_4 => U2PR_tile_id_in(5), X_5 => U2PR_tile_id_in(4), 
    --                                 X_6 => U2PR_tile_id_in(3), X_7 => U2PR_tile_id_in(2), X_8 => U2PR_tile_id_in(1), X_9 => U2PR_tile_id_in(0),
    --                                 X_1 => i_vram_wrn,
    --                                 X_19 => ((not i_vram_rdn) and (not i_vram_wrn)));
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
    
    -- U2M : entity work.SN74LS174N(SYNTH) port map (X_3 => '1', X_4 => '1', X_6 => data_2N(3), X_11 => data_2N(2), X_13 => data_2N(1), X_14 => data_2N(0), 
    --                                 X_7 => col(3), X_10 => col(2), X_12 => col(1), X_15 => col(0),
    --                                 X_1 => '1',
    --                                 X_9 => clk_color_latch);
    -- U2M
    U2M: process(Phi34)
    begin
        if rising_edge(Phi34) then
            clk_color_latch_0 <= clk_color_latch;
            clk_color_latch_1 <= clk_color_latch_0;
            -- Detection front montant clk_color_latch
            if (clk_color_latch_0 = '1' and clk_color_latch_1 = '0') then
		      col <= data_2N;
		    end if;
        end if;
    end process;                                         

    addr_tiles_data_3PN <= U2PR_tile_id_out & vf(2 downto 0);
    U3P_tile_bank_1 : entity work.dist_mem_gen_3P port map (a => addr_tiles_data_3PN, spo => data_tile_1);
    U3N_tile_bank_2 : entity work.dist_mem_gen_3N port map (a => addr_tiles_data_3PN, spo => data_tile_2);
    
    -- U4P_tile_shift_reg : entity work.SN74LS299N(SYNTH) port map (X_8 => Q0_4P, X_11 => '0', X_17 => Q7_4P, X_18 => '0',
    --                                X_7 => data_tile_1(7), X_13 => data_tile_1(6), X_6 => data_tile_1(5), X_14 => data_tile_1(4), X_5 => data_tile_1(3), X_15 => data_tile_1(2), X_4 => data_tile_1(1), X_16 => data_tile_1(0),
    --                                X_12 => not h(0), X_9 => '1', X_2 => '1', X_3 => '1',
    --                                X_1 => S0_U4PN, X_19 => S1_U4PN);
    -- U4P                               
	U4P : process(Phi34)
	begin
        if rising_edge(Phi34) then
           u14p_h_0_0 <= h(0);
           u14p_h_0_1 <= u14p_h_0_0;
          -- Detection front descendant h(0)
		  if (u14p_h_0_0 = '0') and (u14p_h_0_1 = '1') then
            case S_U4PN is
                when "10" => shift_reg_U4P <= shift_reg_U4P(1 to 7) & '0'; -- Shift left
                when "01" => shift_reg_U4P <= '0' & shift_reg_U4P(0 to 6); -- Shift right
                when "11" => shift_reg_U4P <= data_tile_1;                     -- Parallel load
                when others => null;
            end case;
          end if;
		end if;
	end process;
	Q7_4P	<= shift_reg_U4P(7);
	Q0_4P	<= shift_reg_U4P(0);	                                   
    
    -- U4N_tile_shift_reg : entity work.SN74LS299N(SYNTH) port map (X_8 => Q0_4N, X_11 => '0', X_17 => Q7_4N, X_18 => '0',
    --                                X_7 => data_tile_2(7), X_13 => data_tile_2(6), X_6 => data_tile_2(5), X_14 => data_tile_2(4), X_5 => data_tile_2(3), X_15 => data_tile_2(2), X_4 => data_tile_2(1), X_16 => data_tile_2(0),
    --                                X_12 => not h(0), X_9 => '1', X_2 => '1', X_3 => '1',
    --                                X_1 => S0_U4PN, X_19 => S1_U4PN);
    -- U4N                               
	process(Phi34)
	begin
      if rising_edge(Phi34) then
          -- Detection front descendant h(0)
          u14n_h_0_0 <= h(0);
          u14n_h_0_1 <= u14n_h_0_0;          
          if (u14n_h_0_0 = '0' and u14n_h_0_1 = '1') then
            case S_U4PN is
                when "10" => shift_reg_U4N <= shift_reg_U4N(1 to 7) & '0'; -- Shift left
                when "01" => shift_reg_U4N <= '0' & shift_reg_U4N(0 to 6); -- Shift right
                when "11" => shift_reg_U4N <= data_tile_2;                     -- Parallel load
                when others => null;
            end case;
          end if;
      end if;
	end process;
	Q7_4N	<= shift_reg_U4N(7);
	Q0_4N	<= shift_reg_U4N(0);	                                                                      
	
	S_U4PN <= S1_U4PN & S0_U4PN;
	    
    tile_shift_reg_reload_l <= (not clk_color_latch) and (not char_tile_reload);
    -- U4M : entity work.SN74LS157N(SYNTH) port map (X_2 => Q0_4P, X_5 => Q0_4N, X_14 => tile_shift_reg_reload_l, X_11 => '1',
    --                                 X_3 => Q7_4P, X_6 => Q7_4N, X_13 => '1', X_10 => tile_shift_reg_reload_l,
    --                                 X_4 => vid_1, X_7 => vid_0, X_12 => S0_U4PN, X_9 => S1_U4PN,
    --                                 X_1 => not i_flipn,
    --                                 X_15 => '0');
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