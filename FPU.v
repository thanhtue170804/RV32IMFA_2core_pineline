// fpu.v
// Expanded FPU top that reuses existing FP_Add / FP_Sub / FP_Mul / FP_Div IPs
// Adds many RV32F ops implemented with bit-level logic (no shortreal/systemverilog)
// in_FPU_Op: 5-bit control (see localparam mapping below)
// in_rs1/in_rs2: 32-bit bit-pattern operands
// out_data: 32-bit result (bit-pattern or integer result in LSB for comparisons)
// out_stall: stall request when FDIV is busy

module FPU(
    input  wire        in_Clk,
    input  wire        in_Rst_N,
    input  wire        in_start,      // start for iterative DIV IP
    input  wire [4:0]  in_FPU_Op,     // 5-bit FPU opcode/control
    input  wire [31:0] in_rs1,        // operand 1 (float bit-pattern or int when used)
    input  wire [31:0] in_rs2,        // operand 2
    output reg  [31:0] out_data,
    output wire        out_stall
);

    // -------------------------
    // Control encoding (5-bit)
    // keep these values in sync with your FPU decoder
    // -------------------------
    localparam FADD_S    = 5'b00000;
    localparam FSUB_S    = 5'b00001;
    localparam FMUL_S    = 5'b00010;
    localparam FDIV_S    = 5'b00011;
    localparam FSQRT_S   = 5'b00100; // optional, returns 0 if no sqrt IP

    localparam FSGNJ_S   = 5'b00101;
    localparam FSGNJN_S  = 5'b00110;
    localparam FSGNJX_S  = 5'b00111;

    localparam FEQ_S     = 5'b01000;
    localparam FLT_S     = 5'b01001;
    localparam FLE_S     = 5'b01010;

    localparam FCVT_W_S  = 5'b01100; // float -> int (signed)
    localparam FCVT_WU_S = 5'b01101; // float -> uint
    localparam FCVT_S_W  = 5'b01110; // int -> float (signed)
    localparam FCVT_S_WU = 5'b01111; // uint -> float

    localparam FMV_X_W   = 5'b10000; // float->int bitwise
    localparam FMV_W_X   = 5'b10001; // int->float bitwise
    localparam FCLASS_S  = 5'b10010;

    localparam FMIN_S    = 5'b10100;
    localparam FMAX_S    = 5'b10101;

    // optional FMA codes left unimplemented
    localparam FMADD_S   = 5'b10110;
    localparam FMSUB_S   = 5'b10111;
    localparam FNMSUB_S  = 5'b11000;
    localparam FNMADD_S  = 5'b11001;

    // -------------------------
    // Arithmetic IP outputs (assumed present in project)
    // -------------------------
    wire [31:0] add_out;
    wire [31:0] sub_out;
    wire [31:0] mul_out;
    wire [31:0] div_out;
    wire        div_busy;

    // Instantiate your existing IPs (adjust names/ports if different)
    FP_Add u_fp_add (
        .in_numA(in_rs1),
        .in_numB(in_rs2),
        .out_data(add_out)
    );

    FP_Sub u_fp_sub (
        .in_numA(in_rs1),
        .in_numB(in_rs2),
        .out_data(sub_out)
    );

    FP_Mul u_fp_mul (
        .A(in_rs1),
        .B(in_rs2),
        .Mul_Out(mul_out)
    );

    FP_Div u_fp_div (
        .in_Clk(in_Clk),
        .in_Rst_N(in_Rst_N),
        .in_start(in_start),
        .in_numA(in_rs1),
        .in_numB(in_rs2),
        .out_result(div_out),
        .out_stall(div_busy)
    );

    // no sqrt IP in example -> return zero for FSQRT
    wire [31:0] sqrt_out = 32'h00000000;
    wire sqrt_busy = 1'b0;

    assign out_stall = div_busy | sqrt_busy;

    // -------------------------
    // Helper functions (bit-level)
    // -------------------------
    function is_nan;
        input [31:0] x;
        reg [7:0] e;
        reg [22:0] f;
        begin
            e = x[30:23];
            f = x[22:0];
            is_nan = (e == 8'hFF) && (f != 0);
        end
    endfunction

    function is_zero;
        input [31:0] x;
        reg [30:0] a;
        begin
            a = x[30:0] & 31'h7FFFFFFF;
            is_zero = (a == 31'h00000000);
        end
    endfunction

    // Compare magnitude (absolute, ignoring sign)
    function mag_less;
        input [31:0] x;
        input [31:0] y;
        reg [30:0] xm;
        reg [30:0] ym;
        begin
            xm = x[30:0];
            ym = y[30:0];
            mag_less = (xm < ym);
        end
    endfunction

    // float equality (NaN -> false; +0 == -0)
    function float_eq;
        input [31:0] x;
        input [31:0] y;
        begin
            if (is_nan(x) || is_nan(y)) begin
                float_eq = 1'b0;
            end else if (is_zero(x) && is_zero(y)) begin
                float_eq = 1'b1;
            end else begin
                float_eq = (x == y);
            end
        end
    endfunction

    // float less-than (returns 1 if x < y per IEEE rules, NaN -> false)
    function float_lt;
        input [31:0] x;
        input [31:0] y;
        reg sx, sy;
        begin
            if (is_nan(x) || is_nan(y)) begin
                float_lt = 1'b0;
            end else begin
                sx = x[31];
                sy = y[31];
                if (x == y) begin
                    float_lt = 1'b0;
                end else if (sx != sy) begin
                    float_lt = (sx == 1'b1); // negative < positive
                end else if (sx == 1'b0) begin
                    // both positive: compare magnitude
                    float_lt = (x[30:0] < y[30:0]);
                end else begin
                    // both negative: reverse magnitude compare
                    float_lt = (x[30:0] > y[30:0]);
                end
            end
        end
    endfunction

    function float_le;
        input [31:0] x;
        input [31:0] y;
        begin
            float_le = float_lt(x,y) | float_eq(x,y);
        end
    endfunction

    // float -> signed int (round towards zero), saturate on overflow
    function [31:0] float_to_int;
        input [31:0] f;
        reg sign;
        reg [7:0] exp;
        reg [22:0] frac;
        integer e;
        reg [47:0] mant; // 1.frac << 24
        reg [31:0] uval;
        integer shift;
        begin
            sign = f[31];
            exp  = f[30:23];
            frac = f[22:0];

            // NaN or Inf -> saturate
            if (is_nan(f) || (exp == 8'hFF)) begin
                float_to_int = sign ? 32'h80000000 : 32'h7FFFFFFF;
            end else if (exp == 8'h00) begin
                // zero or subnormal -> 0
                float_to_int = 32'h00000000;
            end else begin
                e = exp - 127;
                // mantissa with implicit 1, left-aligned to bit 47
                mant = {1'b1, frac, 24'd0}; // 1.frac << 24
                if (e < 0) begin
                    float_to_int = 32'h00000000;
                end else if (e > 31) begin
                    float_to_int = sign ? 32'h80000000 : 32'h7FFFFFFF;
                end else if (e >= 24) begin
                    // integer part spans beyond fraction -> shift left
                    shift = e - 24;
                    uval = (mant << shift) >> 24; // keep lower 32 bits
                    if (sign)
                        float_to_int = ~uval + 1; // two's complement
                    else
                        float_to_int = uval;
                end else begin
                    // need to shift right to drop fraction
                    shift = 24 - e;
                    uval = (mant >> shift); // integer part
                    if (sign)
                        float_to_int = ~uval + 1;
                    else
                        float_to_int = uval;
                end
            end
        end
    endfunction

    // float -> unsigned int (round toward zero), saturate on overflow
    function [31:0] float_to_uint;
        input [31:0] f;
        reg [7:0] exp;
        reg [22:0] frac;
        integer e;
        reg [47:0] mant;
        reg [31:0] uval;
        integer shift;
        begin
            exp  = f[30:23];
            frac = f[22:0];

            if (is_nan(f) || (exp == 8'hFF)) begin
                float_to_uint = 32'hFFFFFFFF;
            end else if (exp == 8'h00) begin
                float_to_uint = 32'h00000000;
            end else begin
                e = exp - 127;
                mant = {1'b1, frac, 24'd0};
                if (e < 0) begin
                    float_to_uint = 32'h00000000;
                end else if (e > 31) begin
                    float_to_uint = 32'hFFFFFFFF;
                end else if (e >= 24) begin
                    shift = e - 24;
                    uval = (mant << shift) >> 24;
                    float_to_uint = uval;
                end else begin
                    shift = 24 - e;
                    uval = (mant >> shift);
                    float_to_uint = uval;
                end
            end
        end
    endfunction

    // int (signed) -> float (simple implementation, no precise rounding modes)
    function [31:0] int_to_float;
        input [31:0] i;
        reg sign;
        reg [31:0] absval;
        integer msb;
        integer idx;
        reg [22:0] fract;
        reg [7:0] exponent;
        reg [47:0] tmp;
        begin
            if (i == 32'h00000000) begin
                int_to_float = 32'h00000000;
            end else begin
                sign = i[31];
                absval = sign ? (~i + 1) : i;
                // find msb position
                msb = -1;
                for (idx = 31; idx >= 0; idx = idx - 1) begin
                    if (absval[idx] && (msb == -1)) begin
                        msb = idx;
                    end
                end
                if (msb < 0) begin
                    int_to_float = 32'h00000000;
                end else begin
                    exponent = msb + 127;
                    if (msb <= 23) begin
                        fract = (absval << (23 - msb)) & 23'h7FFFFF;
                    end else begin
                        fract = (absval >> (msb - 23)) & 23'h7FFFFF;
                    end
                    int_to_float = {sign, exponent, fract};
                end
            end
        end
    endfunction

    // FCLASS helper (produce 32-bit mask; mapping chosen here is simple)
    function [31:0] fclass_mask;
        input [31:0] f;
        reg sign;
        reg [7:0] exp;
        reg [22:0] frac;
        reg [31:0] outm;
        begin
            sign = f[31];
            exp  = f[30:23];
            frac = f[22:0];
            outm = 32'h0;
            if (exp == 8'hFF) begin
                if (frac == 0) begin
                    outm = sign ? 32'h00000001 : 32'h00000080; // neg inf / pos inf
                end else begin
                    outm = 32'h00000100; // NaN
                end
            end else if (exp == 8'h00) begin
                if (frac == 0) begin
                    outm = sign ? 32'h00000008 : 32'h00000010; // negative zero / positive zero
                end else begin
                    outm = sign ? 32'h00000004 : 32'h00000020; // subnormal neg/pos
                end
            end else begin
                outm = sign ? 32'h00000002 : 32'h00000040; // normal neg/pos
            end
            fclass_mask = outm;
        end
    endfunction

    // -------------------------
    // fmin/fmax helpers (respect NaN: return the non-NaN operand; if both NaN return first)
    // -------------------------
    function [31:0] fmin_fn;
        input [31:0] x;
        input [31:0] y;
        begin
            if (is_nan(x) && is_nan(y)) begin
                fmin_fn = x;
            end else if (is_nan(x)) begin
                fmin_fn = y;
            end else if (is_nan(y)) begin
                fmin_fn = x;
            end else begin
                fmin_fn = float_lt(x,y) ? x : y;
            end
        end
    endfunction

    function [31:0] fmax_fn;
        input [31:0] x;
        input [31:0] y;
        begin
            if (is_nan(x) && is_nan(y)) begin
                fmax_fn = x;
            end else if (is_nan(x)) begin
                fmax_fn = y;
            end else if (is_nan(y)) begin
                fmax_fn = x;
            end else begin
                fmax_fn = float_lt(x,y) ? y : x;
            end
        end
    endfunction

    // -------------------------
    // Main combinational selection
    // -------------------------
    always @(*) begin
        case (in_FPU_Op)
            FADD_S:   out_data = add_out;
            FSUB_S:   out_data = sub_out;
            FMUL_S:   out_data = mul_out;
            FDIV_S:   out_data = div_out;
            FSQRT_S:  out_data = sqrt_out;

            FSGNJ_S:  out_data = { in_rs2[31], in_rs1[30:0] };
            FSGNJN_S: out_data = { ~in_rs2[31], in_rs1[30:0] };
            FSGNJX_S: out_data = { in_rs1[31] ^ in_rs2[31], in_rs1[30:0] };

            FEQ_S:    out_data = {31'd0, float_eq(in_rs1, in_rs2)};
            FLT_S:    out_data = {31'd0, float_lt(in_rs1, in_rs2)};
            FLE_S:    out_data = {31'd0, float_le(in_rs1, in_rs2)};

            FCVT_W_S:  out_data = float_to_int(in_rs1);
            FCVT_WU_S: out_data = float_to_uint(in_rs1);
            FCVT_S_W:  out_data = int_to_float(in_rs1);
            FCVT_S_WU: out_data = int_to_float(in_rs1);

            FMV_X_W:   out_data = in_rs1;
            FMV_W_X:   out_data = in_rs1;

            FCLASS_S:  out_data = fclass_mask(in_rs1);

            FMIN_S:    out_data = fmin_fn(in_rs1, in_rs2);
            FMAX_S:    out_data = fmax_fn(in_rs1, in_rs2);

            // FMA family (not implemented) -> return zero
            FMADD_S,
            FMSUB_S,
            FNMSUB_S,
            FNMADD_S:  out_data = 32'h00000000;

            default:   out_data = 32'h00000000;
        endcase
    end

endmodule
