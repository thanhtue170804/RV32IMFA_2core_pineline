module Register_File(
    // Điều khiển
    input clk,          // Xung clock
    input rst,          // Tín hiệu reset
    input WE3,          // Write Enable - cho phép ghi thanh ghi

    // Địa chỉ các thanh ghi
    input [4:0] A1,     // Địa chỉ thanh ghi đọc 1
    input [4:0] A2,     // Địa chỉ thanh ghi đọc 2
    input [4:0] A3,     // Địa chỉ thanh ghi ghi (đích)

    // Dữ liệu
    input [31:0] WD3,   // Dữ liệu ghi vào thanh ghi

    // Giá trị đọc ra
    output [31:0] RD1,  // Giá trị đọc từ thanh ghi 1
    output [31:0] RD2   // Giá trị đọc từ thanh ghi 2
);
    // Mảng 32 thanh ghi, mỗi thanh ghi 32-bit
    reg [31:0] Register [31:0];

    // Logic ghi thanh ghi (diễn ra theo cạnh dương clock)
    always @(posedge clk) begin
        // Ghi với điều kiện:
        // 1. Cho phép ghi (WE3)
        // 2. Không phải ghi vào thanh ghi zero (x0)
        if(WE3 & (A3 != 5'h00))
            Register[A3] <= WD3;
    end

    // Đọc thanh ghi 1
    // Nếu reset: trả về 0
    // Ngược lại: đọc giá trị từ địa chỉ A1
    assign RD1 = (rst == 1'b0) ? 32'd0 : Register[A1];

    // Đọc thanh ghi 2
    // Nếu reset: trả về 0
    // Ngược lại: đọc giá trị từ địa chỉ A2
    assign RD2 = (rst == 1'b0) ? 32'd0 : Register[A2];

    // Khởi tạo ban đầu: thanh ghi 0 luôn bằng 0
    initial begin
        Register[0] = 32'h00000000;
    end
endmodule