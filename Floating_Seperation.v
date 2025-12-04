module Floating_Seperation (A,B,Sign_A,Sign_B,Mantissa_A,Mantissa_B,Exponent_A,Exponent_B);
  input [31:0]A,B;
  output Sign_A; 
  output Sign_B;
  output [22:0]Mantissa_A,Mantissa_B;
  output [7:0]Exponent_A,Exponent_B;
  
  
  assign Sign_A=A[31];
  assign Sign_B=B[31];
  assign Exponent_A=A[30:23];
  assign Exponent_B=B[30:23];
  assign Mantissa_A=A[22:0];
  assign Mantissa_B=B[22:0];
  
  
endmodule