----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.02.2025 18:06:46
-- Design Name: 
-- Module Name: dkong_adec - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Decodage des adresses et gestion des signaux du Z80 de Donkey Kong Nintendo 1984 version TKG4
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dkong_adec is
port (
        i_rst : in std_logic;
        i_clk : in std_logic; -- Phi34n
        i_addr : in std_logic_vector(15 downto 0);
        i_vblk_l : in std_logic;
        i_vram_busy_l : in std_logic;
        i_rfrsh_l : in std_logic;
        i_mreq_comb_l : in std_logic;
        i_rd_l : in std_logic; -- Z80 read
        i_wr_l : in std_logic; -- Z80 write
        i_rams_wr_enable : in std_logic; -- Enable WR to RAMs if not RAM busy
        
        o_objrd_l : out std_logic;
        o_objwr_l : out std_logic;
        o_objrq_l : out std_logic;
        o_vram_wr_l : out std_logic;
        o_vram_rd_l : out std_logic;
        o_vram_req_l : out std_logic;
        o_ram_34A_cs_l : out std_logic;
        o_ram_34B_cs_l : out std_logic;
        o_ram_34C_cs_l : out std_logic;
        
        o_rom_cs_l : out std_logic;
        o_uart_cs_l : out std_logic;
        o_dma_cs_l : out std_logic;
        o_in1_cs_l : out std_logic;
        o_in2_cs_l : out std_logic;
        o_in3_cs_l : out std_logic;
        o_dipsw_cs_l : out std_logic;
        o_5H_cs_l : out std_logic;
        o_6H_cs_l : out std_logic;
        o_3D_cs_l : out std_logic
    );
end dkong_adec;

architecture Behavioral of dkong_adec is

signal Q0_4D, Q1_4D, Q2_4D, Q3_4D, Q6_4D, Q7_4D : std_logic;
signal Q1_2A_1 : std_logic;
signal Q0_2A_2, Q1_2A_2, Q3_2A_2, Q0_2B, Q1_2B, Q0_2C, Q1_2C : std_logic;
signal Q0_2D, Q1_2D, Q2_2D, Q0_1B, Q1_1B, Q2_1B, Q3_1B : std_logic;
signal Q0_1C, Q2_1C, Q3_1C : std_logic;

begin
    
    --    
    -- Decodage adresses:
    --
    -- 0x0000 - 0x3FFF => ROM (U5A, U5B, U5C, U5E)
    -- 0x7000 - 0x7FFF => Buffer enable U6A, (pas utilise dans la cas du FPGA car DIN et DOUT sont separes
    -- 0x7800 - 0x783F => Acces DMA
    -- 0x7000 - 0x73FF => OBJRQn
    -- 0x7000 - 0x73FF => OBJWRn (avec WRn = 0)  - RAM sprites, valide l'accès (A11 = 0) via le tranceiver U6A
    -- 0x7000 - 0x73FF => OBJRDn (avec RDn = 0)  - RAM sprites, valide l'accès (A11 = 0) via le tranceiver U6A
    -- 0x7400 - 0x77FF => VRAMWRn (avec WRn = 0) - RAM tiles, valide l'accès (A11 = 0) via le tranceiver U6A
    -- 0x7400 - 0x77FF => VRAMRDn (avec RDn = 0) - RAM tiles, valide l'accès (A11 = 0) via le tranceiver U6A
    -- 
    -- 0x6000 - 0x63FF => RAM1 (U3C, U4C)
    -- 0x6400 - 0x67FF => RAM2 (U3B, U4B)
    -- 0x6800 - 0x6BFF => RAM3 (U3A, U4A)
    --
    -- 0x7C00 - 0x7C7F => IN1 (read)
    -- 0x7C80 - 0x7CFF => IN2 (read)
    -- 0x7D00 - 0x7D7F => IN3 (read)
    -- 0x7D80 - 0x7DFF => DIP switch (read)
    --
    -- U5H
    -- 0x7D80 => digital sound trigger - dead (write)
    -- 0x7D82 => flip screen (write)
    -- 0x7D83 => Son jump ? (PB5 CPU Audio) (write)
    -- 0x7D84 => interrupt enable (write)
    -- 0x7D85 => DMA request (write)
    -- 0x7D86-7D87 => palette bank selector (only bit 0 is significant: 7d86 = bit 0 7d87 = bit 1) (write)
    --
    -- U6H
    -- 0x7D00 => Sound effects
    -- Index 0 Walk
    -- Index 1 Boom
    -- Index 2 Barrel hits Mario
    -- Index 3 Spring (writes to i8035's P1)
    -- Index 4 Fall (writes to i8035's P2)
    -- Index 5 Points (Got points, grabbed the hammer, etc.)
    --
    -- U3D
    -- Background sound/music select (U3D, ecriture vers le CPU audio)
    -- 0x7c00 - nothing
    -- 0x7c01 - Intro tune
    -- 0x7c02 - How high can you get ?
    -- 0x7c03 - Out of time
    -- 0x7c04 - Hammer
    -- 0x7c05 - Rivet level 2 completed (end tune)
    -- 0x7c06 - Hammer hit
    -- 0x7c07 - Standard level end
    -- 0x7c08 - Background 1 (barrels)
    -- 0x7c09 - Background 4 (pie factory)
    -- 0x7c0A - Background 3 (springs)
    -- 0x7c0B - Background 2 (rivets)
    -- 0x7c0C - Rivet level 1 completed (end tune)
    -- 0x7c0D - Rivet removed
    -- 0x7c0E - Rivet level completed
    -- 0x7c0F - Gorilla roar
    --
    
    -- U4D
    Q0_4D <= '0' when (i_addr(15 downto 12) = "0000" and i_rfrsh_l = '1') else '1';
    Q1_4D <= '0' when (i_addr(15 downto 12) = "0001" and i_rfrsh_l = '1') else '1';
    Q2_4D <= '0' when (i_addr(15 downto 12) = "0010" and i_rfrsh_l = '1') else '1';
    Q3_4D <= '0' when (i_addr(15 downto 12) = "0011" and i_rfrsh_l = '1') else '1';
    Q6_4D <= '0' when (i_addr(15 downto 12) = "0110" and i_rfrsh_l = '1') else '1';
    Q7_4D <= '0' when (i_addr(15 downto 12) = "0111" and i_rfrsh_l = '1') else '1';
    
    -- U2A_1
    Q1_2A_1 <= '0' when i_addr(11) = '1' and Q7_4D = '0' else '1';

    -- U2A_2
    Q0_2A_2 <= '0' when i_addr(11 downto 10) = "00" and (Q7_4D = '0' and i_mreq_comb_l = '0') else '1';
    Q1_2A_2 <= '0' when i_addr(11 downto 10) = "01" and (Q7_4D = '0' and i_mreq_comb_l = '0') else '1';
    Q3_2A_2 <= '0' when i_addr(11 downto 10) = "11" and (Q7_4D = '0' and i_mreq_comb_l = '0') else '1';
        
    -- U2B
    Q0_2B <= '0' when (i_addr(11 downto 10) = "00" and Q7_4D = '0' and i_mreq_comb_l = '0' and i_rd_l = '0') else '1';
    Q1_2B <= '0' when (i_addr(11 downto 10) = "01" and Q7_4D = '0' and i_mreq_comb_l = '0' and i_rd_l = '0') else '1';
    
    -- U2C
    Q0_2C <= '0' when (i_addr(11 downto 10) = "00" and Q7_4D = '0' and i_mreq_comb_l = '0' and i_wr_l = '0' and i_rams_wr_enable = '1') else '1';
    Q1_2C <= '0' when (i_addr(11 downto 10) = "01" and Q7_4D = '0' and i_mreq_comb_l = '0' and i_wr_l = '0' and i_rams_wr_enable = '1') else '1';
    
    -- U2D
    Q0_2D <= '0' when (i_addr(11 downto 10) = "00" and Q6_4D = '0' and i_mreq_comb_l = '0' and (i_rd_l = '0' or i_wr_l = '0') and i_rams_wr_enable = '1') else '1';
    Q1_2D <= '0' when (i_addr(11 downto 10) = "01" and Q6_4D = '0' and i_mreq_comb_l = '0' and (i_rd_l = '0' or i_wr_l = '0') and i_rams_wr_enable = '1') else '1';
    Q2_2D <= '0' when (i_addr(11 downto 10) = "10" and Q6_4D = '0' and i_mreq_comb_l = '0' and (i_rd_l = '0' or i_wr_l = '0') and i_rams_wr_enable = '1') else '1';

    -- U1B
    Q0_1B <= '0' when (i_addr(9 downto 7) = "000" and Q3_2A_2 = '0' and i_rd_l = '0') else '1';
    Q1_1B <= '0' when (i_addr(9 downto 7) = "001" and Q3_2A_2 = '0' and i_rd_l = '0') else '1';
    Q2_1B <= '0' when (i_addr(9 downto 7) = "010" and Q3_2A_2 = '0' and i_rd_l = '0') else '1';
    Q3_1B <= '0' when (i_addr(9 downto 7) = "011" and Q3_2A_2 = '0' and i_rd_l = '0') else '1';

    -- U1C
    Q0_1C <= '0' when (i_addr(9 downto 7) = "000" and Q3_2A_2 = '0' and i_wr_l = '0') else '1';
    Q2_1C <= '0' when (i_addr(9 downto 7) = "010" and Q3_2A_2 = '0' and i_wr_l = '0') else '1';
    Q3_1C <= '0' when (i_addr(9 downto 7) = "011" and Q3_2A_2 = '0' and i_wr_l = '0') else '1';

    o_objwr_l <= Q0_2C;
    o_vram_wr_l <= Q1_2C;
    o_vram_req_l <= Q1_2A_2;
    o_objrd_l <= Q0_2B;
    o_vram_rd_l <= Q1_2B;
    o_objrq_l <= Q0_2A_2;
    o_dma_cs_l <= '0' when (Q1_2A_1 = '0' and i_addr(10) = '0') else '1';
    o_rom_cs_l <= '0' when (Q0_4D = '0' or Q1_4D = '0' or Q2_4D = '0' or Q3_4D = '0') else '1';
    o_uart_cs_l <= '0' when (i_addr(15 downto 14) = "10" and i_rfrsh_l = '1') else '1';    
    o_ram_34A_cs_l <= Q2_2D;
    o_ram_34B_cs_l <= Q1_2D;
    o_ram_34C_cs_l <= Q0_2D;
    o_in1_cs_l <= Q0_1B;
    o_in2_cs_l <= Q1_1B;
    o_in3_cs_l <= Q2_1B;
    o_dipsw_cs_l <= Q3_1B;
    o_5H_cs_l <= Q3_1C;
    o_6H_cs_l <= Q2_1C;
    o_3D_cs_l <= Q0_1C;

end Behavioral;
