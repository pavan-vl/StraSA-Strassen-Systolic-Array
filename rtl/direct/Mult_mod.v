`timescale 1ns/1ps

// Signed two's complement multiplier using the built in signed multiply

module mult_mod_9 #(
    parameter Width = 9
) (
    input   [Width - 1 : 0]   		InVal_1,
    input   [Width - 1 : 0]   		InVal_2,
    output  [2 * Width - 1 : 0] 	R
);

    // Signed product of the two inputs

    wire signed [2 * Width - 1 : 0] prod_w 	= $signed(InVal_1) * $signed(InVal_2);

    assign R 					= prod_w;

endmodule
