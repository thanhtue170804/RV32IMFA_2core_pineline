module OneBit_Div (
    input [24:0] in_dividend, // Số dư hiện tại (25-bit)
    input [23:0] in_divisor,  // Số chia (24-bit)
    output reg out_quotient,  // Bit thương
    output reg [24:0] out_remainder // Số dư mới
);
    wire [24:0] divisor_ext = {1'b0, in_divisor}; // Mở rộng số chia thành 25-bit

    always @(*) begin
        if (in_divisor == 24'h0) begin
            out_quotient = 1'b0;
            out_remainder = in_dividend;
        end else begin
            // So sánh số dư với số chia
            if (in_dividend >= divisor_ext) begin
                out_quotient = 1'b1;
                out_remainder = (in_dividend - divisor_ext); // Không dịch trái ở đây
            end else begin
                out_quotient = 1'b0;
                out_remainder = in_dividend; // Không dịch trái
            end
        end
    end
endmodule