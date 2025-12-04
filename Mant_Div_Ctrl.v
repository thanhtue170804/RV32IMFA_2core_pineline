module Mant_Div_Ctrl (
    input in_Clk, in_start, in_Rst_N,
    output reg out_load, out_shift_en, out_stall
);
    reg [4:0] State_Reg;

    always @(posedge in_Clk or negedge in_Rst_N) begin
        if (!in_Rst_N) begin
            State_Reg <= 5'd0;
            out_load <= 1'b0;
            out_shift_en <= 1'b0;
            out_stall <= 1'b0;
        end else begin
            case (State_Reg)
                5'd0: begin
                    if (in_start) begin
                        State_Reg <= 5'd1;
                        out_load <= 1'b1;
                        out_stall <= 1'b1;
                    end
                end
                5'd1: begin
                    out_load <= 1'b0;
                    out_shift_en <= 1'b1;
                    State_Reg <= 5'd2;
                end
                5'd2, 5'd3, 5'd4, 5'd5, 5'd6, 5'd7, 5'd8, 5'd9, 5'd10, 5'd11,
                5'd12, 5'd13, 5'd14, 5'd15, 5'd16, 5'd17, 5'd18, 5'd19, 5'd20,
                5'd21, 5'd22, 5'd23: begin
                    State_Reg <= State_Reg + 5'd1;
                end
                5'd24: begin
                    out_shift_en <= 1'b0;
                    out_stall <= 1'b0;
                    State_Reg <= 5'd0;
                end
                default: begin
                    State_Reg <= 5'd0;
                    out_load <= 1'b0;
                    out_shift_en <= 1'b0;
                    out_stall <= 1'b0;
                end
            endcase
        end
    end
endmodule