 module fetch_stage(
    // Đầu vào điều khiển
    input clk, rst,
    input stall,              // Thêm tín hiệu stall cho Fetch
    input PCSrcE,
    input [31:0] PCTargetE,
    
    // Đầu ra đến IF/ID
    output [31:0] InstrF, PCF, PCPlus4F
);
    // Dây nội bộ
    wire [31:0] PC_Next;
    wire PC_Write;            // Cho phép cập nhật PC
    
    // Không cập nhật PC khi stall
    assign PC_Write = ~stall;

    // PC MUX
    mux PC_MUX (
        .a(PCPlus4F),
        .b(PCTargetE),
        .s(PCSrcE),
        .c(PC_Next)
    );

    // PC Counter có hỗ trợ stall
    PC_module Program_Counter (
        .clk(clk),
        .rst(rst),
        .PC_Write(PC_Write),  // Chỉ cập nhật PC khi không stall
        .PC(PCF),
        .PC_Next(PC_Next)
    );

    // Instruction Memory
    Instruction_Memory IMEM (
        .rst(rst),
        .A(PCF),
        .RD(InstrF)
    );

    // PC Adder
    PC_Adder PC_adder (
        .a(PCF),
        .b(32'h00000004),
        .c(PCPlus4F)
    );
endmodule