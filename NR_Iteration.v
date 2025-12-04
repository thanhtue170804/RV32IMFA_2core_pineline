module NR_Iteration (
    input [31:0] x_n,
    input [31:0] divisor,
    output [31:0] x_n_plus_1
);
    wire [31:0] b_times_x;
    wire [31:0] two_minus_bx;
    wire [31:0] two = 32'h40000000;  // 2.0 in IEEE 754
    
    // Calculate B * x_n
    FP_Mul mult_inst (
        .A(divisor),
        .B(x_n),
        .Mul_Out(b_times_x)
    );
    
    // Calculate 2 - B*x_n
    FP_Sub sub_inst (
        .in_numA(two),
        .in_numB(b_times_x),
        .out_data(two_minus_bx)
    );
    
    // Calculate x_n * (2 - B*x_n)
    FP_Mul final_mult (
        .A(x_n),
        .B(two_minus_bx),
        .Mul_Out(x_n_plus_1)
    );
endmodule