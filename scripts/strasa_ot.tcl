read_celllib -min sky130_ot_min.lib
read_celllib -max sky130_ot_max.lib
read_verilog strasa_4x4_top_netlist.v
read_sdc strasa_ot_cons.sdc
report_tns -max
report_wns -max
report_tns -min
report_wns -min
report_timing -max
report_timing -min
report_area
report_leakage_power
dump_power -o strasa_power_pins.rpt
