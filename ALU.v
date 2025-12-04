// ALU_rv32im.v
// ALU mở rộng cho RV32I + M-extension
// ALUControl: 5-bit (mã do ALU_Decoder cung cấp)
module ALU(
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [4:0]  ALUControl,   // 5-bit code từ ALU decoder

    output wire        Carry,        // carry-out (unsigned, meaningful for ADD/SUB)
    output wire        OverFlow,     // overflow (signed, meaningful cho ADD/SUB)
    output wire        Zero,
    output wire        Negative,
    output wire [31:0] Result
);

    // ----- ALUControl encoding (phù hợp với ALU_Decoder phải sinh ra) -----
    localparam ALU_ADD     = 5'b00000;
    localparam ALU_SUB     = 5'b00001;
    localparam ALU_SLL     = 5'b00010;
    localparam ALU_SLT     = 5'b00011;
    localparam ALU_SLTU    = 5'b00100;
    localparam ALU_XOR     = 5'b00101;
    localparam ALU_SRL     = 5'b00110;
    localparam ALU_SRA     = 5'b00111;
    localparam ALU_OR      = 5'b01000;
    localparam ALU_AND     = 5'b01001;

    // M-extension codes (5-bit)
    localparam ALU_MUL     = 5'b10000; // MUL   -> low 32 bits of (rs1*rs2) signed*signed
    localparam ALU_MULH    = 5'b10001; // MULH  -> high 32 bits of (rs1*rs2) signed*signed
    localparam ALU_MULHSU  = 5'b10010; // MULHSU-> high 32 bits of (rs1_signed * rs2_unsigned)
    localparam ALU_MULHU   = 5'b10011; // MULHU -> high 32 bits of (rs1*rs2) unsigned*unsigned
    localparam ALU_DIV     = 5'b10100; // DIV   -> signed division (with spec edge-cases)
    localparam ALU_DIVU    = 5'b10101; // DIVU  -> unsigned division
    localparam ALU_REM     = 5'b10110; // REM   -> signed remainder
    localparam ALU_REMU    = 5'b10111; // REMU  -> unsigned remainder

    // ----- Intermediate results -----
    // Add/Sub (33-bit for carry)
    wire [32:0] add_w = {1'b0, A} + {1'b0, B};
    wire [32:0] sub_w = {1'b0, A} + {1'b0, (~B)} + 33'd1;

    // Shifts
    wire [31:0] sll_res = A << B[4:0];
    wire [31:0] srl_res = A >> B[4:0];
    wire [31:0] sra_res = $signed(A) >>> B[4:0];

    // Comparisons
    wire       slt_bit  = ($signed(A) < $signed(B)) ? 1'b1 : 1'b0;
    wire       sltu_bit = (A < B) ? 1'b1 : 1'b0;

    // Multiplication products (64-bit)
    wire signed [63:0] prod_ss = $signed(A) * $signed(B);     // signed * signed
    wire signed [63:0] prod_su = $signed(A) * $unsigned(B);   // signed * unsigned
    wire       [63:0] prod_uu = A * B;                        // unsigned * unsigned

    // Division helpers (signed view)
    wire signed [31:0] As = $signed(A);
    wire signed [31:0] Bs = $signed(B);

    // constants
    localparam [31:0] MIN_INT = 32'h80000000;

    // ----- result registers -----
    reg  [31:0] res_internal;
    reg         carry_internal;
    reg         overflow_internal;

    always @(*) begin
        // defaults
        res_internal      = 32'h00000000;
        carry_internal    = 1'b0;
        overflow_internal = 1'b0;

        case (ALUControl)
            // -------------------------
            // RV32I basic operations
            // -------------------------
            ALU_ADD: begin
                res_internal      = add_w[31:0];
                carry_internal    = add_w[32];
                overflow_internal = (A[31] == B[31]) && (res_internal[31] != A[31]);
            end

            ALU_SUB: begin
                res_internal      = sub_w[31:0];
                carry_internal    = sub_w[32]; // carry_out: 1 => unsigned A >= B (no borrow)
                overflow_internal = (A[31] != B[31]) && (res_internal[31] != A[31]);
            end

            ALU_SLL: begin
                res_internal = sll_res;
            end

            ALU_SLT: begin
                res_internal = {31'b0, slt_bit};
            end

            ALU_SLTU: begin
                res_internal = {31'b0, sltu_bit};
            end

            ALU_XOR: begin
                res_internal = A ^ B;
            end

            ALU_SRL: begin
                res_internal = srl_res;
            end

            ALU_SRA: begin
                res_internal = sra_res;
            end

            ALU_OR: begin
                res_internal = A | B;
            end

            ALU_AND: begin
                res_internal = A & B;
            end

            // -------------------------
            // M-extension (RV32M)
            // -------------------------
            ALU_MUL: begin
                // lower 32 bits of signed*signed product
                res_internal = prod_ss[31:0];
            end

            ALU_MULH: begin
                // upper 32 bits of signed*signed product
                res_internal = prod_ss[63:32];
            end

            ALU_MULHSU: begin
                // upper 32 bits of signed(rs1) * unsigned(rs2)
                res_internal = prod_su[63:32];
            end

            ALU_MULHU: begin
                // upper 32 bits of unsigned*unsigned product
                res_internal = prod_uu[63:32];
            end

            ALU_DIV: begin
                // Signed division per RISC-V spec:
                // - if rs2 == 0 -> -1
                // - if rs1 == MIN_INT and rs2 == -1 -> MIN_INT (overflow case)
                // - else -> signed quotient truncated toward zero (Verilog $signed does trunc toward zero)
                if (B == 32'd0) begin
                    res_internal = 32'hffffffff; // -1
                end else if ((A == MIN_INT) && (B == 32'hffffffff)) begin
                    res_internal = MIN_INT;
                end else begin
                    res_internal = $signed(As / Bs);
                end
            end

            ALU_DIVU: begin
                // Unsigned division, rs2 == 0 -> all 1s
                if (B == 32'd0) begin
                    res_internal = 32'hffffffff;
                end else begin
                    res_internal = (A / B);
                end
            end

            ALU_REM: begin
                // Signed remainder per RISC-V:
                // - if rs2 == 0 -> rs1
                // - if rs1 == MIN_INT and rs2 == -1 -> 0
                // - else -> signed remainder (rs1 % rs2)
                if (B == 32'd0) begin
                    res_internal = A;
                end else if ((A == MIN_INT) && (B == 32'hffffffff)) begin
                    res_internal = 32'd0;
                end else begin
                    res_internal = $signed(As % Bs);
                end
            end

            ALU_REMU: begin
                // Unsigned remainder; if divisor == 0 -> dividend
                if (B == 32'd0) begin
                    res_internal = A;
                end else begin
                    res_internal = (A % B);
                end
            end

            default: begin
                res_internal = 32'h00000000;
            end
        endcase
    end

    // ----- outputs -----
    assign Result   = res_internal;
    assign Carry    = carry_internal;
    assign OverFlow = overflow_internal;
    assign Zero     = (res_internal == 32'h00000000);
    assign Negative = res_internal[31];

endmodule
