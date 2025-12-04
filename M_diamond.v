module M_diamond(Hi,Ci,Si);
input Hi,Ci;
output Si; 
xor m1 (Si,Hi,Ci);
endmodule