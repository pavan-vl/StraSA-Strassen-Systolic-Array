`timescale 1ns/1ps

module tb_strasa_4x4_top;

    reg            clk;
    reg            rst_n;
    reg            start;
    reg  [ 127 : 0 ] InVal_1_flat;
    reg  [ 127 : 0 ] InVal_2_flat;
    wire [ 287 : 0 ] R_flat;
    wire           busy;
    wire           done;

    strasa_4x4_top strasa_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .InVal_1_flat (InVal_1_flat),
        .InVal_2_flat (InVal_2_flat),
        .R_flat       (R_flat),
        .busy         (busy),
        .done         (done)
    );

    // 10 ns clock

    always #5 clk = ~clk;

    // Matrices in row order so mat_a[ r * 4 + c ] is row r column c

    reg signed [ 7 : 0 ] mat_a [ 0 : 15 ];
    reg signed [ 7 : 0 ] mat_b [ 0 : 15 ];

    integer r, c, k, exp_v, got_v, errors;

    // Flatten both matrices into the Z order buses the design expects

    task flatten;
        begin
            for (r = 0; r < 4; r = r + 1)
                for (c = 0; c < 4; c = c + 1)
                begin
                    InVal_1_flat[ { r[1], c[1], r[0], c[0] } * 8 +: 8 ] = mat_a[ r * 4 + c ];
                    InVal_2_flat[ { r[1], c[1], r[0], c[0] } * 8 +: 8 ] = mat_b[ r * 4 + c ];
                end
        end
    endtask

    // Pulse start then wait for done

    task run;
        begin
            flatten;
            @(negedge clk) start = 1'b1;
            @(negedge clk) start = 1'b0;
            wait (done);
            @(negedge clk);
        end
    endtask

    // Print C and compare it with plain A times B

    task check;
        begin
            errors = 0;
            for (r = 0; r < 4; r = r + 1)
            begin
                for (c = 0; c < 4; c = c + 1)
                begin
                    exp_v = 0;
                    for (k = 0; k < 4; k = k + 1)
                        exp_v = exp_v + mat_a[ r * 4 + k ] * mat_b[ k * 4 + c ];
                    got_v = $signed(R_flat[ { r[1], c[1], r[0], c[0] } * 18 +: 18 ]);
                    $write("%8d", got_v);
                    if (got_v != exp_v) errors = errors + 1;
                end
                $write("\n");
            end
            if (errors == 0) $display("PASS\n");
            else             $display("FAIL with %0d wrong values\n", errors);
        end
    endtask

    initial
    begin
        clk          = 1'b0;
        rst_n        = 1'b0;
        start        = 1'b0;
        InVal_1_flat = 128'd0;
        InVal_2_flat = 128'd0;
        #20 rst_n    = 1'b1;

        // Test 1 small mixed values

        mat_a[0]  =  1; mat_a[1]  =  2; mat_a[2]  =  3; mat_a[3]  =  4;
        mat_a[4]  = -1; mat_a[5]  =  0; mat_a[6]  =  2; mat_a[7]  = -3;
        mat_a[8]  =  5; mat_a[9]  = -2; mat_a[10] =  1; mat_a[11] =  0;
        mat_a[12] =  0; mat_a[13] =  3; mat_a[14] = -4; mat_a[15] =  2;

        mat_b[0]  =  2; mat_b[1]  = -1; mat_b[2]  =  0; mat_b[3]  =  3;
        mat_b[4]  =  1; mat_b[5]  =  4; mat_b[6]  = -2; mat_b[7]  =  0;
        mat_b[8]  = -3; mat_b[9]  =  2; mat_b[10] =  1; mat_b[11] =  5;
        mat_b[12] =  0; mat_b[13] = -1; mat_b[14] =  3; mat_b[15] =  2;

        $display("Test 1");
        run;
        check;

        // Test 2 larger values with both signs

        mat_a[0]  =  100; mat_a[1]  =  -50; mat_a[2]  =   25; mat_a[3]  =  -12;
        mat_a[4]  =   -7; mat_a[5]  =   90; mat_a[6]  =  -33; mat_a[7]  =   61;
        mat_a[8]  =   44; mat_a[9]  =  -88; mat_a[10] =   17; mat_a[11] =  -99;
        mat_a[12] =  -64; mat_a[13] =   32; mat_a[14] =  -16; mat_a[15] =    8;

        mat_b[0]  =   -3; mat_b[1]  =   70; mat_b[2]  =  -45; mat_b[3]  =   11;
        mat_b[4]  =   56; mat_b[5]  =  -20; mat_b[6]  =   81; mat_b[7]  =  -72;
        mat_b[8]  =  -95; mat_b[9]  =   13; mat_b[10] =   -8; mat_b[11] =   40;
        mat_b[12] =   27; mat_b[13] =  -60; mat_b[14] =  110; mat_b[15] = -127;

        $display("Test 2");
        run;
        check;

        // Test 3 extreme values where every C is 4 times -128 times -128 = 65536

        for (k = 0; k < 16; k = k + 1)
        begin
            mat_a[k] = -128;
            mat_b[k] = -128;
        end

        $display("Test 3");
        run;
        check;

        $finish;
    end

endmodule
