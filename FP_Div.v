

module FP_Div (
    input in_Clk, in_Rst_N, in_start,
    input [31:0] in_numA, in_numB,
    output reg out_stall,
    output reg [31:0] out_result
);
    // State machine for Newton-Raphson division
    localparam IDLE = 2'd0;
    localparam COMPUTE = 2'd1;
    localparam WAIT = 2'd2;
    localparam DONE = 2'd3;
    
    reg [1:0] state;
    reg [1:0] wait_count;
    
    // Extract IEEE 754 components
    wire sign_A = in_numA[31];
    wire sign_B = in_numB[31];
    wire [7:0] exp_A = in_numA[30:23];
    wire [7:0] exp_B = in_numB[30:23];
    wire [22:0] frac_A = in_numA[22:0];
    wire [22:0] frac_B = in_numB[22:0];
    
    // Special case detection
    wire A_is_zero = (exp_A == 8'h00 && frac_A == 23'h0);
    wire B_is_zero = (exp_B == 8'h00 && frac_B == 23'h0);
    wire A_is_inf = (exp_A == 8'hFF && frac_A == 23'h0);
    wire B_is_inf = (exp_B == 8'hFF && frac_B == 23'h0);
    wire A_is_nan = (exp_A == 8'hFF && frac_A != 23'h0);
    wire B_is_nan = (exp_B == 8'hFF && frac_B != 23'h0);
    
    // Result sign
    wire result_sign = (A_is_zero && B_is_zero) ? 1'b0 : (A_is_zero && !B_is_zero) ? 1'b0 : (sign_A ^ sign_B);
    
    // Special case results
    wire [31:0] special_result = 
        (A_is_nan || B_is_nan) ? 32'h7FC00000 :
        (A_is_zero && B_is_zero) ? 32'h7FC00000 :  // 0/0 = NaN
        (A_is_inf && B_is_inf) ? 32'h7FC00000 :    // Inf/Inf = NaN
        (B_is_zero && !A_is_zero) ? {result_sign, 8'hFF, 23'h0} :  // x/0 = Inf
        (A_is_inf && !B_is_inf) ? {result_sign, 8'hFF, 23'h0} :    // Inf/x = Inf
        (B_is_inf && !A_is_inf) ? {result_sign, 31'h0} :           // x/Inf = 0
        (A_is_zero && !B_is_zero) ? {1'b0, 31'h0} :                // 0/x = +0
        32'h7FC00000;
    
    // Check if we need special handling
    wire use_special = A_is_zero || B_is_zero || A_is_inf || B_is_inf || 
                      A_is_nan || B_is_nan;
    
    // Combinational Newton-Raphson computation
    wire [7:0] shift = (exp_B == 8'h00) ? 8'd0 : (exp_B < 8'd127) ? 8'd127 - exp_B : exp_B - 8'd126;
    wire [31:0] divisor = (exp_B == 8'h00) ? {1'b0, 8'h00, frac_B} : {1'b0, 8'd126, frac_B};
    wire [7:0] exponent_a = (exp_B == 8'h00) ? exp_A : (exp_A >= shift) ? exp_A - shift : 8'h00;
    wire [31:0] operand_a = (exp_B == 8'h00) ? {sign_A, 8'h00, frac_A} : {sign_A, exponent_a, frac_A};
    wire [7:0] norm_exp = (exp_B == 8'h00) ? 8'h7E : exp_B - 8'd1;
    wire [31:0] adjusted_divisor = (exp_B == 8'h00 || exp_B < 8'd100) ? {1'b0, norm_exp, 1'b1, frac_B[22:1]} : divisor;
    
    // Newton-Raphson iterations (combinational)
    wire [31:0] x0_mult_out;
    wire [31:0] x0_add_out;
    wire [31:0] iter1_out;
    wire [31:0] iter2_out;
    wire [31:0] iter3_out;
    wire [31:0] iter4_out;
    wire [31:0] final_mult_out;
    
    // Initial approximation
    FP_Mul x0_mult (
        .A(32'hC00B_4B4B),  // -37/17
        .B(adjusted_divisor),
        .Mul_Out(x0_mult_out)
    );
    
    FP_Add x0_add (
        .in_numA(x0_mult_out),
        .in_numB(32'h4034_B4B5),  // 48/17  
        .out_data(x0_add_out)
    );
    
    // Clamp x0 to ensure valid range
    wire [31:0] clamped_x0 = 
        (x0_add_out[30:23] == 8'hFF) ? {1'b0, 8'h7E, x0_add_out[22:0]} : // Prevent overflow
        (x0_add_out[30:23] == 8'h00) ? {1'b0, 8'h7F, x0_add_out[22:0]} : // Prevent underflow
        {1'b0, x0_add_out[30:0]}; // Force positive
    
    // Iteration 1
    NR_Iteration iter1 (
        .x_n(clamped_x0),
        .divisor(adjusted_divisor),
        .x_n_plus_1(iter1_out)
    );
    
    // Iteration 2
    NR_Iteration iter2 (
        .x_n(iter1_out),
        .divisor(adjusted_divisor),
        .x_n_plus_1(iter2_out)
    );
    
    // Iteration 3
    NR_Iteration iter3 (
        .x_n(iter2_out),
        .divisor(adjusted_divisor),
        .x_n_plus_1(iter3_out)
    );
    
    // Iteration 4
    NR_Iteration iter4 (
        .x_n(iter3_out),
        .divisor(adjusted_divisor),
        .x_n_plus_1(iter4_out)
    );
    
    // Final multiplication
    FP_Mul final_mult (
        .A(iter4_out),
        .B(operand_a),
        .Mul_Out(final_mult_out)
    );
    
    // Normalize final multiplication result with IEEE 754 rounding
    wire [24:0] extended_mantissa = {1'b1, final_mult_out[22:0], 1'b0}; // Thêm guard bit
    wire round_up = extended_mantissa[1] & (extended_mantissa[0] | |extended_mantissa[24:2]);
    wire [22:0] rounded_mantissa = final_mult_out[22:0] + (round_up ? 1'b1 : 1'b0);
    wire [7:0] rounded_exp = final_mult_out[30:23] + (round_up && final_mult_out[22:0] == 23'h7FFFFF ? 1'b1 : 1'b0);
    wire [31:0] normalized_final_mult = 
        (final_mult_out[30:23] == 8'hFF && final_mult_out[22:0] != 23'h0) ? 32'h7FC00000 : // NaN
        (final_mult_out[30:23] == 8'hFF) ? {result_sign, 8'hFF, 23'h0} : // Infinity
        (final_mult_out[30:23] == 8'h00 && final_mult_out[22:0] != 23'h0) ? {result_sign, 8'h00, final_mult_out[22:0]} : // Denormal
        {result_sign, rounded_exp, rounded_mantissa};
    
    // Final result
    wire [31:0] newton_result = {result_sign, normalized_final_mult[30:0]};
    wire [31:0] final_result = use_special ? special_result : newton_result;
    
    // State machine
    always @(posedge in_Clk or negedge in_Rst_N) begin
        if (!in_Rst_N) begin
            state <= IDLE;
            out_stall <= 1'b0;
            out_result <= 32'h0;
            wait_count <= 2'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (in_start) begin
                        out_stall <= 1'b1;
                        state <= COMPUTE;
                    end else begin
                        out_stall <= 1'b0;
                    end
                end
                COMPUTE: begin
                    state <= WAIT;
                    wait_count <= 2'd0;
                end
                WAIT: begin
                    if (wait_count == 2'd1) begin
                        out_result <= final_result;
                        state <= DONE;
                    end else begin
                        wait_count <= wait_count + 1;
                    end
                end
                DONE: begin
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