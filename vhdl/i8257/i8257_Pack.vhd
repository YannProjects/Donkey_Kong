
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

package i8257_Pack is


    constant AUTOLOAD : unsigned(7 downto 0) := X"80";
    constant TC_STOP : unsigned(7 downto 0) := X"40";
    constant EXTENDED_WRITE : unsigned(7 downto 0) := X"20";
    constant RP : unsigned(7 downto 0) := X"10";
    constant CH3_EN : unsigned(7 downto 0) := X"08";
    constant CH2_EN : unsigned(7 downto 0) := X"04";
    constant CH1_EN : unsigned(7 downto 0) := X"02";
    constant CH0_EN : unsigned(7 downto 0) := X"01";
    
    constant DMA_READ : unsigned(7 downto 0) := X"80";
    constant DMA_WRITE : unsigned(7 downto 0) := X"40";

    component i8257 is
    port (
        i_clk       : in std_logic;
        i_reset     : in std_logic;
        i_ready     : in std_logic;
        o_aen       : out std_logic;
        i_hdla      : in std_logic;
        o_hrq       : out std_logic;
        i_drq       : in std_logic_vector(3 downto 0); -- Just one channel here
        o_dackn     : out std_logic_vector(3 downto 0); -- Just one channel here
        o_adstb     : out std_logic;
        i_As        : in std_logic_vector(3 downto 0); -- Low addresses bus is input in slave mode
        o_Am        : out std_logic_vector(7 downto 0); -- Address bus is output in master mode
        i_iorsn     : in std_logic; -- IORn is input in slave mode
        i_iowsn     : in std_logic; -- IOWn is input in slave mode
        o_iormn     : out std_logic; -- IORn is output in master mode
        o_iowmn     : out std_logic; -- IOWn is output in master mode
        i_Din       : in std_logic_vector(7 downto 0);
        o_Dout      : out std_logic_vector(7 downto 0);
        i_csn       : in std_logic;
        o_memrn     : out std_logic;
        o_memwn     : out std_logic;
        o_mark      : out std_logic;
        o_tc        : out std_logic
    );
    end component;

end;