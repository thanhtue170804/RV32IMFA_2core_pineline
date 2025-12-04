// execute_stage.v
// Execute stage with integer ALU + FPU integration and forwarding (integer + FP)

module execute_stage(
    // control inputs
    input  wire        RegWriteE,
    input  wire        ALUSrcE,
    input  wire        MemWriteE,
    input  wire        ResultSrcE,
    input  wire        BranchE,

    // integer ALU control
    input  wire [4:0]  ALUControlE,

    // FP control
    input  wire        isFPUE,        // 1 = this instruction uses FPU
    input  wire [4:0]  FPUControlE,

    // integer data inputs (from ID/EX)
    input  wire [31:0] RD1_E,
    input  wire [31:0] RD2_E,
    input  wire [31:0] Imm_Ext_E,
    input  wire [31:0] PCE,
    input  wire [31:0] PCPlus4E,
    input  wire [4:0]  RD_E,

    // integer forwarding inputs
    input  wire [31:0] ResultW,       // forwarding from WB (integer)
    input  wire [31:0] ALU_ResultM,   // forwarding from MEM (integer)
    input  wire [1:0]  ForwardA_E,    // 00 = from RD1_E, 01 = from ResultW, 10 = from ALU_ResultM
    input  wire [1:0]  ForwardB_E,

    // FP data inputs (from ID/EX)
    input  wire [31:0] FPRD1_E,
    input  wire [31:0] FPRD2_E,
    input  wire [4:0]  FP_RD_E,

    // FP forwarding inputs (bit-pattern forwarding)
    input  wire [31:0] FP_ResultW,       // forwarded FP from WB (bit-pattern)
    input  wire [31:0] FP_ALU_ResultM,   // forwarded FP from MEM
    input  wire [1:0]  FP_ForwardA_E,    // 00 = from FPRD1_E, 01 = from FP_ResultW, 10 = from FP_ALU_ResultM
    input  wire [1:0]  FP_ForwardB_E,

    // outputs
    output reg         PCSrcE,
    output reg  [31:0] ALU_ResultE,      // integer ALU result (bit-pattern)
    output reg  [31:0] FP_ALU_ResultE,   // FP result (bit-pattern) from FPU
    output reg  [31:0] WriteDataE,
    output reg  [31:0] PCTargetE,
    output wire        FP_StallE         // stall request from FPU (if multi-cycle)
);

    // Internal signals for integer forwarding
    reg  [31:0] Src_A_int;
    reg  [31:0] Src_B_interim_int;
    reg  [31:0] Src_B_int;

    // Internal signals for FP forwarding
    reg  [31:0] Src_A_fp;
    reg  [31:0] Src_B_fp;

    // ALU intermediate
    wire        alu_zero;
    wire [31:0] alu_result_internal;
    wire        alu_carry, alu_overflow, alu_negative;

    // FPU instance result & busy
    wire [31:0] fpu_result;
    wire        fpu_busy;

    // ---------------------------
    // Integer forwarding selection
    // ---------------------------
    always @(*) begin
        // Forwarding for Src_A (integer)
        case (ForwardA_E)
            2'b10: Src_A_int = ALU_ResultM;
            2'b01: Src_A_int = ResultW;
            default: Src_A_int = RD1_E;
        endcase

        // Forwarding for Src_B_interim (integer)
        case (ForwardB_E)
            2'b10: Src_B_interim_int = ALU_ResultM;
            2'b01: Src_B_interim_int = ResultW;
            default: Src_B_interim_int = RD2_E;
        endcase

        // ALU second operand selection (immediate or register)
        Src_B_int = (ALUSrcE) ? Imm_Ext_E : Src_B_interim_int;

        // Write data (for stores) is the forwarded RD2 value (non-immediate)
        WriteDataE = Src_B_interim_int;
    end

    // ---------------------------
    // FP forwarding selection
    // ---------------------------
    always @(*) begin
        case (FP_ForwardA_E)
            2'b10: Src_A_fp = FP_ALU_ResultM;
            2'b01: Src_A_fp = FP_ResultW;
            default: Src_A_fp = FPRD1_E;
        endcase

        case (FP_ForwardB_E)
            2'b10: Src_B_fp = FP_ALU_ResultM;
            2'b01: Src_B_fp = FP_ResultW;
            default: Src_B_fp = FPRD2_E;
        endcase
    end

    // ---------------------------
    // Integer ALU instantiation
    // Uses your ALU module (ALU_rv32im.v)
    // ---------------------------
    ALU alu_inst (
        .A(Src_A_int),
        .B(Src_B_int),
        .ALUControl(ALUControlE),
        .Carry(alu_carry),
        .OverFlow(alu_overflow),
        .Zero(alu_zero),
        .Negative(alu_negative),
        .Result(alu_result_internal)
    );

    // ---------------------------
    // Floating-point unit instantiation
    // - Uses the FPU module you implemented (fpu.v)
    // - in_start tied to 1 (combinational start); if your FPU needs a pulse, change logic
    // ---------------------------
    FPU fpu_inst (
        .in_Clk(clk),
        .in_Rst_N(rst),
        .in_start(1'b1),
        .in_FPU_Op(FPUControlE),
        .in_rs1(Src_A_fp),
        .in_rs2(Src_B_fp),
        .out_data(fpu_result),
        .out_stall(fpu_busy)
    );

    assign FP_StallE = fpu_busy;

    // ---------------------------
    // Select outputs based on instruction type (integer vs FP)
    // ---------------------------
    always @(*) begin
        // integer ALU result always produced
        ALU_ResultE = alu_result_internal;

        // FP result produced by FPU; only valid if isFPUE asserted and fpu not busy
        FP_ALU_ResultE = fpu_result;

        // branch target adder (simple)
        PCTargetE = PCE + Imm_Ext_E;

        // branch decision uses integer ALU zero (as spec: branches are integer comparisons)
        PCSrcE = alu_zero & BranchE;
    end

endmodule
