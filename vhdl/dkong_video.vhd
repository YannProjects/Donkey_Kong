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
            o_cmpsyncn : out std_logic;
            o_hsyncn : out std_logic;
            o_cmpblk2 : out std_logic;
            o_1_2_hb : out std_logic;
            o_1_hb : out std_logic;
            o_vf_2 : out std_logic;
            o_col : out std_logic_vector(3 downto 0);
            o_vid : out std_logic_vector(1 downto 0);
            o_esblkn : out std_logic;
            o_vram_busyn : out std_logic;
            i_vram_wrn : in std_logic;
            i_vram_rdn : in std_logic;
            i_psl_2 : in std_logic;
            i_addr : in std_logic_vector(9 downto 0);
            i_data : inout std_logic_vector(7 downto 0);
            i_objwrn : in std_logic;
            i_objrdn : in std_logic;
            i_objrqn : in std_logic;
            i_flipn : in std_logic
        );
end dk_tg4_video;

architecture Behavioral of dk_tg4_video is

signal Phi34, Phi34n, g_3K : std_logic;
signal h_1_2, h_1, h_2, h_4, h_8, h_16, h_32, h_64, h_128, h_256, h_128n, h_256n : std_logic;
signal cnt : unsigned(3 downto 0);
signal dc, da : std_logic_vector(5 downto 0);
signal cd, db, data_2N, S_7P, S_8P, S_7R, S_8R, S_7J, S_8J  : std_logic_vector(3 downto 0);
signal hpo, mb7074_addr, hd, Q_6H, data_7C, data_7D, data_7E, data_7F, U2PR_tile_id_in : std_logic_vector(7 downto 0);
signal data_6N, din_6PR, dout_6PR, datain_7M, data_tile_1, data_tile_2, U2PR_tile_id_out : std_logic_vector(7 downto 0);
signal addr_6PR: std_logic_vector(9 downto 0);
signal mb7074_do_2E, mb7074_do_2H, col : std_logic_vector(3 downto 0);
signal s2, v_16, v_32, v_64, v_128 : std_logic;
signal Q2_3A, Q1_3A : std_logic;
signal Q1_3B, Q2_3B, Q2_5D, CA_5D, CA_6D, Q0_5D, Q1_5D : std_logic;
signal U1L_reload, CA_1N, CA_1M, Q1n_4A, Q2_4A, Q2n_4A : std_logic;
signal vf_1, vf_2, vf_4, vf_8, vf_16, vf_32, vf_64, vf_128  : std_logic;
signal vfc_1, vfc_2, vfc_4, vfc_8, vfc_16, vfc_32, vfc_64, vfc_128  : std_logic;
signal Q1n_4B, Q1_4B, Q2n_4B, Q1_6D : std_logic;
signal Q7_6K, G_5F, O1_5F, Q1_3E, Q0_4E : std_logic;
signal O3_5F, CA_4E, Q1_4E, Q3_4E, Q3_3E, Q2_4E, Q2_3E, Q0_3E, Q6_6K : std_logic;
signal Q3_6J, O2B_5F, Q6_6J, Q2_6J, Q4_6J, Q5_6J : std_logic;
signal O1B_5F, O0B_5F, Q0_8C, Q8_8D, Q7_8E, Q7_8C, Q7_8F, Q8_8F, Q7_8D : std_logic;
signal Q1_6K, Q5_6K, Q0_8E : std_logic;
signal I1C_I0D_8B, Q7_8H, Q1_8H, Q0_8H, Q6_8H, C4_8J, C4_8K, Q1_8N  : std_logic;
signal mb7074_wrn, csn_6PR : std_logic;
signal S0_8R, S1_8R, S2_8R, S3_8R, Q0_5L, Q1_5L, Q2_5L, Q3_5L : std_logic;
signal Q0_5K, Q1_5K, Q2_5K, Q3_5K, C4_8R, C4_8P, TC_5L, scanline_wr_l : std_logic;
signal Q0_4P, Q0_4N, Q7_4P, Q7_4N : std_logic;
signal DI0_7M, Q2_4L : std_logic;
signal addr_7M : std_logic_vector(5 downto 0);
signal dataout_7M : std_logic_vector(8 downto 0);
signal addr_7CDEF, addr_tiles_data_3PN : std_logic_vector(10 downto 0);
signal vid_0, vid_1, S0_U4PN, S1_U4PN : std_logic;

signal vram_busy, esblk, tile_shift_reg_reload_l, U8B_sprite_reload_S1, U8B_sprite_reload_S0 : std_logic;
signal do_draw_l, u6pr_ram_wr : std_logic;
signal U8B_sprite_data : std_logic_vector(1 downto 0);
signal addr_ram_tiles : std_logic_vector(9 downto 0);
signal addr_tiles_ram_cs_l, char_tile_reload, U234S_S, clk_color_latch : std_logic;
signal scanline_wr : std_logic;

begin

    -- 1E, 1F, 1H - Video sheet schematic
    p_mc10136 : process(i_clk)
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
    U1N : entity work.SN74LS163N generic map(tPLHT => 0 ns, tPHLT => 0 ns, tPLHQ => 0 ns, tPHLQ => 0 ns)  
                                 port map (X_1 => not i_rst, X_2 => Phi34n, X_3 => '1', X_4 => '1', X_5 => '1', X_6 => '1', 
                                           X_7 => '1', X_10 => '1', X_9 => '1', X_15 => CA_1N, X_14 => h_1_2, X_13 => h_1, X_12 => h_2, X_11 => h_4); 
    U1M : entity work.SN74LS163N generic map(tPLHT => 0 ns, tPHLT => 0 ns, tPLHQ => 0 ns, tPHLQ => 0 ns) 
                                 port map (X_1 => not i_rst, X_2 => Phi34n, X_3 => '1', X_4 => '1', X_5 => '1', X_6 => '1', 
                                           X_7 => CA_1N, X_10 => CA_1N, X_9 => '1', X_15 => CA_1M, X_14 => h_8, X_13 => h_16, X_12 => h_32, X_11 => h_64); 
    U1L : entity  work.SN74LS163N generic map(tPLHT => 0 ns, tPHLT => 0 ns, tPLHQ => 0 ns, tPHLQ => 0 ns)
                                 port map (X_1 => not i_rst, X_2 => Phi34n, X_3 => '1', X_4 => '0', X_5 => '1', X_6 => '1', 
                                           X_7 => CA_1N, X_10 => CA_1M, X_9 => not U1L_reload, X_15 => U1L_reload, X_13 => h_128n, X_14 => h_256n);   
    
    h_128 <= not h_128n;
    h_256 <= not h_256n;
    
    -- U3A
    U3A : entity work.SN74123N
    generic map (
        W1 => 1359ns,
        W2 => 12516ns
    ) 
    port map(
        X_1 => Q2_3A,
        X_2 => '1',
        X_3 => not i_rst,
        X_5 => Q2_3A,
        X_9 => '0',
        X_10 => h_256,
        X_11 => not i_rst,
        X_13 => Q1_3A
    );

    U3B : entity work.SN74123N
    generic map (
        W1 => 500us,
        W2 => 1400us
    ) 
    port map(
        X_1 => Q2_3B,
        X_2 => '1',
        X_3 => not i_rst,
        X_5 => Q2_3B,
        X_9 => Q1_4B,
        X_10 => '1',
        X_11 => not i_rst,
        X_13 => Q1_3B
    );
    
    -- 6B
    o_vsyncn <= not Q1_3B;
    o_hsyncn <= not Q1_3A;
    o_cmpsyncn <= not (Q1_3A or Q1_3B);
    
    -- 4A, 4B, 5D, 6D
    U4A : entity work.SN74LS74N port map (X_1 => not i_rst, X_2 => not ((not h_64) and h_32), X_3 => h_16, X_4 => h_256,
        X_6 => Q1n_4A, X_8 => Q2n_4A, X_9 => Q2_4A, X_10 => not i_rst, X_11 => Q1n_4A, X_12 => Q2n_4A, X_13 => '1');
        
    o_vblkn <= not Q1n_4B;
        
    U4B : entity work.SN74LS74N port map (X_1 => not i_rst, X_2 => not (v_32 and v_64 and v_128), X_3 => v_16, X_4 => '1', X_5 => Q1_4B,
        X_6 => Q1n_4B, X_8 => Q2n_4B, X_10 => not i_rst, X_11 => Q1_6D, X_12 => Q2n_4B, X_13 => '1');        
    
    U5C : entity work.SN74LS163N port map (X_1 => not i_rst, X_2 => Q1n_4A, X_3 => '0', X_4 => '0', X_5 => '1', X_6 => '1', X_7 => Q2_4A, X_9 => not CA_6D,
        X_10 => Q2_4A, X_11 => v_16, X_12 => Q2_5D, X_13 => Q1_5D, X_14 => Q0_5D, X_15 => CA_5D);  
    
    U6C : entity work.SN74LS163N port map (X_1 => not i_rst, X_2 => Q1n_4A, X_3 => '1', X_4 => '1', X_5 => '1', X_6 => '0', X_7 => CA_5D, X_9 => not CA_6D,
        X_10 => CA_5D, X_11 => Q1_6D, X_12 => v_128, X_13 => v_64, X_14 => v_32, X_15 => CA_6D);  

    -- 5E, 6E
    vf_1 <= (i_flipn xor Q2_4A);
    vf_2 <= (i_flipn xor Q0_5D);
    vf_4 <= (i_flipn xor Q1_5D);
    vf_8 <= (i_flipn xor Q2_5D);
    vf_16 <= (i_flipn xor v_16);
    vf_32 <= (i_flipn xor v_32);
    vf_64 <= (i_flipn xor v_64);
    vf_128 <= (i_flipn xor v_128);
    
    U5E : entity work.SN74LS175N port map (X_1 => not i_rst, X_9 => h_256n, X_4 => vf_1, X_5 => vf_2, X_12 => vf_4, X_13 => vf_8,
        X_2 => vfc_1, X_7 => vfc_2, X_10 => vfc_4, X_15 => vfc_8);    

    U6E : entity work.SN74LS175N port map (X_1 => not i_rst, X_9 => h_256n, X_4 => vf_16, X_5 => vf_32, X_12 => vf_64, X_13 => vf_128,
        X_2 => vfc_16, X_7 => vfc_32, X_10 => vfc_64, X_15 => vfc_128);    
    
    -- 3J, 4J
    U4J : entity work.SN74LS157N port map (X_1 => (U8B_sprite_data(0) or U8B_sprite_data(1)), X_2 => '0', X_5 => '0', X_14 => da(5), X_11 => da(4),
        X_3 => '0', X_6 => '0', X_13 => cd(3), X_10 => cd(2), X_15 => Q7_6K,
        X_12 => dc(5), X_9 => dc(4)); 

    U3J : entity work.SN74LS157N port map (X_1 => (U8B_sprite_data(0) or U8B_sprite_data(1)), X_2 => da(3), X_5 => da(2), X_14 => da(1), X_11 => da(0),
        X_3 => cd(1), X_6 => cd(0), X_13 => U8B_sprite_data(0), X_10 => U8B_sprite_data(1), X_15 => Q7_6K,
        X_4 => dc(3), X_7 => dc(2), X_12 => dc(1), X_9 => dc(0)); 
    
    -- 5F
    G_5F <= not (h_1_2 and h_1 and h_2 and h_4);
    U5F : entity work.SN74LS139N port map (X_1 => G_5F, X_2 => h_4, X_3 => h_256n, X_5 => O1_5F, X_7 => O3_5F,
                                    X_13 => h_4, X_14 => h_2, X_15 => '0', X_10 => O2B_5F, X_11 => O1B_5F, X_12 => O0B_5F);
    -- 3E, 4E
    U3E : entity work.SN74LS163N port map (X_1 => (O3_5F or Q7_6K), X_2 => mb7074_wrn,
        X_3 => hpo(4), X_4 => hpo(5), X_5 => hpo(6), X_6 => hpo(7), X_9 => O1_5F,
        X_11 => Q3_3E, X_12 => Q2_3E, X_13 => Q1_3E, X_14 => Q0_3E, 
        X_7 => CA_4E, X_10 => CA_4E);
        
    U4E : entity work.SN74LS163N port map (X_1 => (O3_5F or Q7_6K), X_2 => mb7074_wrn,
        X_3 => hpo(0), X_4 => hpo(1), X_5 => hpo(2), X_6 => hpo(3), X_9 => O1_5F,
        X_11 => Q3_4E, X_12 => Q2_4E, X_13 => Q1_4E, X_14 => Q0_4E, 
        X_7 => '1', X_10 => '1', X_15 => CA_4E);

    mb7074_wrn <= not ((not ((not h_1_2) and Q7_6K)) and Phi34);
    mb7074_addr <= (Q1_4E & Q3_4E & Q1_3E & Q3_3E & Q2_3E & Q0_3E & Q2_4E & Q0_4E) xor (Q6_6K & Q6_6K & Q6_6K & Q6_6K & Q6_6K & Q6_6K & Q6_6K & Q6_6K);
        
    -- 2E, 2H, 3K
    U2E : entity work.blk_mem_gen_2E port map (clka => Phi34, wea(0) => mb7074_wrn, addra => mb7074_addr , dina => dc(5 downto 3) & '0', douta => mb7074_do_2E);
    U2H : entity work.blk_mem_gen_2H port map (clka => Phi34, wea(0) => mb7074_wrn, addra => mb7074_addr , dina => dc(2 downto 0) & '0', douta => mb7074_do_2H);
    
    U3K : entity work.SN74LS373N port map (X_11 => g_3K, X_1 => '0',
        X_17 => mb7074_do_2E(3), X_7 => mb7074_do_2E(2), X_18 => mb7074_do_2E(1), X_8 => '1',
        X_4 => mb7074_do_2H(3), X_3 => mb7074_do_2H(2), X_14 => mb7074_do_2H(1), X_13 => '1',
        X_16 => da(5), X_6 => da(4), X_19 => da(3), X_5 => da(2), X_2 => da(1), X_15 => da(0));
        
    --- 6J, 6K
    U6J : entity work.SN74LS273N port map (X_1 => not i_rst, X_11 => O2B_5F,
        X_8 => hd(0), X_14 => hd(1), X_7 => hd(2), X_13 => hd(3), X_4 => hd(4), X_18 => hd(5), X_3 =>hd(6), X_17 => hd(7),
        X_9 => Q3_6J, X_15 => Q5_6J, X_6 => Q2_6J, X_12 => Q4_6J, X_16 => Q6_6J);
        
    U6K : entity work.SN74LS273N port map (X_1 => G_5F, X_11 => Phi34n,
        X_8 => Q3_6J, X_14 => Q5_6J, X_7 => Q2_6J, X_13 => Q4_6J, X_17 => (not h_256) and (not i_flipn), X_18 => h_256n, X_3 => not (h_256 or Q1n_4B), X_4 => Q6_6J,
        X_9 => cd(0), X_15 => cd(1), X_6 => cd(2), X_12 => cd(3), X_16 => Q6_6K, X_19 => Q7_6K, X_2 => o_cmpblk2, X_5 => Q1_6K);
    
    -- 6H    
    U6H : entity work.SN74LS373N port map (X_8 => hd(0), X_14 => hd(1), X_7 => hd(2), X_13 => hd(3), X_4 => hd(4), X_18 => hd(5), X_3 => hd(6), X_17 => hd(7),
                                    X_9 => Q_6H(0), X_15 => Q_6H(1), X_6 => Q_6H(2), X_12 => Q_6H(3), X_5 => Q_6H(4), X_19 => Q_6H(5), X_2 => Q_6H(6), X_16 => Q_6H(7),
                                    X_11 => not O1B_5F, X_1 => '0');
    -- U7C, U7D, U7E, U7F
    addr_7CDEF <= Q_6H(6 downto 0) & (db(3 downto 0) xor (Q_6H(7) & Q_6H(7) & Q_6H(7) & Q_6H(7)));
    U7C_sprite_bank_1 : entity work.dist_mem_gen_7C port map(a => addr_7CDEF, spo => data_7C);
    U7D_sprite_bank_2 : entity work.dist_mem_gen_7D port map(a => addr_7CDEF, spo => data_7D);
    U7E_sprite_bank_3 : entity work.dist_mem_gen_7E port map(a => addr_7CDEF, spo => data_7E);
    U7F_sprite_bank_4 : entity work.dist_mem_gen_7F port map(a => addr_7CDEF, spo => data_7F);
    
    -- 8B
    U8B : entity work.SN74LS157N port map(X_1 => Q5_6K, X_15 => '0',
                                   X_2 => Q0_8C, X_3 => Q7_8D, X_5 => Q0_8E, X_6 => Q7_8F,
                                   X_11 => '1', X_10 => I1C_I0D_8B, X_14 => I1C_I0D_8B, X_13 => '1',
                                   X_4 => U8B_sprite_data(0), X_7 => U8B_sprite_data(1), X_9 => U8B_sprite_reload_S1, X_12 => U8B_sprite_reload_S0);
    I1C_I0D_8B <= ((not (Q7_8H and Q0_8H and Q1_8H and Q6_8H)) and (not Q1_8N)) and (not G_5F);
    
    -- U8C, U8D, U8E, U8F
    U8C_sprite_shit_reg_1 : entity work.SN74LS299N port map(X_8 => Q0_8C, X_11 => '0', X_17 => Q7_8C, X_18 => Q8_8D,
                                   X_7 => data_7C(7), X_13 => data_7C(6), X_6 => data_7C(5), X_14 => data_7C(4), X_5 => data_7C(3), X_15 => data_7C(2), X_4 => data_7C(1), X_16 => data_7C(0),
                                   X_12 => Phi34n, X_9 => '1', X_2 => '1', X_3 => '1', X_19 => U8B_sprite_reload_S1, X_1 => U8B_sprite_reload_S0);
    U8D_sprite_shit_reg_2 : entity work.SN74LS299N port map(X_8 => Q8_8D, X_11 => Q7_8C, X_17 => Q7_8D, X_18 => '0',
                                   X_7 => data_7D(7), X_13 => data_7D(6), X_6 => data_7D(5), X_14 => data_7D(4), X_5 => data_7D(3), X_15 => data_7D(2), X_4 => data_7D(1), X_16 => data_7D(0),
                                   X_12 => Phi34n, X_9 => '1', X_2 => '1', X_3 => '1', X_19 => U8B_sprite_reload_S1, X_1 => U8B_sprite_reload_S0);
    U8E_sprite_shit_reg_3 : entity work.SN74LS299N port map(X_8 => Q0_8E, X_11 => '0', X_17 => Q7_8E, X_18 => Q8_8F,
                                   X_7 => data_7E(7), X_13 => data_7E(6), X_6 => data_7E(5), X_14 => data_7E(4), X_5 => data_7E(3), X_15 => data_7E(2), X_4 => data_7E(1), X_16 => data_7E(0),
                                   X_12 => Phi34n, X_9 => '1', X_2 => '1', X_3 => '1', X_19 => U8B_sprite_reload_S1, X_1 => U8B_sprite_reload_S0);                                     
    U8F_sprite_shit_reg_4 : entity work.SN74LS299N port map(X_8 => Q8_8F, X_11 => Q7_8E, X_17 => Q7_8F, X_18 => '0',
                                   X_7 => data_7F(7), X_13 => data_7F(6), X_6 => data_7F(5), X_14 => data_7F(4), X_5 => data_7F(3), X_15 => data_7F(2), X_4 => data_7F(1), X_16 => data_7F(0),
                                   X_12 => Phi34n, X_9 => '1', X_2 => '1', X_3 => '1', X_19 => U8B_sprite_reload_S1, X_1 => U8B_sprite_reload_S0);
    
    U7K : entity work.SN74LS283N port map(X_5 => '1', X_3 => '1', X_14 => '1', X_12 => '1',
                                   X_6 => hd(4), X_2 => hd(5), X_15 => hd(6), X_11 => hd(7),
                                   X_4 => hpo(4), X_1 => hpo(5), X_13 => hpo(6), X_10 => hpo(7),
                                   X_7 => C4_8K);
    U8K : entity work.SN74LS283N port map(X_5 => '1', X_3 => '1', X_14 => '1', X_12 => '1',
                                   X_6 => hd(3), X_2 => hd(2), X_15 => hd(1), X_11 => hd(0),
                                   X_4 => hpo(3), X_1 => hpo(2), X_13 => hpo(1), X_10 => hpo(0),
                                   X_7 => '1', X_9 => C4_8K);

    U7J : entity work.SN74LS283N port map(X_5 => vfc_16, X_3 => vfc_32, X_14 => vfc_64, X_12 => vfc_128,
                                   X_6 => hpo(4), X_2 => hpo(5), X_15 => hpo(6), X_11 => hpo(7),
                                   X_4 => S_7J(0), X_1 => S_7J(1), X_13 => S_7J(2), X_10 => S_7J(3),
                                   X_7 => C4_8J);
    U8J : entity work.SN74LS283N port map(X_5 => vfc_1, X_3 => vfc_2, X_14 => vfc_4, X_12 => vfc_8,
                                   X_6 => hpo(0), X_2 => hpo(1), X_15 => hpo(2), X_11 => hpo(3),
                                   X_4 => S_8J(0), X_1 => S_8J(1), X_13 => S_8J(2), X_10 => S_8J(3),
                                   X_7 => '0', X_9 => C4_8J);
    U8H : entity work.SN74LS273N port map(X_14 => S_8J(0), X_7 => S_8J(1), X_8 => S_8J(2), X_13 => S_8J(3), X_18 => S_7J(3), X_3 => S_7J(2), X_4 => S_7J(1), X_17 => S_7J(0),
                                   X_15 => db(0), X_6 => db(1), X_9 => db(2), X_12 => db(3), X_19 => Q7_8H, X_2 => Q0_8H, X_5 => Q1_8H, X_16 => Q6_8H,
                                   X_11 => O0B_5F, X_1 => not i_rst);
    -- 8N
    U8N : entity work.SN74LS109N port map(X_11 => '1', X_12 => '0', X_13 => '0', X_14 => '0', X_15 => '1',
                                          X_1 => '1', X_2 => dataout_7M(0), X_3 => '1', X_4 => O0B_5F, X_5 => '1', X_6 => Q1_8N);
    
    -- Zone A-J 1-9
    -- 3L, 3M
    o_col <= da(5 downto 2) when not (da(0) or da(1)) = '0' else col;
    o_vid <= da(1 downto 0) when not (da(0) or da(1)) = '0' else (vid_1 & vid_0);
    -- U3M : entity work.SN74LS157N port map(X_11 => da(4), X_10 => col(2), X_14 => da(5), X_13 => col(3), X_5 => '0', X_6 => '0', X_2 => '0', X_3 => '0', 
    --                                X_12 => o_col(3), X_9 => o_col(2),
    --                                X_1 => not (da(0) or da(1)),
    --                               X_15 => '0');
    -- U3L : entity work.SN74LS157N port map(X_11 => da(0), X_10 => vid_0, X_14 => da(1), X_13 => vid_1, X_5 => da(2), X_6 => col(0), X_2 => da(3), X_3 => col(1), 
    --                                X_9 => o_vid(0), X_12 => o_vid(1), X_7 => o_col(0), X_4 => o_col(1),
    --                                X_1 => not (da(0) or da(1)),
    --                                X_15 => '0');
                                   
    -- 6S, 7S, 8S
    U6S : entity work.SN74LS157N port map(X_11 => i_addr(8), X_10 => h_128, X_14 => (i_objwrn and i_objrdn), X_13 => '0', X_5 => i_addr(9), X_6 => h_128, X_2 => '0', X_3 => '0', 
                                   X_12 => csn_6PR, X_7 => addr_6PR(9), X_9 => addr_6PR(8),   
                                   X_1 => (i_objwrn and i_objrdn and i_objrqn), X_15 => '0');
    U7S : entity work.SN74LS157N port map(X_11 => i_addr(4), X_10 => h_8, X_5 => i_addr(5), X_6 => h_16, X_14 => i_addr(6), X_13 => h_32, X_2 => i_addr(7), X_3 => h_64, 
                                   X_9 => addr_6PR(4), X_7 => addr_6PR(5), X_12 => addr_6PR(6), X_4 => addr_6PR(7),    
                                   X_1 => (i_objwrn and i_objrdn and i_objrqn), X_15 => '0');                            
    U8S : entity work.SN74LS157N port map(X_11 => i_addr(0), X_10 => h_1_2, X_5 => i_addr(1), X_6 => h_1, X_14 => i_addr(2), X_13 => h_2, X_2 => i_addr(3), X_3 => h_4, 
                                   X_9 => addr_6PR(0), X_7 => addr_6PR(1), X_12 => addr_6PR(2), X_4 => addr_6PR(3),    
                                   X_1 => (i_objwrn and i_objrdn and i_objrqn), X_15 => '0');
                                   
    -- U5S
    U5S : entity work.SN74LS245N port map(X_1 => i_objwrn, 
                                   X_18 => i_data(0), X_17 => i_data(1), X_16 => i_data(2), X_15 => i_data(3), X_14 => i_data(4), X_13 => i_data(5), X_12 => i_data(6), X_11 => i_data(7),
                                   X_2 => din_6PR(0), X_3 => din_6PR(1), X_4 => din_6PR(2), X_5 => din_6PR(3), X_6 => din_6PR(4), X_7 => din_6PR(5), X_8 => din_6PR(6), X_9 => din_6PR(7),
                                   X_19 => (i_objrdn and i_objwrn));
                                   
    -- 6P, 6R
    u6pr_ram_wr <= not i_objwrn;
    U6PR : entity work.blk_mem_gen_6PR port map(clka => Phi34, ena => not csn_6PR, wea(0) => u6pr_ram_wr, addra => addr_6PR, dina => din_6PR, douta => dout_6PR);
    
    -- 6N, 6M
    U6N : entity work.SN74LS273N port map(X_11 => Phi34n,
                                   X_1 => '1',
                                   X_7 => dout_6PR(0), X_14 => dout_6PR(1), X_8 => dout_6PR(2), X_13 => dout_6PR(3), X_3 => dout_6PR(4), X_18 => dout_6PR(5), X_4 => dout_6PR(6), X_17 => dout_6PR(7),
                                   X_6 => data_6N(0), X_15 => data_6N(1), X_9 => data_6N(2), X_12 => data_6N(3), X_2 => data_6N(4), X_19 => data_6N(5), X_5 => data_6N(6), X_16 => data_6N(7));
    U6M : entity work.SN74LS273N port map(X_11 => Phi34n,
                                   X_1 => '1',
                                   X_7 => data_6N(0), X_14 => data_6N(1), X_8 => data_6N(2), X_13 => data_6N(3), X_3 => data_6N(4), X_18 => data_6N(5), X_4 => data_6N(6), X_17 => data_6N(7),
                                   X_6 => datain_7M(0), X_15 => datain_7M(1), X_9 => datain_7M(2), X_12 => datain_7M(3), X_2 => datain_7M(4), X_19 => datain_7M(5), X_5 => datain_7M(6), X_16 => datain_7M(7));
                                   
    -- 7R, 8R, 7P, 8P
    U7R : entity work.SN74LS283N port map(X_5 => '1', X_6 => data_6N(4), X_3 => '1', X_2 => data_6N(5), X_14 => '1', X_15 => data_6N(6), X_12 => '1', X_11 => data_6N(7),
                                   X_7 => C4_8R,
                                   X_4 => S_7R(0), X_1 => S_7R(1), X_13 => S_7R(2), X_10 => S_7R(3));
    U8R : entity work.SN74LS283N port map(X_5 => data_6N(0), X_6 => '1', X_3 => data_6N(1), X_2 => not i_flipn, X_14 => data_6N(2), X_15 => not i_flipn, X_12 => data_6N(3), X_11 => i_flipn,
                                   X_7 => '1', X_9 => C4_8R,
                                   X_4 => S_8R(0), X_1 => S_8R(1), X_13 => S_8R(2), X_10 => S_8R(3));
    U7P : entity work.SN74LS283N port map(X_6 => S_7R(0), X_5 => vf_16, X_2 => S_7R(1), X_3 => vf_32, X_14 => S_7R(2), X_15 => vf_64, X_12 => S_7R(3), X_11 => vf_128,
                                   X_7 => C4_8P,
                                   X_4 => S_7P(0), X_1 => S_7P(1), X_13 => S_7P(2), X_10 => S_7P(3));
    U8P : entity work.SN74LS283N port map(X_6 => S_8R(0), X_5 => vf_1, X_2 => S_8R(1), X_3 => vf_2, X_14 => S_8R(2), X_15 => vf_4, X_12 => S_8R(3), X_11 => vf_8,
                                   X_7 => '0', X_9 => C4_8P,
                                   X_4 => S_8P(0), X_1 => S_8P(1), X_13 => S_8P(2), X_10 => S_8P(3));           
                                   
    DI0_7M <= not ((not(Q2_5K or Q3_5K))and h_2 and h_4 and h_8 and h_16 and h_32 and h_64 and h_128);
    do_draw_l <= not(S_7P(0) and S_7P(1) and S_7P(2) and S_7P(3));
    
    -- 5L, 5K
    scanline_wr_l <= not((not(Q2_5K or Q3_5K)) and Q2_4L and h_256n and Phi34);
    U5L : entity work.SN74LS161N port map(X_3 => '1', X_4 => '1', X_5 => '1', X_6 => '1',
                                   X_9 => '1', X_7 => '1', X_10 => '1',
                                   X_14 => Q0_5L, X_13 => Q1_5L, X_12 => Q2_5L, X_11 => Q3_5L, 
                                   X_2 => scanline_wr_l, X_1 => h_256n, X_15 => TC_5L);
    U5K : entity work.SN74LS161N port map(X_3 => '1', X_4 => '1', X_5 => '1', X_6 => '1',
                                   X_9 => '1', X_7 => TC_5L, X_10 => TC_5L,
                                   X_14 => Q0_5K, X_13 => Q1_5K, X_12 => Q2_5K, X_11 => Q3_5K, 
                                   X_2 => scanline_wr_l, X_1 => h_256n);                          
    -- 4L
    U4L : entity work.SN74LS74N port map(X_1 => '1', X_2 => '0', X_3 => '0', X_4 => '1',
                               X_11 => not((not h_1) and h_1_2), X_12 => not(do_draw_l and DI0_7M), X_10 => not i_rst,
                               X_13 => h_256n, X_9 => Q2_4L);
                               
    -- 5N, 5M
    -- U5N : entity work.SN74LS157N port map (X_1 => h_256n,
    --                                 X_2 => h_32, X_5 => h_16, X_11 => h_64, X_13 => '0',
    --                                 X_3 => Q0_5K, X_6 => Q3_5L, X_10 => Q1_5K, X_14 => '0',
    --                                 X_9 => addr_7M(5), X_4 => addr_7M(4), X_7 => addr_7M(3),
    --                                 X_15 => '0');
    -- U5M : entity work.SN74LS157N port map (X_1 => h_256n,
    --                                 X_2 => h_4, X_5 => h_2, X_11 => h_8, X_13 => '0',
    --                                 X_3 => Q1_5L, X_6 => Q0_5L, X_10 => Q2_5L, X_14 => '0',
    --                                 X_9 => addr_7M(2), X_4 => addr_7M(1), X_7 => addr_7M(0),
    --                                 X_15 => '0');
                                    
    addr_7M <= (h_64 & h_32 & h_16 & h_8 & h_4 & h_2) when h_256n = '0' else (Q1_5K & Q0_5K & Q3_5L & Q2_5L & Q1_5L & Q0_5L);    
    
    -- _Scanline buffer (64 x 9 bits)
    scanline_wr <= not scanline_wr_l;
    U7M : entity work.blk_mem_gen_7M port map (clka => Phi34, wea(0) => scanline_wr, addra => addr_7M , dina => DI0_7M & datain_7M, douta => dataout_7M);
    hd(7 downto 0) <= not dataout_7M(8 downto 1);
    
    U2K : entity work.SN74LS74N port map(X_3 => h_32, X_2 => h_64, X_4 => h_256,
                               X_1 => not i_rst, X_6 => esblk,
                               X_11 => h_2, X_12 => not(h_8 and h_16 and h_32 and h_64), X_10 => not i_rst,
                               X_13 => h_256, X_8 => vram_busy);
    o_vram_busyn <= not vram_busy;
    o_esblkn <= not esblk;
    o_1_2_hb <= h_1_2;
    o_1_hb <= h_1;
    o_vf_2 <= vf_2;
                                
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
    --                                X_3 => (not i_flipn) xor h_64, X_6 => (not i_flipn) xor h_32, X_13 => (not i_flipn) xor h_16, X_10 => (not i_flipn) xor h_8,
    --                                X_4 => U4S_Y(3), X_7 => U4S_Y(1), X_12 => U4S_Y(2), X_9 => U4S_Y(0),
    --                                X_1 => not (Q1n_4B or h_256),
    --                                X_15 => '0');

    U234S_S <= (not (Q1n_4B or h_256));
    addr_ram_tiles <= i_addr(9 downto 0) when U234S_S = '0' else 
                        vf_128 & vf_64 & vf_32 & vf_16 & vf_8 & 
                        (h_128 xor (not i_flipn)) & (h_64 xor (not i_flipn)) &
                        (h_32 xor (not i_flipn)) & (h_16 xor (not i_flipn)) & (h_8 xor (not i_flipn));
                        
    addr_tiles_ram_cs_l <= (not i_vram_wrn) and (not i_vram_rdn) when U234S_S = '0' else '0';
    char_tile_reload <= '1' when U234S_S = '0' else '0';
                                   
    U1S : entity work.SN74LS245N port map(X_18 => i_data(7), X_17 => i_data(6), X_16 => i_data(5), X_15 => i_data(4), X_14 => i_data(3), X_13 => i_data(2), X_12 => i_data(1), X_11 => i_data(0), 
                                    X_2 => U2PR_tile_id_in(7), X_3 => U2PR_tile_id_in(6), X_4 => U2PR_tile_id_in(5), X_5 => U2PR_tile_id_in(4), 
                                    X_6 => U2PR_tile_id_in(3), X_7 => U2PR_tile_id_in(2), X_8 => U2PR_tile_id_in(1), X_9 => U2PR_tile_id_in(0),
                                    X_1 => i_vram_wrn,
                                    X_19 => ((not i_vram_rdn) and (not i_vram_wrn)));
    
    U2PR : entity work.blk_mem_gen_2PR port map (clka => Phi34, wea(0) => not(i_vram_wrn), 
                                addra => addr_ram_tiles, dina => U2PR_tile_id_in, douta => U2PR_tile_id_out, ena => not addr_tiles_ram_cs_l);

    U2N : entity work.dist_mem_gen_2N port map (a => addr_ram_tiles(9 downto 7)& addr_ram_tiles(4 downto 0), spo => data_2N);
    
    clk_color_latch <= not(h_4 and h_2 and h_1);
    U2M : entity work.SN74LS174N port map (X_3 => '1', X_4 => '1', X_6 => data_2N(3), X_11 => data_2N(2), X_13 => data_2N(1), X_14 => data_2N(0), 
                                    X_7 => col(3), X_10 => col(2), X_12 => col(1), X_15 => col(0),
                                    X_1 => '1',
                                    X_9 => clk_color_latch);

    addr_tiles_data_3PN <= U2PR_tile_id_out & vf_4 & vf_2 & vf_1;
    U3P_tile_bank_1 : entity work.dist_mem_gen_3P port map (a => addr_tiles_data_3PN, spo => data_tile_1);
    U3N_tile_bank_2 : entity work.dist_mem_gen_3N port map (a => addr_tiles_data_3PN, spo => data_tile_2);
    
    U4P : entity work.SN74LS299N port map (X_8 => Q0_4P, X_11 => '0', X_17 => Q7_4P, X_18 => '0',
                                   X_7 => data_tile_1(7), X_13 => data_tile_1(6), X_6 => data_tile_1(5), X_14 => data_tile_1(4), X_5 => data_tile_1(3), X_15 => data_tile_1(2), X_4 => data_tile_1(1), X_16 => data_tile_1(0),
                                   X_12 => not h_1_2, X_9 => '1', X_2 => '1', X_3 => '1',
                                   X_1 => S0_U4PN, X_19 => S1_U4PN);
    
    U4N : entity work.SN74LS299N port map (X_8 => Q0_4N, X_11 => '0', X_17 => Q7_4N, X_18 => '0',
                                   X_7 => data_tile_2(7), X_13 => data_tile_2(6), X_6 => data_tile_2(5), X_14 => data_tile_2(4), X_5 => data_tile_2(3), X_15 => data_tile_2(2), X_4 => data_tile_2(1), X_16 => data_tile_2(0),
                                   X_12 => not h_1_2, X_9 => '1', X_2 => '1', X_3 => '1',
                                   X_1 => S0_U4PN, X_19 => S1_U4PN);                                   
    
    tile_shift_reg_reload_l <= clk_color_latch and (not char_tile_reload);
    U4M : entity work.SN74LS157N port map (X_2 => Q0_4P, X_5 => Q0_4N, X_14 => tile_shift_reg_reload_l, X_11 => '1',
                                    X_3 => Q7_4P, X_6 => Q7_4N, X_13 => '1', X_10 => tile_shift_reg_reload_l,
                                    X_4 => vid_1, X_7 => vid_0, X_12 => S1_U4PN, X_9 => S0_U4PN,
                                    X_1 => not i_flipn,
                                    X_15 => '0');

end Behavioral;