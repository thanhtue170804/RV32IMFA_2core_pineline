// Control_Unit.v
// Wrapper: Main_Decoder -> ALU decode -> final control outputs for pipeline
// Updated to use ALU_Decoder (produces 5-bit ALUControl) and support RV32M decoding.

module Control_Unit(
    input  wire [6:0] Op,
    input  wire [6:0] funct7,
    input  wire [2:0] funct3,

    // outputs used by pipeline
    output wire       RegWrite,
    output wire       ALUSrc,
    output wire       MemWrite,
    output wire       MemRead,
    output wire [1:0] ResultSrc,
    output wire       Branch,
    output wire       Jump,
    output wire [2:0] ImmSrc,
    output wire [4:0] ALUControl,   // <-- updated: 5-bit control for ALU (matches ALU_rv32im)
    output wire [2:0] MemOp,        // forwarded funct3 for memory unit
    output wire       CSR,
    output wire       Fence
);

    // Internal wires from Main_Decoder
    wire [1:0] ALUOp;

    // Instantiate main decoder that produces the high-level controls
    Main_Decoder md (
        .Op(Op),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .ResultSrc(ResultSrc),
        .Branch(Branch),
        .Jump(Jump),
        .ImmSrc(ImmSrc),
        .ALUOp(ALUOp),
        .CSR(CSR),
        .Fence(Fence)
    );

    // Forward MemOp (funct3) to memory unit
    assign MemOp = funct3;

    // ----------------------------------------------------------------
    // Instantiate ALU_Decoder (produces 5-bit ALUControl matching ALU module)
    // ALU_Decoder needs:
    //   - ALUOp (from Main_Decoder)
    //   - funct3, funct7 (from instruction)
    //   - is_op_imm  (1 if current instruction is OP-IMM)
    // ----------------------------------------------------------------

    // Detect OP-IMM opcode (0010011) -> used to tell decoder this is an immediate form
    // (SRAI / SRLI are OP-IMM; SUB only selected on R-type with funct7[5]==1)
    wire is_op_imm = (Op == 7'b0010011);

    // Instantiate the ALU_Decoder (assumes file ALU_Decoder.v exists and matches signature)
    ALU_Decoder alu_dec (
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .is_op_imm(is_op_imm),
        .ALUControl(ALUControl)    // 5-bit output
    );

    // NOTE: previous Control_Unit emitted a 4-bit ALUControl; now we forward the full 5-bit
    // code that matches ALU (RV32I + M-extension). Make sure any other modules/wires that
    // used the old 4-bit signal are updated to 5-bit accordingly.

endmodule
