module ex_mem_registers(
    // ========================
    // Tín hiệu điều khiển chung
    // ========================
    input clk, rst,
    input stall,
    input flush,
    
    // -------------------------
    // Đầu vào tín hiệu điều khiển từ EX (Integer)
    // -------------------------
    input RegWriteE, MemWriteE, ResultSrcE,
    
    // -------------------------
    // Đầu vào tín hiệu điều khiển từ EX (Floating Point)
    // -------------------------
    input FPRegWriteE, FPResultSrcE,        // Cho phần FPU
    
    // -------------------------
    // Đầu vào dữ liệu từ EX stage
    // -------------------------
    input [4:0] RD_E, FP_RD_E,              // Thanh ghi đích của Integer và FPU
    input [31:0] PCPlus4E, ALU_ResultE, WriteDataE,  // Dữ liệu integer
    input [31:0] FP_ALU_ResultE,            // Kết quả từ FPU
    
    // ========================
    // Đầu ra tín hiệu điều khiển đến MEM stage
    // ========================
    output reg RegWriteM, MemWriteM, ResultSrcM,
    output reg FPRegWriteM, FPResultSrcM,
    
    // ========================
    // Đầu ra dữ liệu đến MEM stage
    // ========================
    output reg [4:0] RD_M, FP_RD_M,
    output reg [31:0] PCPlus4M, ALU_ResultM, WriteDataM,
    output reg [31:0] FP_ALU_ResultM
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Reset toàn bộ pipeline EX/MEM
            RegWriteM       <= 1'b0;
            MemWriteM       <= 1'b0;
            ResultSrcM      <= 1'b0;
            FPRegWriteM     <= 1'b0;
            FPResultSrcM    <= 1'b0;
            
            RD_M            <= 5'h00;
            FP_RD_M         <= 5'h00;
            
            PCPlus4M        <= 32'h00000000;
            ALU_ResultM     <= 32'h00000000;
            WriteDataM      <= 32'h00000000;
            FP_ALU_ResultM  <= 32'h00000000;
        end
        else if (flush) begin
            // Xóa stage khi flush
            RegWriteM       <= 1'b0;
            MemWriteM       <= 1'b0;
            ResultSrcM      <= 1'b0;
            FPRegWriteM     <= 1'b0;
            FPResultSrcM    <= 1'b0;
            
            RD_M            <= 5'h00;
            FP_RD_M         <= 5'h00;
            
            PCPlus4M        <= 32'h00000000;
            ALU_ResultM     <= 32'h00000000;
            WriteDataM      <= 32'h00000000;
            FP_ALU_ResultM  <= 32'h00000000;
        end
        else if (!stall) begin
            // Truyền dữ liệu bình thường khi không bị dừng
            RegWriteM       <= RegWriteE;
            MemWriteM       <= MemWriteE;
            ResultSrcM      <= ResultSrcE;
            FPRegWriteM     <= FPRegWriteE;
            FPResultSrcM    <= FPResultSrcE;
            
            RD_M            <= RD_E;
            FP_RD_M         <= FP_RD_E;
            
            PCPlus4M        <= PCPlus4E;
            ALU_ResultM     <= ALU_ResultE;
            WriteDataM      <= WriteDataE;
            FP_ALU_ResultM  <= FP_ALU_ResultE;
        end
    end

endmodule
