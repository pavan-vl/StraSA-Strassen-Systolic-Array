`timescale 1ns/1ps

// Two's complement add or subtract

// Both inputs are sign extended from InWidth bits to OutWidth bits before the add
// op = 0 for add, op = 1 for subtract

// Set OutWidth to InWidth plus 1 to keep every carry or set OutWidth to InWidth for wrap around math

module addsub #(
    parameter InWidth = 8,
    parameter OutWidth = 9
) (
    input   [InWidth - 1 : 0] 	InVal_1,
    input   [InWidth - 1 : 0] 	InVal_2,
    input            	        op,
    output  [OutWidth - 1 : 0] 	R
);

    // Sign extend both inputs

    wire signed [OutWidth - 1 : 0] a_w = $signed(InVal_1);
    wire signed [OutWidth - 1 : 0] b_w = $signed(InVal_2);

    // Flip B and add one when op is set so one adder does both jobs

    wire [OutWidth - 1 : 0] b_x_w = b_w ^ {OutWidth {op} };

    assign R = a_w + b_x_w + {{(OutWidth - 1 ) {1'b0}}, op};

endmodule
