//===========================================================================
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : EC_TOP.v
//   	Module Name : EC_TOP
//===========================================================================

//synopsys translate_off
`include "INV_IP.v"
//synopsys translate_on

module EC_TOP(
    // Input signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Output signals
    out_valid, out_Rx, out_Ry
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [6-1:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
output reg out_valid;
output reg [6-1:0] out_Rx, out_Ry;

// ==========
// Parameters
// ========== 
parameter IP_WIDTH = 6;

//=======================
// Wire & Reg Declaration
//=======================
reg [1:0]  counter, next_counter;
reg [6:0]  lv1_out;
reg [5:0]  lv1_r;

reg [5:0]  inv_in;
reg [5:0]  comb_in, comb_out;
reg [5:0]  square_in, square_r;
reg [11:0] square_out;

reg [7:0]  sub1_out, mul1_out, sel1_out;
reg [5:0]  sel1_r;

reg [6:0]  sel2_out;
reg [5:0]  sel3_in, sel3_r;
reg [6:0]  sel3_out;

reg [5:0]  mul2_in;
reg [11:0] mul2_out;

reg [5:0]  Px, Py, Qx, Qy, prime, a, Rx, Ry;
reg [5:0]  next_Px, next_Py, next_Qx, next_Qy, next_prime, next_a;
wire [5:0] inv_out;

//========
// Design
//========
// counter
always @(*) begin
    next_counter = 0;
    if(in_valid || counter != 0) begin
        next_counter = counter + 1;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  counter <= 0;
    else        counter <= next_counter;
end

// output
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else begin
        if(next_counter == 3) begin
            out_valid <= 1;
        end
        else begin
            out_valid <= 0;
        end
    end
end
always @(*) begin
    if(out_valid) begin
        out_Rx = Rx;
        out_Ry = Ry;
    end
    else begin
        out_Rx = 0;
        out_Ry = 0;
    end
end

// computation units
always @(*) begin
    lv1_out = (in_Px == in_Qx) ? (in_Py << 2) : (in_Qx - in_Px + in_prime);
    lv1_r   = (lv1_out >= in_prime) ? (lv1_out - in_prime) : lv1_out;
end

always @(posedge clk) begin
    inv_in <= lv1_r;
    comb_in <= comb_out;
end

always @(*) begin
    square_in  = (counter[1]) ? comb_in : Px;
    square_out = square_in * square_in;
    square_r   = square_out % prime;

    sub1_out = square_r - Px - Qx + 2 * prime;
    mul1_out = square_out * 3;
    sel1_out = (counter[1]) ? sub1_out : mul1_out;
    sel1_r   = sel1_out % prime;
    //sel_r = (sel_out * 2 > prime) ? (sel_out - 2 * prime) : ((sel_out > prime) ? (sel_out - prime) : sel_out);

    sel2_out = (counter[1]) ? (Px - sel1_r + prime) : (sel1_r + a);
    sel3_r   = (sel3_out >= prime) ? (sel3_out - prime) : sel3_out;

    mul2_in  = (counter[1]) ? comb_in : inv_out;
    mul2_out = mul2_in * sel3_r;
    comb_out = mul2_out % prime;
end

always @(*) begin
    sel3_in = (counter[1]) ? comb_in : Qy;
    if(counter[1]) begin
        if(counter[0])     sel3_out = sel3_in - Py + prime;  // counter == 3
        else               sel3_out = sel2_out;              // counter == 2
    end
    else begin                                               // counter == 1
        if(in_Px == in_Qx) sel3_out = sel2_out;
        else               sel3_out = sel3_in - Py + prime;
    end
end

always @(*) begin
    Ry = sel3_r;
end

always @(posedge clk) begin
    Rx <= sel1_r;
end

// save inputs
always @(*) begin
    if(in_valid) begin
        next_Px = in_Px;
        next_Py = in_Py;
        next_Qx = in_Qx;
        next_Qy = in_Qy;
        next_a  = in_a;
        next_prime = in_prime;
    end
    else begin
        next_Px = Px;
        next_Py = Py;
        next_Qx = Qx;
        next_Qy = Qy;
        next_a  = a;
        next_prime = prime;
    end
end

always @(posedge clk) begin
    Px <= next_Px;
    Py <= next_Py;
    Qx <= next_Qx;
    Qy <= next_Qy;
    a  <= next_a;
    prime <= next_prime;
end

INV_IP #(.IP_WIDTH(IP_WIDTH)) inv_ip (.IN_1(prime), .IN_2(inv_in), .OUT_INV(inv_out));
endmodule

