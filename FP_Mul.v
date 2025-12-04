module FP_Mul (
    input [31:0] A, B,
    output reg [31:0] Mul_Out
);
    wire Sign_A, Sign_B, Sign;
    wire [22:0] Mantissa_A, Mantissa_B;
    wire [7:0] Exponent_A, Exponent_B;
    wire [23:0] A_m, B_m;
    wire [47:0] Out_m;
    wire [7:0] E_r;
    wire [30:0] Normalized_Out;

    // Trích xuất các trường hợp đặc biệt
    wire is_A_zero = (A[30:0] == 31'h0);
    wire is_B_zero = (B[30:0] == 31'h0);
    wire is_A_inf = (A[30:23] == 8'hFF && A[22:0] == 23'h0);
    wire is_B_inf = (B[30:23] == 8'hFF && B[22:0] == 23'h0);
    wire is_A_nan = (A[30:23] == 8'hFF && A[22:0] != 23'h0);
    wire is_B_nan = (B[30:23] == 8'hFF && B[22:0] != 23'h0);

    Floating_Seperation SD_Initialisation_Unit (
        .A(A),
        .B(B),
        .Sign_A(Sign_A),
        .Sign_B(Sign_B),
        .Mantissa_A(Mantissa_A),
        .Mantissa_B(Mantissa_B),
        .Exponent_A(Exponent_A),
        .Exponent_B(Exponent_B)
    );

    Adder_Exponent_Bias SD_Adder_Exponent_Unit (
        .E_a(Exponent_A),
        .E_b(Exponent_B),
        .E_r(E_r)
    );

    Mantissa_Normalisation SD_Mantissa_Normalisation_Unit (
        .A_In(Mantissa_A),
        .B_In(Mantissa_B),
        .A_Out(A_m),
        .B_Out(B_m)
    );

    Mantissa_Multiplier SD_Matissa_Mul_Mtiplier_Unit (
        .A_m(A_m),
        .B_m(B_m),
        .Out_m(Out_m)
    );

    Normalizer Normalizer_Unit (
        .Out_m(Out_m),
        .E_r(E_r),
        .Normalized_Out(Normalized_Out)
    );

    Sign_Unit Sign_Unit (
        .A_s(Sign_A),
        .B_s(Sign_B),
        .Sign(Sign)
    );

    // Xử lý trường hợp đặc biệt
    always @(*) begin
        if (is_A_nan || is_B_nan) begin
            // NaN * bất kỳ = NaN
            Mul_Out = 32'h7FC00000; // Canonical NaN
        end
        else if ((is_A_inf && is_B_zero) || (is_B_inf && is_A_zero)) begin
            // Inf * 0 = NaN
            Mul_Out = 32'h7FC00000;
        end
        else if (is_A_zero || is_B_zero) begin
            // 0 * bất kỳ (trừ NaN, Inf) = 0 với dấu phù hợp
            Mul_Out = {Sign, 31'h0};
        end
        else if (is_A_inf || is_B_inf) begin
            // Inf * bất kỳ (trừ 0, NaN) = Infinity với dấu phù hợp
            Mul_Out = {Sign, 8'hFF, 23'h0};
        end
        else if (Normalized_Out[30:23] == 8'hFF) begin
            // Overflow -> Infinity với dấu phù hợp
            Mul_Out = {Sign, 8'hFF, 23'h0};
        end
        else if (Normalized_Out[30:23] == 8'h0 && Normalized_Out[22:0] == 23'h0) begin
            // Kết quả là 0
            Mul_Out = {Sign, 31'h0};
        end
        else begin
            // Kết quả bình thường
            Mul_Out = {Sign, Normalized_Out};
        end
    end
endmodule