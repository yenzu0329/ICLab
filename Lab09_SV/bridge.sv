module bridge(input clk, INF.bridge_inf inf);

wire rst_n;
wire in_valid;
wire read_flg;
wire write_flg;

assign rst_n = inf.rst_n;
assign in_valid =  inf.C_in_valid;
assign read_flg =  inf.C_in_valid && inf.C_r_wb;
assign write_flg = inf.C_in_valid && !inf.C_r_wb;

// ======================
//   DRAM Read controls
// ======================
// AXI Read Address Channel
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)                   inf.AR_VALID <= 0;
    else begin
        if(read_flg)             inf.AR_VALID <= 1;
        else if(inf.AR_READY)    inf.AR_VALID <= 0;
        else                     inf.AR_VALID <= inf.AR_VALID;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)                   inf.AR_ADDR <= 0;
    else begin
        if(read_flg)             inf.AR_ADDR <= {1'b1, 5'b0, inf.C_addr, 3'b0};
        else                     inf.AR_ADDR <= inf.AR_ADDR;
    end
end

//   AXI Read Data Channel
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)                   inf.R_READY <= 0;
    else                         inf.R_READY <= 1;
end


// =======================
//   DRAM write controls
// =======================
// AXI Write Address Channel
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)                   inf.AW_VALID <= 0;
    else begin
        if(write_flg)            inf.AW_VALID <= 1;
        else if(inf.AW_READY)    inf.AW_VALID <= 0;
        else                     inf.AW_VALID <= inf.AW_VALID;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)                   inf.AW_ADDR <= 0;
    else begin
        if(write_flg)            inf.AW_ADDR <= {1'b1, 5'b0, inf.C_addr, 3'b0};
        else                     inf.AW_ADDR <= inf.AW_ADDR;
    end
end

// AXI Write Data Channel
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)                   inf.W_VALID <= 0;
    else begin  
        if(inf.AW_READY)         inf.W_VALID <= 1;
        else if(inf.W_READY)     inf.W_VALID <= 0;
        else                     inf.W_VALID <= inf.W_VALID;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)                   inf.W_DATA <= 0;
    else begin
        if(write_flg)            inf.W_DATA <= inf.C_data_w;
        else                     inf.W_DATA <= inf.W_DATA;
    end
end

// AXI Write Response Channel 
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)                   inf.B_READY <= 0;
    else                         inf.B_READY <= 1;
end

// ===================
//   Bridge controls
// ===================
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)                   inf.C_out_valid <= 0;
    else                         inf.C_out_valid <= (inf.R_VALID || inf.B_VALID);
end
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)                   inf.C_data_r <= 0;
    else if(inf.R_VALID)         inf.C_data_r <= inf.R_DATA;
    else                         inf.C_data_r <= 0;
end

endmodule