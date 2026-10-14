`timescale 1ns/1ps


module direct_sa_4x4_top (
    input          		clk,
    input          		rst_n,
    input          		start,
    input  [ 127 : 0 ] 		InVal_1_flat,
    input  [ 127 : 0 ] 		InVal_2_flat,
    output [ 287 : 0 ] 		R_flat,
    output         		busy,
    output         		done
);

    localparam Width          = 8;
    localparam AccWidth       = 18;
    localparam PidWidth       = 2;
    localparam NumberOfPasses = 4;
    localparam STEPS          = 16;

    // Control and input registers

    reg [ 127 : 0 ] a_in_reg;
    reg [ 127 : 0 ] b_in_reg;
    reg             busy_reg;
    reg             run_reg;
    reg [ 3 : 0 ]   step_reg;
    reg             done_reg;

    // Pass number gives the output block and k is the step inside the pass

    wire [ 1 : 0 ] p_w  = step_reg[ 3 : 2 ];
    wire [ 1 : 0 ] k_w  = step_reg[ 1 : 0 ];
    wire           bi_w = p_w[1];
    wire           bj_w = p_w[0];

    // Z order index of A row i at step k and B column j at step k

    wire [ 3 : 0 ] idx_a0_w 		= { bi_w, k_w[1], 1'b0, k_w[0] };
    wire [ 3 : 0 ] idx_a1_w 		= { bi_w, k_w[1], 1'b1, k_w[0] };
    wire [ 3 : 0 ] idx_b0_w 		= { k_w[1], bj_w, k_w[0], 1'b0 };
    wire [ 3 : 0 ] idx_b1_w 		= { k_w[1], bj_w, k_w[0], 1'b1 };

    wire [ Width - 1 : 0 ] a0_feed_w 		= a_in_reg[ idx_a0_w * Width +: Width ];
    wire [ Width - 1 : 0 ] a1_feed_w 		= a_in_reg[ idx_a1_w * Width +: Width ];
    wire [ Width - 1 : 0 ] b0_feed_w 		= b_in_reg[ idx_b0_w * Width +: Width ];
    wire [ Width - 1 : 0 ] b1_feed_w 		= b_in_reg[ idx_b1_w * Width +: Width ];

    // Edge register stage in front of the array

    reg [ 2 * Width - 1 : 0 ]  a_edge_reg;
    reg [ 2 * Width - 1 : 0 ]  b_edge_reg;
    reg                        first_edge_reg;
    reg                        last_edge_reg;
    reg [ PidWidth - 1 : 0 ]   pid_edge_reg;

    // Array outputs

    wire [ 4 * AccWidth - 1 : 0 ] acc_flat_w;
    wire [ 3 : 0 ]                valid_w;
    wire [ 4 * PidWidth - 1 : 0 ] pid_flat_w;

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

                if (busy_reg && valid_w[3] && (pid_flat_w[ 3 * PidWidth +: PidWidth ] == NumberOfPasses - 1))
                begin
                    busy_reg <= 1'b0;
                    done_reg <= 1'b1;
                end
            end
        end
    end

    // Load the edge registers while running and send zeros otherwise

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            a_edge_reg     <= { 2 * Width { 1'b0 } };
            b_edge_reg     <= { 2 * Width { 1'b0 } };
            first_edge_reg <= 1'b0;
            last_edge_reg  <= 1'b0;
            pid_edge_reg   <= { PidWidth { 1'b0 } };
        end
        else if (run_reg)
        begin
            a_edge_reg     <= { a1_feed_w, a0_feed_w };
            b_edge_reg     <= { b1_feed_w, b0_feed_w };
            first_edge_reg <= (k_w == 2'd0);
            last_edge_reg  <= (k_w == 2'd3);
            pid_edge_reg   <= p_w;
        end
        else
        begin
            a_edge_reg     <= { 2 * Width { 1'b0 } };
            b_edge_reg     <= { 2 * Width { 1'b0 } };
            first_edge_reg <= 1'b0;
            last_edge_reg  <= 1'b0;
            pid_edge_reg   <= { PidWidth { 1'b0 } };
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

    // Capture each finished PE result straight into its output element

    genvar loop_i;
    generate
        for (loop_i = 0; loop_i < 4; loop_i = loop_i + 1)
        begin : elem_loop

            reg [ 4 * AccWidth - 1 : 0 ] c_elem_reg;

            // Slot b of c_elem_reg holds element loop_i of output block b

            always @(posedge clk or negedge rst_n)
            begin
                if (!rst_n)
                begin
                    c_elem_reg <= { 4 * AccWidth { 1'b0 } };
                end
                else if (valid_w[loop_i])
                begin
                    c_elem_reg[ pid_flat_w[ loop_i * PidWidth +: PidWidth ] * AccWidth +: AccWidth ] <= acc_flat_w[ loop_i * AccWidth +: AccWidth ];
                end
            end

            assign R_flat[ 0 * 4 * AccWidth + loop_i * AccWidth +: AccWidth ] = c_elem_reg[ 0 * AccWidth +: AccWidth ];
            assign R_flat[ 1 * 4 * AccWidth + loop_i * AccWidth +: AccWidth ] = c_elem_reg[ 1 * AccWidth +: AccWidth ];
            assign R_flat[ 2 * 4 * AccWidth + loop_i * AccWidth +: AccWidth ] = c_elem_reg[ 2 * AccWidth +: AccWidth ];
            assign R_flat[ 3 * 4 * AccWidth + loop_i * AccWidth +: AccWidth ] = c_elem_reg[ 3 * AccWidth +: AccWidth ];
        end
    endgenerate

    assign busy = busy_reg;
    assign done = done_reg;

endmodule
