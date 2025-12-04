module Normalizer (
    input [47:0] Out_m,
    input [7:0] E_r,
    output reg [30:0] Normalized_Out
);
    reg [7:0] normalized_exp;
    reg [22:0] normalized_mant;
    reg [7:0] shift_count;
    reg [47:0] shifted_mant;
    wire guard, round, sticky;

    // Tính các bit làm tròn
    assign guard = Out_m[22]; // Bit ngay sau mantissa
    assign round = Out_m[21]; // Bit tiếp theo
    assign sticky = |Out_m[20:0]; // OR của tất cả các bit còn lại

    always @(*) begin
        // Khởi tạo giá trị mặc định
        normalized_exp = 8'd0;
        normalized_mant = 23'd0;
        shift_count = 8'd0;
        shifted_mant = 48'd0;
        
        if (Out_m == 48'h0) begin
            // Nếu kết quả nhân là 0, trả về 0
            normalized_exp = 8'd0;
            normalized_mant = 23'd0;
        end else begin
            // Tìm vị trí bit 1 cao nhất trong kết quả nhân
            if (Out_m[47])      begin shift_count = 8'd47; end
            else if (Out_m[46]) begin shift_count = 8'd46; end
            else if (Out_m[45]) begin shift_count = 8'd45; end
            else if (Out_m[44]) begin shift_count = 8'd44; end
            else if (Out_m[43]) begin shift_count = 8'd43; end
            else if (Out_m[42]) begin shift_count = 8'd42; end
            else if (Out_m[41]) begin shift_count = 8'd41; end
            else if (Out_m[40]) begin shift_count = 8'd40; end
            else if (Out_m[39]) begin shift_count = 8'd39; end
            else if (Out_m[38]) begin shift_count = 8'd38; end
            else if (Out_m[37]) begin shift_count = 8'd37; end
            else if (Out_m[36]) begin shift_count = 8'd36; end
            else if (Out_m[35]) begin shift_count = 8'd35; end
            else if (Out_m[34]) begin shift_count = 8'd34; end
            else if (Out_m[33]) begin shift_count = 8'd33; end
            else if (Out_m[32]) begin shift_count = 8'd32; end
            else if (Out_m[31]) begin shift_count = 8'd31; end
            else if (Out_m[30]) begin shift_count = 8'd30; end
            else if (Out_m[29]) begin shift_count = 8'd29; end
            else if (Out_m[28]) begin shift_count = 8'd28; end
            else if (Out_m[27]) begin shift_count = 8'd27; end
            else if (Out_m[26]) begin shift_count = 8'd26; end
            else if (Out_m[25]) begin shift_count = 8'd25; end
            else if (Out_m[24]) begin shift_count = 8'd24; end
            else if (Out_m[23]) begin shift_count = 8'd23; end
            else if (Out_m[22]) begin shift_count = 8'd22; end
            else if (Out_m[21]) begin shift_count = 8'd21; end
            else if (Out_m[20]) begin shift_count = 8'd20; end
            else if (Out_m[19]) begin shift_count = 8'd19; end
            else if (Out_m[18]) begin shift_count = 8'd18; end
            else if (Out_m[17]) begin shift_count = 8'd17; end
            else if (Out_m[16]) begin shift_count = 8'd16; end
            else if (Out_m[15]) begin shift_count = 8'd15; end
            else if (Out_m[14]) begin shift_count = 8'd14; end
            else if (Out_m[13]) begin shift_count = 8'd13; end
            else if (Out_m[12]) begin shift_count = 8'd12; end
            else if (Out_m[11]) begin shift_count = 8'd11; end
            else if (Out_m[10]) begin shift_count = 8'd10; end
            else if (Out_m[9])  begin shift_count = 8'd9;  end
            else if (Out_m[8])  begin shift_count = 8'd8;  end
            else if (Out_m[7])  begin shift_count = 8'd7;  end
            else if (Out_m[6])  begin shift_count = 8'd6;  end
            else if (Out_m[5])  begin shift_count = 8'd5;  end
            else if (Out_m[4])  begin shift_count = 8'd4;  end
            else if (Out_m[3])  begin shift_count = 8'd3;  end
            else if (Out_m[2])  begin shift_count = 8'd2;  end
            else if (Out_m[1])  begin shift_count = 8'd1;  end
            else                begin shift_count = 8'd0;  end

            // Chuẩn hóa dựa trên vị trí bit 1 cao nhất
            if (shift_count == 8'd47) begin
                // Bit 47 là 1, cần dịch phải 1 bit
                normalized_mant = Out_m[46:24];
                normalized_exp = (E_r >= 8'hFE) ? 8'hFF : (E_r + 8'd1);
            end
            else if (shift_count == 8'd46) begin
                // Bit 46 là 1, đã chuẩn hóa
                normalized_mant = Out_m[45:23];
                normalized_exp = E_r;
            end
            else if (shift_count >= 8'd23) begin
                // Bit 1 cao nhất nằm giữa vị trí 23 và 45, cần dịch phải
                normalized_mant = Out_m >> (8'd46 - shift_count);
                normalized_exp = (E_r <= (8'd46 - shift_count)) ? 8'h0 : (E_r - (8'd46 - shift_count));
            end
            else begin
                // Bit 1 cao nhất nằm dưới vị trí 23, cần dịch trái
                normalized_mant = Out_m << (8'd23 - shift_count);
                normalized_exp = (E_r <= (8'd23 - shift_count)) ? 8'h0 : (E_r - (8'd23 - shift_count));
            end

            // Xử lý trường hợp đặc biệt cho underflow/overflow
            if (normalized_exp == 8'h0 && normalized_mant != 23'h0) begin
                // Số không chuẩn (denormal)
                normalized_exp = 8'h0;
            end
            else if (normalized_exp >= 8'hFF) begin
                // Overflow -> Infinity
                normalized_exp = 8'hFF;
                normalized_mant = 23'h0;
            end
        end

        // Kết hợp exponent và mantissa
        Normalized_Out = {normalized_exp, normalized_mant};
    end
endmodule