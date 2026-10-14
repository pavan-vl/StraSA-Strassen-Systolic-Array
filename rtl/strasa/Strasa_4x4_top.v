`timescale 1ns/1ps
module strasa_4x4_top (
    input          			clk,
    input          			rst_n,
    input          			start,
    input  [127:0] 			InVal_1_flat,
    input  [127:0] 			InVal_2_flat,
    output [287:0] 			R_flat,
    output         			busy,
    output         			done
);

    localparam InWidth    				= 8;
    localparam Width     				= 9;
    localparam AccWidth    				= 18;
    localparam PidWidth    				= 3;
    localparam NumberOfPasses   		= 7;
    localparam STEPS 					= 14;

    // Coefficient of pass pid inside output block blk given as use then first then neg

    function [2:0] coef;
        input [1:0] blk;
        input [2:0] pid;
        begin
            case ({blk, pid})

                // C11 is P5 plus P4 minus P2 plus P6

                5'b00_001: coef = 3'b111;
                5'b00_011: coef = 3'b100;
                5'b00_100: coef = 3'b100;
                5'b00_101: coef = 3'b100;

                // C12 is P1 plus P2

                5'b01_000: coef = 3'b110;
                5'b01_001: coef = 3'b100;

                // C21 is P3 plus P4

                5'b10_010: coef = 3'b110;
                5'b10_011: coef = 3'b100;

                // C22 is P5 plus P1 minus P3 minus P7

                5'b11_000: coef = 3'b110;
                5'b11_010: coef = 3'b101;
                5'b11_100: coef = 3'b100;
                5'b11_110: coef = 3'b101;
                default:   coef = 3'b000;
            endcase
        end
    endfunction

    // Control and input registers

    reg [127:0] a_in_reg;
    reg [127:0] b_in_reg;
    reg         busy_reg;
    reg         run_reg;
    reg [3:0]   step_reg;
    reg         done_reg;

    // Blocks of A and B

    wire [ 4 * InWidth - 1 : 0 ] a11_w = a_in_reg[ 0	* 4	* InWidth +: 4 * InWidth ];
    wire [ 4 * InWidth - 1 : 0 ] a12_w = a_in_reg[ 1	* 4	* InWidth +: 4 * InWidth ];
    wire [ 4 * InWidth - 1 : 0 ] a21_w = a_in_reg[ 2	* 4	* InWidth +: 4 * InWidth ];
    wire [ 4 * InWidth - 1 : 0 ] a22_w = a_in_reg[ 3	* 4	* InWidth +: 4 * InWidth ];
    wire [ 4 * InWidth - 1 : 0 ] b11_w = b_in_reg[ 0	* 4	* InWidth +: 4 * InWidth ];
    wire [ 4 * InWidth - 1 : 0 ] b12_w = b_in_reg[ 1	* 4	* InWidth +: 4 * InWidth ];
    wire [ 4 * InWidth - 1 : 0 ] b21_w = b_in_reg[ 2	* 4	* InWidth +: 4 * InWidth ];
    wire [ 4 * InWidth - 1 : 0 ] b22_w = b_in_reg[ 3	* 4	* InWidth +: 4 * InWidth ];

    // Pre add results with 9 bit elements

    wire [4*Width-1:0] a11p12_w, a21p22_w, a11p22_w, a12m22_w, a11m21_w;
    wire [4*Width-1:0] b12m22_w, b21m11_w, b11p22_w, b21p22_w, b11p12_w;

    mat_add2x2 #(.InWidth(InWidth)) pa0_for_p2_inst (.InVal_1_flat(a11_w), .InVal_2_flat(a12_w), .op(1'b0), .R_flat(a11p12_w));
    mat_add2x2 #(.InWidth(InWidth)) pa1_for_p3_inst (.InVal_1_flat(a21_w), .InVal_2_flat(a22_w), .op(1'b0), .R_flat(a21p22_w));
    mat_add2x2 #(.InWidth(InWidth)) pa2_for_p5_inst (.InVal_1_flat(a11_w), .InVal_2_flat(a22_w), .op(1'b0), .R_flat(a11p22_w));
    mat_add2x2 #(.InWidth(InWidth)) pa3_for_p6_inst (.InVal_1_flat(a12_w), .InVal_2_flat(a22_w), .op(1'b1), .R_flat(a12m22_w));
    mat_add2x2 #(.InWidth(InWidth)) pa4_for_p7_inst (.InVal_1_flat(a11_w), .InVal_2_flat(a21_w), .op(1'b1), .R_flat(a11m21_w));
    mat_add2x2 #(.InWidth(InWidth)) pb0_for_p1_inst (.InVal_1_flat(b12_w), .InVal_2_flat(b22_w), .op(1'b1), .R_flat(b12m22_w));
    mat_add2x2 #(.InWidth(InWidth)) pb1_for_p4_inst (.InVal_1_flat(b21_w), .InVal_2_flat(b11_w), .op(1'b1), .R_flat(b21m11_w));
    mat_add2x2 #(.InWidth(InWidth)) pb2_for_p5_inst (.InVal_1_flat(b11_w), .InVal_2_flat(b22_w), .op(1'b0), .R_flat(b11p22_w));
    mat_add2x2 #(.InWidth(InWidth)) pb3_for_p6_inst (.InVal_1_flat(b21_w), .InVal_2_flat(b22_w), .op(1'b0), .R_flat(b21p22_w));
    mat_add2x2 #(.InWidth(InWidth)) pb4_for_p7_inst (.InVal_1_flat(b11_w), .InVal_2_flat(b12_w), .op(1'b0), .R_flat(b11p12_w));

    // Sign extend the blocks that are used without a pre add

    wire [ 4 * Width - 1 : 0 ] a11x_w, a22x_w, b11x_w, b22x_w;

    genvar loop_g;
    generate
        for (loop_g = 0; loop_g < 4; loop_g = loop_g + 1) 
		begin 
            assign a11x_w[loop_g * Width +: Width] = {a11_w[loop_g * InWidth+InWidth-1], a11_w[loop_g * InWidth +: InWidth]};
            assign a22x_w[loop_g * Width +: Width] = {a22_w[loop_g * InWidth+InWidth-1], a22_w[loop_g * InWidth +: InWidth]};
            assign b11x_w[loop_g * Width +: Width] = {b11_w[loop_g * InWidth+InWidth-1], b11_w[loop_g * InWidth +: InWidth]};
            assign b22x_w[loop_g * Width +: Width] = {b22_w[loop_g * InWidth+InWidth-1], b22_w[loop_g * InWidth +: InWidth]};
        end
    endgenerate

    // Left and right operand of every pass packed with pass 0 in the low bits

    wire [ NumberOfPasses * 4 * Width - 1 : 0 ] left_all_w  		= {a11m21_w, a12m22_w, a11p22_w, a22x_w, a21p22_w, a11p12_w, a11x_w};
    wire [ NumberOfPasses * 4 * Width - 1 : 0 ] right_all_w 		= {b11p12_w, b21p22_w, b11p22_w, b21m11_w, b11x_w, b22x_w, b12m22_w};

    // Pass number and step inside the pass

    wire [2:0] p_w 													= step_reg[3:1];
    wire       k_w 													= step_reg[0];

    // Pick the operand blocks of the current pass

    wire [4 * Width - 1 : 0] left_sel_w  							= left_all_w[p_w*4*Width +: 4*Width];
    wire [4 * Width - 1 : 0] right_sel_w 							= right_all_w[p_w*4*Width +: 4*Width];

    // Row i gets left element i*2+k and column j gets right element k*2+j

    wire [Width - 1 : 0] a0_feed_w 									= k_w ? left_sel_w[1 * Width +: Width]  : left_sel_w[0 * Width +: Width];
    wire [Width - 1 : 0] a1_feed_w 									= k_w ? left_sel_w[3 * Width +: Width]  : left_sel_w[2 * Width +: Width];
    wire [Width - 1 : 0] b0_feed_w 									= k_w ? right_sel_w[2 * Width +: Width] : right_sel_w[0 * Width +: Width];
    wire [Width - 1 : 0] b1_feed_w 									= k_w ? right_sel_w[3 * Width +: Width] : right_sel_w[1 * Width +: Width];

    // Edge register stage between the pre add mux and the array

    reg [2 * Width - 1 : 0] 			a_edge_reg;
    reg [2 * Width - 1 : 0] 			b_edge_reg;
    reg           						first_edge_reg;
    reg           						last_edge_reg;
    reg [PidWidth - 1 : 0]  			pid_edge_reg;

    // Array outputs

    wire [4 * AccWidth - 1 : 0] 		acc_flat_w;
    wire [3:0]      					valid_w;
    wire [4 * PidWidth - 1 : 0] 		pid_flat_w;

    // Control and input capture

    always @(posedge clk or negedge rst_n) 
	begin
        if (!rst_n) 
		begin
            a_in_reg <= 128'd0;
            b_in_reg <= 128'd0;
            busy_reg <= 1'b0;
            run_reg  <= 1'b0;
            step_reg <= 4'd0;
            done_reg <= 1'b0;
        end 
		else 
		begin
            done_reg <= 1'b0;
            if (start && !busy_reg) 
			begin
                a_in_reg <= InVal_1_flat;
                b_in_reg <= InVal_2_flat;
                busy_reg <= 1'b1;
                run_reg  <= 1'b1;
                step_reg <= 4'd0;
            end 
			else 
			begin
                if (run_reg) 
				begin
                    step_reg <= step_reg + 4'd1;
                    if (step_reg == STEPS - 1) 
					begin
                        run_reg <= 1'b0;
                    end
                end

                // Finish when the bottom right PE hands out the last pass

                if (busy_reg && valid_w[3] && (pid_flat_w[3 * PidWidth +: PidWidth] == NumberOfPasses - 1 )) 
				begin
                    busy_reg <= 1'b0;
                    done_reg <= 1'b1;
                end
            end
        end
    end

    // Load the edge registers while running and send zeros otherwise

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
		begin
            a_edge_reg     <= {2 * Width{1'b0} };
            b_edge_reg     <= {2 * Width{1'b0} };
            first_edge_reg <= 1'b0;
            last_edge_reg  <= 1'b0;
            pid_edge_reg   <= { PidWidth{1'b0} };
        end 
		else if (run_reg) 
		begin
            a_edge_reg     <= {a1_feed_w, a0_feed_w};
            b_edge_reg     <= {b1_feed_w, b0_feed_w};
            first_edge_reg <= ~k_w;
            last_edge_reg  <= k_w;
            pid_edge_reg   <= p_w;
        end 
		else 
		begin
            a_edge_reg     <= {2 * Width {1'b0} };
            b_edge_reg     <= {2 * Width {1'b0} };
            first_edge_reg <= 1'b0;
            last_edge_reg  <= 1'b0;
            pid_edge_reg   <= {PidWidth {1'b0} };
        end
    end

    // Shared systolic array

    systolic_2x2 #(.Width(Width), .AccWidth(AccWidth), .PidWidth(PidWidth)) systolic2x2_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .a_row     (a_edge_reg),
        .b_col     (b_edge_reg),
        .first_row (first_edge_reg),
        .last_row  (last_edge_reg),
        .pid_row   (pid_edge_reg),
        .acc_flat  (acc_flat_w),
        .valid     (valid_w),
        .pid_flat  (pid_flat_w)
    );

    // Output accumulators that add or subtract each PE result as it comes out

    genvar blk, loop_i;
    generate
        for (blk = 0; blk < 4; blk = blk + 1) 
		
		begin : outer_loop
		
            for (loop_i = 0; loop_i < 4; loop_i = loop_i + 1) 
			
			begin : inner_loop
			
                reg  [AccWidth-1:0] 		c_acc_reg;
				
                wire [2 : 0]    cf_w 				= coef( blk, pid_flat_w[loop_i * PidWidth +: PidWidth] );
				
                wire            cap_w 				= valid_w[loop_i] & cf_w[2];

                // The first product of a block loads directly so no clear is needed

                wire [AccWidth - 1 : 0] c_base_w 	= cf_w[1] ? { AccWidth{1'b0} } : c_acc_reg;
				
                wire [AccWidth - 1 : 0] c_next_w;

                addsub #(.InWidth(AccWidth), .OutWidth(AccWidth) ) addsub_top_inst (
                    .InVal_1 (c_base_w),
                    .InVal_2 (acc_flat_w[loop_i * AccWidth +: AccWidth]),
                    .op      (cf_w[0]),
                    .R       (c_next_w)
                );

                always @(posedge clk or negedge rst_n) 
				begin
                    if (!rst_n) 
					begin
                        c_acc_reg <= { AccWidth{1'b0} };
                    end 
					else if (cap_w) 
					begin
                        c_acc_reg <= c_next_w;
                    end
                end

                assign R_flat[( blk * 4 + loop_i ) * AccWidth +: AccWidth] = c_acc_reg;
            end
        end
    endgenerate

    assign busy 			= busy_reg;
    assign done 			= done_reg;

endmodule
