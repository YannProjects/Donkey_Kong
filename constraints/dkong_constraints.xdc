# set_property PACKAGE_PIN D3 [get_ports i_cpu_m1_l_core]
set_property PACKAGE_PIN P17 [get_ports i_clk_sys]
set_property IOSTANDARD LVCMOS33 [get_ports i_clk_sys]
set_property PACKAGE_PIN P5 [get_ports i_rst_sysn]
set_property IOSTANDARD LVCMOS33 [get_ports i_rst_sysn]

# Bus adresses CPU
set_property PACKAGE_PIN A6 [get_ports {i_cpu_a_core[11]}]
set_property PACKAGE_PIN E5 [get_ports {i_cpu_a_core[4]}]
set_property PACKAGE_PIN D8 [get_ports {i_cpu_a_core[12]}]
set_property PACKAGE_PIN B6 [get_ports {i_cpu_a_core[2]}]
set_property PACKAGE_PIN F6 [get_ports {i_cpu_a_core[14]}]
set_property PACKAGE_PIN B7 [get_ports {i_cpu_a_core[10]}]
set_property PACKAGE_PIN C4 [get_ports {i_cpu_a_core[9]}]
set_property PACKAGE_PIN C7 [get_ports {i_cpu_a_core[7]}]
set_property PACKAGE_PIN D7 [get_ports {i_cpu_a_core[5]}]
set_property PACKAGE_PIN C5 [get_ports {i_cpu_a_core[0]}]
set_property PACKAGE_PIN A5 [get_ports {i_cpu_a_core[3]}]
set_property PACKAGE_PIN B4 [get_ports {i_cpu_a_core[1]}]
set_property PACKAGE_PIN E6 [get_ports {i_cpu_a_core[15]}]
set_property PACKAGE_PIN E7 [get_ports {i_cpu_a_core[13]}]
set_property PACKAGE_PIN C6 [get_ports {i_cpu_a_core[8]}]
set_property PACKAGE_PIN G6 [get_ports {i_cpu_a_core[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_cpu_a_core[0]}]

set_property PULLDOWN true [get_ports {i_cpu_a_core[15]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[14]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[13]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[12]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[11]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[10]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[9]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[8]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[7]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[6]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[5]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[4]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[3]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[2]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[1]}]
set_property PULLDOWN true [get_ports {i_cpu_a_core[0]}]

# Bus BiDir CPU data
set_property PACKAGE_PIN H1 [get_ports {io_cpu_data_bidir[0]}]
set_property PACKAGE_PIN F1 [get_ports {io_cpu_data_bidir[1]}]
set_property PACKAGE_PIN E2 [get_ports {io_cpu_data_bidir[2]}]
set_property PACKAGE_PIN J2 [get_ports {io_cpu_data_bidir[3]}]
set_property PACKAGE_PIN C1 [get_ports {io_cpu_data_bidir[7]}]
set_property PACKAGE_PIN F4 [get_ports {io_cpu_data_bidir[6]}]
set_property PACKAGE_PIN H2 [get_ports {io_cpu_data_bidir[5]}]
set_property PACKAGE_PIN K2 [get_ports {io_cpu_data_bidir[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_cpu_data_bidir[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_cpu_data_bidir[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_cpu_data_bidir[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_cpu_data_bidir[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_cpu_data_bidir[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_cpu_data_bidir[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_cpu_data_bidir[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_cpu_data_bidir[4]}]

# Signaux CPU
set_property PACKAGE_PIN D2 [get_ports o_buffer_dir]
set_property IOSTANDARD LVCMOS33 [get_ports o_buffer_dir]

set_property PACKAGE_PIN E1 [get_ports o_buffer_enable_n]
set_property IOSTANDARD LVCMOS33 [get_ports o_buffer_enable_n]

set_property IOSTANDARD LVCMOS33 [get_ports o_cpu_rst_core]
set_property PACKAGE_PIN A3 [get_ports o_cpu_rst_core]

set_property PACKAGE_PIN A1 [get_ports o_cpu_clk_core]
set_property IOSTANDARD LVCMOS33 [get_ports o_cpu_clk_core]


set_property PACKAGE_PIN J3 [get_ports i_cpu_mreq_l_core]
set_property IOSTANDARD LVCMOS33 [get_ports i_cpu_mreq_l_core]

set_property PACKAGE_PIN G2 [get_ports i_cpu_rd_l_core]
set_property IOSTANDARD LVCMOS33 [get_ports i_cpu_rd_l_core]

set_property PACKAGE_PIN K1 [get_ports i_cpu_wr_l_core]
set_property IOSTANDARD LVCMOS33 [get_ports i_cpu_wr_l_core]

set_property IOSTANDARD LVCMOS33 [get_ports i_cpu_rfrsh_l_core]
set_property PACKAGE_PIN G1 [get_ports i_cpu_rfrsh_l_core]

set_property IOSTANDARD LVCMOS33 [get_ports o_cpu_waitn]
set_property PACKAGE_PIN B3 [get_ports o_cpu_waitn]

set_property PACKAGE_PIN M3 [get_ports {o_vga[b_vga][2]}]
set_property PACKAGE_PIN M1 [get_ports {o_vga[b_vga][1]}]
set_property PACKAGE_PIN N1 [get_ports {o_vga[b_vga][0]}]
set_property PACKAGE_PIN R2 [get_ports {o_vga[g_vga][2]}]
set_property PACKAGE_PIN T1 [get_ports {o_vga[g_vga][0]}]
set_property PACKAGE_PIN N4 [get_ports {o_vga[r_vga][2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[b_vga][2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[b_vga][1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[b_vga][0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[g_vga][2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[g_vga][1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[g_vga][0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[r_vga][2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[r_vga][1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[r_vga][0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[hsync]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_vga[vsync]}]
set_property PACKAGE_PIN R1 [get_ports {o_vga[g_vga][1]}]
set_property PACKAGE_PIN P4 [get_ports {o_vga[r_vga][1]}]
set_property PACKAGE_PIN T3 [get_ports {o_vga[r_vga][0]}]

set_property IOSTANDARD LVCMOS33 [get_ports i_cpu_busack_l]
set_property PACKAGE_PIN E3 [get_ports i_cpu_busack_l]
set_property PACKAGE_PIN B1 [get_ports o_cpu_busrq_l]
set_property IOSTANDARD LVCMOS33 [get_ports o_cpu_busrq_l]
set_property IOSTANDARD LVCMOS33 [get_ports o_cpu_nmi_l]
set_property IOSTANDARD LVCMOS33 [get_ports o_rom_cs_l]
set_property PACKAGE_PIN D4 [get_ports o_rom_cs_l]




#set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[0]}]
set_property PACKAGE_PIN L18 [get_ports o_uart_tx]
set_property PACKAGE_PIN M18 [get_ports i_uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports i_uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports o_uart_tx]
#set_property IOSTANDARD LVCMOS33 [get_ports i_cpu_m1_l_core]















#set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks DMA_CLK]
#set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT0]]



#set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT2]]
#set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT2]] -to [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT0]]
#set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT1]]
#set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT2]]


set_property PACKAGE_PIN M2 [get_ports o_walk_driver]
set_property IOSTANDARD LVCMOS33 [get_ports o_walk_driver]






create_generated_clock -name PHI34N -source [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT0] -edges {1 7 11} -edge_shift {0.000 0.000 0.000} [get_nets Phi34n]

#create_generated_clock -name DMA_CLK -source u_Core/clk -divide_by 4 [get_pins {u_Core/u_HVClocks/h_cnt_reg[1]/Q}]
#create_generated_clock -name DMA_CLK -source [get_pins u_Core/u_Dkong_Video_i_1/O] -divide_by 4 [get_pins {u_Core/u_HVClocks/h_cnt_reg[1]/Q}]

#set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT2]] -to [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT0]]
#set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT2]]

set_clock_groups -name SYSTEM_CLOCKS -logically_exclusive -group [get_clocks [list PHI34N [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT0]]]] -group [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT2]] -group [get_clocks -of_objects [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT1]]


set_property PACKAGE_PIN C2 [get_ports o_cpu_nmi_l]
set_property PACKAGE_PIN T5 [get_ports {o_vga[hsync]}]
set_property PACKAGE_PIN N5 [get_ports {o_vga[vsync]}]

set_property PACKAGE_PIN U6 [get_ports {i_config_reg[7]}]
set_property PACKAGE_PIN N6 [get_ports {i_config_reg[6]}]
set_property PACKAGE_PIN V9 [get_ports {i_config_reg[5]}]
set_property PACKAGE_PIN T8 [get_ports {i_config_reg[4]}]
set_property PACKAGE_PIN V6 [get_ports {i_config_reg[3]}]
set_property PACKAGE_PIN T6 [get_ports {i_config_reg[2]}]
set_property PACKAGE_PIN V4 [get_ports {i_config_reg[1]}]
set_property PACKAGE_PIN R6 [get_ports {i_config_reg[0]}]
set_property PACKAGE_PIN R5 [get_ports {o_music_data[7]}]
set_property PACKAGE_PIN V5 [get_ports {o_music_data[6]}]
set_property PACKAGE_PIN R7 [get_ports {o_music_data[5]}]
set_property PACKAGE_PIN V7 [get_ports {o_music_data[4]}]
set_property PACKAGE_PIN U7 [get_ports {o_music_data[3]}]
set_property PACKAGE_PIN M6 [get_ports {o_music_data[2]}]
set_property PACKAGE_PIN U9 [get_ports {o_music_data[1]}]
set_property PACKAGE_PIN R8 [get_ports {o_music_data[0]}]
set_property PACKAGE_PIN R3 [get_ports i_coin_insert]
set_property PACKAGE_PIN V2 [get_ports i_service]
set_property PACKAGE_PIN N2 [get_ports o_boom_driver]
set_property PACKAGE_PIN P2 [get_ports o_boom_seq_driver]
set_property PACKAGE_PIN U3 [get_ports o_dipsw_l]
set_property PACKAGE_PIN L1 [get_ports o_jump_driver]
set_property PACKAGE_PIN V1 [get_ports o_vol_decay]
set_property IOSTANDARD LVCMOS33 [get_ports o_dipsw_l]
set_property IOSTANDARD LVCMOS33 [get_ports o_jump_driver]
set_property IOSTANDARD LVCMOS33 [get_ports o_vol_decay]
set_property IOSTANDARD LVCMOS33 [get_ports i_service]
set_property IOSTANDARD LVCMOS33 [get_ports o_boom_driver]
set_property IOSTANDARD LVCMOS33 [get_ports o_boom_seq_driver]
set_property IOSTANDARD LVCMOS33 [get_ports i_coin_insert]
set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_config_reg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_music_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_music_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_music_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_music_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_music_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_music_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_music_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_music_data[0]}]

set_property PACKAGE_PIN U2 [get_ports o_merged_inputs_cs_l]
set_property IOSTANDARD LVCMOS33 [get_ports o_merged_inputs_cs_l]

create_generated_clock -name CLK_61M -source [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKIN1] -master_clock [get_clocks i_clk_sys] [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name CLK_SOUND -source [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKIN1] -master_clock [get_clocks i_clk_sys] [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT1]
create_generated_clock -name CLK_VGA -source [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKIN1] -master_clock [get_clocks i_clk_sys] [get_pins clk_gen_0/inst/mmcm_adv_inst/CLKOUT2]

set_property PACKAGE_PIN U4 [get_ports o_hb]
set_property IOSTANDARD LVCMOS33 [get_ports o_hb]
