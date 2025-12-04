// M_Multiplier.v
// 2-bit sel:
//   2'b00 -> MUL   : low 32 bits of (signed rs1 * signed rs2)
//   2'b01 -> MULH  : high 32 bits of (signed rs1 * signed rs2)
//   2'b10 -> MULHSU: high 32 bits of (signed rs1 * unsigned rs2)
//   2'b11 -> MULHU : high 32 bits of (unsigned rs1 * unsigned rs2)
module M_Multiplier(
    input  wire [31:0] rs1,
    input  wire [31:0] rs2,
    input  wire [1:0]  sel,
    output reg  [31:0] rd
);
    // typed intermediates
    wire signed [31:0] s1 = $signed(rs1);
    wire signed [31:0] s2 = $signed(rs2);
    wire [31:0]         u1 = rs1;
    wire [31:0]         u2 = rs2;

    // 64-bit products (different signedness combos)
    wire signed   [63:0] prod_ss = $signed(s1) * $signed(s2);
    wire signed   [63:0] prod_su = $signed(s1) * $unsigned(u2);
    wire unsigned [63:0] prod_uu = $unsigned(u1) * $unsigned(u2);

    always @(*) begin
        case (sel)
            2'b00: begin // MUL (low 32)
                rd = prod_ss[31:0];
            end
            2'b01: begin // MULH (high 32 of signed*signed)
                rd = prod_ss[63:32];
            end
            2'b10: begin // MULHSU (high 32 of signed*unsigned)
                rd = prod_su[63:32];
            end
            2'b11: begin // MULHU (high 32 of unsigned*unsigned)
                rd = prod_uu[63:32];
            end
            default: rd = 32'h00000000;
        endcase
    end
endmodule
