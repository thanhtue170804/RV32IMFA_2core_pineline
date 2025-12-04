// M_Divider.v
// 2-bit sel:
//   2'b00 -> DIV   : signed division (quotient)
//   2'b01 -> DIVU  : unsigned division (quotient)
//   2'b10 -> REM   : signed remainder
//   2'b11 -> REMU  : unsigned remainder
module M_Divider(
    input  wire [31:0] rs1,
    input  wire [31:0] rs2,
    input  wire [1:0]  sel,
    output reg  [31:0] rd
);
    // constants
    localparam [31:0] MIN_INT = 32'h80000000; // -2^31
    localparam [31:0] ALL_ONES = 32'hFFFFFFFF;

    // signed/unsigned views
    wire signed [31:0] s1 = $signed(rs1);
    wire signed [31:0] s2 = $signed(rs2);
    wire        [31:0] u1 = rs1;
    wire        [31:0] u2 = rs2;

    // combinational implementation following RISC-V spec:
    // - div/divu: when divisor==0 -> quotient = -1 (all ones) for signed, and all ones for unsigned
    // - rem/remu: when divisor==0 -> remainder = dividend
    // - signed overflow case: DIV of MIN_INT by -1 -> quotient = MIN_INT, remainder = 0
    always @(*) begin
        case (sel)
            2'b00: begin // DIV (signed quotient)
                if (rs2 == 32'h00000000) begin
                    rd = ALL_ONES; // division by zero -> -1
                end else if (s1 == $signed(MIN_INT) && s2 == $signed(32'hFFFFFFFF)) begin
                    // divisor == -1 (0xFFFFFFFF) and dividend == MIN_INT -> overflow
                    rd = MIN_INT;
                end else begin
                    rd = $signed(s1 / s2);
                end
            end

            2'b01: begin // DIVU (unsigned quotient)
                if (rs2 == 32'h00000000) begin
                    rd = ALL_ONES; // division by zero -> max unsigned
                end else begin
                    rd = $unsigned(u1 / u2);
                end
            end

            2'b10: begin // REM (signed remainder)
                if (rs2 == 32'h00000000) begin
                    rd = rs1; // remainder = dividend when divide-by-zero
                end else if (s1 == $signed(MIN_INT) && s2 == $signed(32'hFFFFFFFF)) begin
                    // overflow case: remainder = 0
                    rd = 32'h00000000;
                end else begin
                    rd = $signed(s1 % s2);
                end
            end

            2'b11: begin // REMU (unsigned remainder)
                if (rs2 == 32'h00000000) begin
                    rd = rs1; // remainder = dividend
                end else begin
                    rd = $unsigned(u1 % u2);
                end
            end

            default: rd = 32'h00000000;
        endcase
    end
endmodule
