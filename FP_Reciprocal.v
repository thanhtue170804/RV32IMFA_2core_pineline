module FP_Reciprocal (
    input in_Clk, in_Rst_N, in_start,
    input [31:0] in_numA, in_numB,
    output reg out_stall,
    output reg [31:0] out_result
);
    // Các định nghĩa trạng thái máy
    localparam IDLE = 4'd0;
    localparam PREPARE = 4'd1;
    localparam ITER1_BX = 4'd2;
    localparam ITER1_2_MINUS_BX = 4'd3;
    localparam ITER1_X_NEXT = 4'd4;
    localparam ITER2_BX = 4'd5;
    localparam ITER2_2_MINUS_BX = 4'd6;
    localparam ITER2_X_NEXT = 4'd7;
    localparam ITER3_BX = 4'd8;
    localparam ITER3_2_MINUS_BX = 4'd9;
    localparam ITER3_X_NEXT = 4'd10;
    localparam CALC_RESULT = 4'd11;
    localparam DONE = 4'd12;
    
    reg [3:0] state;
    
    // Thanh ghi và tín hiệu nội bộ
    reg [31:0] numA_reg, numB_reg;
    reg [31:0] x_n;                  // Xấp xỉ hiện tại của 1/B
    reg [31:0] b_normalized;         // B chuẩn hóa về khoảng [1,2)
    reg [7:0] result_exp;            // Số mũ kết quả cuối cùng
    reg result_sign;                 // Dấu kết quả cuối cùng
    
    // Hằng số số học dấu phẩy động
    wire [31:0] two = 32'h40000000;  // 2.0 trong biểu diễn IEEE 754
    wire [31:0] one = 32'h3F800000;  // 1.0 trong biểu diễn IEEE 754
    
    // Kết nối đến các module FP
    wire [31:0] mul_out, sub_out, mul_final_out;
    reg [31:0] mul_a, mul_b, sub_a, sub_b, mul_final_a, mul_final_b;
    
    // Phát hiện trường hợp đặc biệt
    wire is_a_zero = (in_numA[30:0] == 31'h0);
    wire is_b_zero = (in_numB[30:0] == 31'h0);
    wire is_a_inf = (in_numA[30:23] == 8'hFF && in_numA[22:0] == 23'h0);
    wire is_b_inf = (in_numB[30:23] == 8'hFF && in_numB[22:0] == 23'h0);
    wire is_a_nan = (in_numA[30:23] == 8'hFF && in_numA[22:0] != 23'h0);
    wire is_b_nan = (in_numB[30:23] == 8'hFF && in_numB[22:0] != 23'h0);
    wire is_special_case = is_a_zero || is_b_zero || is_a_inf || is_b_inf || is_a_nan || is_b_nan;
    
    // Kết quả cho các trường hợp đặc biệt
    reg [31:0] special_result;
    
    // Khởi tạo bộ nhân và bộ trừ
    FP_Mul mul_iter (
        .A(mul_a),
        .B(mul_b),
        .Mul_Out(mul_out)
    );
    
    FP_Sub sub_iter (
        .in_numA(sub_a),
        .in_numB(sub_b),
        .out_data(sub_out)
    );
    
    FP_Mul mul_final (
        .A(mul_final_a),
        .B(mul_final_b),
        .Mul_Out(mul_final_out)
    );
    
    // Hàm tạo xấp xỉ ban đầu dựa trên 5 bit quan trọng nhất của mantissa
    function [31:0] initial_approx;
        input [4:0] mant_msb;
        reg [31:0] result;
        begin
            // Bảng tra cứu chính xác cao
            casez (mant_msb)
                5'b00000: result = 32'h3F800000; // 1.0000 cho B = 1.00000
                5'b00001: result = 32'h3F7E0000; // 0.9844 cho B = 1.00391
                5'b00010: result = 32'h3F7C0000; // 0.9688 cho B = 1.00781
                5'b00011: result = 32'h3F7A0000; // 0.9531 cho B = 1.01172
                5'b00100: result = 32'h3F780000; // 0.9375 cho B = 1.01562
                5'b00101: result = 32'h3F760000; // 0.9219 cho B = 1.01953
                5'b00110: result = 32'h3F740000; // 0.9063 cho B = 1.02344
                5'b00111: result = 32'h3F720000; // 0.8906 cho B = 1.02734
                5'b01000: result = 32'h3F700000; // 0.8750 cho B = 1.03125
                5'b01001: result = 32'h3F6E0000; // 0.8594 cho B = 1.03516
                5'b01010: result = 32'h3F6C0000; // 0.8438 cho B = 1.03906
                5'b01011: result = 32'h3F6A0000; // 0.8281 cho B = 1.04297
                5'b01100: result = 32'h3F680000; // 0.8125 cho B = 1.04688
                5'b01101: result = 32'h3F660000; // 0.7969 cho B = 1.05078
                5'b01110: result = 32'h3F640000; // 0.7813 cho B = 1.05469
                5'b01111: result = 32'h3F620000; // 0.7656 cho B = 1.05859
                5'b10000: result = 32'h3F600000; // 0.7500 cho B = 1.06250
                5'b10001: result = 32'h3F5E0000; // 0.7344 cho B = 1.06641
                5'b10010: result = 32'h3F5C0000; // 0.7188 cho B = 1.07031
                5'b10011: result = 32'h3F5A0000; // 0.7031 cho B = 1.07422
                5'b10100: result = 32'h3F580000; // 0.6875 cho B = 1.07813
                5'b10101: result = 32'h3F560000; // 0.6719 cho B = 1.08203
                5'b10110: result = 32'h3F540000; // 0.6563 cho B = 1.08594
                5'b10111: result = 32'h3F520000; // 0.6406 cho B = 1.08984
                5'b11000: result = 32'h3F500000; // 0.6250 cho B = 1.09375
                5'b11001: result = 32'h3F4E0000; // 0.6094 cho B = 1.09766
                5'b11010: result = 32'h3F4C0000; // 0.5938 cho B = 1.10156
                5'b11011: result = 32'h3F4A0000; // 0.5781 cho B = 1.10547
                5'b11100: result = 32'h3F480000; // 0.5625 cho B = 1.10938
                5'b11101: result = 32'h3F460000; // 0.5469 cho B = 1.11328
                5'b11110: result = 32'h3F440000; // 0.5313 cho B = 1.11719
                5'b11111: result = 32'h3F420000; // 0.5156 cho B = 1.12109
            endcase
            initial_approx = result;
        end
    endfunction
    
    // Máy trạng thái chính
    always @(posedge in_Clk or negedge in_Rst_N) begin
        if (!in_Rst_N) begin
            state <= IDLE;
            out_stall <= 1'b0;
            out_result <= 32'h0;
            numA_reg <= 32'h0;
            numB_reg <= 32'h0;
            x_n <= 32'h0;
            b_normalized <= 32'h0;
            result_exp <= 8'h0;
            result_sign <= 1'b0;
            mul_a <= 32'h0;
            mul_b <= 32'h0;
            sub_a <= 32'h0;
            sub_b <= 32'h0;
            mul_final_a <= 32'h0;
            mul_final_b <= 32'h0;
            special_result <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    if (in_start) begin
                        out_stall <= 1'b1;
                        numA_reg <= in_numA;
                        numB_reg <= in_numB;
                        result_sign <= in_numA[31] ^ in_numB[31];
                        
                        // Xử lý các trường hợp đặc biệt
                        if (is_a_zero && !is_b_zero && !is_b_inf && !is_b_nan) begin
                            // 0 / x = 0 (với dấu đúng)
                            special_result <= {result_sign, 31'h0};
                            state <= DONE;
                        end else if (is_b_zero && !is_a_zero && !is_a_inf && !is_a_nan) begin
                            // x / 0 = Infinity (với dấu đúng)
                            special_result <= {result_sign, 8'hFF, 23'h0};
                            state <= DONE;
                        end else if ((is_a_zero && is_b_zero) || (is_a_inf && is_b_inf)) begin
                            // 0/0 hoặc Inf/Inf = NaN
                            special_result <= {1'b0, 8'hFF, 23'h400000}; // qNaN
                            state <= DONE;
                        end else if (is_a_nan || is_b_nan) begin
                            // NaN input = NaN
                            special_result <= {1'b0, 8'hFF, 23'h400000}; // qNaN
                            state <= DONE;
                        end else if (is_a_inf && !is_b_inf && !is_b_zero) begin
                            // Infinity / x = Infinity (với dấu đúng)
                            special_result <= {result_sign, 8'hFF, 23'h0};
                            state <= DONE;
                        end else if (!is_a_inf && !is_a_zero && is_b_inf) begin
                            // x / Infinity = 0 (với dấu đúng)
                            special_result <= {result_sign, 31'h0};
                            state <= DONE;
                        end else begin
                            state <= PREPARE;
                        end
                    end else begin
                        out_stall <= 1'b0;
                    end
                end
                
                PREPARE: begin
                    // Chuẩn bị cho các phép tính toán
                    
                    // Chuẩn hóa B về khoảng [1,2) để áp dụng thuật toán Newton-Raphson
                    b_normalized <= {1'b0, 8'h7F, numB_reg[22:0]};
                    
                    // Tính toán số mũ kết quả: A_exp - B_exp + bias
                    if (numA_reg[30:23] == 8'h0 && numB_reg[30:23] != 8'h0) begin
                        // A là denormal, B bình thường
                        result_exp <= 8'h0 - numB_reg[30:23] + 8'd127;
                    end else if (numA_reg[30:23] != 8'h0 && numB_reg[30:23] == 8'h0) begin
                        // A bình thường, B denormal
                        result_exp <= numA_reg[30:23] - 8'h0 + 8'd127;
                    end else begin
                        // Cả A và B đều bình thường
                        result_exp <= numA_reg[30:23] - numB_reg[30:23] + 8'd127;
                    end
                    
                    // Khởi tạo giá trị xấp xỉ ban đầu cho 1/B từ bảng tra cứu
                    x_n <= initial_approx(numB_reg[22:18]);
                    
                    // Chuẩn bị cho vòng lặp đầu tiên
                    mul_a <= {1'b0, 8'h7F, numB_reg[22:0]};                  // B chuẩn hóa
                    mul_b <= initial_approx(numB_reg[22:18]);                // x₀
                    
                    state <= ITER1_BX;
                end
                
                ITER1_BX: begin
                    // Iteration 1: Tính B * x_n
                    sub_a <= two;      // 2.0
                    sub_b <= mul_out;  // B * x_n
                    
                    state <= ITER1_2_MINUS_BX;
                end
                
                ITER1_2_MINUS_BX: begin
                    // Iteration 1: Tính 2 - B * x_n
                    mul_a <= x_n;      // x_n
                    mul_b <= sub_out;  // 2 - B * x_n
                    
                    state <= ITER1_X_NEXT;
                end
                
                ITER1_X_NEXT: begin
                    // Iteration 1: Tính x_{n+1} = x_n * (2 - B * x_n)
                    x_n <= mul_out;    // Cập nhật xấp xỉ
                    
                    // Chuẩn bị cho vòng lặp thứ hai
                    mul_a <= b_normalized;  // B chuẩn hóa
                    mul_b <= mul_out;       // x_{n+1}
                    
                    state <= ITER2_BX;
                end
                
                ITER2_BX: begin
                    // Iteration 2: Tính B * x_n
                    sub_a <= two;      // 2.0
                    sub_b <= mul_out;  // B * x_n
                    
                    state <= ITER2_2_MINUS_BX;
                end
                
                ITER2_2_MINUS_BX: begin
                    // Iteration 2: Tính 2 - B * x_n
                    mul_a <= x_n;      // x_n
                    mul_b <= sub_out;  // 2 - B * x_n
                    
                    state <= ITER2_X_NEXT;
                end
                
                ITER2_X_NEXT: begin
                    // Iteration 2: Tính x_{n+1} = x_n * (2 - B * x_n)
                    x_n <= mul_out;    // Cập nhật xấp xỉ
                    
                    // Chuẩn bị cho vòng lặp thứ ba
                    mul_a <= b_normalized;  // B chuẩn hóa
                    mul_b <= mul_out;       // x_{n+1}
                    
                    state <= ITER3_BX;
                end
                
                ITER3_BX: begin
                    // Iteration 3: Tính B * x_n
                    sub_a <= two;      // 2.0
                    sub_b <= mul_out;  // B * x_n
                    
                    state <= ITER3_2_MINUS_BX;
                end
                
                ITER3_2_MINUS_BX: begin
                    // Iteration 3: Tính 2 - B * x_n
                    mul_a <= x_n;      // x_n
                    mul_b <= sub_out;  // 2 - B * x_n
                    
                    state <= ITER3_X_NEXT;
                end
                
                ITER3_X_NEXT: begin
                    // Iteration 3: Tính x_{n+1} = x_n * (2 - B * x_n)
                    x_n <= mul_out;    // Cập nhật xấp xỉ cuối cùng
                    
                    // Chuẩn bị tính kết quả cuối cùng: A * (1/B)
                    mul_final_a <= numA_reg;  // A
                    mul_final_b <= {result_sign, result_exp, mul_out[22:0]};  // 1/B với số mũ đã điều chỉnh
                    
                    state <= CALC_RESULT;
                end
                
                CALC_RESULT: begin
                    // Gán kết quả cuối cùng
                    out_result <= mul_final_out;
                    state <= DONE;
                end
                
                DONE: begin
                    // Trạng thái cuối cùng
                    if (is_special_case) begin
                        out_result <= special_result;
                    end
                    out_stall <= 1'b0;
                    state <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule