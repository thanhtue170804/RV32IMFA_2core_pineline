// fpu_inst.v - compatibility wrapper
module fpu_inst(
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [4:0]  FPUControl,
    input  wire [31:0] int_in,
    output wire [31:0] Result,
    output wire        Zero
);
    // instantiate your actual FPU (assumed module name "FPU" with ports in_rs1,in_rs2,...)
    // If your real FPU has different name/ports adjust below mapping.
    wire fpu_stall;
    FPU u_fpu_core (
        .in_Clk(1'b0),           // if your FPU needs real clock, change mapping
        .in_Rst_N(1'b1),
        .in_start(1'b1),
        .in_FPU_Op(FPUControl),
        .in_rs1(A),
        .in_rs2(B),
        .int_in(int_in),
        .out_data(Result),
        .out_stall(fpu_stall)
    );

    assign Zero = (Result == 32'h00000000);
endmodule
