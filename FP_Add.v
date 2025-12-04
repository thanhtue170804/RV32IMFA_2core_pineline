module FP_Add (
    input [31:0] in_numA, in_numB,
    output reg [31:0] out_data
);
    // Internal registers and wires
    reg signA, signB, sign_result;
    reg [7:0] expA, expB, bigger_exp, exp_diff, normalised_exp;
    reg [23:0] mantA, mantB, aligned_A, aligned_B;
    reg [24:0] sum_mant;
    reg [7:0] shift_count;

    // Trích xuất các trường hợp đặc biệt
    wire is_A_zero = (in_numA[30:0] == 31'h0);
    wire is_B_zero = (in_numB[30:0] == 31'h0);
    wire is_A_inf = (in_numA[30:23] == 8'hFF && in_numA[22:0] == 23'h0);
    wire is_B_inf = (in_numB[30:23] == 8'hFF && in_numB[22:0] == 23'h0);
    wire is_A_nan = (in_numA[30:23] == 8'hFF && in_numA[22:0] != 23'h0);
    wire is_B_nan = (in_numB[30:23] == 8'hFF && in_numB[22:0] != 23'h0);
    wire opposite_inf = (is_A_inf && is_B_inf && (in_numA[31] != in_numB[31]));

    always @ (*) begin
        // Khởi tạo các tín hiệu
        signA = in_numA[31];
        signB = in_numB[31];
        expA = in_numA[30:23];
        expB = in_numB[30:23];
        mantA = is_A_zero ? 24'h0 : {1'b1, in_numA[22:0]};
        mantB = is_B_zero ? 24'h0 : {1'b1, in_numB[22:0]};
        aligned_A = 24'h0;
        aligned_B = 24'h0;
        sum_mant = 25'h0;
        sign_result = 1'b0;
        normalised_exp = 8'h0;
        shift_count = 8'd0;
        
        // Xử lý các trường hợp đặc biệt
        if (is_A_nan || is_B_nan || opposite_inf) begin
            // NaN hoặc Infinity trái dấu = NaN
            out_data = 32'h7FC00000; // Canonical NaN
        end
        else if (is_A_inf) begin
            // A là vô cực
            out_data = {signA, 8'hFF, 23'h0}; // Vô cực với dấu của A
        end
        else if (is_B_inf) begin
            // B là vô cực
            out_data = {signB, 8'hFF, 23'h0}; // Vô cực với dấu của B
        end
        else if (is_A_zero && is_B_zero) begin
            // Cả hai là 0
            out_data = (signA == signB) ? {signA, 31'h0} : 32'h0;
        end
        else if (is_A_zero) begin
            // Chỉ A là 0
            out_data = in_numB;
        end
        else if (is_B_zero) begin
            // Chỉ B là 0
            out_data = in_numA;
        end
        else begin
            // Xử lý trường hợp bình thường
            
            // Canh chỉnh số mũ
            if (expA > expB) begin
                bigger_exp = expA;
                exp_diff = expA - expB;
                aligned_A = mantA;
                
                // Điều chỉnh mantissa B và giữ lại bit làm tròn
                if (exp_diff > 24) begin
                    aligned_B = 24'h0; // Quá nhỏ so với A
                end else begin
                    aligned_B = mantB >> exp_diff;
                end
            end else if (expB > expA) begin
                bigger_exp = expB;
                exp_diff = expB - expA;
                aligned_B = mantB;
                
                // Điều chỉnh mantissa A và giữ lại bit làm tròn
                if (exp_diff > 24) begin
                    aligned_A = 24'h0; // Quá nhỏ so với B
                end else begin
                    aligned_A = mantA >> exp_diff;
                end
            end else begin
                // Số mũ bằng nhau
                bigger_exp = expA;
                aligned_A = mantA;
                aligned_B = mantB;
            end
            
            // Thực hiện phép tính
            if (signA == signB) begin
                // Cùng dấu -> cộng
                sum_mant = {1'b0, aligned_A} + {1'b0, aligned_B};
                sign_result = signA;
            end else begin
                // Khác dấu -> trừ
                if (aligned_A >= aligned_B) begin
                    sum_mant = {1'b0, aligned_A} - {1'b0, aligned_B};
                    sign_result = signA;
                end else begin
                    sum_mant = {1'b0, aligned_B} - {1'b0, aligned_A};
                    sign_result = signB;
                end
            end
            
            // Chuẩn hóa kết quả
            if (sum_mant == 25'h0) begin
                // Kết quả là 0
                out_data = 32'h0;
            end
            else if (sum_mant[24]) begin
                // Bit MSB là 1, cần dịch phải 1 bit
                normalised_exp = bigger_exp + 8'd1;
                
                if (normalised_exp >= 8'hFF) begin
                    // Overflow -> Infinity
                    out_data = {sign_result, 8'hFF, 23'h0};
                end else begin
                    // Lấy 23 bit mantissa
                    out_data = {sign_result, normalised_exp, sum_mant[23:1]};
                end
            end
            else if (sum_mant[23]) begin
                // Đã chuẩn hóa (bit ẩn là 1)
                out_data = {sign_result, bigger_exp, sum_mant[22:0]};
            end
            else begin
                // Leading zeros - cần dịch trái
                // Tìm bit 1 đầu tiên bằng cách kiểm tra từng bit
                if (sum_mant[22])      shift_count = 8'd1;
                else if (sum_mant[21]) shift_count = 8'd2;
                else if (sum_mant[20]) shift_count = 8'd3;
                else if (sum_mant[19]) shift_count = 8'd4;
                else if (sum_mant[18]) shift_count = 8'd5;
                else if (sum_mant[17]) shift_count = 8'd6;
                else if (sum_mant[16]) shift_count = 8'd7;
                else if (sum_mant[15]) shift_count = 8'd8;
                else if (sum_mant[14]) shift_count = 8'd9;
                else if (sum_mant[13]) shift_count = 8'd10;
                else if (sum_mant[12]) shift_count = 8'd11;
                else if (sum_mant[11]) shift_count = 8'd12;
                else if (sum_mant[10]) shift_count = 8'd13;
                else if (sum_mant[9])  shift_count = 8'd14;
                else if (sum_mant[8])  shift_count = 8'd15;
                else if (sum_mant[7])  shift_count = 8'd16;
                else if (sum_mant[6])  shift_count = 8'd17;
                else if (sum_mant[5])  shift_count = 8'd18;
                else if (sum_mant[4])  shift_count = 8'd19;
                else if (sum_mant[3])  shift_count = 8'd20;
                else if (sum_mant[2])  shift_count = 8'd21;
                else if (sum_mant[1])  shift_count = 8'd22;
                else if (sum_mant[0])  shift_count = 8'd23;
                else                   shift_count = 8'd24;
                
                if (bigger_exp <= shift_count) begin
                    // Underflow -> 0
                    out_data = {sign_result, 31'h0};
                end else begin
                    normalised_exp = bigger_exp - shift_count;
                    
                    // Dịch mantissa trái để chuẩn hóa
                    case (shift_count)
                        8'd1:  out_data = {sign_result, normalised_exp, sum_mant[21:0], 1'b0};
                        8'd2:  out_data = {sign_result, normalised_exp, sum_mant[20:0], 2'b0};
                        8'd3:  out_data = {sign_result, normalised_exp, sum_mant[19:0], 3'b0};
                        8'd4:  out_data = {sign_result, normalised_exp, sum_mant[18:0], 4'b0};
                        8'd5:  out_data = {sign_result, normalised_exp, sum_mant[17:0], 5'b0};
                        8'd6:  out_data = {sign_result, normalised_exp, sum_mant[16:0], 6'b0};
                        8'd7:  out_data = {sign_result, normalised_exp, sum_mant[15:0], 7'b0};
                        8'd8:  out_data = {sign_result, normalised_exp, sum_mant[14:0], 8'b0};
                        8'd9:  out_data = {sign_result, normalised_exp, sum_mant[13:0], 9'b0};
                        8'd10: out_data = {sign_result, normalised_exp, sum_mant[12:0], 10'b0};
                        8'd11: out_data = {sign_result, normalised_exp, sum_mant[11:0], 11'b0};
                        8'd12: out_data = {sign_result, normalised_exp, sum_mant[10:0], 12'b0};
                        8'd13: out_data = {sign_result, normalised_exp, sum_mant[9:0], 13'b0};
                        8'd14: out_data = {sign_result, normalised_exp, sum_mant[8:0], 14'b0};
                        8'd15: out_data = {sign_result, normalised_exp, sum_mant[7:0], 15'b0};
                        8'd16: out_data = {sign_result, normalised_exp, sum_mant[6:0], 16'b0};
                        8'd17: out_data = {sign_result, normalised_exp, sum_mant[5:0], 17'b0};
                        8'd18: out_data = {sign_result, normalised_exp, sum_mant[4:0], 18'b0};
                        8'd19: out_data = {sign_result, normalised_exp, sum_mant[3:0], 19'b0};
                        8'd20: out_data = {sign_result, normalised_exp, sum_mant[2:0], 20'b0};
                        8'd21: out_data = {sign_result, normalised_exp, sum_mant[1:0], 21'b0};
                        8'd22: out_data = {sign_result, normalised_exp, sum_mant[0], 22'b0};
                        default: out_data = {sign_result, normalised_exp, 23'b0};
                    endcase
                end
            end
        end
    end
endmodule