module memory_stage(
    // ===== Điều khiển =====
    input clk, rst,
    input MemWriteM,
    input isFPUM,               // <-- mới: xác định lệnh load/store float
    
    // ===== Dữ liệu =====
    input [31:0] ALU_ResultM, WriteDataM,
    
    // ===== Đầu ra =====
    output [31:0] ReadDataM
);
    // Bộ nhớ dữ liệu chung cho cả integer & float
    Data_Memory dmem (
        .clk(clk),
        .rst(rst),
        .WE(MemWriteM),
        .WD(WriteDataM),
        .A(ALU_ResultM),
        .RD(ReadDataM)
    );
endmodule
