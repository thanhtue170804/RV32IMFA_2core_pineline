module Reciprocal (
    input wire clk,
    input wire reset_n,
    input wire start,
    input wire [31:0] fp_input,  // B (IEEE-754 single precision)
    output reg [31:0] fp_output, // 1/B (IEEE-754 single precision)
    output reg done
);
    // Số lượng vòng lặp Newton-Raphson
    parameter ITERATIONS = 3;
    
    // Các trạng thái
    localparam IDLE = 3'd0;
    localparam INIT = 3'd1;
    localparam ITERATE = 3'd2;
    localparam FINALIZE = 3'd3;
    localparam DONE_STATE = 3'd4;
    
    reg [2:0] state;
    reg [2:0] iteration_count;
    
    // Các giá trị trung gian
    reg [31:0] x;                  // Giá trị xấp xỉ hiện tại (x_n)
    reg [31:0] two = 32'h40000000; // Hằng số 2.0
    wire [31:0] b_times_x;         // b * x_n
    wire [31:0] two_minus_bx;      // 2 - b * x_n
    wire [31:0] x_times_factor;    // x_n * (2 - b * x_n)
    
    // Các thanh ghi cho phép nhân và trừ
    reg [31:0] mult_a, mult_b;
    reg [31:0] sub_a, sub_b;
    
    // Kết quả từ các phép toán
    wire [31:0] mult_result;
    wire [31:0] sub_result;
    
    // Dấu và số mũ của kết quả cuối
    wire result_sign = fp_input[31];  // Dấu không đổi
    wire [7:0] result_exp;
    
    // Tính toán số mũ cho nghịch đảo: 254 - fp_input[30:23]
    // 254 = 2*127 (bias kép)
    assign result_exp = (fp_input[30:23] == 8'h0) ? 8'hFF :  // 1/denorm = Infinity
                       (fp_input[30:23] == 8'hFF) ? 8'h0 :  // 1/Infinity = 0
                       (8'd254 - fp_input[30:23]);
    
    // Tạo giá trị xấp xỉ ban đầu (x0) dựa trên bảng tra cứu
    function [31:0] get_initial_approx;
        input [22:0] mantissa;
        begin
            // Lấy 4 bit MSB của mantissa để tra cứu
            case(mantissa[22:19])
                4'b0000: get_initial_approx = 32'h3F800000;  // x_0 = 1.0      (b ≈ 1.0)
                4'b0001: get_initial_approx = 32'h3F7C0000;  // x_0 ≈ 0.97     (b ≈ 1.03)
                4'b0010: get_initial_approx = 32'h3F780000;  // x_0 ≈ 0.94     (b ≈ 1.06)
                4'b0011: get_initial_approx = 32'h3F740000;  // x_0 ≈ 0.91     (b ≈ 1.09)
                4'b0100: get_initial_approx = 32'h3F700000;  // x_0 ≈ 0.88     (b ≈ 1.13)
                4'b0101: get_initial_approx = 32'h3F6C0000;  // x_0 ≈ 0.85     (b ≈ 1.16)
                4'b0110: get_initial_approx = 32'h3F680000;  // x_0 ≈ 0.82     (b ≈ 1.19)
                4'b0111: get_initial_approx = 32'h3F640000;  // x_0 ≈ 0.79     (b ≈ 1.22)
                4'b1000: get_initial_approx = 32'h3F600000;  // x_0 ≈ 0.75     (b ≈ 1.25)
                4'b1001: get_initial_approx = 32'h3F5C0000;  // x_0 ≈ 0.72     (b ≈ 1.28)
                4'b1010: get_initial_approx = 32'h3F580000;  // x_0 ≈ 0.69     (b ≈ 1.31)
                4'b1011: get_initial_approx = 32'h3F540000;  // x_0 ≈ 0.66     (b ≈ 1.34)
                4'b1100: get_initial_approx = 32'h3F500000;  // x_0 ≈ 0.63     (b ≈ 1.38)
                4'b1101: get_initial_approx = 32'h3F4C0000;  // x_0 ≈ 0.60     (b ≈ 1.41)
                4'b1110: get_initial_approx = 32'h3F480000;  // x_0 ≈ 0.56     (b ≈ 1.44)
                4'b1111: get_initial_approx = 32'h3F440000;  // x_0 ≈ 0.53     (b ≈ 1.47)
            endcase
        end
    endfunction
    
    // Normalize input to [1,2) range for Newton-Raphson method
    // We only need the mantissa for iterations, exponent is handled separately
    wire [31:0] normalized_input = {fp_input[31], 8'h7F, fp_input[22:0]};
    
    // Instantiate multiplier and subtractor
    FP_Mul multiplier (
        .A(mult_a),
        .B(mult_b),
        .Mul_Out(mult_result)
    );
    
    FP_Sub subtractor (
        .in_numA(sub_a),
        .in_numB(sub_b),
        .out_data(sub_result)
    );
    
    // State machine for Newton-Raphson iteration
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            iteration_count <= 3'd0;
            x <= 32'h0;
            fp_output <= 32'h0;
            done <= 1'b0;
            mult_a <= 32'h0;
            mult_b <= 32'h0;
            sub_a <= 32'h0;
            sub_b <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        // Handle special cases
                        if (fp_input[30:0] == 31'h0) begin
                            // 1/0 = Infinity
                            fp_output <= {result_sign, 8'hFF, 23'h0};
                            state <= DONE_STATE;
                        end else if (fp_input[30:23] == 8'hFF) begin
                            // 1/Infinity = 0, 1/NaN = NaN
                            fp_output <= (fp_input[22:0] == 23'h0) ? 
                                        {result_sign, 31'h0} :        // 1/Infinity = 0
                                        {1'b0, 8'hFF, 23'h400000};    // 1/NaN = NaN
                            state <= DONE_STATE;
                        end else begin
                            // Normal case - start Newton-Raphson
                            x <= get_initial_approx(fp_input[22:0]);
                            state <= INIT;
                            iteration_count <= 3'd0;
                        end
                    end
                end
                
                INIT: begin
                    // Set up for first iteration: calculate b * x_n
                    mult_a <= normalized_input;  // Use normalized input for iterations
                    mult_b <= x;
                    state <= ITERATE;
                end
                
                ITERATE: begin
                    // Newton-Raphson iterations: x_n+1 = x_n * (2 - b * x_n)
                    if (iteration_count[0] == 1'b0) begin
                        // Even iterations: calculate (2 - b * x_n)
                        sub_a <= two;
                        sub_b <= mult_result;
                        iteration_count <= iteration_count + 3'd1;
                    end else begin
                        // Odd iterations: calculate x_n * (2 - b * x_n)
                        mult_a <= x;
                        mult_b <= sub_result;
                        
                        // Update x for next iteration
                        x <= mult_result;
                        
                        iteration_count <= iteration_count + 3'd1;
                        
                        // Check if we've completed all iterations
                        if (iteration_count >= (ITERATIONS * 2 - 1)) begin
                            state <= FINALIZE;
                        end else if (iteration_count[0] == 1'b1) begin
                            // Set up for next iteration
                            mult_a <= normalized_input;
                            mult_b <= mult_result;
                        end
                    end
                end
                
                FINALIZE: begin
                    // Apply correct exponent to the final result
                    fp_output <= {result_sign, result_exp, x[22:0]};
                    state <= DONE_STATE;
                end
                
                DONE_STATE: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule