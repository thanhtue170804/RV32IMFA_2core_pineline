module Inverse (
    input wire clk,
    input wire reset_n,
    input wire start,
    input wire [31:0] b,           // Số chia (IEEE 754)
    output reg [31:0] inv_b,       // Nghịch đảo (1/b, IEEE 754)
    output reg done
);
    reg [2:0] state;               // Trạng thái: 0=idle, 1=init, 2=iter1, 3=iter2, 4=iter3, 5=wait, 6=done
    reg [31:0] x;                  // Giá trị lặp (x_n)
    wire [31:0] prod, two_minus_bx;// Kết quả nhân và 2 - b*x_n
    wire [31:0] lut_out;           // Giá trị khởi tạo từ LUT

    // Bảng tra cứu (LUT) cho x_0
    reg [31:0] lut [0:15];
    initial begin
        lut[0]  = 32'h3F800000; // x_0 = 1.0       (b = 1.0)
        lut[1]  = 32'h3F70F0F1; // x_0 ≈ 0.941176  (b = 1.0625)
        lut[2]  = 32'h3F638E39; // x_0 ≈ 0.888889  (b = 1.125)
        lut[3]  = 32'h3F57CED9; // x_0 ≈ 0.842105  (b = 1.1875)
        lut[4]  = 32'h3F4CCCCD; // x_0 = 0.8       (b = 1.25)
        lut[5]  = 32'h3F428F5C; // x_0 ≈ 0.761905  (b = 1.3125)
        lut[6]  = 32'h3F3A2E8C; // x_0 ≈ 0.727273  (b = 1.375)
        lut[7]  = 32'h3F31A92A; // x_0 ≈ 0.695652  (b = 1.4375)
        lut[8]  = 32'h3F2AAAAA; // x_0 ≈ 0.666667  (b = 1.5)
        lut[9]  = 32'h3F23D70A; // x_0 = 0.64      (b = 1.5625)
        lut[10] = 32'h3F1D89D9; // x_0 ≈ 0.615385  (b = 1.625)
        lut[11] = 32'h3F17B426; // x_0 ≈ 0.592593  (b = 1.6875)
        lut[12] = 32'h3F124925; // x_0 ≈ 0.571429  (b = 1.75)
        lut[13] = 32'h3F0D3DCB; // x_0 ≈ 0.551724  (b = 1.8125)
        lut[14] = 32'h3F088889; // x_0 ≈ 0.533333  (b = 1.875)
        lut[15] = 32'h3F041893; // x_0 ≈ 0.516129  (b = 1.9375)
    end

    // Lấy x_0 từ LUT hoặc xử lý trường hợp đặc biệt
    assign lut_out = (b[30:23] == 8'hFF) ? 32'h00000000 : // b = Inf hoặc NaN -> 0
                     (b[30:0] == 31'h0) ? 32'h7f800000 : // b = 0 -> Inf
                     lut[b[22:19]];                       // Bình thường

    // Nhân b * x_n
    FP_Mul mul_inst1 (
        .A(b),
        .B(x),
        .Mul_Out(prod)
    );

    // Tính 2 - b*x_n bằng phép trừ
    wire sign_prod, sign_two;
    wire [7:0] exp_prod, exp_two;
    wire [22:0] mant_prod, mant_two;
    Floating_Seperation sep (
        .A(prod),
        .B(32'h40000000), // 2.0
        .Sign_A(sign_prod),
        .Sign_B(sign_two),
        .Exponent_A(exp_prod),
        .Exponent_B(exp_two),
        .Mantissa_A(mant_prod),
        .Mantissa_B(mant_two)
    );

    wire [7:0] exp_diff;
    Sub_Exponent_Bias sub_exp (
        .E_a(exp_two),
        .E_b(exp_prod),
        .E_r(exp_diff)
    );

    wire [23:0] mant_two_norm = {1'b1, mant_two};
    wire [23:0] mant_prod_norm = {1'b1, mant_prod};
    wire [24:0] mant_result = mant_two_norm - (mant_prod_norm >> (exp_two > exp_prod ? exp_two - exp_prod : 0));
    assign two_minus_bx = {sign_two, exp_diff, mant_result[22:0]};

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= 3'b000;
            x <= 32'h0;
            inv_b <= 32'h0;
            done <= 1'b0;
        end else begin
            case (state)
                3'b000: begin // Idle
                    if (start) begin
                        x <= lut_out;
                        inv_b <= (b[30:23] == 8'hFF || b[30:0] == 31'h0) ? lut_out : 32'h0;
                        state <= (b[30:23] == 8'hFF || b[30:0] == 31'h0) ? 3'b101 : 3'b001;
                        done <= 1'b0;
                    end
                end
                3'b001: begin // Lần lặp 1
                    x <= two_minus_bx;
                    state <= 3'b010;
                end
                3'b010: begin // Lần lặp 2
                    x <= two_minus_bx;
                    state <= 3'b011;
                end
                3'b011: begin // Lần lặp 3
                    x <= two_minus_bx;
                    state <= 3'b100;
                end
                3'b100: begin // Ghi kết quả
                    inv_b <= x;
                    state <= 3'b101;
                end
                3'b101: begin // Chờ
                    state <= 3'b110;
                end
                3'b110: begin // Hoàn thành
                    done <= 1'b1;
                    state <= 3'b000;
                end
                default: begin
                    state <= 3'b000;
                    done <= 1'b0;
                end
            endcase
        end
    end
endmodule