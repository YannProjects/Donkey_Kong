----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.05.2023 10:41:36
-- Design Name: 
-- Module Name: dkong_logic - Behavioral
-- Project Name: Donkey Kong Nintendo 1981
-- Target Devices: Artyx 7
-- Tool Versions: 
-- Description: Composants logiques de base
-- (vient de https://github.com/MiSTer-devel/Arcade-DonkeyKong_MiSTer mais en VHDL).
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

------------------------------------------------------
------------------   74XX109   -----------------------
------------------------------------------------------

entity logic_74xx109 is
port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_j : in std_logic;
    i_k : in std_logic;
    o_q : out std_logic
);
end logic_74xx109;

architecture Behavioral of logic_74xx109 is

signal q : std_logic;
signal jk : std_logic_vector(1 downto 0);

begin
p_74xx109: process(i_clk, i_rst)
begin
    if i_rst = '1' then
        q <= '0';
    elsif rising_edge(i_clk) then
        case jk is
            when "00" =>
                q <= '1';
            when "01" =>
                q <= q;
            when "10" =>
                q <= not q;
            when "11" =>
                q <= '1';
        end case;
    end if;
end process;

jk <= i_j & i_k;
o_q <= q;
    
end Behavioral;

------------------------------------------------------
------------------   74XX138   -----------------------
------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity logic_74xx138 is
port (
    i_clk : in std_logic;
    i_g1 : in std_logic;
    i_g2a : in std_logic;
    i_g2b : in std_logic;
    i_sel : in std_logic_vector(2 downto 0);
    o_q : out std_logic_vector(7 downto 0)
);
end logic_74xx138;

architecture Behavioral of logic_74xx138 is

signal g : std_logic_vector(2 downto 0);

begin
p_74xx139 : process(i_g1, i_g2a, i_g2b, i_sel)
begin
    if g = "100" then
       case i_sel is
            when "000" =>
                o_q <= "11111110";
            when "001" =>
                o_q <= "11111101";
            when "010" =>
                o_q <= "11111011";
            when "011" =>
                o_q <= "11110111";
            when "100" =>
                o_q <= "11101111";
            when "101" =>
                o_q <= "11011111";
            when "110" =>
                o_q <= "10111111";
            when "111" =>
                o_q <= "01111111";
       end case;
    else
        o_q <= "11111111";
    end if;
end process;

g <= i_g1 & i_g2a & i_g2b;
    
end Behavioral;

------------------------------------------------------
------------------   74XX139   -----------------------
------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity logic_74xx139 is
port (
    i_g : in std_logic;
    i_sel : in std_logic_vector(1 downto 0);
    o_q : out std_logic_vector(3 downto 0)
);
end logic_74xx139;

architecture Behavioral of logic_74xx139 is

signal g : std_logic_vector(2 downto 0);

begin
p_74xx139 : process(i_g, i_sel)
begin
    if i_g = '0' then
       case i_sel is
            when "00" =>
                o_q <= "1110";
            when "01" =>
                o_q <= "1101";
            when "10" =>
                o_q <= "1011";
            when "11" =>
                o_q <= "0111";
       end case;
    else
        o_q <= "1111";
    end if;
end process;

end Behavioral;

------------------------------------------------------
------------------   74XX259   -----------------------
------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity logic_74xx259 is
port (
    i_gn : in std_logic;
    i_clear : in std_logic;
    i_sel : in std_logic_vector(2 downto 0);
    i_d : in std_logic;
    o_q : out std_logic_vector(7 downto 0)
);
end logic_74xx259;

architecture Behavioral of logic_74xx259 is

signal g : std_logic_vector(2 downto 0);

begin
p_74xx259 : process(i_gn, i_sel)
begin
    if i_clear = '0' and i_gn = '0' then
        case i_sel is
            when "000" => o_q <= (0 => i_d, others => '0');
            when "001" => o_q <= (1 => i_d, others => '0');
            when "010" => o_q <= (2 => i_d, others => '0');
            when "011" => o_q <= (3 => i_d, others => '0');
            when "100" => o_q <= (4 => i_d, others => '0');
            when "101" => o_q <= (5 => i_d, others => '0');
            when "110" => o_q <= (6 => i_d, others => '0');
            when "111" => o_q <= (7 => i_d, others => '0');
        end case;
    elsif i_clear = '0' and i_gn = '1' then
        o_q <= (others => '0');
    elsif i_clear = '1' and i_gn = '0' then
       case i_sel is
            when "000" => o_q(0) <= i_d;
            when "001" => o_q(1) <= i_d;
            when "010" => o_q(2) <= i_d;
            when "011" => o_q(3) <= i_d;
            when "100" => o_q(4) <= i_d;
            when "101" => o_q(5) <= i_d;
            when "110" => o_q(6) <= i_d;
            when "111" => o_q(7) <= i_d;
       end case;
    end if;
    
end process;

end Behavioral;

------------------------------------------------------
------------------   74XX175   -----------------------
------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity logic_74xx175 is
port (
    i_clk : in std_logic;
    i_clrn : in std_logic;
    i_d : in std_logic_vector(3 downto 0);
    o_q, o_qn : out std_logic_vector(3 downto 0)
);
end logic_74xx175;

architecture Behavioral of logic_74xx175 is

begin
p_74xx175 : process(i_clk, i_clrn, i_d)
begin
    if i_clrn = '0' then
        o_q <= (others => '0');
    elsif rising_edge(i_clk) then
        o_q <= i_d;
        o_qn <= not i_d;
    end if;
end process;

end Behavioral;

------------------------------------------------------
------------------   74XX299   -----------------------
------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity logic_74xx299 is
port (
    i_clk : in std_logic;
    i_s0 : in std_logic;
    i_s1 : in std_logic;
    i_sr : in std_logic;
    i_sl : in std_logic;        
    i_d : in std_logic_vector(7 downto 0);
    o_qaprim, o_qhprim : out std_logic
);
end logic_74xx299;

architecture Behavioral of logic_74xx299 is

signal reg : std_logic_vector(7 downto 0);
signal s0s1 : std_logic_vector(1 downto 0);

begin
p_74xx299 : process(i_clk, i_s0, i_s1, i_sr, i_sl, i_d)
begin
    if rising_edge(i_clk) then
       case s0s1 is
            when "00" => reg <= reg;
            when "01" => reg <= i_sr & reg(6 downto 0);
            when "10" => reg <= reg(7 downto 1) & i_sl;
            when "11" => reg <= i_d;
       end case;
    end if;
    
    s0s1 <= i_s1 & i_s0;
    o_qaprim <= reg(0);
    o_qhprim <= reg(7);
    
end process;

end Behavioral;

------------------------------------------------------
------------------   74XX163   -----------------------
------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;

entity logic_74XX163 is
port (
    i_clk : in std_logic;
    i_clrn : in std_logic;
    i_d : in std_logic_vector(3 downto 0);
    i_enp : in std_logic;
    i_ent : in std_logic;
    i_loadn : in std_logic;
    o_rco : out std_logic;
    o_q : out std_logic_vector(3 downto 0)
);
end logic_74XX163;

architecture Behavioral of logic_74XX163 is

signal cnt : unsigned(3 downto 0);

begin
p_74XX163 : process(i_clk, i_clrn, i_d, i_enp, i_ent, i_loadn)

begin
    if i_clrn = '0' then
        o_q <= (others => '0');
    elsif rising_edge(i_clk) then
        if i_loadn = '0' then
            cnt <= unsigned(i_d);
        elsif i_enp = '1' and i_ent = '1' then
            cnt <= cnt + '1';
        end if;
    end if;
    
end process;

o_q <= std_logic_vector(cnt);

end Behavioral;

