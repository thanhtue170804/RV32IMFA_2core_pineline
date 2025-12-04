module hazard_unit(
    // ====== Tín hiệu điều khiển ======
    input rst,               // Reset (active low)

    // ====== Integer pipeline ======
    input RegWriteM,         // Giai đoạn Memory (integer)
    input RegWriteW,         // Giai đoạn Writeback (integer)
    input [4:0] RD_M,        // Thanh ghi đích (Memory)
    input [4:0] RD_W,        // Thanh ghi đích (Writeback)
    input [4:0] Rs1_E,       // Nguồn 1 (Execute)
    input [4:0] Rs2_E,       // Nguồn 2 (Execute)
    output [1:0] ForwardAE,  // Chuyển tiếp toán hạng A (integer)
    output [1:0] ForwardBE,  // Chuyển tiếp toán hạng B (integer)

    // ====== Floating-point pipeline ======
    input FPRegWriteM,       // Cho phép ghi FP ở Memory
    input FPRegWriteW,       // Cho phép ghi FP ở Writeback
    input [4:0] FP_RD_M,     // FP dest register ở Memory
    input [4:0] FP_RD_W,     // FP dest register ở Writeback
    input [4:0] FP_RS1_E,    // FP source 1 ở Execute
    input [4:0] FP_RS2_E,    // FP source 2 ở Execute
    output [1:0] FP_ForwardAE, // FP chuyển tiếp toán hạng A
    output [1:0] FP_ForwardBE  // FP chuyển tiếp toán hạng B
);

    // ====== Forwarding cho pipeline Integer ======
    assign ForwardAE = 
        (rst == 1'b0) ? 2'b00 :
        ((RegWriteM == 1'b1) &&
         (RD_M != 5'h00) &&
         (RD_M == Rs1_E)) ? 2'b10 :
        ((RegWriteW == 1'b1) &&
         (RD_W != 5'h00) &&
         (RD_W == Rs1_E)) ? 2'b01 :
        2'b00;

    assign ForwardBE = 
        (rst == 1'b0) ? 2'b00 :
        ((RegWriteM == 1'b1) &&
         (RD_M != 5'h00) &&
         (RD_M == Rs2_E)) ? 2'b10 :
        ((RegWriteW == 1'b1) &&
         (RD_W != 5'h00) &&
         (RD_W == Rs2_E)) ? 2'b01 :
        2'b00;

    // ====== Forwarding cho pipeline Floating-point ======
    assign FP_ForwardAE =
        (rst == 1'b0) ? 2'b00 :
        ((FPRegWriteM == 1'b1) &&
         (FP_RD_M != 5'h00) &&
         (FP_RD_M == FP_RS1_E)) ? 2'b10 :
        ((FPRegWriteW == 1'b1) &&
         (FP_RD_W != 5'h00) &&
         (FP_RD_W == FP_RS1_E)) ? 2'b01 :
        2'b00;

    assign FP_ForwardBE =
        (rst == 1'b0) ? 2'b00 :
        ((FPRegWriteM == 1'b1) &&
         (FP_RD_M != 5'h00) &&
         (FP_RD_M == FP_RS2_E)) ? 2'b10 :
        ((FPRegWriteW == 1'b1) &&
         (FP_RD_W != 5'h00) &&
         (FP_RD_W == FP_RS2_E)) ? 2'b01 :
        2'b00;

endmodule
