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
        i_clk_audio_12M : in std_logic;
        i_addr : in std_logic_vector(15 downto 0);
        i_data : in std_logic_vector(3 downto 0);
        i_vblk_l : in std_logic;
        i_vram_busy : in std_logic;
        i_rfrsh_l : in std_logic;
        i_mreq_comb_l : in std_logic;
        i_rd_l : in std_logic; -- Z80 read
        i_wr_l : in std_logic; -- Z80 write
        i_h_1 : in std_logic;
        
        o_objrd_l : out std_logic;
        o_objwr_l : out std_logic;
        o_objrq_l : out std_logic;
        o_vram_wr_l : out std_logic;
        o_vram_rd_l : out std_logic;
        o_cpu_wait_l : out std_logic;
        o_nmi_l : out std_logic;
        o_ram_34A_cs_l : out std_logic;
        o_ram_34B_cs_l : out std_logic;
        o_ram_34C_cs_l : out std_logic;
        
        o_rom_cs_l : out std_logic;
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

signal Q2_7F, Q1n_7F, Q7_4D, Q6_4D, Q0_2A_1, Q1_2A_1 : std_logic;
signal Q0_2A_2, Q1_2A_2, Q3_2A_2, Q0_2B, Q1_2B, Q0_2C, Q1_2C : std_logic;
signal Q0_2D, Q1_2D, Q2_2D, Q0_1B, Q1_1B, Q2_1B, Q3_1B : std_logic;
signal Q0_1C, Q2_1C, Q3_1C : std_logic;
signal QA_2A, QB_2A, Q_3D : std_logic_vector(3 downto 0);
signal Q_5H, Q_6H : std_logic_vector(7 downto 0);

begin

    -- Signaux CPUs
    -- U7F
    --
    U7F_1 : process(i_h_1, i_vblk_l, i_rst)
    begin
        if (i_vblk_l = '0') then
            Q1n_7F <= '1';
        elsif (i_rst = '1') then
            Q1n_7F <= '0';
        elsif rising_edge(i_h_1) then
            if ((not i_vram_busy) and (not Q1_2A_2)) = '1' then
                Q1n_7F <= '0';
            else
                Q1n_7F <= '1';
            end if;
        end if;
    end process;
    
    U7F_2 : process(i_h_1, i_rst)
    begin
        if (i_rst = '1') then
            Q2_7F <= '0';
        elsif falling_edge(i_h_1) then
            if Q1n_7F = '1' then
                Q2_7F <= '1';
            else
                Q2_7F <= '0';
            end if;
        end if;
    end process;                                
                           
    -- U8F 
    --
    U8F : process(i_h_1, i_vblk_l, i_rst)
    begin
        if (Q_5H(4) = '0') then
            o_nmi_l <= '1';
        elsif (i_rst = '1') then
            o_nmi_l <= '0';
        elsif falling_edge(i_vblk_l) then
            o_nmi_l <= '0';
        end if;
    end process;
    
    --    
    -- Decodage adresses:
    --
    -- 0x0000 - 0x3FFF => ROM (U5A, U5B, U5C, U5E)
    -- 0x7000 - 0x7FFF => Buffer enable U6A, 
    -- 0x7800 - 0x783F => Acces DMA
    -- 0x7000 - 0x73FF => OBJRQn
    -- 0x7000 - 0x73FF => OBJWRn (avec WRn = 0)
    -- 0x7000 - 0x73FF => OBJRDn (avec RDn = 0)
    -- 0x7400 - 0x77FF => VRAMWRn (avec WRn = 0)
    -- 0x7400 - 0x77FF => VRAMRDn (avec RDn = 0)
    -- 
    -- 0x6000 - 0x63FF => RAM1 (U3C, U4C)
    -- 0x6400 - 0x67FF => RAM2 (U3B, U4B)
    -- 0x6800 - 0x6BFF => RAM3 (U3A, U4A)
    --
    -- 0x7C00 - 0x7C7F => IN1
    -- 0x7C80 - 0x7CFF => IN2
    -- 0x7D00 - 0x7D7F => IN3
    -- 0x7D80 - 0x7DFF => DIP switch
    --
    -- U4D
    o_rom_cs_l <= '0' when (i_addr(15 downto 14) = "00" and i_rfrsh_l = '1') else '1';
    Q7_4D <= '0' when (i_addr(15 downto 12) = "0111" and i_rfrsh_l = '1') else '1';
    Q6_4D <= '0' when (i_addr(15 downto 12) = "0110" and i_rfrsh_l = '1') else '1';
    
    -- U2A_1
    Q0_2A_1 <= '0' when i_addr(11) = '0' and Q7_4D = '0' else '1';
    Q1_2A_1 <= '0' when i_addr(11) = '1' and Q7_4D = '0' else '1';

    -- U2A_2
    Q0_2A_2 <= '0' when i_addr(11 downto 10) = "00" and (Q7_4D = '0' and i_mreq_comb_l = '0') else '1';
    Q1_2A_2 <= '0' when i_addr(11 downto 10) = "01" and (Q7_4D = '0' and i_mreq_comb_l = '0') else '1';
    Q3_2A_2 <= '0' when i_addr(11 downto 10) = "11" and (Q7_4D = '0' and i_mreq_comb_l = '0') else '1';
        
    -- U2B
    Q0_2B <= '0' when (i_addr(11 downto 10) = "00" and Q7_4D = '0' and i_mreq_comb_l = '0' and i_rd_l = '0') else '1';
    Q1_2B <= '0' when (i_addr(11 downto 10) = "01" and Q7_4D = '0' and i_mreq_comb_l = '0' and i_rd_l = '0') else '1';
    
    -- U2C
    Q0_2C <= '0' when (i_addr(11 downto 10) = "00" and Q7_4D = '0' and i_mreq_comb_l = '0' and i_wr_l = '0' and Q2_7F = '1') else '1';
    Q1_2C <= '0' when (i_addr(11 downto 10) = "01" and Q7_4D = '0' and i_mreq_comb_l = '0' and i_wr_l = '0' and Q2_7F = '1') else '1';
    
    -- U2D
    Q0_2D <= '0' when (i_addr(11 downto 10) = "00" and Q6_4D = '0' and i_mreq_comb_l = '0' and (i_rd_l = '0' or i_wr_l = '0') and Q2_7F = '1') else '1';
    Q1_2D <= '0' when (i_addr(11 downto 10) = "01" and Q6_4D = '0' and i_mreq_comb_l = '0' and (i_rd_l = '0' or i_wr_l = '0') and Q2_7F = '1') else '1';
    Q2_2D <= '0' when (i_addr(11 downto 10) = "10" and Q6_4D = '0' and i_mreq_comb_l = '0' and (i_rd_l = '0' or i_wr_l = '0') and Q2_7F = '1') else '1';

    -- U1B
    Q0_1B <= '0' when (i_addr(9 downto 7) = "00" and Q3_2A_2 = '0' and i_rd_l = '0') else '1';
    Q1_1B <= '0' when (i_addr(9 downto 7) = "01" and Q3_2A_2 = '0' and i_rd_l = '0') else '1';
    Q2_1B <= '0' when (i_addr(9 downto 7) = "10" and Q3_2A_2 = '0' and i_rd_l = '0') else '1';
    Q3_1B <= '0' when (i_addr(9 downto 7) = "11" and Q3_2A_2 = '0' and i_rd_l = '0') else '1';

    -- U1C
    Q0_1C <= '0' when (i_addr(9 downto 7) = "00" and Q3_2A_2 = '0' and i_wr_l = '0') else '1';
    Q2_1C <= '0' when (i_addr(9 downto 7) = "10" and Q3_2A_2 = '0' and i_wr_l = '0') else '1';
    Q3_1C <= '0' when (i_addr(9 downto 7) = "11" and Q3_2A_2 = '0' and i_wr_l = '0') else '1';

    -- U5H
    U5H : process(i_clk_audio_12M, i_rst)
	begin
		if i_rst = '1' then
			Q_5H <= (others => '0');
		elsif rising_edge(i_clk_audio_12M) then
			if Q3_1C = '0' then
				case i_addr(2 downto 0) is
					when "000" => Q_5H(0) <= i_data(0);
					when "001" => Q_5H(1) <= i_data(0);
					when "010" => Q_5H(2) <= i_data(0);
					when "011" => Q_5H(3) <= i_data(0);
					when "100" => Q_5H(4) <= i_data(0);
					when "101" => Q_5H(5) <= i_data(0);
					when "110" => Q_5H(6) <= i_data(0);
					when "111" => Q_5H(7) <= i_data(0);
					when others => null;
				end case;
			end if;
		end if;
	end process;

    -- U6H
    U6H : process(i_clk_audio_12M, i_rst)
	begin
		if i_rst = '1' then
			Q_6H <= (others => '0');
		elsif rising_edge(i_clk_audio_12M) then
			if Q2_1C = '0' then
				case i_addr(2 downto 0) is
					when "000" => Q_6H(0) <= i_data(0);
					when "001" => Q_6H(1) <= i_data(0);
					when "010" => Q_6H(2) <= i_data(0);
					when "011" => Q_6H(3) <= i_data(0);
					when "100" => Q_6H(4) <= i_data(0);
					when "101" => Q_6H(5) <= i_data(0);
					when "110" => Q_6H(6) <= i_data(0);
					when "111" => Q_6H(7) <= i_data(0);
					when others => null;
				end case;
			end if;
		end if;
	end process;    
  
    -- U3D
    U3D : process(Q0_1C, i_rst)
	begin
		if i_rst = '0' then
			Q_3D <= (others => '0');
		elsif rising_edge(Q0_1C) then
			Q_3D <= i_data;
		end if;
	end process;
    
    o_cpu_wait_l <= Q1n_7F;
    o_objwr_l <= Q0_2C;
    o_vram_wr_l <= Q1_2C;
    o_objrd_l <= Q0_2B;
    o_vram_rd_l <= Q1_2B;
    o_objrq_l <= Q0_2A_2;
    o_dma_cs_l <= '0' when (Q1_2A_1 = '0' and i_addr(10) = '0') else '1';
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
