module hazard_control (
    input rst,                     // Reset (active low)
    
    // ======= Integer pipeline =======
    input PCSrcE,                  // Tín hiệu nhảy từ Execute
    input ResultSrcE,              // Tín hiệu nhận diện lệnh load integer
    input [4:0] RD_E,              // Thanh ghi đích (Execute)
    input [4:0] RS1_D,             // Thanh ghi nguồn 1 (Decode)
    input [4:0] RS2_D,             // Thanh ghi nguồn 2 (Decode)

    // ======= Floating-point pipeline =======
    input FPResultSrcE,            // Tín hiệu nhận diện lệnh load FP
    input [4:0] FP_RD_E,           // Thanh ghi đích FP (Execute)
    input [4:0] FP_RS1_D,          // Thanh ghi nguồn FP 1 (Decode)
    input [4:0] FP_RS2_D,          // Thanh ghi nguồn FP 2 (Decode)

    // ======= Stall signals =======
    output reg StallF,
    output reg StallD,
    output reg StallE,
    output reg StallM,
    output reg StallW,

    // ======= Flush signals =======
    output reg FlushD,
    output reg FlushE,
    output reg FlushM,
    output reg FlushW,

    // ======= Hazard indicators =======
    output reg lwStall,            // Load-use hazard (integer)
    output reg f_lwStall,          // Load-use hazard (floating point)
    output reg branchStall         // Branch hazard
);
    always @(*) begin
        if (!rst) begin
            lwStall      = 1'b0;
            f_lwStall    = 1'b0;
            branchStall  = 1'b0;
            StallF       = 1'b0;
            StallD       = 1'b0;
            StallE       = 1'b0;
            StallM       = 1'b0;
            StallW       = 1'b0;
            FlushD       = 1'b0;
            FlushE       = 1'b0;
            FlushM       = 1'b0;
            FlushW       = 1'b0;
        end else begin
            // ===== Integer load-use hazard =====
            lwStall = ResultSrcE && (RD_E != 5'b0) && 
                      ((RD_E == RS1_D) || (RD_E == RS2_D));

            // ===== Floating-point load-use hazard =====
            f_lwStall = FPResultSrcE && (FP_RD_E != 5'b0) &&
                        ((FP_RD_E == FP_RS1_D) || (FP_RD_E == FP_RS2_D));

            // ===== Branch hazard =====
            branchStall = PCSrcE;

            // ===== Stall logic =====
            StallF = lwStall || f_lwStall;
            StallD = lwStall || f_lwStall;
            StallE = 1'b0;
            StallM = 1'b0;
            StallW = 1'b0;

            // ===== Flush logic =====
            FlushD = branchStall;
            FlushE = branchStall;
            FlushM = 1'b0;
            FlushW = 1'b0;
        end
    end
endmodule
