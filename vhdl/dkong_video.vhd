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
    Port (  i_rst : in std_logic;
            i_clk : in std_logic; -- 61.44 MHz
            i_Phi34 : in std_logic; -- System clock (6 MHz)
            i_Phi34n : in std_logic;
            i_cnt : in unsigned(3 downto 0);
            i_vblk : in std_logic;
            i_vram_wrn : in std_logic;
            i_vram_rdn : in std_logic;
            i_v  : in unsigned(7 downto 0);
            i_h  : in unsigned(9 downto 0); 
            i_g_3K_clk : in std_logic;
            i_game_palette : in std_logic_vector(1 downto 0);
            i_psl_2 : in std_logic; -- Palette switch
            i_addr : in std_logic_vector(9 downto 0);
            i_vid_data_in : in std_logic_vector(7 downto 0);
            i_objwrn : in std_logic;
            i_objrdn : in std_logic;
            i_objrqn : in std_logic;
            i_flipn : in std_logic;
            i_invert_colors_n : in std_logic;            
            o_r : out std_logic_vector(2 downto 0);
            o_g : out std_logic_vector(2 downto 0);
            o_b : out std_logic_vector(1 downto 0); 
            o_pixel_write : out std_logic;
            o_cmpblk2_l : out std_logic;
            o_1_hb : out std_logic;
            o_vf_2 : out std_logic;
            o_esblkn : out std_logic;
            o_vram_busyn : out std_logic;
            o_vid_data_out : out std_logic_vector(7 downto 0)
        );
    
end dk_tg4_video;

architecture Behavioral of dk_tg4_video is

signal hpo, S_7_8_J, S_78R, S_78P : unsigned(7 downto 0);
signal h_128, h_256 : std_logic;
signal dc, da : std_logic_vector(5 downto 0);
signal cd, db, data_2N, A_4M, B_4M, Y_4M : std_logic_vector(3 downto 0);
signal mb7074_addr, hd, Q_6H, data_7C, data_7D, data_7E, data_7F, U2PR_tile_id_in, Q_6J : std_logic_vector(7 downto 0);
signal data_6N, din_6PR, dout_6PR, datain_7M, data_tile_1, data_tile_2, U2PR_tile_id_out : std_logic_vector(7 downto 0);
signal shift_reg_U4N, shift_reg_U4P  : std_logic_vector(0 to 7);
signal addr_6PR : std_logic_vector(9 downto 0);
signal mb7074_do_2E, mb7074_do_2H, col : std_logic_vector(3 downto 0);
signal Q7_6K, Q5_6K, Q4_6K, G_5F, O1A_5F : std_logic;
signal O3A_5F : std_logic;
signal O2B_5F : std_logic;
signal O1B_5F, O0B_5F : std_logic;
signal I1C_I0D_8B, Q7_8H, Q1_8H, Q0_8H, Q6_8H, Q1_8N  : std_logic;
signal clk_u3E4E, mb7074_wr, csn_6PR : std_logic;
signal Q_5KL : unsigned(7 downto 0);
signal scanline_wr_l : std_logic;
signal Q0_4P, Q0_4N, Q7_4P, Q7_4N : std_logic;
signal DI0_7M, Q_4L, u1ef_clr_l, rom_u2F_cs_l : std_logic;
signal addr_7M : std_logic_vector(5 downto 0);
signal dataout_7M : std_logic_vector(8 downto 0);
signal addr_7CDEF, addr_tiles_data_3PN, Y_6_7_8_S, A_6_7_8_S, B_6_7_8_S : std_logic_vector(10 downto 0);
signal vid_0, vid_1, S0_U4PN, S1_U4PN : std_logic;

signal vram_busy_l, esblk_l, tile_shift_reg_reload_l, sprite_reload_S1, sprite_reload_S0 : std_logic;
signal do_draw_l, u6pr_ram_wr : std_logic;
signal U8B_sprite_data, sprite_shifter : std_logic_vector(1 downto 0);
signal addr_ram_tiles : std_logic_vector(9 downto 0);
signal addr_tiles_ram_cs_l, char_tile_reload, U234S_S, clk_color_latch : std_logic;
signal scanline_wr, clk_4KL, clr_u3E4E_l, load_u3E4E_l, cmpblk2_l : std_logic;
signal final_vid, S_U4PN : std_logic_vector(1 downto 0);
signal final_col, A_U8B, B_U8B, Y_U8B : std_logic_vector(3 downto 0);
signal addr_2EF, data_2E, data_2F, U6K_D, U6K_Q, vf : std_logic_vector(7 downto 0);
signal Q_3_4_E, vfc : unsigned(7 downto 0);
signal flip_1, flip_2, flip_3, flip_4, flip_5 : std_logic;
signal Q0_8CD, Q15_8CD, Q0_8EF, Q15_8EF : std_logic;
signal U8CD_reg, U8CD_sprite_data, U8EF_reg, U8EF_sprite_data : std_logic_vector(15 downto 0);
signal h_256n, h_128n : std_logic;
signal AB_1, AB_2 : std_logic_vector(1 downto 0);

-- Debug
-- attribute MARK_DEBUG : string;
-- attribute MARK_DEBUG of final_vid, final_col, S0_U4PN, S1_U4PN, clk_color_latch, cmpblk2_l, vblk : signal is "true";    

begin

    -- U5E, U6E
    vf <= (flip_3 & flip_3 & flip_3 & flip_3 & flip_3 & flip_3 & flip_3 & flip_3) xor std_logic_vector(i_v(7 downto 0));
    h_256n <= i_h(8);
    h_256 <= not h_256n;
    h_128n <= i_h(9);
    h_128 <= not h_128n;

    U56E : process(i_Phi34n)
    begin
        if rising_edge(i_Phi34n) then
            -- Detection front montant h_256n (=not h_cnt(8))
            if (i_h(7 downto 0) = X"FF") then  
                vfc <= unsigned(vf);
            end if;
        end if;
    end process;
        
    -------------------------
    -- Gestion des Tiles
    -------------------------
    -- U2S, U3S, U4S
    U234S_S <= not (i_vblk or h_256);
    addr_ram_tiles <= i_addr(9 downto 0) when U234S_S = '0' else 
                        vf(7) & vf(6) & vf(5) & vf(4) & vf(3) & 
                        (h_128 xor flip_1) & (i_h(7) xor flip_1) &
                        (i_h(6) xor flip_1) & (i_h(5) xor flip_1) & (i_h(4) xor flip_1);
                        
    char_tile_reload <= '1' when U234S_S = '0' else '0';
    
    -- U1S
    U2PR_tile_id_in <= i_vid_data_in when i_vram_wrn = '0' else (others => '0');
    
    -- Pour simplifier on retourne U2PR_tile_id_out par defaut.
    o_vid_data_out <= dout_6PR when i_objrdn = '0' else U2PR_tile_id_out;
    
    U2PR : entity work.dist_mem_gen_2PR port map (clk => i_clk, we => not(i_vram_wrn), 
                                a => addr_ram_tiles, d => U2PR_tile_id_in, spo => U2PR_tile_id_out);

    U2N : entity work.dist_mem_gen_2N port map (a => addr_ram_tiles(9 downto 7)& addr_ram_tiles(4 downto 0), spo => data_2N);
    
    clk_color_latch <= not(i_h(3) and i_h(2) and i_h(1));

    -- U2M
    U2M: process(i_Phi34n)
    begin
        if rising_edge(i_Phi34n) then
            -- Detection front montant color latch (not(i_h(3) and i_h(2) and i_h(1)))
            if (i_h(3 downto 0) = X"F") then
                col <= data_2N;
            end if;
        end if;
    end process;                                         

    addr_tiles_data_3PN <= U2PR_tile_id_out & vf(2 downto 0);
    U3P_tile_bank_1 : entity work.dist_mem_gen_3P port map (a => addr_tiles_data_3PN, spo => data_tile_1);
    U3N_tile_bank_2 : entity work.dist_mem_gen_3N port map (a => addr_tiles_data_3PN, spo => data_tile_2);

    -- U4P                               
	U4P : process(i_Phi34n)
	begin
        if rising_edge(i_Phi34n) then
            -- Front descendant 1/2 H
            if (i_h(0) = '1') then
                case S_U4PN is
                    when "10" => shift_reg_U4P <= shift_reg_U4P(1 to 7) & '0'; -- Shift left
                    when "01" => shift_reg_U4P <= '0' & shift_reg_U4P(0 to 6); -- Shift right
                    when "11" => shift_reg_U4P <= data_tile_1;                 -- Parallel load
                    when others => null;
                end case;
            end if;
        end if;
	end process;
	Q7_4P	<= shift_reg_U4P(7);
	Q0_4P	<= shift_reg_U4P(0);	                                   

    -- U4N                               
	process(i_Phi34n)
	begin
        if rising_edge(i_Phi34n) then
            -- Front descendant 1/2 H
            if (i_h(0) = '1') then
                case S_U4PN is
                    when "10" => shift_reg_U4N <= shift_reg_U4N(1 to 7) & '0'; -- Shift left
                    when "01" => shift_reg_U4N <= '0' & shift_reg_U4N(0 to 6); -- Shift right
                    when "11" => shift_reg_U4N <= data_tile_2;                 -- Parallel load
                    when others => null;
                end case;
            end if;
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
    
    -------------------------
    -- Gestion des Sprites
    -------------------------
    -- U3E, U4E
    clr_u3E4E_l <= (O3A_5F or Q5_6K);
    load_u3E4E_l <= O1A_5F;

	clk_u3E4E <= not ((not(((not i_h(0)) and Q5_6K))) and i_Phi34);
	
	U3E4E : process(i_Phi34n)
	begin
        if rising_edge(i_Phi34n) then
            if(load_u3E4E_l = '0') then
                Q_3_4_E <= hpo;
            elsif (clr_u3E4E_l = '0') then
                Q_3_4_E <= (others => '0');
            -- Version combinatoire de clk_u3E4E <= not ((not(((not i_h(0)) and Q5_6K))) and i_Phi34);
            elsif (not(((not i_h(0)) and Q5_6K))) = '1' then
                Q_3_4_E <= Q_3_4_E + 1;
            end if;
        end if;
    end process;
    
    -- U3J, U4J
    -- Les sortie de 3J/4J sont a zero dans le cas du LS157 si Q5_6K (G) =1
    dc <= (others => '0') when Q5_6K = '1' else da when U8B_sprite_data = "00" else (cd & U8B_sprite_data(1 downto 0));    

    mb7074_wr <= not clk_u3E4E;
    mb7074_addr <= (Q_3_4_E(7) & Q_3_4_E(6) & Q_3_4_E(5) & Q_3_4_E(4) & Q_3_4_E(3) & Q_3_4_E(2) & Q_3_4_E(1) & Q_3_4_E(0))
         xor (Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K & Q4_6K);
        
    -- 2E, 2H, 3K
    U2E : entity work.dist_mem_gen_MB7074_2E port map (clk => i_clk, we => mb7074_wr, a => mb7074_addr , d => dc(5 downto 3) & '0', spo => mb7074_do_2E);
    U2H : entity work.dist_mem_gen_MB7074_2H port map (clk => i_clk, we => mb7074_wr, a => mb7074_addr , d => dc(2 downto 0) & '0', spo => mb7074_do_2H);
    
    U3K : process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_g_3K_clk = '1' then
                da <= mb7074_do_2E(3 downto 1) & mb7074_do_2H(3 downto 1);
            end if;
        end if;
    end process;

    -- 6J, 6K
    -- U6J
    process(i_Phi34n) is
    begin
        if rising_edge(i_Phi34n) then
	        -- Front montant O2B_5F
	        if (i_h(3 downto 0) = "1011") then
                Q_6J <= hd;
            end if;
        end if;
    end process;
    
    -- U6K
    U6K_D <= (Q_6J(7), not (h_256 or i_vblk), h_256n, not (h_256 or flip_2), Q_6J(3), Q_6J(2), Q_6J(1), Q_6J(0));
    (Q7_6K, cmpblk2_l, Q5_6K, Q4_6K, cd(3), cd(2), cd(1), cd(0)) <= U6K_Q;
	process(i_Phi34n)
	begin
		if rising_edge(i_Phi34n) then
			if (G_5F = '0') then
				U6K_Q <= U6K_D;
			end if;
		end if;
	end process;
    
    -- U6H
    U6H : process (i_Phi34n)
    begin
        if rising_edge(i_Phi34n) then
            if O1B_5F = '0' then
                Q_6H <= hd(7 downto 0);
            end if;
        end if;
    end process;

    -- U5F-1
    AB_1 <= (i_h(3), i_h(2));
    process(AB_1)
    begin
        O0B_5F <= '1';
        O1B_5F <= '1';
        O2B_5F <= '1';
        case AB_1 is
            when "00" =>
                O0B_5F <= '0';
            when "01" =>
                O1B_5F <= '0';
            when "10" =>
                O2B_5F <= '0';
            when others =>
        end case;
    end process;
    
    -- U5F-2
    AB_2 <= (h_256n, i_h(3));
    G_5F <= not (i_h(0) and i_h(1) and i_h(2) and i_h(3));
    process(AB_2, G_5F)
    begin
        O1A_5F <= '1';
        O3A_5F <= '1';
        case AB_2 is
            when "01" =>
                if G_5F = '0' then
                    O1A_5F <= '0';
                end if;
            when "11" =>
                if G_5F = '0' then
                    O3A_5F <= '0';
                end if;
            when others =>
        end case;
    end process;

    -- U7C, U7D, U7E, U7F
    addr_7CDEF <= Q_6H(6 downto 0) & (db(3 downto 0) xor (Q_6H(7) & Q_6H(7) & Q_6H(7) & Q_6H(7)));
    U7C_sprite_bank_1 : entity work.dist_mem_gen_7C port map(a => addr_7CDEF, spo => data_7C);
    U7D_sprite_bank_2 : entity work.dist_mem_gen_7D port map(a => addr_7CDEF, spo => data_7D);
    U7E_sprite_bank_3 : entity work.dist_mem_gen_7E port map(a => addr_7CDEF, spo => data_7E);
    U7F_sprite_bank_4 : entity work.dist_mem_gen_7F port map(a => addr_7CDEF, spo => data_7F);
    
    -- U8B
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
	                    
	process(i_Phi34n)
	begin
		if rising_edge(i_Phi34n) then
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
	
	process(i_Phi34n)
	begin
		if rising_edge(i_Phi34n) then
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
    U8H : process(i_Phi34n)
    begin
        if rising_edge(i_Phi34n) then
            -- Front montant O0B_5F (la sortie 0 de U5F est selection quand 2H et 4H passent de 0 à 1 
            -- c-à-d sur le front montant de Phi34n quand h(3 downto 0) = "0011"
            if (i_h(3 downto 0) = "0011") then
                db <= std_logic_vector(S_7_8_J(3 downto 0));
                (Q6_8H, Q1_8H, Q0_8H, Q7_8H) <= S_7_8_J(7 downto 4);
            end if;
        end if;
    end process;
    
    -- U8N
    U8N : process(i_Phi34n, h_256)
        variable q_tmp : std_logic;
	begin
        if h_256 = '0' then
		  q_tmp := '0';
        elsif rising_edge(i_Phi34n) then
            -- Front montant O0B_5F (la sortie 0 de U5F est selection quand 2H et 4H passent de 0 à 1 
            -- c-à-d sur le front montant de Phi34n quand h(3 downto 0) = "0011"
            if (i_h(3 downto 0) = "0011") then
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
		end if;
		
		Q1_8N <= q_tmp;
	end process;	                                     
    
    -- U3L, U3M
    final_col <= col when da(1 downto 0) = "00" else da(5 downto 2);
    final_vid <= (vid_1 & vid_0) when da(1 downto 0) = "00" else da(1 downto 0);
    U1EF: process(i_Phi34n, cmpblk2_l, u1ef_clr_l) is
    begin
        if (cmpblk2_l = '0') or (u1ef_clr_l = '0') then
            addr_2EF <= (others => '0');
            rom_u2F_cs_l <= '1';
            u1ef_clr_l <= '1';
        elsif rising_edge(i_Phi34n) then
            if i_h(0) = '0' then
                addr_2EF <= i_game_palette & final_col & final_vid;
                rom_u2F_cs_l <= not (final_vid(0) or final_vid(1));
                u1ef_clr_l <= cmpblk2_l;
            end if;
        end if;
    end process;        
      
    -- U2E, U2F (sur la carte CPU)
    -- Conversion de la palette en couleurs RGB
    U2E_COL : entity work.dist_mem_gen_2E port map (a => addr_2EF, spo => data_2E);
    U2F_COL : entity work.dist_mem_gen_2F port map (a => addr_2EF, spo => data_2F);

    -- Par défaut les couleurs sont inversées par les transistors Q15, Q19,...
    -- On ne sait plus bien à quelle couleur ça correspond. J'ai échantillonés les 17 couleurs
    -- utilisés dans la palette et les ai convertit en RGB sur 8 bits. Chaque sortie de 2E, 2F
    -- est un index dans la table de couleur du controlleur VGA vers la couleur finale.
    o_r <= data_2E(3 downto 1) when rom_u2F_cs_l = '0' else (others => '1');
    o_g <= data_2E(0) & data_2F(3 downto 2) when rom_u2F_cs_l = '0' else (others => '1');
    o_b <= data_2F(1 downto 0) when rom_u2F_cs_l = '0' else (others => '1');
                                   
    -- U6S, U7S, U8S
    (csn_6PR, addr_6PR) <= Y_6_7_8_S;
    A_6_7_8_S <= ((i_objwrn and i_objrdn), i_addr(9 downto 0));
    B_6_7_8_S <= ('0', i_psl_2, h_128, i_h(7), i_h(6), i_h(5), i_h(4), i_h(3), i_h(2), i_h(1), i_h(0));
    Y_6_7_8_S <= A_6_7_8_S when (i_objwrn and i_objrdn and i_objrqn) = '0' else B_6_7_8_S;

    -- U5S                  
    din_6PR <= i_vid_data_in when (i_objwrn = '0') and ((i_objrdn and i_objwrn) = '0') else (others => 'X');
                                   
    -- 6P, 6R
    u6pr_ram_wr <= not i_objwrn;
    U6PR : entity work.dist_mem_gen_6PR port map(clk => i_clk, we => u6pr_ram_wr, a => addr_6PR, d => din_6PR, spo => dout_6PR);
    
    -- U6N, U6M
    U6N : process(i_Phi34n)
    begin
        if rising_edge(i_Phi34n) then
            data_6N <= dout_6PR;
        end if;
    end process;
                                       
    -- U6M
    U6M : process(i_Phi34n)
    begin
        if rising_edge(i_Phi34n) then
            datain_7M <= data_6N;
        end if;
    end process;

    -- U7R, U8R
    S_78R <= unsigned(data_6N) + ("1111" & i_flipn & flip_1 & flip_1 & '1') + 1;

	-- U7P, U8P
    S_78P <= unsigned(vf) + S_78R;
                                   
    DI0_7M <= not ((not(Q_5KL(6) or Q_5KL(7))) and i_h(2) and i_h(3) and i_h(4) and i_h(5) and i_h(6) and i_h(7) and h_128);
    do_draw_l <= not(S_78P(7) and S_78P(6) and S_78P(5) and S_78P(4));
    
    -- U5L, U5K
    scanline_wr_l <= not((not(Q_5KL(6) or Q_5KL(7))) and Q_4L and h_256n and i_Phi34);
 
    p_u5kl : process(i_Phi34n, h_256n)
    begin
        if (h_256n = '0') then
            Q_5KL <= (others => '0');
        elsif rising_edge(i_Phi34n) then
            -- Detection front montant Phi34 (= front descendant Phi34n)
            if ((not(Q_5KL(6) or Q_5KL(7))) and Q_4L and h_256n) = '1' then
                Q_5KL <= Q_5KL + 1;
            end if;
        end if;
    end process;

    -- Scanline buffer (64 x 9 bits)
    scanline_wr <= not scanline_wr_l;
    U7M : entity work.dist_mem_gen_7M port map (clk => i_clk, we => scanline_wr, a => addr_7M , d => datain_7M & DI0_7M , spo => dataout_7M);
    -- La memoire 93419 est a collector ouvert en sortie, les bits sont donc inversés, ce qui n'est pas
    -- le cas avec une memoire classique comme avec l'Artyx 7, on n'inverse donc pas dataout_7M contrairement au schema
    -- L'ordre des bits n'est pas inverse entre dataout_7M et hd car il y a déjà une inversion entre l'entree et la sortie de U6M => Ca ne change rien
    hd <= dataout_7M(8 downto 1);    
                                                         
    -- U4L
    clk_4KL <= not ((not i_h(1)) and i_h(0));
    U4L : process(i_Phi34n, h_256n)
    begin
        if (h_256n = '0') then
            Q_4L <= '0';
        elsif rising_edge(i_Phi34n) then
            -- Front montant clk_4KL. A verifier, mais a priori il y a front montant sur 4L sur le front montant Phi34n si 1/2_h = 1 et 1H = 1
            if (i_h(1 downto 0) = "01") then
                if (not (do_draw_l and DI0_7M)) = '1' then
                    Q_4L <='1';
                else
                    Q_4L <='0';
                end if;
            end if;
        end if;
    end process;
                               
    -- U5N, U5M                       
    addr_7M <= (i_h(7) & i_h(6) & i_h(5) & i_h(4) & i_h(3) & i_h(2)) when h_256n = '0' else (Q_5KL(5) & Q_5KL(4) & Q_5KL(3) & Q_5KL(2) & Q_5KL(1) & Q_5KL(0));    
    
    -- U2K
    -- U2K part 1
    U2K_1 : process(i_Phi34n, h_256)
    begin
        if (h_256 = '0') then
           esblk_l  <= '1';
        elsif rising_edge(i_Phi34n) then
            -- Front montant h(5)
            if (i_h(5 downto 0) = "011111") then
                if (i_h(6) = '1') then
                    esblk_l <='1';
                else
                    esblk_l <='0';
                end if;
            end if;
        end if;
    end process; 
  
    -- U2K part 2
    U2K_2 : process(i_Phi34n, h_256)
    begin
        if (h_256 = '0') then
           vram_busy_l <= '0';
        elsif rising_edge(i_Phi34n) then
            -- Front montant h(2)
            if (i_h(2 downto 0) = "011") then            
                if (i_h(7 downto 4) = "1111") then
                    vram_busy_l <='0';
                else
                    vram_busy_l <='1';
                end if;
            end if;
        end if;
    end process;

    o_vram_busyn <= vram_busy_l;
    o_esblkn <= esblk_l;
    -- Dephasage de h(0) pour resoudre des problemes de timing dans l'ecriture de la RAM du controlleur VGA 
    o_pixel_write <= i_h(0);
    o_1_hb <= i_h(1);
    o_vf_2 <= vf(1);
    o_cmpblk2_l <= cmpblk2_l;

    flip_1 <= not i_flipn;
    flip_2 <= flip_1 xor '1'; -- 3R
    flip_3 <= not flip_2;
    flip_4 <= flip_3 or O0B_5F; -- 74LS32 = OR gates
    flip_5 <= not flip_4;

end Behavioral;