----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.06.2023 23:17:43
-- Design Name: 
-- Module Name: Simulation Donkey Kong - Behavioral
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
use work.DKong_Pack.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DKong_Sim is
--  Port ( );
end DKong_Sim;

architecture Behavioral of DKong_Sim is

constant clk_period : time := 10 ns;

signal main_clk, rst_sys, flash_csn : std_logic;
signal z80_rst_l, z80_clk : std_logic;
signal z80_mreq_l, z80_iorq_l, z80_rd_l : std_logic;
signal z80_wr_l, z80_rfrsh_l, z80_waitn, z80_m1_l : std_logic;
signal z80_nmin, z80_busak_l, z80_busrq_l : std_logic;
signal z80_a : std_logic_vector(15 downto 0);
signal buffer_enable, buffer_dir : std_logic;
signal D_bidir, core_data_bidir : std_logic_vector(7 downto 0);
signal cfg_dip_sw, in0_reg, in1_reg, config_reg, core_data_output : std_logic_vector(7 downto 0);
signal in1_cs_l, in2_cs_l, in3_cs_l, dip_sw_cs_l : std_logic;

signal dipsw : std_logic_vector(7 downto 0);

begin    
    -- DSW1:
    --  bit 7 : COCKTAIL or UPRIGHT cabinet (1 = UPRIGHT)
    --  bit 6 : \ 000 = 1 coin 1 play   001 = 2 coins 1 play  010 = 1 coin 2 plays
    --  bit 5 : | 011 = 3 coins 1 play  100 = 1 coin 3 plays  101 = 4 coins 1 play
    --  bit 4 : / 110 = 1 coin 4 plays  111 = 5 coins 1 play
    --  bit 3 : \bonus at
    --  bit 2 : / 00 = 7000  01 = 10000  10 = 15000  11 = 20000
    --  bit 1 : \ 00 = 3 lives  01 = 4 lives
    --  bit 0 : / 10 = 5 lives  11 = 6 lives    
    dipsw <= X"84"; -- UPRIGHT + 1 coin 1 play + bonus a 10000

    clk_process :process
    begin
         main_clk <= '0';
         wait for clk_period / 2;
         main_clk <= '1';
         wait for clk_period / 2;
    end process;
       
    u_z80 : entity work.T80a
    port map (
		RESET_n	=> z80_rst_l,
		R800_mode => '0',
		CLK_n => z80_clk,
		WAIT_n => z80_waitn,
		INT_n => '1',
		NMI_n => z80_nmin,
		BUSRQ_n => z80_busrq_l,
		BUSAK_n => z80_busak_l,
		MREQ_n => z80_mreq_l,
		M1_n => z80_m1_l,
		RD_n => z80_rd_l,
		WR_n => z80_wr_l,
		IORQ_n => open,
		HALT_n => open,
		RFSH_n => z80_rfrsh_l,
		A => z80_a,
		D => D_bidir
	);
        
    -- Simulation 74HC245 (Octal Bus Transceiver With 3-State Outputs)
    u1 : entity work.SN74LS245N
    port map (
        -- A(0..7)
        X_2 => D_bidir(0),
        X_3 => D_bidir(1),
        X_4 => D_bidir(2),
        X_5 => D_bidir(3),
        X_6 => D_bidir(4),
        X_7 => D_bidir(5),
        X_8 => D_bidir(6),
        X_9 => D_bidir(7),
        
        -- B(0..7)
        X_18 => core_data_bidir(0),
        X_17 => core_data_bidir(1),
        X_16 => core_data_bidir(2),
        X_15 => core_data_bidir(3),
        X_14 => core_data_bidir(4),
        X_13 => core_data_bidir(5),
        X_12 => core_data_bidir(6),
        X_11 => core_data_bidir(7),
        
        X_19 => buffer_enable,
        X_1 => buffer_dir
    );

   ---------------------
   -- Donkey Kong core top --
   ---------------------
   core_top_0 : entity work.DKong_Main
   port map (
        -- System clock
        i_clk_sys => main_clk,
        -- Core reset
        i_rst_sysn => rst_sys,
    
        i_cpu_a_core => z80_a,
    
        -- CPU data
        -- Port bidirectionnel sur DI_Core et DO_Core
        io_cpu_data_bidir => core_data_bidir,
        -- Data dir
        o_buffer_dir => buffer_dir,
        -- Tri-state buffer enable
        o_buffer_enable_n => buffer_enable,
    
        o_cpu_rst_core => z80_rst_l,
        o_cpu_clk_core => z80_clk,
        i_cpu_m1_l_core => z80_m1_l,
        i_cpu_mreq_l_core => z80_mreq_l,
        i_cpu_rd_l_core => z80_rd_l,
        i_cpu_wr_l_core => z80_wr_l,
        i_cpu_busack_l => z80_busak_l,
        o_cpu_busrq_l => z80_busrq_l,
        i_cpu_rfrsh_l_core => z80_rfrsh_l,
        o_cpu_waitn => z80_waitn,
        o_cpu_nmi_l => z80_nmin,
            
        -- Z80 pacman code en memoire flash
        o_rom_cs_l => flash_csn, -- Flash CS
    
        -- Entrees
        -- i_config_reg => config_reg,
        -- o_in1_l => in1_cs_l,
        -- o_in2_l => in2_cs_l,
        -- o_in3_l => in3_cs_l,
        -- o_dipsw_l => dip_sw_cs_l,
        
        -- UART
        i_uart_rx => '1'
    );  

    -- flash_memory : entity work.s29al008j
    -- generic map (
    --     TimingModel => "UNIT",
    --     UserPreload => TRUE,
    --     mem_file_name => "s29al008j_dkong.mem"
    -- )
    -- port map(
    --     A18 => '0',
    --     A17 => '0',
    --     A16 => '0',
    --     A15 => '0',
    --     A14 => '0',
    --     A13 => z80_a(14),
    --     A12 => z80_a(13),
    --     A11 => z80_a(12),
    --     A10 => z80_a(11),
    --     A9 => z80_a(10),
    --     A8 => z80_a(9),
    --     A7 => z80_a(8),
    --     A6 => z80_a(7),
    --     A5 => z80_a(6),
    --     A4 => z80_a(5),
    --     A3 => z80_a(4),
    --     A2 => z80_a(3),
    --     A1 => z80_a(2),
    --     DQ15 => z80_a(0),
    --     A0 => z80_a(1),
        
    --     DQ7 => D_bidir(7),
    --     DQ6 => D_bidir(6),
    --     DQ5 => D_bidir(5),
    --     DQ4 => D_bidir(4),
    --     DQ3 => D_bidir(3),
    --     DQ2 => D_bidir(2),
    --     DQ1 => D_bidir(1),
    --     DQ0 => D_bidir(0),
        
    --     CENeg => flash_csn,
    --     OENeg => z80_rd_l,
    --     WENeg => z80_wr_l,
    --     RESETNeg => rst_sys,
    --     BYTENeg => '0',
    --     WPNeg => '1'
   -- );

  config_reg <= (others => '1') when in1_cs_l = '0' else (others => 'Z');
  config_reg <= (others => '1') when in2_cs_l = '0' else (others => 'Z');
  config_reg <= (others => '1') when in3_cs_l = '0' else (others => 'Z');
  config_reg <= X"AB" when dip_sw_cs_l = '0' else (others => 'Z');
        
  rst_sys <= '0', '1' after 100 us;

end Behavioral;
