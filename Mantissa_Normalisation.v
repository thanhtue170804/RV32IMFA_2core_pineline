module Mantissa_Normalisation (A_In,B_In,A_Out,B_Out);
  input [22:0]A_In,B_In;
  output [23:0]A_Out,B_Out; 
  
  
  assign A_Out={1'b1,A_In};
  assign B_Out={1'b1,B_In};
  
endmodule