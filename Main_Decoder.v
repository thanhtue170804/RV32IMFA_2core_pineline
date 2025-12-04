// Main_Decoder.v
// Extended for RV32IMF
module Main_Decoder(
    input  wire [6:0] Op,
    output wire       RegWrite,
    output wire       ALUSrc,
    output wire       MemWrite,
    output wire       MemRead,
    output wire [1:0] ResultSrc,
    output wire       Branch,
    output wire       Jump,
    output wire [2:0] ImmSrc,
    output wire [1:0] ALUOp,
    output wire       CSR,
    output wire       Fence,
    // --- New signals for F-extension ---
    output wire       isFPU,         // 1 if instruction uses FPU
    output wire       FPRegWrite,    // write to f-register file
    output wire       FPMemRead,     // FLW
    output wire       FPMemWrite     // FSW
);

    // RV32I / M opcodes
    localparam OP_LUI      = 7'b0110111;
    localparam OP_AUIPC    = 7'b0010111;
    localparam OP_JAL      = 7'b1101111;
    localparam OP_JALR     = 7'b1100111;
    localparam OP_BRANCH   = 7'b1100011;
    localparam OP_LOAD     = 7'b0000011;
    localparam OP_STORE    = 7'b0100011;
    localparam OP_OP_IMM   = 7'b0010011;
    localparam OP_OP       = 7'b0110011;
    localparam OP_MISC_MEM = 7'b0001111;
    localparam OP_SYSTEM   = 7'b1110011;

    // --- F-extension opcodes ---
    localparam OP_FLW   = 7'b0000111;  // FLW
    localparam OP_FSW   = 7'b0100111;  // FSW
    localparam OP_FMADD = 7'b1000011;  // FMADD.S
    localparam OP_FMSUB = 7'b1000111;  // FMSUB.S
    localparam OP_FNMSUB= 7'b1001011;  // FNMSUB.S
    localparam OP_FNMADD= 7'b1001111;  // FNMADD.S
    localparam OP_FOP   = 7'b1010011;  // FADD.S, FSUB.S, FMUL.S, FDIV.S, FSGNJ.S, etc.

    // --- Detect FPU instructions ---
    assign isFPU = (Op == OP_FLW)  ||
                   (Op == OP_FSW)  ||
                   (Op == OP_FMADD)||
                   (Op == OP_FMSUB)||
                   (Op == OP_FNMSUB)||
                   (Op == OP_FNMADD)||
                   (Op == OP_FOP);

    // --- FPRegWrite: all FPU instructions writing to f-registers ---
    assign FPRegWrite = (Op == OP_FLW)  ||
                        (Op == OP_FMADD)||
                        (Op == OP_FMSUB)||
                        (Op == OP_FNMSUB)||
                        (Op == OP_FNMADD)||
                        (Op == OP_FOP);

    // --- FPMemRead / FPMemWrite ---
    assign FPMemRead  = (Op == OP_FLW);
    assign FPMemWrite = (Op == OP_FSW);

    // --- Normal pipeline control signals (unchanged) ---
    assign RegWrite = (Op == OP_LUI)   ||
                      (Op == OP_AUIPC) ||
                      (Op == OP_JAL)   ||
                      (Op == OP_JALR)  ||
                      (Op == OP_LOAD)  ||
                      (Op == OP_OP_IMM)||
                      (Op == OP_OP);

    assign ImmSrc = (Op == OP_STORE) ? 3'b001 :
                    (Op == OP_BRANCH) ? 3'b010 :
                    (Op == OP_LUI || Op == OP_AUIPC) ? 3'b011 :
                    (Op == OP_JAL) ? 3'b100 :
                    3'b000;

    assign ALUSrc = (Op == OP_LOAD) ||
                    (Op == OP_STORE) ||
                    (Op == OP_OP_IMM) ||
                    (Op == OP_JALR) ||
                    (Op == OP_AUIPC) ||
                    (Op == OP_LUI);

    assign MemWrite = (Op == OP_STORE);
    assign MemRead  = (Op == OP_LOAD);

    assign ResultSrc = (Op == OP_LOAD) ? 2'b01 :
                       (Op == OP_JAL || Op == OP_JALR) ? 2'b10 :
                       (Op == OP_LUI || Op == OP_AUIPC) ? 2'b11 :
                       2'b00;

    assign Branch = (Op == OP_BRANCH);
    assign Jump   = (Op == OP_JAL) || (Op == OP_JALR);

    assign ALUOp = (Op == OP_OP || Op == OP_OP_IMM) ? 2'b10 :
                   (Op == OP_BRANCH) ? 2'b01 :
                   2'b00;

    assign CSR   = (Op == OP_SYSTEM);
    assign Fence = (Op == OP_MISC_MEM);

endmodule
