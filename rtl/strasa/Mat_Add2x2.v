`timescale 1ns/1ps

// Adds or subtracts two 2x2 blocks with four two's complement adders in parallel

// Each output element is one bit wider than the inputs so no carry is lost

module mat_add2x2 #(
    parameter InWidth = 8
) (
    input   [4 * InWidth - 1 : 0]     	InVal_1_flat,
    input   [4 * InWidth - 1 : 0]     	InVal_2_flat,
    input                  		op,
    output  [4 * (InWidth+1) - 1 : 0] 	R_flat
);

    genvar Itr;
    generate
        for (Itr = 0; Itr < 4; Itr = Itr + 1) begin : adder_itr

            // One adder per block element

            addsub #(.InWidth(InWidth), .OutWidth(InWidth+1)) addsub_inst (
                .InVal_1 (InVal_1_flat[Itr * InWidth +: InWidth]),
                .InVal_2 (InVal_2_flat[Itr * InWidth +: InWidth]),
                .op      (op),
                .R       (R_flat[Itr * (InWidth+1) +: InWidth+1])
            );
        end
    endgenerate

endmodule
