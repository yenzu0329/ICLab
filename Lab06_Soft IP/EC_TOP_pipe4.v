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
reg [2:0]  counter, next_counter;
reg [6:0]  sel_out;
reg [6:0]  sub_out;
reg [5:0]  sub_in1, sub_in2;
reg [6:0]  add_out;
reg [5:0]  add_in1, add_in2;
reg [5:0]  reduce_out;
//reg [5:0]  reduce_x3_out;

reg [11:0] mul_out;
reg [5:0]  mul_in1, mul_in2;
//reg [7:0]  mul_x3_out;
reg [5:0]  mod_out;

reg [5:0]  Px, Py, Qx, Qy, prime, a, s, Rx, Ry;
wire [5:0] inv_out;

// registers
reg [5:0]  reg_reduce_out, reg_inv_out, reg_mod_out;
reg [5:0]  reg_Px, reg_Py, reg_Qx, reg_Qy, reg_prime, reg_a;

//========
// Design
//========
// counter
always @(*) begin
    next_counter = 0;
    if(counter == 5) begin
        next_counter = 0;
    end
    else if(in_valid || counter != 0) begin
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
        out_Rx <= 0;
        out_Ry <= 0;
    end
    else begin
        if(counter == 5) begin
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


// computation units
always @(*) begin
    sub_out = sub_in1 - sub_in2 + prime;
    add_out = add_in1 + add_in2;
    sel_out = ((Qx == Px && counter < 2) || counter == 2) ? add_out : sub_out;
    reduce_out = (sel_out >= prime) ? (sel_out - prime) : sel_out;

    mul_out = mul_in1 * mul_in2;
    mod_out = mul_out % prime;
    
    // mul_x3_out = Px * 3;
    // reduce_x3_out = mul_x3_out % prime;
end

// input of computation units
always @(*) begin
    case(next_counter)
    1: begin
        sub_in1 = Qx;
        sub_in2 = Px;
        add_in1 = Py;
        add_in2 = Py;
        mul_in1 = Px;
        mul_in2 = 3;
    end
    2: begin
        sub_in1 = Qy;
        sub_in2 = Py;
        add_in1 = a;
        add_in2 = mod_out;
        mul_in1 = Px;
        mul_in2 = reg_mod_out;
    end
    3: begin
        sub_in1 = 'dx;
        sub_in2 = 'dx;
        add_in1 = Px;
        add_in2 = Qx;
        mul_in1 = reg_inv_out;
        mul_in2 = reg_reduce_out;
    end
    4: begin
        sub_in1 = mod_out;
        sub_in2 = reg_reduce_out;
        add_in1 = 'dx;
        add_in2 = 'dx;
        mul_in1 = s;
        mul_in2 = s;
    end
    5: begin
        sub_in1 = Px;
        sub_in2 = reg_reduce_out;
        add_in1 = 'dx;
        add_in2 = 'dx;
        mul_in1 = s;
        mul_in2 = reduce_out;
    end
    default: begin
        sub_in1 = reg_mod_out;
        sub_in2 = Py;
        add_in1 = 'dx;
        add_in2 = 'dx;
        mul_in1 = 'dx;
        mul_in2 = 'dx;
    end
    endcase
end

always @(*) begin
    Ry = reduce_out;
end

// registers
always @(posedge clk) begin
    reg_reduce_out <= reduce_out;
    reg_inv_out <= inv_out;
    reg_mod_out <= mod_out;
end

always @(posedge clk) begin
    if(next_counter == 3)  s <= mod_out;
    else                   s <= s;
end

always @(posedge clk) begin
    if(next_counter == 4)  Rx <= reduce_out;
    else                   Rx <= Rx;
end

// save inputs
always @(*) begin
    if(in_valid) begin
        Px = in_Px;
        Py = in_Py;
        Qx = in_Qx;
        Qy = in_Qy;
        a  = in_a;
        prime = in_prime;
    end
    else begin
        Px = reg_Px;
        Py = reg_Py;
        Qx = reg_Qx;
        Qy = reg_Qy;
        a  = reg_a;
        prime = reg_prime;
    end
end

always @(posedge clk) begin
    reg_Px <= Px;
    reg_Py <= Py;
    reg_Qx <= Qx;
    reg_Qy <= Qy;
    reg_a  <= a;
    reg_prime <= prime;
end

INV_IP #(.IP_WIDTH(IP_WIDTH)) inv_ip (.IN_1(prime), .IN_2(reg_reduce_out), .OUT_INV(inv_out));
endmodule

