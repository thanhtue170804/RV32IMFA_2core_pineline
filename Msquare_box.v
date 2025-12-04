module Msquare_box (Ai,Bi,Hi,Gi,Pi);
    input Ai,Bi; 
    output Hi,Gi,Pi;
    or m1 (Hi,Ai,Bi);
    and m2 (Gi,Ai,Bi);
    or m3 (Pi,Ai,Bi);
endmodule