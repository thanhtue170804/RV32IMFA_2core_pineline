// RV32IMF.v
// Top-level for RV32I core extended with RV32F floating point path
// Integrates integer pipeline + floating-point pipeline (FPU)
// Assumes submodules exist with the port names used below.

module RV32I (
    input  wire        clk,        // clock
    input  wire        rst,        // reset (active low)

    // Fetch outputs
    output wire [31:0] PCF,
    output wire [31:0] InstrF,

    // Writeback outputs (integer)
    output wire [31:0] ResultW,
    output wire [4:0]  RD_W,

    // Pipeline control outputs (for observation)
    output wire stall_F,
    output wire stall_D,
    output wire flush_D,
    output wire flush_E,

    // Forwarding outputs (integer)
    output wire [1:0] ForwardAE,
    output wire [1:0] ForwardBE,
    output wire lwStall,
    output wire branchStall
);

    // ============================
    // Integer pipeline wires
    // ============================
    wire stall_E, stall_M, stall_W;
    wire flush_M, flush_W;

    wire [31:0] PCPlus4F;
    wire [31:0] InstrD, PCD, PCPlus4D;
    wire RegWriteD, ALUSrcD, MemWriteD, ResultSrcD, BranchD;
    wire [4:0] ALUControlD;          // 5-bit
    wire [1:0] ImmSrcD;
    wire [31:0] RD1_D, RD2_D, Imm_Ext_D;
    wire [4:0] RS1_D, RS2_D, RD_D;

    wire RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE;
    wire [4:0] ALUControlE;          // 5-bit
    wire [31:0] RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E;
    wire [4:0] RS1_E, RS2_E, RD_E;

    wire PCSrcE;
    wire [31:0] ALU_ResultE, WriteDataE, PCTargetE;

    wire RegWriteM, MemWriteM, ResultSrcM;
    wire [4:0] RD_M;
    wire [31:0] PCPlus4M, ALU_ResultM, WriteDataM;
    wire [31:0] ReadDataM;

    wire RegWriteW, ResultSrcW;
    wire [31:0] PCPlus4W, ALU_ResultW, ReadDataW;

    // ============================
    // Floating-point pipeline wires
    // ============================
    // Decode stage outputs
    wire FPRegWriteD;
    wire [4:0] FPUControlD;
    wire [31:0] FPRD1_D, FPRD2_D;
    wire [4:0] FP_RD_D, FP_RS1_D, FP_RS2_D;

    // ID/EX latches
    wire FPRegWriteE;
    wire [4:0] FPUControlE;
    wire [31:0] FPRD1_E, FPRD2_E;
    wire [4:0] FP_RD_E, FP_RS1_E, FP_RS2_E;

    // EX stage FP outputs
    wire [31:0] FP_ALU_ResultE;
    wire        FP_StallE;

    // EX/MEM latches
    wire FPRegWriteM;
    wire FPResultSrcM;
    wire [4:0] FP_RD_M;
    wire [31:0] FP_ALU_ResultM;
    wire [31:0] FP_ReadDataM;

    // MEM/WB latches
    wire FPRegWriteW;
    wire FPResultSrcW;
    wire [4:0] FP_RD_W;
    wire [31:0] FP_ALU_ResultW;
    wire [31:0] FP_ReadDataW;

    // forwarded FP result (WB)
    wire [31:0] FP_ResultW;

    // forwarding signals for FP
    wire [1:0] FP_ForwardAE;
    wire [1:0] FP_ForwardBE;

    // ============================================================
    // FETCH
    // ============================================================
    fetch_stage fetch (
        .clk(clk),
        .rst(rst),
        .stall(stall_F),
        .PCSrcE(PCSrcE),
        .PCTargetE(PCTargetE),
        .InstrF(InstrF),
        .PCF(PCF),
        .PCPlus4F(PCPlus4F)
    );

    // IF/ID pipeline registers (assumed existing)
    if_id_registers if_id (
        .clk(clk),
        .rst(rst),
        .stall(stall_D),
        .flush(flush_D),
        .InstrF(InstrF),
        .PCF(PCF),
        .PCPlus4F(PCPlus4F),
        .InstrD(InstrD),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D)
    );

    // ============================================================
    // DECODE
    // decode_stage must provide both integer and FP outputs (see earlier signature)
    // ============================================================
    decode_stage decode (
        .clk(clk),
        .rst(rst),
        .InstrD(InstrD),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D),

        // integer writeback inputs
        .RegWriteW(RegWriteW),
        .RD_W(RD_W),
        .ResultW(ResultW),

        // FP writeback inputs
        .FPRegWriteW(FPRegWriteW),
        .FP_RD_W(FP_RD_W),
        .FP_ResultW(FP_ResultW),

        // outputs: integer control
        .RegWriteD(RegWriteD),
        .ALUSrcD(ALUSrcD),
        .MemWriteD(MemWriteD),
        .ResultSrcD(ResultSrcD),
        .BranchD(BranchD),
        .ALUControlD(ALUControlD),
        .ImmSrcD(ImmSrcD),

        // outputs: integer data
        .RD1_D(RD1_D),
        .RD2_D(RD2_D),
        .Imm_Ext_D(Imm_Ext_D),
        .RD_D(RD_D),
        .RS1_D(RS1_D),
        .RS2_D(RS2_D),

        // outputs: floating-point control/data
        .FPRegWriteD(FPRegWriteD),
        .FPUControlD(FPUControlD),
        .FPRD1_D(FPRD1_D),
        .FPRD2_D(FPRD2_D),
        .FP_RD_D(FP_RD_D),
        .FP_RS1_D(FP_RS1_D),
        .FP_RS2_D(FP_RS2_D)
    );

    // ============================================================
    // ID/EX registers (carry integer + FP signals)
    // ============================================================
    id_ex_registers id_ex (
        .clk(clk),
        .rst(rst),
        .stall(stall_E),
        .flush(flush_E),

        // integer control inputs
        .RegWriteD(RegWriteD),
        .ALUSrcD(ALUSrcD),
        .MemWriteD(MemWriteD),
        .ResultSrcD(ResultSrcD),
        .BranchD(BranchD),
        .ALUControlD(ALUControlD),

        // FP control inputs
        .isFPUD(FPRegWriteD),
        .FPUControlD(FPUControlD),

        // integer data inputs
        .RD1_D(RD1_D),
        .RD2_D(RD2_D),
        .Imm_Ext_D(Imm_Ext_D),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D),
        .RD_D(RD_D),
        .RS1_D(RS1_D),
        .RS2_D(RS2_D),

        // FP data inputs
        .FPRD1_D(FPRD1_D),
        .FPRD2_D(FPRD2_D),
        .FP_RD_D(FP_RD_D),
        .FP_RS1_D(FP_RS1_D),
        .FP_RS2_D(FP_RS2_D),

        // integer outputs to EX
        .RegWriteE(RegWriteE),
        .ALUSrcE(ALUSrcE),
        .MemWriteE(MemWriteE),
        .ResultSrcE(ResultSrcE),
        .BranchE(BranchE),
        .ALUControlE(ALUControlE),

        .RD1_E(RD1_E),
        .RD2_E(RD2_E),
        .Imm_Ext_E(Imm_Ext_E),
        .PCE(PCE),
        .PCPlus4E(PCPlus4E),
        .RD_E(RD_E),
        .RS1_E(RS1_E),
        .RS2_E(RS2_E),

        // FP outputs to EX
        .isFPUE(FPRegWriteE),
        .FPUControlE(FPUControlE),
        .FPRD1_E(FPRD1_E),
        .FPRD2_E(FPRD2_E),
        .FP_RD_E(FP_RD_E),
        .FP_RS1_E(FP_RS1_E),
        .FP_RS2_E(FP_RS2_E)
    );

    // ============================================================
    // EXECUTE stage
    // Must accept integer forwarding and FP forwarding inputs
    // Should produce both ALU_ResultE and FP_ALU_ResultE
    // ============================================================
    execute_stage execute (
        // integer control
        .RegWriteE(RegWriteE),
        .ALUSrcE(ALUSrcE),
        .MemWriteE(MemWriteE),
        .ResultSrcE(ResultSrcE),
        .BranchE(BranchE),

        // integer ALU control
        .ALUControlE(ALUControlE),

        // FP control
        .isFPUE(FPRegWriteE),
        .FPUControlE(FPUControlE),

        // integer data inputs
        .RD1_E(RD1_E),
        .RD2_E(RD2_E),
        .Imm_Ext_E(Imm_Ext_E),
        .PCE(PCE),
        .PCPlus4E(PCPlus4E),
        .RD_E(RD_E),

        // integer forwarding inputs
        .ResultW(ResultW),
        .ALU_ResultM(ALU_ResultM),
        .ForwardA_E(ForwardAE),
        .ForwardB_E(ForwardBE),

        // FP forwarding inputs (bit-pattern forwarding)
        .FP_ResultW(FP_ResultW),
        .FP_ALU_ResultM(FP_ALU_ResultM),
        .FP_ForwardA_E(FP_ForwardAE),
        .FP_ForwardB_E(FP_ForwardBE),

        // outputs
        .PCSrcE(PCSrcE),
        .ALU_ResultE(ALU_ResultE),
        .FP_ALU_ResultE(FP_ALU_ResultE),
        .WriteDataE(WriteDataE),
        .PCTargetE(PCTargetE)
    );

    // ============================================================
    // FPU core instantiation
    // - Uses FPRD1_E/FPRD2_E when isFPUE asserted in execute stage
    // - If your FPU uses a different handshake, adapt here
    // ============================================================
    FPU fpu_core (
        .in_Clk(clk),
        .in_Rst_N(rst),
        .in_start(1'b1),            // if FPU needs start pulse, manage externally (hazard control)
        .in_FPU_Op(FPUControlE),
        .in_rs1(FPRD1_E),
        .in_rs2(FPRD2_E),
        .out_data(FP_ALU_ResultE),
        .out_stall(FP_StallE)
    );

    // ============================================================
    // EX/MEM registers (carry integer + FP)
    // Expect ex_mem_registers has been extended to include FP signals
    // ============================================================
    ex_mem_registers ex_mem (
        .clk(clk),
        .rst(rst),
        .stall(stall_M),
        .flush(flush_M),

        // integer control inputs
        .RegWriteE(RegWriteE),
        .MemWriteE(MemWriteE),
        .ResultSrcE(ResultSrcE),

        // FP control inputs
        .FPRegWriteE(FPRegWriteE),
        .FPResultSrcE(FPResultSrcE /* if available else tie 0 */),

        // integer data inputs
        .RD_E(RD_E),
        .PCPlus4E(PCPlus4E),
        .ALU_ResultE(ALU_ResultE),
        .WriteDataE(WriteDataE),

        // FP data inputs
        .FP_RD_E(FP_RD_E),
        .FP_ALU_ResultE(FP_ALU_ResultE),

        // integer outputs to MEM
        .RegWriteM(RegWriteM),
        .MemWriteM(MemWriteM),
        .ResultSrcM(ResultSrcM),
        .RD_M(RD_M),
        .PCPlus4M(PCPlus4M),
        .ALU_ResultM(ALU_ResultM),
        .WriteDataM(WriteDataM),

        // FP outputs to MEM
        .FPRegWriteM(FPRegWriteM),
        .FPResultSrcM(FPResultSrcM),
        .FP_RD_M(FP_RD_M),
        .FP_ALU_ResultM(FP_ALU_ResultM)
    );

    // ============================================================
    // MEMORY stage (shared 32-bit data memory)
    // ============================================================
    memory_stage memory (
        .clk(clk),
        .rst(rst),
        .MemWriteM(MemWriteM),
        .ALU_ResultM(ALU_ResultM),
        .WriteDataM(WriteDataM),
        .ReadDataM(ReadDataM)
    );

    // ============================================================
    // MEM/WB registers (carry integer + FP)
    // ============================================================
    mem_wb_registers mem_wb (
        .clk(clk),
        .rst(rst),
        .stall(stall_W),
        .flush(flush_W),

        // integer inputs
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .RD_M(RD_M),
        .PCPlus4M(PCPlus4M),
        .ALU_ResultM(ALU_ResultM),
        .ReadDataM(ReadDataM),

        // FP inputs
        .FPRegWriteM(FPRegWriteM),
        .FPResultSrcM(FPResultSrcM),
        .FP_RD_M(FP_RD_M),
        .FP_ALU_ResultM(FP_ALU_ResultM),
        .FP_ReadDataM(ReadDataM),

        // integer outputs to WB
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW),
        .RD_W(RD_W),
        .PCPlus4W(PCPlus4W),
        .ALU_ResultW(ALU_ResultW),
        .ReadDataW(ReadDataW),

        // FP outputs to WB
        .FPRegWriteW(FPRegWriteW),
        .FPResultSrcW(FPResultSrcW),
        .FP_RD_W(FP_RD_W),
        .FP_ALU_ResultW(FP_ALU_ResultW),
        .FP_ReadDataW(FP_ReadDataW)
    );

    // ============================================================
    // WRITEBACK stage
    // writeback_stage assumed extended to accept FP inputs and produce FP_ResultW
    // ============================================================
    writeback_stage writeback (
        .ResultSrcW(ResultSrcW),
        .isFPUW(FPRegWriteW),           // if true, write FP_ResultW to FP regfile
        .ALU_ResultW(ALU_ResultW),
        .ReadDataW(ReadDataW),
        .FP_ALU_ResultW(FP_ALU_ResultW),
        .FP_ReadDataW(FP_ReadDataW),

        .ResultW(ResultW),
        .FP_ResultW(FP_ResultW)
    );

    // ============================================================
    // HAZARD / FORWARDING units
    // hazard_unit extended to handle integer + FP forwarding
    // ============================================================
    hazard_unit data_hazard_unit (
        .rst(rst),

        // integer forwarding inputs
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .RD_M(RD_M),
        .RD_W(RD_W),
        .Rs1_E(RS1_E),
        .Rs2_E(RS2_E),

        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),

        // FP forwarding inputs
        .FPRegWriteM(FPRegWriteM),
        .FPRegWriteW(FPRegWriteW),
        .FP_RD_M(FP_RD_M),
        .FP_RD_W(FP_RD_W),
        .FP_RS1_E(FP_RS1_E),
        .FP_RS2_E(FP_RS2_E),

        .FP_ForwardAE(FP_ForwardAE),
        .FP_ForwardBE(FP_ForwardBE)
    );

    // ============================================================
    // Hazard controller (stalls & flushes)
    // Extended to consider FP load-use hazards
    // ============================================================
    hazard_control hazard_controller (
        .rst(rst),
        .PCSrcE(PCSrcE),
        .ResultSrcE(ResultSrcE),
        .RD_E(RD_E),
        .RS1_D(RS1_D),
        .RS2_D(RS2_D),

        // FP inputs (for load-use detection)
        .FPResultSrcE(FPResultSrcM),
        .FP_RD_E(FP_RD_E),
        .FP_RS1_D(FP_RS1_D),
        .FP_RS2_D(FP_RS2_D),

        // outputs: stalls/flashes
        .StallF(stall_F),
        .StallD(stall_D),
        .StallE(stall_E),
        .StallM(stall_M),
        .StallW(stall_W),

        .FlushD(flush_D),
        .FlushE(flush_E),
        .FlushM(flush_M),
        .FlushW(flush_W),

        .lwStall(lwStall),
        .f_lwStall(),      // optional not connected
        .branchStall(branchStall)
    );

endmodule
