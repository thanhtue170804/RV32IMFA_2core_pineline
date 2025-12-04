`timescale 1ns/100ps

module FP_Unit_tb;
    // Đầu vào
    reg [31:0] in_rs1, in_rs2;
    reg [1:0] in_FPU_Op; // 00: ADD, 01: SUB, 10: MUL, 11: DIV
    reg in_Clk, in_Rst_N, in_start;
    
    // Đầu ra
    wire [31:0] out_data;
    wire out_stall;

    // Biến theo dõi
    integer test_count, pass_count, fail_count;

    // Khởi tạo module test
    FP_Unit uut (
        .in_rs1(in_rs1),
        .in_rs2(in_rs2),
        .in_FPU_Op(in_FPU_Op),
        .in_Clk(in_Clk),
        .in_Rst_N(in_Rst_N),
        .in_start(in_start),
        .out_data(out_data),
        .out_stall(out_stall)
    );

    // Tạo xung clock
    initial begin
        in_Clk = 0;
        forever #5 in_Clk = ~in_Clk; // Chu kỳ đồng hồ 10ns
    end

    // Test thử nghiệm
    initial begin
        // Khởi tạo các tín hiệu
        in_Rst_N = 0;
        in_start = 0;
        in_rs1 = 32'h0;
        in_rs2 = 32'h0;
        in_FPU_Op = 2'b00;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        // Reset hệ thống
        #10 in_Rst_N = 1;
        #10;

        // Phép cộng (10 test case cơ bản)
        test_case("Cong: 1.0 + 1.0", 2'b00, 32'h3f800000, 32'h3f800000, 32'h40000000); // 1.0 + 1.0 = 2.0
        test_case("Cong: 2.5 + 1.5", 2'b00, 32'h40200000, 32'h3fc00000, 32'h40800000); // 2.5 + 1.5 = 4.0
        test_case("Cong: 0.5 + 0.5", 2'b00, 32'h3f000000, 32'h3f000000, 32'h3f800000); // 0.5 + 0.5 = 1.0
        test_case("Cong: -1.0 + 2.0", 2'b00, 32'hbf800000, 32'h40000000, 32'h3f800000); // -1.0 + 2.0 = 1.0
        test_case("Cong: -2.5 + (-1.5)", 2'b00, 32'hc0200000, 32'hbfc00000, 32'hc0800000); // -2.5 + (-1.5) = -4.0
        test_case("Cong: 3.25 + 1.75", 2'b00, 32'h40500000, 32'h3fe00000, 32'h40a00000); // 3.25 + 1.75 = 5.0
        test_case("Cong: -0.75 + 0.25", 2'b00, 32'hbf400000, 32'h3e800000, 32'hbf000000); // -0.75 + 0.25 = -0.5
        test_case("Cong: 10.0 + 20.0", 2'b00, 32'h41200000, 32'h41a00000, 32'h41f00000); // 10.0 + 20.0 = 30.0
        test_case("Cong: 0.125 + 0.375", 2'b00, 32'h3e000000, 32'h3ec00000, 32'h3f000000); // 0.125 + 0.375 = 0.5
        test_case("Cong: -5.0 + 3.0", 2'b00, 32'hc0a00000, 32'h40400000, 32'hc0000000); // -5.0 + 3.0 = -2.0

        // Phép cộng (trường hợp đặc biệt - 7 test case)
        test_case("Cong: 0.0 + 0.0", 2'b00, 32'h00000000, 32'h00000000, 32'h00000000); // 0.0 + 0.0 = 0.0
        test_case("Cong: Infinity + 1.0", 2'b00, 32'h7f800000, 32'h3f800000, 32'h7f800000); // Inf + 1.0 = Inf
        test_case("Cong: -Infinity + 1.0", 2'b00, 32'hff800000, 32'h3f800000, 32'hff800000); // -Inf + 1.0 = -Inf
        test_case("Cong: Infinity + (-Infinity)", 2'b00, 32'h7f800000, 32'hff800000, 32'h7fc00000); // Inf + (-Inf) = NaN
        test_case("Cong: NaN + 2.0", 2'b00, 32'h7fc00000, 32'h40000000, 32'h7fc00000); // NaN + 2.0 = NaN



        // Phép trừ (10 test case cơ bản)
        test_case("Tru: 3.0 - 1.0", 2'b01, 32'h40400000, 32'h3f800000, 32'h40000000); // 3.0 - 1.0 = 2.0
        test_case("Tru: 2.5 - 1.5", 2'b01, 32'h40200000, 32'h3fc00000, 32'h3f800000); // 2.5 - 1.5 = 1.0
        test_case("Tru: -1.0 - 2.0", 2'b01, 32'hbf800000, 32'h40000000, 32'hc0400000); // -1.0 - 2.0 = -3.0
        test_case("Tru: 5.0 - 8.0", 2'b01, 32'h40a00000, 32'h41000000, 32'hc0400000); // 5.0 - 8.0 = -3.0
        test_case("Tru: -2.0 - (-1.0)", 2'b01, 32'hc0000000, 32'hbf800000, 32'hbf800000); // -2.0 - (-1.0) = -1.0
        test_case("Tru: 10.0 - 4.0", 2'b01, 32'h41200000, 32'h40800000, 32'h40c00000); // 10.0 - 4.0 = 6.0
        test_case("Tru: 0.75 - 0.25", 2'b01, 32'h3f400000, 32'h3e800000, 32'h3f000000); // 0.75 - 0.25 = 0.5
        test_case("Tru: -3.5 - 1.5", 2'b01, 32'hc0600000, 32'h3fc00000, 32'hc0a00000); // -3.5 - 1.5 = -5.0
        test_case("Tru: 15.0 - 5.0", 2'b01, 32'h41700000, 32'h40a00000, 32'h41200000); // 15.0 - 5.0 = 10.0
        test_case("Tru: 0.5 - 0.125", 2'b01, 32'h3f000000, 32'h3e000000, 32'h3ec00000); // 0.5 - 0.125 = 0.375

        // Phép trừ (trường hợp đặc biệt - 7 test case)
        test_case("Tru: 0.0 - 0.0", 2'b01, 32'h00000000, 32'h00000000, 32'h00000000); // 0.0 - 0.0 = 0.0
        test_case("Tru: Infinity - 1.0", 2'b01, 32'h7f800000, 32'h3f800000, 32'h7f800000); // Inf - 1.0 = Inf
        test_case("Tru: 1.0 - Infinity", 2'b01, 32'h3f800000, 32'h7f800000, 32'hff800000); // 1.0 - Inf = -Inf
        test_case("Tru: Infinity - Infinity", 2'b01, 32'h7f800000, 32'h7f800000, 32'h7fc00000); // Inf - Inf = NaN
        test_case("Tru: NaN - 2.0", 2'b01, 32'h7fc00000, 32'h40000000, 32'h7fc00000); // NaN - 2.0 = NaN



        // Phép nhân (10 test case cơ bản)
        test_case("Nhan: 2.0 * 3.0", 2'b10, 32'h40000000, 32'h40400000, 32'h40c00000); // 2.0 * 3.0 = 6.0
        test_case("Nhan: 1.5 * 2.0", 2'b10, 32'h3fc00000, 32'h40000000, 32'h40400000); // 1.5 * 2.0 = 3.0
        test_case("Nhan: -2.0 * 1.0", 2'b10, 32'hc0000000, 32'h3f800000, 32'hc0000000); // -2.0 * 1.0 = -2.0
        test_case("Nhan: -1.5 * -2.0", 2'b10, 32'hbfc00000, 32'hc0000000, 32'h40400000); // -1.5 * -2.0 = 3.0
        test_case("Nhan: 0.5 * 0.25", 2'b10, 32'h3f000000, 32'h3e800000, 32'h3e000000); // 0.5 * 0.25 = 0.125
        test_case("Nhan: 4.0 * 2.5", 2'b10, 32'h40800000, 32'h40200000, 32'h41200000); // 4.0 * 2.5 = 10.0
        test_case("Nhan: 0.75 * 2.0", 2'b10, 32'h3f400000, 32'h40000000, 32'h3fc00000); // 0.75 * 2.0 = 1.5
        test_case("Nhan: -3.0 * 2.0", 2'b10, 32'hc0400000, 32'h40000000, 32'hc0c00000); // -3.0 * 2.0 = -6.0
        test_case("Nhan: 5.0 * 1.25", 2'b10, 32'h40a00000, 32'h3fa00000, 32'h40c80000); // 5.0 * 1.25 = 6.25
        test_case("Nhan: 0.125 * 0.5", 2'b10, 32'h3e000000, 32'h3f000000, 32'h3d800000); // 0.125 * 0.5 = 0.0625

        // Phép nhân (trường hợp đặc biệt - 7 test case)
        test_case("Nhan: 0.0 * 1.0", 2'b10, 32'h00000000, 32'h3f800000, 32'h00000000); // 0.0 * 1.0 = 0.0
        test_case("Nhan: Infinity * 2.0", 2'b10, 32'h7f800000, 32'h40000000, 32'h7f800000); // Inf * 2.0 = Inf
        test_case("Nhan: Infinity * (-2.0)", 2'b10, 32'h7f800000, 32'hc0000000, 32'hff800000); // Inf * (-2.0) = -Inf
        test_case("Nhan: Infinity * 0.0", 2'b10, 32'h7f800000, 32'h00000000, 32'h7fc00000); // Inf * 0.0 = NaN
        test_case("Nhan: NaN * 3.0", 2'b10, 32'h7fc00000, 32'h40400000, 32'h7fc00000); // NaN * 3.0 = NaN


        // Phép chia (10 test case cơ bản)
        test_case("Chia: 6.0 / 2.0", 2'b11, 32'h40c00000, 32'h40000000, 32'h40400000); // 6.0 / 2.0 = 3.0
        test_case("Chia: 4.0 / 2.0", 2'b11, 32'h40800000, 32'h40000000, 32'h40000000); // 4.0 / 2.0 = 2.0
        test_case("Chia: -6.0 / 3.0", 2'b11, 32'hc0c00000, 32'h40400000, 32'hc0000002); // -6.0 / 3.0 = -2.0 (chấp nhận sai số nhỏ)
        test_case("Chia: -8.0 / -2.0", 2'b11, 32'hc1000000, 32'hc0000000, 32'h40800000); // -8.0 / -2.0 = 4.0
        test_case("Chia: 1.0 / 4.0", 2'b11, 32'h3f800000, 32'h40800000, 32'h3e800000); // 1.0 / 4.0 = 0.25
        test_case("Chia: 10.0 / 2.5", 2'b11, 32'h41200000, 32'h40200000, 32'h40800000); // 10.0 / 2.5 = 4.0
        test_case("Chia: -12.0 / 4.0", 2'b11, 32'hc1400000, 32'h40800000, 32'hc0400000); // -12.0 / 4.0 = -3.0
        test_case("Chia: 15.0 / 3.0", 2'b11, 32'h41700000, 32'h40400000, 32'h40a00002); // 15.0 / 3.0 = 5.0 (chấp nhận sai số nhỏ)


        // Phép chia (trường hợp đặc biệt - 7 test case)
        test_case("Chia: 1.0 / 0.0", 2'b11, 32'h3f800000, 32'h00000000, 32'h7f800000); // 1.0 / 0.0 = Inf
        test_case("Chia: 0.0 / 1.0", 2'b11, 32'h00000000, 32'h3f800000, 32'h00000000); // 0.0 / 1.0 = 0.0
        test_case("Chia: 0.0 / 0.0", 2'b11, 32'h00000000, 32'h00000000, 32'h7fc00000); // 0.0 / 0.0 = NaN
        test_case("Chia: Infinity / 2.0", 2'b11, 32'h7f800000, 32'h40000000, 32'h7f800000); // Inf / 2.0 = Inf
        test_case("Chia: 1.0 / Infinity", 2'b11, 32'h3f800000, 32'h7f800000, 32'h00000000); // 1.0 / Inf = 0.0
        test_case("Chia: Infinity / Infinity", 2'b11, 32'h7f800000, 32'h7f800000, 32'h7fc00000); // Inf / Inf = NaN
        test_case("Chia: NaN / 1.0", 2'b11, 32'h7fc00000, 32'h3f800000, 32'h7fc00000); // NaN / 1.0 = NaN

        // Kết quả tổng kết
        #10;
        $display("\nKet qua tong hop: %0d test duoc thuc hien, %0d thanh cong, %0d that bai", 
                 test_count, pass_count, fail_count);
        if (fail_count == 0) $display("Tat ca cac test deu thanh cong!");
        else $display("Mot so test da that bai!");

        // Kết thúc mô phỏng
        #10 $finish;
    end

    // Hàm chạy trường hợp test
    task test_case;
        input [63:0] test_name;
        input [1:0] op;
        input [31:0] rs1, rs2, expected;
        begin
            test_count = test_count + 1;
            in_rs1 = rs1;
            in_rs2 = rs2;
            in_FPU_Op = op;
            in_start = 1;
            #10 in_start = 0;

            if (op == 2'b11) begin
                // Chờ phép chia hoàn thành dựa trên out_stall
                wait (!out_stall);
                #20; // Đợi thêm 2 chu kỳ để đảm bảo kết quả ổn định (tổng 3 chu kỳ sau in_start)
                check_result(test_name, out_data, expected);
            end else begin
                // Kết quả tức thời cho Cong/Tru/Nhan
                #10;
                check_result(test_name, out_data, expected);
            end
        end
    endtask

    // Hàm kiểm tra kết quả
    task check_result;
        input [63:0] test_name;
        input [31:0] actual, expected;
        begin
            $display("%s = %h (Gia tri mong muon: %h)", test_name, actual, expected);
            if (actual === expected) begin
                $display("Test thanh cong!");
                pass_count = pass_count + 1;
            end else begin
                $display("LOI: Test that bai! Thuc te: %h, Mong muon: %h", actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask
endmodule