module Adder_Exponent_Bias (
    input [7:0] E_a, E_b,
    output reg [7:0] E_r
);
    reg [8:0] temp_sum; // 9 bit để xử lý overflow
    wire [7:0] bias = 8'h7F; // 127 là bias cho IEEE-754 số thực đơn chính xác
    
    always @(*) begin
        // Kiểm tra các trường hợp đặc biệt khi một trong hai số mũ là 0
        if (E_a == 8'h0 || E_b == 8'h0) begin
            // Khi một số mũ = 0, chúng ta cần xử lý trường hợp số không chuẩn
            if (E_a == 8'h0 && E_b == 8'h0) begin
                // Cả hai đều là 0, kết quả là 0
                E_r = 8'h0;
            end else if (E_a == 8'h0) begin
                // E_a = 0, sử dụng E_b - bias + 1
                temp_sum = E_b - bias + 9'd1;
                if (temp_sum[8]) begin
                    // Underflow
                    E_r = 8'h0;
                end else begin
                    E_r = temp_sum[7:0];
                end
            end else begin
                // E_b = 0, sử dụng E_a - bias + 1
                temp_sum = E_a - bias + 9'd1;
                if (temp_sum[8]) begin
                    // Underflow
                    E_r = 8'h0;
                end else begin
                    E_r = temp_sum[7:0];
                end
            end
        end else begin
            // Trường hợp bình thường: cộng hai số mũ và trừ bias
            temp_sum = E_a + E_b - bias;
            
            if (temp_sum >= 9'h0FF) begin
                // Overflow
                E_r = 8'hFF;
            end else if (temp_sum[8]) begin
                // Underflow (số âm)
                E_r = 8'h0;
            end else begin
                E_r = temp_sum[7:0];
            end
        end
    end
endmodule