`timescale 1ns/1ps

module systolic_2x2 #(
    parameter Width  = 9,
    parameter AccWidth = 18,
    parameter PidWidth = 3
) (
    input             					    clk,
    input             					    rst_n,
    input  [2 * Width-1:0]  				a_row,
    input  [2 * Width-1:0]  				b_col,
    input             					    first_row,
    input             					    last_row,
    input  [PidWidth-1:0]   				pid_row,
    output [4 * AccWidth-1:0] 			acc_flat,
    output [3:0]      					    valid,
    output [4 * PidWidth-1:0] 			pid_flat
);

    // Skew registers for row 1 and column 1

    reg [Width - 1 : 0]  					a1_skew_reg;
    reg [Width - 1 : 0]  					b1_skew_reg;
    reg          						      first1_skew_reg;
    reg          						      last1_skew_reg;
    reg [PidWidth - 1 : 0] 				pid1_skew_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
		begin
            a1_skew_reg     <= {Width {1'b0} };
            b1_skew_reg     <= {Width {1'b0} };
            first1_skew_reg <= 1'b0;
            last1_skew_reg  <= 1'b0;
            pid1_skew_reg   <= {PidWidth {1'b0} };
        end 
		else 
		begin
            a1_skew_reg     <= a_row[2 * Width - 1 : Width];
            b1_skew_reg     <= b_col[2 * Width - 1 : Width];
            first1_skew_reg <= first_row;
            last1_skew_reg  <= last_row;
            pid1_skew_reg   <= pid_row;
        end
    end

    // Links between the PEs

    wire [Width - 1 : 0]  			  a00_w, a10_w;
    wire [Width - 1 : 0]  			  b00_w, b01_w;
    wire          				        f00_w, f10_w;
    wire          				        l00_w, l01_w, l10_w, l11_w;
    wire [PidWidth - 1 : 0] 			p00_w, p01_w, p10_w, p11_w;

    // Unused outputs from the right column and bottom row

    wire [Width - 1 : 0] 			a01_nc_w, a11_nc_w, b10_nc_w, b11_nc_w;
    wire         				      f01_nc_w, f11_nc_w;

    // Top left PE

    pe #(.Width(Width), .AccWidth(AccWidth), .PidWidth(PidWidth)) pe_00_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .a_in      (a_row[Width - 1 : 0]),
        .b_in      (b_col[Width - 1 : 0]),
        .first_in  (first_row),
        .last_in   (last_row),
        .pid_in    (pid_row),
        .a_out     (a00_w),
        .b_out     (b00_w),
        .first_out (f00_w),
        .last_out  (l00_w),
        .pid_out   (p00_w),
        .acc       (acc_flat[0 * AccWidth +: AccWidth])
    );

    // Top right PE

    pe #(.Width(Width), .AccWidth(AccWidth), .PidWidth(PidWidth)) pe_01_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .a_in      (a00_w),
        .b_in      (b1_skew_reg),
        .first_in  (f00_w),
        .last_in   (l00_w),
        .pid_in    (p00_w),
        .a_out     (a01_nc_w),
        .b_out     (b01_w),
        .first_out (f01_nc_w),
        .last_out  (l01_w),
        .pid_out   (p01_w),
        .acc       (acc_flat[1 * AccWidth +: AccWidth])
    );

    // Bottom left PE

    pe #(.Width(Width), .AccWidth(AccWidth), .PidWidth(PidWidth)) pe_10_insst (
        .clk       (clk),
        .rst_n     (rst_n),
        .a_in      (a1_skew_reg),
        .b_in      (b00_w),
        .first_in  (first1_skew_reg),
        .last_in   (last1_skew_reg),
        .pid_in    (pid1_skew_reg),
        .a_out     (a10_w),
        .b_out     (b10_nc_w),
        .first_out (f10_w),
        .last_out  (l10_w),
        .pid_out   (p10_w),
        .acc       (acc_flat[2 * AccWidth +: AccWidth])
    );

    // Bottom right PE

    pe #(.Width(Width), .AccWidth(AccWidth), .PidWidth(PidWidth)) pe_11_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .a_in      (a10_w),
        .b_in      (b01_w),
        .first_in  (f10_w),
        .last_in   (l10_w),
        .pid_in    (p10_w),
        .a_out     (a11_nc_w),
        .b_out     (b11_nc_w),
        .first_out (f11_nc_w),
        .last_out  (l11_w),
        .pid_out   (p11_w),
        .acc       (acc_flat[3 * AccWidth +: AccWidth])
    );

    assign valid    		= {l11_w, l10_w, l01_w, l00_w};
    assign pid_flat 		= {p11_w, p10_w, p01_w, p00_w};

endmodule
