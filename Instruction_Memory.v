
module Instruction_Memory (
    input        rst,    // reset active low
    input  [31:0] A,     // address (byte)
    output wire [31:0] RD // instruction read out
);
    // 1024 words x 32-bit
    reg [31:0] mem[0:1023];

    // Khởi tạo bộ nhớ từ file memfile.bin
    initial begin

        $readmemh("memfile.hex", mem);
    end

    // Đọc dữ liệu (bỏ 2 bit thấp của A để word-align)
    assign RD = (rst == 1'b0) ? 32'h00000000 : mem[A[31:2]];

endmodule
