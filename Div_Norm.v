module Div_Norm (
    input [7:0] in_Exp,
    input [23:0] in_Mant,
    output reg [7:0] out_Exp,
    output reg [23:0] out_Mant
);
    always @(*) begin
        if (in_Mant == 24'h0) begin
            out_Exp = 8'h0;
            out_Mant = 24'h0;
        end else begin
            casez (in_Mant)
                24'b1???????????????????????: begin out_Exp = in_Exp;        out_Mant = in_Mant;        end
                24'b01??????????????????????: begin out_Exp = in_Exp - 8'd1;  out_Mant = in_Mant << 1;  end
                24'b001?????????????????????: begin out_Exp = in_Exp - 8'd2;  out_Mant = in_Mant << 2;  end
                24'b0001????????????????????: begin out_Exp = in_Exp - 8'd3;  out_Mant = in_Mant << 3;  end
                24'b00001???????????????????: begin out_Exp = in_Exp - 8'd4;  out_Mant = in_Mant << 4;  end
                24'b000001??????????????????: begin out_Exp = in_Exp - 8'd5;  out_Mant = in_Mant << 5;  end
                24'b0000001?????????????????: begin out_Exp = in_Exp - 8'd6;  out_Mant = in_Mant << 6;  end
                24'b00000001????????????????: begin out_Exp = in_Exp - 8'd7;  out_Mant = in_Mant << 7;  end
                24'b000000001???????????????: begin out_Exp = in_Exp - 8'd8;  out_Mant = in_Mant << 8;  end
                24'b0000000001??????????????: begin out_Exp = in_Exp - 8'd9;  out_Mant = in_Mant << 9;  end
                24'b00000000001?????????????: begin out_Exp = in_Exp - 8'd10; out_Mant = in_Mant << 10; end
                24'b000000000001????????????: begin out_Exp = in_Exp - 8'd11; out_Mant = in_Mant << 11; end
                24'b0000000000001???????????: begin out_Exp = in_Exp - 8'd12; out_Mant = in_Mant << 12; end
                24'b00000000000001??????????: begin out_Exp = in_Exp - 8'd13; out_Mant = in_Mant << 13; end
                24'b000000000000001?????????: begin out_Exp = in_Exp - 8'd14; out_Mant = in_Mant << 14; end
                24'b0000000000000001????????: begin out_Exp = in_Exp - 8'd15; out_Mant = in_Mant << 15; end
                24'b00000000000000001???????: begin out_Exp = in_Exp - 8'd16; out_Mant = in_Mant << 16; end
                24'b000000000000000001??????: begin out_Exp = in_Exp - 8'd17; out_Mant = in_Mant << 17; end
                24'b0000000000000000001?????: begin out_Exp = in_Exp - 8'd18; out_Mant = in_Mant << 18; end
                24'b00000000000000000001????: begin out_Exp = in_Exp - 8'd19; out_Mant = in_Mant << 19; end
                24'b000000000000000000001???: begin out_Exp = in_Exp - 8'd20; out_Mant = in_Mant << 20; end
                24'b0000000000000000000001??: begin out_Exp = in_Exp - 8'd21; out_Mant = in_Mant << 21; end
                24'b00000000000000000000001?: begin out_Exp = in_Exp - 8'd22; out_Mant = in_Mant << 22; end
                24'b00000000000000000000000?: begin out_Exp = in_Exp - 8'd23; out_Mant = in_Mant << 23; end
                default: begin out_Exp = in_Exp - 8'd24; out_Mant = in_Mant << 24; end
            endcase
        end
    end
endmodule