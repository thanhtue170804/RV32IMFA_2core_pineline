module M_kogge_stone (a,b,s);
  input [7:0]a,b;
  output [7:0]s; 
  wire [7:0]h,g,p;
  wire [7:0]e,f,w,x,y,z;
  wire q;
  assign q = 0;
//first block//

Msquare_box block10 (.Ai(a[0]),.Bi(b[0]),.Hi(h[0]),.Gi(g[0]),.Pi(p[0]));
Msquare_box block11 (.Ai(a[1]),.Bi(b[1]),.Hi(h[1]),.Gi(g[1]),.Pi(p[1]));
Msquare_box block12 (.Ai(a[2]),.Bi(b[2]),.Hi(h[2]),.Gi(g[2]),.Pi(p[2]));
Msquare_box block13 (.Ai(a[3]),.Bi(b[3]),.Hi(h[3]),.Gi(g[3]),.Pi(p[3]));
Msquare_box block14 (.Ai(a[4]),.Bi(b[4]),.Hi(h[4]),.Gi(g[4]),.Pi(p[4]));
Msquare_box block15 (.Ai(a[5]),.Bi(b[5]),.Hi(h[5]),.Gi(g[5]),.Pi(p[5]));
Msquare_box block16 (.Ai(a[6]),.Bi(b[6]),.Hi(h[6]),.Gi(g[6]),.Pi(p[6]));
Msquare_box block17 (.Ai(a[7]),.Bi(b[7]),.Hi(h[7]),.Gi(g[7]),.Pi(p[7]));

//second block//

M_white_ball block20  (.A(g[0]),.B(p[0]),.C(e[0]),.D(f[0]));

M_black_ball block21  (.Gi(g[1]),.Pi(p[1]),.Gk(g[0]),.Pk(p[0]),.Gij(e[1]),.Pij(f[1]));
M_black_ball block22  (.Gi(g[2]),.Pi(p[2]),.Gk(g[1]),.Pk(p[1]),.Gij(e[2]),.Pij(f[2]));
M_black_ball block23  (.Gi(g[3]),.Pi(p[3]),.Gk(g[2]),.Pk(p[2]),.Gij(e[3]),.Pij(f[3]));
M_black_ball block24  (.Gi(g[4]),.Pi(p[4]),.Gk(g[3]),.Pk(p[3]),.Gij(e[4]),.Pij(f[4]));
M_black_ball block25  (.Gi(g[5]),.Pi(p[5]),.Gk(g[4]),.Pk(p[4]),.Gij(e[5]),.Pij(f[5]));
M_black_ball block26  (.Gi(g[6]),.Pi(p[6]),.Gk(g[5]),.Pk(p[5]),.Gij(e[6]),.Pij(f[6]));
M_black_ball block27  (.Gi(g[7]),.Pi(p[7]),.Gk(g[6]),.Pk(p[6]),.Gij(e[7]),.Pij(f[7]));

//third block//

M_white_ball block30  (.A(e[0]),.B(f[0]),.C(w[0]),.D(x[0]));
M_white_ball block31  (.A(e[1]),.B(f[1]),.C(w[1]),.D(x[1]));

M_black_ball block32  (.Gi(e[2]),.Pi(f[2]),.Gk(e[0]),.Pk(f[0]),.Gij(w[2]),.Pij(x[2]));
M_black_ball block33  (.Gi(e[3]),.Pi(f[3]),.Gk(e[1]),.Pk(f[1]),.Gij(w[3]),.Pij(x[3]));
M_black_ball block34  (.Gi(e[4]),.Pi(f[4]),.Gk(e[2]),.Pk(f[2]),.Gij(w[4]),.Pij(x[4]));
M_black_ball block35  (.Gi(e[5]),.Pi(f[5]),.Gk(g[3]),.Pk(f[3]),.Gij(w[5]),.Pij(x[5]));
M_black_ball block36  (.Gi(e[6]),.Pi(f[6]),.Gk(g[4]),.Pk(f[4]),.Gij(w[6]),.Pij(x[6]));
M_black_ball block37  (.Gi(e[7]),.Pi(f[7]),.Gk(g[5]),.Pk(f[5]),.Gij(w[7]),.Pij(x[7]));


//fourth block//

M_white_ball block40  (.A(w[0]),.B(x[0]),.C(y[0]),.D(z[0]));
M_white_ball block41  (.A(w[1]),.B(x[1]),.C(y[1]),.D(z[1]));
M_white_ball block42  (.A(w[2]),.B(x[2]),.C(y[2]),.D(z[2]));
M_white_ball block43  (.A(w[3]),.B(x[3]),.C(y[3]),.D(z[3]));

M_black_ball block44  (.Gi(w[4]),.Pi(x[4]),.Gk(w[0]),.Pk(x[0]),.Gij(y[4]),.Pij(z[4]));
M_black_ball block45  (.Gi(w[5]),.Pi(x[5]),.Gk(w[1]),.Pk(x[1]),.Gij(y[5]),.Pij(z[5]));
M_black_ball block46  (.Gi(w[6]),.Pi(x[6]),.Gk(w[2]),.Pk(x[2]),.Gij(y[6]),.Pij(z[6]));
M_black_ball block47  (.Gi(w[7]),.Pi(x[7]),.Gk(w[3]),.Pk(x[3]),.Gij(y[7]),.Pij(z[7]));

//fifth block//

M_diamond block50 (.Hi(h[0]),.Ci(q),.Si(s[0]));
M_diamond block51 (.Hi(h[1]),.Ci(y[0]),.Si(s[1]));
M_diamond block52 (.Hi(h[2]),.Ci(y[1]),.Si(s[2]));
M_diamond block53 (.Hi(h[3]),.Ci(y[2]),.Si(s[3]));
M_diamond block54 (.Hi(h[4]),.Ci(y[3]),.Si(s[4]));
M_diamond block55 (.Hi(h[5]),.Ci(y[4]),.Si(s[5]));
M_diamond block56 (.Hi(h[6]),.Ci(y[5]),.Si(s[6]));
M_diamond block57 (.Hi(h[7]),.Ci(y[6]),.Si(s[7]));

endmodule