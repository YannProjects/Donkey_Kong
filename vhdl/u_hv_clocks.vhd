----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.04.2025 18:06:07
-- Design Name: 
-- Module Name: u_hv_clocks - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- Contient la generation des signaux lignaux horizontales et verticales et synchronisation video
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

entity hv_clocks_wait_nmi is
    Port (  i_rst : in std_logic; -- Signal de reset (actif niveau haut)
            i_Phi34n : in std_logic; -- 6 MHz Phi34n clock
            i_vram_busy_l : in std_logic;
            i_vram_req_l : in std_logic;
            i_clear_nmi_l : in std_logic;
            -- h_128n = h(9)
            -- h_256n = h(8)
            o_h : out unsigned(9 downto 0);
            o_v : out unsigned(7 downto 0);
            o_hsyncn : out std_logic;
            o_vblkn : out std_logic;
            o_vsyncn : out std_logic;
            o_cpu_wait_l : out std_logic;
            o_rams_wr_enable : out std_logic;
            o_cpu_nmi_l : out std_logic
         );
end hv_clocks_wait_nmi;

architecture Behavioral of hv_clocks_wait_nmi is

    signal h_cnt : unsigned(11 downto 0);
    signal cnt_hsync, cnt_vsync : unsigned(7 downto 0);
    signal h_256, vblk : std_logic;
    signal v : unsigned(8 downto 0);
    signal v_clk : std_logic;
    signal Q1n_7F, Q2_7F : std_logic;
        
    -- VSYNC_P = Nombre de pulse Phi34 entre le début de VBLK et le début du pulse signal VSYNCn
    -- VSYNC_W = Nombre de pulse Phi34 pour la durée de VSYNCn
    constant VSYNC_P : unsigned(7 downto 0) := X"F2";
    constant VSYNC_W : unsigned(7 downto 0) := X"08";
    
    -- HSYNC_P = Nombre de pulse Phi34 entre le début de h_256 et le début du pulse signal HSYNCn
    -- HSYNC_W = Nombre de pulse Phi34 pour la durée de VSYNCn
    constant HSYNC_P : unsigned(7 downto 0) := X"E7";
    constant HSYNC_W : unsigned(7 downto 0) := X"10";    

begin
    -------------------------------
    -- Generation HSYNC / VSYNC
    -------------------------------
    -- U1L, U1M, U1N                       
    p_u1lmn : process(i_Phi34n, i_rst)
    begin
        if i_rst = '1' then
            h_cnt <= X"D00";
        elsif rising_edge(i_Phi34n) then
            if (h_cnt = X"FFF") then
                h_cnt <= X"D00";
            else
                h_cnt <= h_cnt + 1;
            end if;
        end if;
    end process;
    o_h <= h_cnt(9 downto 0);

    -- U1L, U1M, U1N 
    h_256 <= not h_cnt(8);
    
    -- U3A
    -- Equivalent U3A synthetisable
    p_u3a : process(i_Phi34n, h_256, i_rst)
    begin
        if (h_256 = '0') or (i_rst = '1') then
            cnt_hsync <= HSYNC_P;
        elsif rising_edge(i_Phi34n) then
            -- Front montant h(1)
            if (h_cnt(1 downto 0) = "01") then
                cnt_hsync <= cnt_hsync + 1;
            end if;
        end if;
    end process;
    
    o_hsyncn <= '0' when (cnt_hsync < HSYNC_W) else '1';    
    
    -- U3B
    -- Equivalent U3B synthetisable
    p_u3b : process(i_Phi34n, vblk, i_rst)
    begin
        if (vblk = '0') or (i_rst = '1') then
            cnt_vsync <= VSYNC_P;
        elsif rising_edge(i_Phi34n) then
            -- Detection front montant h_256
            if (h_cnt(9 downto 0) = "01" & X"FF") then
                cnt_vsync <= cnt_vsync + 1;
            end if;
        end if;
    end process;
    
    o_vsyncn <= '0' when (cnt_vsync < VSYNC_W) else '1';
        
    -- U4A, U4B, U5D, U6D
    -- Ne sert plus à rien a priori. Etait utilise dans U56D mais remplacé avec un if sur h_cnt
    -- pour éviter d'ajouter une horloge.   
    -- U4A : process(i_Phi34n, h_256)
    -- begin
    --     if (h_256 = '0') then
    --         v_clk <= '0';
    --     elsif rising_edge(i_Phi34n) then
            -- Front montant h(5)
    --         if (h_cnt(5 downto 0) = "011111") then
    --           if (not((not(h_cnt(7))) and h_cnt(6))) = '1' then
    --               v_clk <= '0';
    --           else
    --               v_clk <= '1';
    --           end if;
    --        end if;
    --    end if;
    -- end process;
   
    U56D : process(i_rst, i_Phi34n)
    begin
        if (i_rst = '1') then
           v <= (others => '0');
        elsif rising_edge(i_Phi34n) then
           -- Front montant v_clk si h_cnt = 0xe5f
           if h_cnt = X"E5F" then
               if (v = "1" & X"FF") then
                   v <= "011111000";
               else 
                   v <= v + 1;
               end if;
           end if;
        end if;
    end process;

    o_v <= v(7 downto 0);

    -- U4B et U8F
    U4B : process(i_Phi34n, i_clear_nmi_l)
    begin
        -- Gestion de la NMI ici pour éviter d'avoir à redéfinir une horloge sur le signal VBLKn
        if (i_clear_nmi_l = '0') then
            o_cpu_nmi_l <= '1';
        elsif rising_edge(i_Phi34n) then
            -- Front montant v(4). v change sur v_clk qui change lui-même quand h_cnt = X"E5F"...
            if (h_cnt = X"E5F") and v(3 downto 0) = "1111" then
                if (v(7 downto 5) = "111") then
                    if  (vblk = '0') then
                        vblk <='1';
                        o_cpu_nmi_l <= '0';
                    end if;
                else
                    vblk <='0';
                end if;
            end if;
        end if;
    end process;
    
    o_vblkn <= not vblk; 
    
    -- Signaux CPUs
    -- U7F
    --   
    U7F_1 : process(i_Phi34n, vblk)
    begin
        if (vblk = '1') then
            Q1n_7F <= '1';
        elsif rising_edge(i_Phi34n) then
            -- Detection front montant h(1)
            if (h_cnt(1 downto 0) = "01") then
                if ((not i_vram_busy_l) and (not i_vram_req_l)) = '1' then
                    Q1n_7F <= '0';
                else
                    Q1n_7F <= '1';
                end if;
            end if;
        end if;
    end process;
    
    U7F_2 : process(i_Phi34n, i_rst)
    begin
        if (i_rst = '1') then
            Q2_7F <= '0';
        elsif rising_edge(i_Phi34n) then
            -- Detection front descendant h(1)
            if (h_cnt(1 downto 0) = "11") then
                if Q1n_7F = '1' then
                    Q2_7F <= '1';
                else
                    Q2_7F <= '0';
                end if;
            end if;
        end if;
    end process;  
    
    o_rams_wr_enable <= Q2_7F;
    o_cpu_wait_l <= Q1n_7F;

end Behavioral;