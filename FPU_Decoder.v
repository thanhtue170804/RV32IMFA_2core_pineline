// ============================================================================
// FPU_Decoder.v
// Decode funct7 + funct3 + opcode (1010011) -> 5-bit FPUControl
// Phong cách giống ALU_Decoder.v
// Hỗ trợ toàn bộ RV32F (single-precision float)
// ----------------------------------------------------------------------------
// Tác giả: GPT-5
// ============================================================================
module FPU_Decoder (
    input  wire [6:0] funct7,       // bit [31:25]
    input  wire [2:0] funct3,       // bit [14:12]
    input  wire [6:0] opcode,       // bit [6:0], phải = 7'b1010011 cho RV32F
    output reg  [4:0] FPUControl    // mã điều khiển cho module FPU_rv32imf.v
);

    // -----------------------------
    // Mã khớp với module FPU_rv32imf.v
    // -----------------------------
    localparam [4:0]
        FADD_S    = 5'b00000,
        FSUB_S    = 5'b00001,
        FMUL_S    = 5'b00010,
        FDIV_S    = 5'b00011,
        FSQRT_S   = 5'b00100,
        FSGNJ_S   = 5'b00101,
        FSGNJN_S  = 5'b00110,
        FSGNJX_S  = 5'b00111,
        FEQ_S     = 5'b01000,
        FLT_S     = 5'b01001,
        FLE_S     = 5'b01010,
        FCVT_W_S  = 5'b01100,
        FCVT_WU_S = 5'b01101,
        FCVT_S_W  = 5'b01110,
        FCVT_S_WU = 5'b01111,
        FMV_X_W   = 5'b10000,
        FMV_W_X   = 5'b10001,
        FCLASS_S  = 5'b10010;

    always @(*) begin
        FPUControl = FADD_S; // mặc định

        if (opcode == 7'b1010011) begin
            case (funct7)
                // -----------------------------
                // Nhóm số học cơ bản
                // -----------------------------
                7'b0000000: FPUControl = FADD_S;   // FADD.S
                7'b0000100: FPUControl = FSUB_S;   // FSUB.S
                7'b0001000: FPUControl = FMUL_S;   // FMUL.S
                7'b0001100: FPUControl = FDIV_S;   // FDIV.S
                7'b0101100: FPUControl = FSQRT_S;  // FSQRT.S

                // -----------------------------
                // Nhóm gán dấu (funct7 = 0010000)
                // -----------------------------
                7'b0010000: begin
                    case (funct3)
                        3'b000: FPUControl = FSGNJ_S;   // FSGNJ.S
                        3'b001: FPUControl = FSGNJN_S;  // FSGNJN.S
                        3'b010: FPUControl = FSGNJX_S;  // FSGNJX.S
                        default: FPUControl = FADD_S;
                    endcase
                end

                // -----------------------------
                // So sánh (funct7 = 1010000)
                // -----------------------------
                7'b1010000: begin
                    case (funct3)
                        3'b010: FPUControl = FEQ_S;     // FEQ.S
                        3'b001: FPUControl = FLT_S;     // FLT.S
                        3'b000: FPUControl = FLE_S;     // FLE.S
                        default: FPUControl = FADD_S;
                    endcase
                end

                // -----------------------------
                // Chuyển đổi float <-> int
                // -----------------------------
                7'b1100000: begin // FCVT.W.S / FCVT.WU.S
                    case (funct3)
                        3'b000: FPUControl = FCVT_W_S;   // to signed int
                        3'b001: FPUControl = FCVT_WU_S;  // to unsigned int
                        default: FPUControl = FADD_S;
                    endcase
                end

                7'b1101000: begin // FCVT.S.W / FCVT.S.WU
                    case (funct3)
                        3'b000: FPUControl = FCVT_S_W;   // from signed int
                        3'b001: FPUControl = FCVT_S_WU;  // from unsigned int
                        default: FPUControl = FADD_S;
                    endcase
                end

                // -----------------------------
                // Move / classify
                // -----------------------------
                7'b1110000: begin
                    case (funct3)
                        3'b000: FPUControl = FMV_X_W;   // FMV.X.W
                        3'b001: FPUControl = FCLASS_S;  // FCLASS.S
                        default: FPUControl = FADD_S;
                    endcase
                end

                7'b1111000: begin
                    case (funct3)
                        3'b000: FPUControl = FMV_W_X;   // FMV.W.X
                        default: FPUControl = FADD_S;
                    endcase
                end

                default: FPUControl = FADD_S;
            endcase
        end
    end

endmodule
