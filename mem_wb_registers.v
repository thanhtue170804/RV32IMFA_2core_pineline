module mem_wb_registers(
    // ========================
    // Tín hiệu điều khiển chung
    // ========================
    input clk, rst,
    input stall,
    input flush,
    
    // -------------------------
    // Đầu vào tín hiệu điều khiển từ Memory (Integer)
    // -------------------------
    input RegWriteM, ResultSrcM,
    
    // -------------------------
    // Đầu vào tín hiệu điều khiển từ Memory (Floating Point)
    // -------------------------
    input FPRegWriteM, FPResultSrcM,
    
    // -------------------------
    // Đầu vào dữ liệu từ Memory
    // -------------------------
    input [4:0] RD_M, FP_RD_M,
    input [31:0] PCPlus4M, ALU_ResultM, ReadDataM,   // Integer data path
    input [31:0] FP_ALU_ResultM, FP_ReadDataM,       // Floating-point data path (nếu có load/store FP)
    
    // ========================
    // Đầu ra tín hiệu điều khiển đến Writeback
    // ========================
    output reg RegWriteW, ResultSrcW,
    output reg FPRegWriteW, FPResultSrcW,
    
    // ========================
    // Đầu ra dữ liệu đến Writeback
    // ========================
    output reg [4:0] RD_W, FP_RD_W,
    output reg [31:0] PCPlus4W, ALU_ResultW, ReadDataW,
    output reg [31:0] FP_ALU_ResultW, FP_ReadDataW
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // ===== Reset toàn bộ thanh ghi pipeline =====
            RegWriteW       <= 1'b0;
            ResultSrcW      <= 1'b0;
            FPRegWriteW     <= 1'b0;
            FPResultSrcW    <= 1'b0;
            
            RD_W            <= 5'h00;
            FP_RD_W         <= 5'h00;
            
            PCPlus4W        <= 32'h00000000;
            ALU_ResultW     <= 32'h00000000;
            ReadDataW       <= 32'h00000000;
            FP_ALU_ResultW  <= 32'h00000000;
            FP_ReadDataW    <= 32'h00000000;
        end
        else if (flush) begin
            // ===== Khi có flush (branch/jump) =====
            RegWriteW       <= 1'b0;
            ResultSrcW      <= 1'b0;
            FPRegWriteW     <= 1'b0;
            FPResultSrcW    <= 1'b0;
            
            RD_W            <= 5'h00;
            FP_RD_W         <= 5'h00;
            
            PCPlus4W        <= 32'h00000000;
            ALU_ResultW     <= 32'h00000000;
            ReadDataW       <= 32'h00000000;
            FP_ALU_ResultW  <= 32'h00000000;
            FP_ReadDataW    <= 32'h00000000;
        end
        else if (!stall) begin
            // ===== Khi pipeline hoạt động bình thường =====
            RegWriteW       <= RegWriteM;
            ResultSrcW      <= ResultSrcM;
            FPRegWriteW     <= FPRegWriteM;
            FPResultSrcW    <= FPResultSrcM;
            
            RD_W            <= RD_M;
            FP_RD_W         <= FP_RD_M;
            
            PCPlus4W        <= PCPlus4M;
            ALU_ResultW     <= ALU_ResultM;
            ReadDataW       <= ReadDataM;
            FP_ALU_ResultW  <= FP_ALU_ResultM;
            FP_ReadDataW    <= FP_ReadDataM;
        end
    end

endmodule
