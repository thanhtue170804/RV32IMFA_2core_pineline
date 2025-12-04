module Mantissa_Multiplier (
    input  [23:0] A_m,
    input  [23:0] B_m,
    output [47:0] Out_m
);
    // Nhân 2 số 24-bit, kết quả là 48-bit
    assign Out_m = A_m * B_m;
    
endmodule
