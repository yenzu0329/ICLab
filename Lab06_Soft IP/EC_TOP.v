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
reg valid_d1, valid_d2;
reg [6:0]  shift1;
reg [6:0]  sub_1, sub_2, sub_4, sub_5, sub_6;
reg [6:0]  sel_1, sel_2;
reg [6:0]  add_2, add_4;
reg [11:0] mul_1, mul_2, mul_4, mul_5;
reg [5:0]  mul_1_a, mul_1_b;

reg [5:0]  s;
reg [5:0]  mod_1, mod_2, mod_4, mod_5;
reg [5:0]  reduce_1, reduce_2, reduce_4, reduce_5;
reg [5:0]  next_mod_1;
reg [5:0]  next_reduce_1;

reg [5:0]  Px, Py, Qx, Qy, prime, a, Rx, Ry;
reg [5:0]  next_prime;
wire [5:0] inv;

//========
// Design
//========
// output
always @(posedge clk) begin
    if(in_valid)   valid_d1 <= 1;
    else           valid_d1 <= 0;
end

always @(posedge clk) begin
    valid_d2 <= valid_d1;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_Rx <= 0;
        out_Ry <= 0;
    end
    else begin
        if(valid_d2) begin
            out_valid <= 1;
            out_Rx <= Rx;
            out_Ry <= Ry;
        end
        else begin
            out_valid <= 0;
            out_Rx <= 0;
            out_Ry <= 0;
        end
    end
end

// computation unit
always @(*) begin
    shift1 = in_Py << 1;
    sub_1 = in_Qx - in_Px + in_prime;
    sel_1 = (in_Qx == in_Px) ? shift1 : sub_1;
    next_reduce_1 = (sel_1 >= in_prime) ? (sel_1-in_prime) : sel_1;

    if(valid_d1) begin      // 2st cycle
        mul_1_a = inv;
        mul_1_b = reduce_2;
    end
    else if(valid_d2) begin // 3st cycle
        mul_1_a = s;
        mul_1_b = reduce_5;
    end
    else begin             // 1st cycle
        mul_1_a = in_Px;
        mul_1_b = in_Px;
    end
    mul_1 = mul_1_a * mul_1_b;
    next_mod_1 = mul_1 % next_prime;

    mul_2 = mod_1 * 3;
    mod_2 = mul_2 % prime;
    add_2 = mod_2 + a;
    sub_2 = Qy - Py + prime;
    sel_2 = (Qx == Px) ? add_2 : sub_2;
    reduce_2 = (sel_2 >= prime) ? (sel_2-prime) : sel_2;

    s = mod_1;
    mul_4 = s * s;
    mod_4 = mul_4 % prime;
    add_4 = Px + Qx;
    reduce_4 = (add_4 >= prime) ? (add_4-prime) : add_4;
    sub_4[5:0] = mod_4 - reduce_4;
    sub_4[6] = (reduce_4 > mod_4);
    Rx = (sub_4[6]) ? (sub_4+prime) : sub_4;

    sub_5[5:0] = Px - Rx;
    sub_5[6] = (Rx > Px);
    reduce_5 = (sub_5[6]) ? (sub_5+prime) : sub_5;
    mod_5 = next_mod_1;
    sub_6[5:0] = mod_5 - Py;
    sub_6[6] = (Py > mod_5);
    Ry = (sub_6[6]) ? (sub_6+prime) : sub_6;
end

always @(posedge clk) begin
    reduce_1 <= next_reduce_1;
    mod_1 <= next_mod_1;
end

// save inputs
always @(posedge clk) begin
    if(in_valid) begin
        Px <= in_Px;
        Py <= in_Py;
        Qx <= in_Qx;
        Qy <= in_Qy;
        a  <= in_a;
    end
    else begin
        Px <= Px;
        Py <= Py;
        Qx <= Qx;
        Qy <= Qy;
        a  <= a;
    end
end

always @(*) begin
    if(in_valid) next_prime = in_prime;
    else         next_prime = prime;
end

always @(posedge clk) begin
    prime <= next_prime;
end

INV_IP #(.IP_WIDTH(IP_WIDTH)) inv_ip (.IN_1(reduce_1), .IN_2(prime), .OUT_INV(inv));
endmodule

