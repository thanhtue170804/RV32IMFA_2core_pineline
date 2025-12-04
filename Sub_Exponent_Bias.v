module Sub_Exponent_Bias (
    input [7:0] E_a, E_b,
    output [7:0] E_r
);
    wire [7:0] E_r1;
    M_kogge_stone sub (
        .a(E_a),
        .b(~E_b + 1), // Số bù 2 của E_b
        .s(E_r1)
    );
    M_kogge_stone add_bias (
        .a(E_r1),
        .b(8'h7F), // Bias = 127
        .s(E_r)
    );
endmodule