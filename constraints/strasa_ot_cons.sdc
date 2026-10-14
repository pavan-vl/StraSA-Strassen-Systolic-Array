create_clock -period 20 -name clk [get_ports clk]
set_input_delay 1 -min -rise [all_inputs] -clock clk
set_input_delay 1 -min -fall [all_inputs] -clock clk
set_input_delay 2 -max -rise [all_inputs] -clock clk
set_input_delay 2 -max -fall [all_inputs] -clock clk
set_input_delay 0 -min -rise [get_ports clk] -clock clk
set_input_delay 0 -min -fall [get_ports clk] -clock clk
set_input_delay 0 -max -rise [get_ports clk] -clock clk
set_input_delay 0 -max -fall [get_ports clk] -clock clk
set_input_delay 0 -max -rise [get_ports rst_n] -clock clk
set_input_delay 0 -max -fall [get_ports rst_n] -clock clk
set_input_transition 0.05 -min -rise [all_inputs] -clock clk
set_input_transition 0.05 -min -fall [all_inputs] -clock clk
set_input_transition 0.05 -max -rise [all_inputs] -clock clk
set_input_transition 0.05 -max -fall [all_inputs] -clock clk
set_output_delay 0 -min -rise [all_outputs] -clock clk
set_output_delay 0 -min -fall [all_outputs] -clock clk
set_output_delay 2 -max -rise [all_outputs] -clock clk
set_output_delay 2 -max -fall [all_outputs] -clock clk
set_load -pin_load 0.005 [all_outputs]
