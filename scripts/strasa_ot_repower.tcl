read_celllib -min sky130_ot_min.lib
read_celllib -max sky130_ot_max.lib
read_verilog strasa_4x4_top_netlist.v
read_sdc strasa_ot_cons.sdc
report_wns -max
report_wns -min
report_area
repower_gate _10890_ sky130_fd_sc_hd__dfrtp_4
repower_gate _10891_ sky130_fd_sc_hd__dfrtp_2
repower_gate _10530_ sky130_fd_sc_hd__lpflow_isobufsrc_2
repower_gate _10473_ sky130_fd_sc_hd__lpflow_isobufsrc_2
report_tns -max
report_wns -max
report_tns -min
report_wns -min
report_timing -max
report_timing -min
report_area
report_leakage_power
dump_power -o strasa_resized_power_pins.rpt
dump_verilog -o strasa_4x4_top_resized.v
