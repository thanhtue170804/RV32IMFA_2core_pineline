// id_ex_registers.v (phiên bản có FP fields)
module id_ex_registers(
    input  wire clk, rst,
    input  wire stall,
    input  wire flush,

    // integer control
    input  wire RegWriteD, ALUSrcD, MemWriteD, ResultSrcD, BranchD,
    input  wire [4:0] ALUControlD,

    // FP control
    input  wire isFPUD,
    input  wire [4:0] FPUControlD,

    // integer data inputs
    input  wire [31:0] RD1_D, RD2_D, Imm_Ext_D, PCD, PCPlus4D,
    input  wire [4:0] RD_D, RS1_D, RS2_D,

    // FP data inputs
    input  wire [31:0] FPRD1_D, FPRD2_D,
    input  wire [4:0] FP_RD_D, FP_RS1_D, FP_RS2_D,

    // outputs integer
    output reg RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE,
    output reg [4:0] ALUControlE,
    output reg [31:0] RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E,
    output reg [4:0] RD_E, RS1_E, RS2_E,

    // outputs FP
    output reg isFPUE,
    output reg [4:0] FPUControlE,
    output reg [31:0] FPRD1_E, FPRD2_E,
    output reg [4:0] FP_RD_E, FP_RS1_E, FP_RS2_E
);
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            RegWriteE <= 0; ALUSrcE <= 0; MemWriteE <= 0; ResultSrcE <= 0; BranchE <= 0;
            ALUControlE <= 5'd0;
            RD1_E <= 32'd0; RD2_E <= 32'd0; Imm_Ext_E <= 32'd0; PCE <= 32'd0; PCPlus4E <= 32'd0;
            RD_E <= 5'd0; RS1_E <= 5'd0; RS2_E <= 5'd0;
            isFPUE <= 1'b0; FPUControlE <= 5'd0; FPRD1_E <= 32'd0; FPRD2_E <= 32'd0;
            FP_RD_E <= 5'd0; FP_RS1_E <= 5'd0; FP_RS2_E <= 5'd0;
        end else if (flush) begin
            RegWriteE <= 0; ALUSrcE <= 0; MemWriteE <= 0; ResultSrcE <= 0; BranchE <= 0;
            ALUControlE <= 5'd0;
            RD1_E <= 32'd0; RD2_E <= 32'd0; Imm_Ext_E <= 32'd0; PCE <= 32'd0; PCPlus4E <= 32'd0;
            RD_E <= 5'd0; RS1_E <= 5'd0; RS2_E <= 5'd0;
            isFPUE <= 1'b0; FPUControlE <= 5'd0; FPRD1_E <= 32'd0; FPRD2_E <= 32'd0;
            FP_RD_E <= 5'd0; FP_RS1_E <= 5'd0; FP_RS2_E <= 5'd0;
        end else if (!stall) begin
            RegWriteE <= RegWriteD; ALUSrcE <= ALUSrcD; MemWriteE <= MemWriteD;
            ResultSrcE <= ResultSrcD; BranchE <= BranchD; ALUControlE <= ALUControlD;
            RD1_E <= RD1_D; RD2_E <= RD2_D; Imm_Ext_E <= Imm_Ext_D; PCE <= PCD; PCPlus4E <= PCPlus4D;
            RD_E <= RD_D; RS1_E <= RS1_D; RS2_E <= RS2_D;
            isFPUE <= isFPUD; FPUControlE <= FPUControlD;
            FPRD1_E <= FPRD1_D; FPRD2_E <= FPRD2_D;
            FP_RD_E <= FP_RD_D; FP_RS1_E <= FP_RS1_D; FP_RS2_E <= FP_RS2_D;
        end
    end
endmodule
