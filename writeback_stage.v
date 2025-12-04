// writeback_stage.v
module writeback_stage(
    input  wire       ResultSrcW,      // 0=ALU,1=MEM (from Main_Decoder/ResultSrc)
    input  wire       isFPUW,          // if true, we are writing FP result (to FP regfile)
    input  wire [31:0] ALU_ResultW,
    input  wire [31:0] ReadDataW,
    // floating point inputs
    input  wire [31:0] FP_ALU_ResultW,
    input  wire [31:0] FP_ReadDataW,

    output reg  [31:0] ResultW,        // integer result (to integer regfile)
    output reg  [31:0] FP_ResultW      // FP result (to FP regfile)
);
    // integer result select
    always @(*) begin
        ResultW = (ResultSrcW) ? ReadDataW : ALU_ResultW;
        // FP result selection: we use same ResultSrcW meaning MEM reads FP as well if ResultSrcW==1
        FP_ResultW = (ResultSrcW) ? FP_ReadDataW : FP_ALU_ResultW;
    end
endmodule
