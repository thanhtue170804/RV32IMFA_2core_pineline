// ALU_Decoder.v
// Decode ALUOp + funct3 + funct7 -> 5-bit ALUControl (supports RV32I + M-extension)

module ALU_Decoder (
    input  wire [1:0] ALUOp,        // from Main_Decoder
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,       // full funct7 (needed to detect M-extension and SRA)
    input  wire       is_op_imm,    // 1 if OP-IMM (ADDI, SRAI, SRLI, etc.)
    output reg  [4:0] ALUControl    // 5-bit control for ALU
);

    // Local encodings (match ALU module)
    localparam [4:0]
        ALU_ADD     = 5'b00000,
        ALU_SUB     = 5'b00001,
        ALU_SLL     = 5'b00010,
        ALU_SLT     = 5'b00011,
        ALU_SLTU    = 5'b00100,
        ALU_XOR     = 5'b00101,
        ALU_SRL     = 5'b00110,
        ALU_SRA     = 5'b00111,
        ALU_OR      = 5'b01000,
        ALU_AND     = 5'b01001,
        // M-extension
        ALU_MUL     = 5'b10000,
        ALU_MULH    = 5'b10001,
        ALU_MULHSU  = 5'b10010,
        ALU_MULHU   = 5'b10011,
        ALU_DIV     = 5'b10100,
        ALU_DIVU    = 5'b10101,
        ALU_REM     = 5'b10110,
        ALU_REMU    = 5'b10111;

    // Helper: check if this is M-group (funct7 == 7'b0000001).
    // Only valid for R-type (so ensure ALUOp==2'b10 and not OP-IMM).
    wire is_m_group = (ALUOp == 2'b10) && (!is_op_imm) && (funct7 == 7'b0000001);

    always @(*) begin
        // default
        ALUControl = ALU_ADD;

        case (ALUOp)
            2'b00: begin
                // loads/stores/auipc/lui/jalr/etc -> use ADD
                ALUControl = ALU_ADD;
            end

            2'b01: begin
                // branches -> use SUB (for comparisons)
                ALUControl = ALU_SUB;
            end

            2'b10: begin
                // OP / OP-IMM or R-type -> inspect funct7/funct3
                if (is_m_group) begin
                    // M-extension (R-type with funct7==0000001)
                    case (funct3)
                        3'b000: ALUControl = ALU_MUL;     // MUL
                        3'b001: ALUControl = ALU_MULH;    // MULH
                        3'b010: ALUControl = ALU_MULHSU;  // MULHSU
                        3'b011: ALUControl = ALU_MULHU;   // MULHU
                        3'b100: ALUControl = ALU_DIV;     // DIV
                        3'b101: ALUControl = ALU_DIVU;    // DIVU
                        3'b110: ALUControl = ALU_REM;     // REM
                        3'b111: ALUControl = ALU_REMU;    // REMU
                        default: ALUControl = ALU_ADD;
                    endcase
                end else begin
                    // Regular RV32I ops (R-type or OP-IMM)
                    case (funct3)
                        3'b000: begin
                            // ADD / SUB
                            // SUB occurs only for R-type where funct7[5] == 1 (i.e. 0100000)
                            // For OP-IMM (ADDI), always ADD
                            if (!is_op_imm && (funct7[5] == 1'b1)) ALUControl = ALU_SUB;
                            else ALUControl = ALU_ADD;
                        end
                        3'b001: begin
                            // SLL / SLLI
                            ALUControl = ALU_SLL;
                        end
                        3'b010: begin
                            // SLT / SLTI (signed)
                            ALUControl = ALU_SLT;
                        end
                        3'b011: begin
                            // SLTU / SLTIU (unsigned)
                            ALUControl = ALU_SLTU;
                        end
                        3'b100: begin
                            // XOR / XORI
                            ALUControl = ALU_XOR;
                        end
                        3'b101: begin
                            // SRL / SRA  OR  SRLI / SRAI
                            // SRA when funct7[5]==1 (0100000 for R-type SRA or SRAI immediate)
                            if (funct7[5] == 1'b1) ALUControl = ALU_SRA;
                            else                   ALUControl = ALU_SRL;
                        end
                        3'b110: begin
                            // OR / ORI
                            ALUControl = ALU_OR;
                        end
                        3'b111: begin
                            // AND / ANDI
                            ALUControl = ALU_AND;
                        end
                        default: ALUControl = ALU_ADD;
                    endcase
                end
            end

            default: ALUControl = ALU_ADD;
        endcase
    end

endmodule
