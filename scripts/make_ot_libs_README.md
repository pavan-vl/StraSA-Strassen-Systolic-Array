### Run in terminal before running ot-shell:

python3 make_ot_libs.py /path/to/sky130_fd_sc_hd__tt_025C_1v80.lib

OpenTimer keeps only one timing check per pin, so sky130's setup and hold checks clash and give `nan`.
This makes `sky130_ot_max.lib` (setup only) and `sky130_ot_min.lib` (hold only), with min-pulse-width removed.

