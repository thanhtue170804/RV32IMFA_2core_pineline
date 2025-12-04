module M_black_ball (Gi,Pi,Gk,Pk,Gij,Pij);
input Gi,Pi,Gk,Pk;
output Gij,Pij; 
wire a;
and m1 (a,Pi,Gk);
and m2 (Pij,Pi,Pk);
or m3 (Gij,Gi,a);
endmodule