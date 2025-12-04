// FP_Register_File.v (fixed)
// 32 x 64-bit floating-point register file
// Asynchronous read, synchronous write, async active-low reset

module FP_Register_File (
    input  wire        clk,
    input  wire        rst,    // active low (consistent with other modules)
    input  wire        WE3,
    input  wire [63:0] WD3,
    input  wire [4:0]  A1,
    input  wire [4:0]  A2,
    input  wire [4:0]  A3,
    output wire [63:0] RD1,
    output wire [63:0] RD2
);

    reg [63:0] regs [0:31];  // 32 registers, each 64-bit
    integer i;               // must be declared at module scope, not inside always

    // Asynchronous read (combinational)
    assign RD1 = regs[A1];
    assign RD2 = regs[A2];

    // Synchronous write and asynchronous active-low reset
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // async reset: clear all registers
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 64'b0;
            end
        end else begin
            // write on rising clock edge when enabled; do not write x0
            if (WE3 && (A3 != 5'd0)) begin
                regs[A3] <= WD3;
            end
        end
    end

endmodule
