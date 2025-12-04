module decode_stage(
    // Đầu vào điều khiển
    input clk, rst,
    
    // Đầu vào từ thanh ghi IF/ID
    input [31:0] InstrD, PCD, PCPlus4D,
    
    // Đầu vào từ Writeback
    input RegWriteW,
    input [4:0] RD_W,
    input [31:0] ResultW,

    // Đầu vào từ Writeback (FPU)
    input FPRegWriteW,
    input [4:0] FP_RD_W,
    input [31:0] FP_ResultW,

    // Đầu ra tín hiệu điều khiển đến ID/EX
    output RegWriteD, ALUSrcD, MemWriteD, ResultSrcD, BranchD,
    output [4:0] ALUControlD,
    output [1:0] ImmSrcD,
    output FPRegWriteD,
    output [4:0] FPUControlD,

    // Đầu ra dữ liệu đến ID/EX
    output [31:0] RD1_D, RD2_D, Imm_Ext_D,
    output [31:0] FPRD1_D, FPRD2_D,
    output [4:0] RD_D, RS1_D, RS2_D, FP_RD_D, FP_RS1_D, FP_RS2_D
);
    wire [6:0] opcode = InstrD[6:0];
    wire is_fpu_instr = (opcode == 7'b1010011); // opcode F-type

    // Control Unit cho integer
    Control_Unit control (
        .Op(InstrD[6:0]),
        .RegWrite(RegWriteD),
        .ImmSrc(ImmSrcD),
        .ALUSrc(ALUSrcD),
        .MemWrite(MemWriteD),
        .ResultSrc(ResultSrcD),
        .Branch(BranchD),
        .funct3(InstrD[14:12]),
        .funct7(InstrD[31:25]),
        .ALUControl(ALUControlD)
    );

    // FPU Control Unit
    // --- SỬA: bỏ dấu phẩy thừa và (nếu có) nối FPRegWrite ---
    // Nếu module FPU_Control_Unit THỰC SỰ có port FPRegWrite, bật dòng .FPRegWrite(FPRegWriteD)
    // Nếu không, xóa dòng đó.
    FPU_Control_Unit fpu_control (
        .funct7(InstrD[31:25]),
        .funct3(InstrD[14:12]),
        .opcode(InstrD[6:0]),
        .FPUControl(FPUControlD)
        // ,.FPRegWrite(FPRegWriteD) // <-- chỉ bật nếu module định nghĩa cổng này
    );

    // Register File (Integer)
    Register_File rf (
        .clk(clk),
        .rst(rst),
        .WE3(RegWriteW),
        .WD3(ResultW),
        .A1(InstrD[19:15]),
        .A2(InstrD[24:20]),
        .A3(RD_W),
        .RD1(RD1_D),
        .RD2(RD2_D)
    );

    // Floating Point Register File
    FP_Register_File fprf (
        .clk(clk),
        .rst(rst),
        .WE3(FPRegWriteW),
        .WD3(FP_ResultW),
        .A1(InstrD[19:15]),
        .A2(InstrD[24:20]),
        .A3(FP_RD_W),
        .RD1(FPRD1_D),
        .RD2(FPRD2_D)
    );

    // Sign Extension
    Sign_Extend extension (
        .In(InstrD[31:0]),
        .Imm_Ext(Imm_Ext_D),
        .ImmSrc(ImmSrcD)
    );

    // Địa chỉ thanh ghi
    assign RD_D     = InstrD[11:7];
    assign RS1_D    = InstrD[19:15];
    assign RS2_D    = InstrD[24:20];

    assign FP_RD_D  = InstrD[11:7];
    assign FP_RS1_D = InstrD[19:15];
    assign FP_RS2_D = InstrD[24:20];
endmodule
