`timescale 1ns / 100ps
module RV32I_tb;
    // Clock / reset
    reg clk;
    reg rst_n; // active-low reset in your design

    // Top-level DUT ports (observed)
    wire [31:0] PCF;
    wire [31:0] InstrF;
    wire [31:0] ResultW;
    wire [4:0]  RD_W;
    wire        stall_F;
    wire        stall_D;
    wire        flush_D;
    wire        flush_E;
    wire [1:0]  ForwardAE;
    wire [1:0]  ForwardBE;
    wire        lwStall;
    wire        branchStall;

    // Instantiate DUT 
    RV32I dut (
        .clk(clk),
        .rst(rst_n),

        // fetch outputs
        .PCF(PCF),
        .InstrF(InstrF),

        // writeback outputs
        .ResultW(ResultW),
        .RD_W(RD_W),

        // pipeline control observation
        .stall_F(stall_F),
        .stall_D(stall_D),
        .flush_D(flush_D),
        .flush_E(flush_E),

        // forwarding + hazard
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
        .lwStall(lwStall),
        .branchStall(branchStall)
    );

    // Clock generation: 100 ns period (50 ns half period)
    initial begin
        clk = 1'b0;
        forever #50 clk = ~clk;
    end

    // Reset and simulation control
    initial begin
        // waveform dump (ModelSim / VCD compatible)
        $dumpfile("RV32I_tb.vcd");
        $dumpvars(0, RV32I_tb);

        // apply reset (active-low)
        rst_n = 1'b0;
        #200;            // hold reset for 200 ns
        rst_n = 1'b1;    // release reset

        // run for some cycles then finish
        #50000;
        $display("\n--- End simulation (timeout) ---\n");
        $finish;
    end

    // Basic per-cycle monitor (safe: uses only top-level ports)
    integer cycle;
    initial cycle = 0;
    always @(posedge clk) begin
        if (rst_n) begin
            cycle = cycle + 1;
            $display("\n===== Cycle %0d =====", cycle);
            $display("PCF        = 0x%08h", PCF);
            $display("InstrF     = 0x%08h", InstrF);
            $display("ResultW    = 0x%08h (rd = x%0d)", ResultW, RD_W);
            $display("stall_F/D  = %b / %b  flush_D/E = %b / %b", stall_F, stall_D, flush_D, flush_E);
            $display("ForwardA/B = %b / %b  lwStall=%b branchStall=%b", ForwardAE, ForwardBE, lwStall, branchStall);
        end
    end

    // -------------------------------
    // Optional extended internal probes
    // -------------------------------
    // The following block contains example hierarchical probes to internal
    // signals (IF/ID, ID/EX, EX, MEM, FP). They are COMMENTED OUT by default
    // because hierarchical names must match your DUT exactly. If your DUT has
    // instances with the same names (if_id, decode, id_ex, execute, memory,
    // mem_wb), you may uncomment lines you need.
    //
    // To enable, remove `/*` ... `*/` markers around the desired lines.
    //
    /* Example: show some internal signals (uncomment if instance names match)
    always @(posedge clk) begin
        if (rst_n) begin
            // IF/ID
            $display("IF/ID: PCD = 0x%08h  InstrD = 0x%08h", dut.if_id.PCD, dut.if_id.InstrD);

            // ID stage control
            $display("DECODE: RegWriteD=%b ALUSrcD=%b MemWriteD=%b ALUControlD=%b",
                     dut.decode.RegWriteD, dut.decode.ALUSrcD, dut.decode.MemWriteD, dut.decode.ALUControlD);

            // ID/EX
            $display("ID/EX: PCE=0x%08h RD1=0x%08h RD2=0x%08h Imm=0x%08h",
                     dut.id_ex.PCE, dut.id_ex.RD1_E, dut.id_ex.RD2_E, dut.id_ex.Imm_Ext_E);

            // EX stage
            $display("EX: ALU_ResultE=0x%08h WriteDataE=0x%08h PCSrcE=%b",
                     dut.execute.ALU_ResultE, dut.execute.WriteDataE, dut.execute.PCSrcE);

            // MEM stage
            $display("MEM: ALU_ResultM=0x%08h WriteDataM=0x%08h ReadDataM=0x%08h",
                     dut.memory.ALU_ResultM, dut.memory.WriteDataM, dut.memory.ReadDataM);

            // FP signals (if present)
            // $display("FP EX: FP_ALU_ResultE=0x%08h FP_StallE=%b", dut.execute.FP_ALU_ResultE, dut.execute.FP_StallE);
            // $display("FP MEM/WB: FP_ALU_ResultM=0x%08h FP_ReadDataM=0x%08h", dut.ex_mem.FP_ALU_ResultM, dut.mem_wb.FP_ReadDataW);
        end
    end
    */

    // Example stop condition: stop when PCF reaches some address (adjust if needed)
    always @(posedge clk) begin
        if (rst_n && (PCF == 32'h00000040)) begin
            $display("\n>>> PCF reached 0x00000040, stopping sim.");
            #20;
            $finish;
        end
    end

endmodule
