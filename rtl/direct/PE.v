`timescale 1ns/1ps

// A moves to the right and B moves down with one register each

module pe #(
    parameter Width  = 9,
    parameter AccWidth = 18,
    parameter PidWidth = 3
) (
    input            		clk,
    input            		rst_n,
    input   [Width - 1 : 0]  	a_in,
    input   [Width - 1 : 0]  	b_in,
    input            		first_in,
    input            		last_in,
    input   [PidWidth - 1 : 0] 	pid_in,
    output  [Width - 1 : 0]  	a_out,
    output  [Width - 1 : 0]  	b_out,
    output           		first_out,
    output           		last_out,
    output  [PidWidth - 1 : 0] 	pid_out,
    output  [AccWidth - 1 : 0] 	acc
);

    reg [Width - 1 : 0]  		a_reg;
    reg [Width - 1 : 0]  		b_reg;
    reg          			first_reg;
    reg          			last_reg;
    reg [PidWidth - 1 : 0] 		pid_reg;
    reg [AccWidth-  1 : 0] 		acc_reg;

    // Exact signed product

    wire [2 * Width - 1 : 0] 		prod_w;

    mult_mod_9 #(.Width(Width)) multiplier_inst (
        .InVal_1 (a_in),
        .InVal_2 (b_in),
        .R       (prod_w)
    );

    // Sign extend the product to the accumulator width

    wire signed [AccWidth - 1 : 0] prod_x_w 			= $signed(prod_w);

    // Start from zero on the first step of a pass

    wire [AccWidth - 1 : 0] 	acc_base_w 			= first_in ? {AccWidth{1'b0}} : acc_reg;

    // New accumulator value

    wire [AccWidth - 1 : 0] 	acc_next_w;

    addsub #(.InWidth(AccWidth), .OutWidth(AccWidth)) u_acc (
        .InVal_1 (acc_base_w),
        .InVal_2 (prod_x_w),
        .op      (1'b0),
        .R       (acc_next_w)
    );
    // The first last and pid tags move to the right together with A
    // Pipeline registers for data tags and the total

    always @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            a_reg     <= {Width {1'b0} };
            b_reg     <= {Width {1'b0} };
            first_reg <= 1'b0;
            last_reg  <= 1'b0;
            pid_reg   <= {PidWidth {1'b0} };
            acc_reg   <= {AccWidth {1'b0} };
        end 
        else 
        begin
            a_reg     <= a_in;
            b_reg     <= b_in;
            first_reg <= first_in;
            last_reg  <= last_in;
            pid_reg   <= pid_in;
            acc_reg   <= acc_next_w;
        end
    end

    assign a_out     = a_reg;
    assign b_out     = b_reg;
    assign first_out = first_reg;
    assign last_out  = last_reg;
    assign pid_out   = pid_reg;
    assign acc       = acc_reg;

endmodule
