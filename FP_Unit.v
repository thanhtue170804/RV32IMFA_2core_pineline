module FP_Unit (
    input in_Clk, in_Rst_N, in_start,
    input [1:0] in_FPU_Op,
    input [31:0] in_rs1, in_rs2,
    output [31:0] out_data,
    output out_stall
);
    // Internal wires
    wire [31:0] FP_Add_Out, FP_Sub_Out, FP_Mul_Out, FP_Div_Out;
    wire div_stall;

    // Add module
    FP_Add FP_Add_Inst0 (
        .in_numA(in_rs1),
        .in_numB(in_rs2),
        .out_data(FP_Add_Out)
    );

    // Sub module
    FP_Sub FP_Sub_Inst0 (
        .in_numA(in_rs1),
        .in_numB(in_rs2),
        .out_data(FP_Sub_Out)
    );

    // Mul module
    FP_Mul FP_Mul_Inst0 (
        .A(in_rs1),
        .B(in_rs2),
        .Mul_Out(FP_Mul_Out)
    );

    // Fixed logic division module
    FP_Div FP_Div_Inst0 (
        .in_Clk(in_Clk),
        .in_Rst_N(in_Rst_N),
        .in_start(in_start),
        .in_numA(in_rs1),
        .in_numB(in_rs2),
        .out_result(FP_Div_Out),
        .out_stall(div_stall)
    );
    
    // Assign stall signal
    assign out_stall = (in_FPU_Op == 2'b11) ? div_stall : 1'b0;

    // Output selection based on operation
    assign out_data = (in_FPU_Op == 2'b00) ? FP_Add_Out :
                      (in_FPU_Op == 2'b01) ? FP_Sub_Out :
                      (in_FPU_Op == 2'b10) ? FP_Mul_Out :
                      (in_FPU_Op == 2'b11) ? FP_Div_Out : 32'd0;
endmodule