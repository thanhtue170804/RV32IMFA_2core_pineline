module PC_module(
    input clk,
    input rst,
    input PC_Write,           // Tín hiệu cho phép cập nhật PC
    input [31:0] PC_Next,
    output reg [31:0] PC
);
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            PC <= 32'h00000000;
        end
        else if (PC_Write) begin  // Chỉ cập nhật PC khi PC_Write = 1
            PC <= PC_Next;
        end
        // Nếu PC_Write = 0 (stall), giữ nguyên giá trị PC
    end
endmodule