yosys read_verilog Mult_mod.v
yosys read_verilog Add_Sub.v
yosys read_verilog Mat_Add2x2.v
yosys read_verilog PE.v
yosys read_verilog Systolic2x2.v
yosys read_verilog strasa_4x4_top.v
yosys hierarchy -check -top strasa_4x4_top
yosys proc
yosys opt
yosys fsm
yosys memory
yosys techmap
yosys opt
yosys dfflibmap -liberty /home/paaji/open_pdks/sources/sky130_fd_sc_hd/timing/sky130_fd_sc_hd__tt_025C_1v80.lib
yosys abc -D 8000 -liberty /home/paaji/open_pdks/sources/sky130_fd_sc_hd/timing/sky130_fd_sc_hd__tt_025C_1v80.lib -script {+strash;&get,-n;&fraig,-x;&put;scorr;dc2;dretime;strash;&get,-n;&dch,-f;&nf,{D};&put;buffer,-p;upsize,{D};dnsize,{D}}
yosys clean -purge
yosys stat -top strasa_4x4_top -liberty /home/paaji/open_pdks/sources/sky130_fd_sc_hd/timing/sky130_fd_sc_hd__tt_025C_1v80.lib
yosys flatten
yosys opt_clean -purge
yosys hilomap -hicell sky130_fd_sc_hd__conb_1 HI -locell sky130_fd_sc_hd__conb_1 LO
yosys insbuf -buf sky130_fd_sc_hd__buf_1 A X
yosys opt_clean -purge
yosys stat -top strasa_4x4_top -liberty /home/paaji/open_pdks/sources/sky130_fd_sc_hd/timing/sky130_fd_sc_hd__tt_025C_1v80.lib
yosys rename -hide w:* i:* %d o:* %d
yosys rename -hide c:*
yosys rename -enumerate
yosys splitnets -ports -format _
yosys write_verilog -attr2comment -noexpr strasa_4x4_top_netlist.v
