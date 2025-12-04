module if_id_registers(
    // Tín hiệu điều khiển
    input clk, rst,
    input stall,     // Tín hiệu dừng để giữ nguyên trạng thái
    input flush,     // Tín hiệu xóa nội dung thanh ghi
    
    // Đầu vào từ giai đoạn Fetch
    input [31:0] InstrF, PCF, PCPlus4F,
    
    // Đầu ra đến giai đoạn Decode
    output reg [31:0] InstrD, PCD, PCPlus4D
);

    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            // Logic reset
            InstrD <= 32'h00000000;
            PCD <= 32'h00000000;
            PCPlus4D <= 32'h00000000;
        end
        else if(flush) begin
            // Xóa thanh ghi khi có tín hiệu flush
            InstrD <= 32'h00000000;
            PCD <= 32'h00000000;
            PCPlus4D <= 32'h00000000;
        end
        else if(!stall) begin
            // Cập nhật chỉ khi không bị dừng
            InstrD <= InstrF;
            PCD <= PCF;
            PCPlus4D <= PCPlus4F;
        end
        // Nếu bị dừng, giữ nguyên giá trị hiện tại
    end
endmodule