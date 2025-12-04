module Sign_Extend (
    // Input lệnh 32-bit
    input [31:0] In,        // Toàn bộ lệnh đầu vào
    
    // Nguồn mở rộng hằng số
    input [1:0] ImmSrc,     // Chọn loại mở rộng
        // 2'b00: I-type (load, I-type arithmetic)
        // 2'b01: S-type (store instructions)
    
    // Output hằng số đã mở rộng
    output [31:0] Imm_Ext   // Hằng số 32-bit sau khi mở rộng dấu
);

    // Logic mở rộng dấu
    assign Imm_Ext = 
        // I-type (load, I-type arithmetic)
        // Mở rộng immediate 12-bit
        (ImmSrc == 2'b00) ? {{20{In[31]}}, In[31:20]} : 
        
        // S-type (store instructions)
        // Ghép immediate từ hai phần của lệnh
        (ImmSrc == 2'b01) ? {{20{In[31]}}, In[31:25], In[11:7]} : 
        
        // Mặc định trả về 0 nếu không khớp
        32'h00000000; 

    // Giải thích chi tiết:
    // {{20{In[31]}} => Lặp lại bit dấu 20 lần để mở rộng
    // In[31:20] => 12-bit immediate cho I-type
    // In[31:25], In[11:7] => Ghép immediate cho S-type
endmodule