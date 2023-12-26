//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//`include "Usertype_PKG.sv"

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

covergroup Spec1 @(posedge clk iff(inf.amnt_valid));
    // d _money: 5 bins * 10 time
    option.per_instance = 1;
    Check_Money: coverpoint inf.D.d_money {
        option.at_least = 10;
        bins b1 = {[    0:12000]};
        bins b2 = {[12001:24000]};
        bins b3 = {[24001:36000]};
        bins b4 = {[36001:48000]};
        bins b5 = {[48001:60000]};
    }
endgroup

covergroup Spec2 @(posedge clk iff(inf.id_valid));
    // d_id: 256 bins * 2 time
    option.per_instance = 1;
    Check_ID: coverpoint inf.D.d_id[0] {
        option.at_least = 2;
        option.auto_bin_max = 256;
    }
endgroup

covergroup Spec3 @(posedge clk iff(inf.act_valid));
    // d_act: 16 bins * 10 time
    option.per_instance = 1;
    Check_Act: coverpoint inf.D.d_act[0] {
        option.at_least = 10;
        bins b[] = (Buy, Check, Deposit, Return => Buy, Check, Deposit, Return);
    }
endgroup

covergroup Spec4 @(posedge clk iff(inf.item_valid));
    // d_item: 3 bins * 20 time
    option.per_instance = 1;
    Check_Item: coverpoint inf.D.d_item[0] {
        option.at_least = 20;
        bins b_large  = {Large};
        bins b_medium = {Medium};
        bins b_small  = {Small};
    }
endgroup

covergroup Spec5 @(negedge clk iff(inf.out_valid));
    // err_msg: 8 bins * 20 time
    option.per_instance = 1;
    Check_Err: coverpoint inf.err_msg {
        option.at_least = 20;
        bins b_INV_Not_Enough = {INV_Not_Enough};
        bins b_Out_of_money = {Out_of_money};
        bins b_INV_Full = {INV_Full};
        bins b_Wallet_is_Full = {Wallet_is_Full};
        bins b_Wrong_ID = {Wrong_ID};
        bins b_Wrong_Num = {Wrong_Num};
        bins b_Wrong_Item = {Wrong_Item};
        bins b_Wrong_act = {Wrong_act};
    }
endgroup

covergroup Spec6 @(negedge clk iff(inf.out_valid));
    // complete: 2 bins * 200 time
    option.per_instance = 1;
    Check_Complete: coverpoint inf.complete {
        option.at_least = 200;
    }
endgroup

//declare the cover group 
Spec1 cov_inst_1 = new();
Spec2 cov_inst_2 = new();
Spec3 cov_inst_3 = new();
Spec4 cov_inst_4 = new();
Spec5 cov_inst_5 = new();
Spec6 cov_inst_6 = new();

//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write other assertions at the below
// assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0)
// else
// begin
// 	$display("Assertion X is violated");
// 	$fatal; 
// end

// ==============================================================
//                             Assert 1
//          All outputs signals should be zero after reset
// ==============================================================
assert_1 : assert property (prop_Reset)
else begin
    $display("Assertion 1 is violated");
    $fatal; 
end

property prop_Reset;
    @(inf.rst_n) !inf.rst_n |-> 
        // Pattern
        ((inf.out_valid === 0) &&
        (inf.err_msg === No_Err) &&
        (inf.complete === 0) &&
        (inf.out_info === 0) &&
		// Bridge
		(inf.C_addr === 0) && (inf.C_data_w === 0) && (inf.C_in_valid === 0) && (inf.C_r_wb === 0) &&
        (inf.C_out_valid === 0) && (inf.C_data_r === 0) &&
		// DRAM
		(inf.AR_VALID === 0) && (inf.AR_ADDR === 0) && (inf.R_READY === 0) &&
        (inf.AW_VALID === 0) && (inf.AW_ADDR === 0) && (inf.W_VALID === 0) && (inf.W_DATA === 0) && (inf.B_READY === 0));
endproperty

// ==============================================================
//                             Assert 2
//          If action is completed, err_msg must be 4’b0
// ==============================================================
assert_2 : assert property (@(negedge clk) (inf.out_valid && inf.complete) |-> (inf.err_msg === No_Err))
else begin
    $display("Assertion 2 is violated");
    $fatal; 
end

// ==============================================================
//                             Assert 3
//     If action is not completed, out_info should be 32’b0
// ==============================================================
assert_3 : assert property (@(negedge clk) (inf.out_valid && !inf.complete) |-> (inf.out_info === 0))
else begin
    $display("Assertion 3 is violated");
    $fatal; 
end

// ==============================================================
//                             Assert 4
//     All input valid can only be high for exactly one cycle
// ==============================================================
assert_4a : assert property (@(posedge clk) (inf.id_valid) |=> (!inf.id_valid))
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4b : assert property (@(posedge clk) (inf.act_valid) |=> (!inf.act_valid))
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4c : assert property (@(posedge clk) (inf.item_valid) |=> (!inf.item_valid))
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4d : assert property (@(posedge clk) (inf.amnt_valid) |=> (!inf.amnt_valid))
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4e : assert property (@(posedge clk) (inf.num_valid) |=> (!inf.num_valid))
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

// ==============================================================
//                             Assert 5
//     The five valid signals won’t overlap with each other
// ==============================================================
assert_5 : assert property (@(posedge clk) $onehot0 ({inf.id_valid, inf.act_valid, inf.amnt_valid, inf.item_valid, inf.num_valid}))
else begin
    $display("Assertion 5 is violated");
    $fatal; 
end

// ==============================================================
//                             Assert 6
//              The gap between each input valid is
//             at least 1 cycle and at most 5 cycles
// ==============================================================
logic  all_zero;
logic  wo_act, detect_act;
logic  wo_item, detect_item;
logic  wo_num, detect_num;
logic  wo_id, detect_id;
logic  wo_amt, detect_amt;
logic  over_5_cycle;
logic  wait_out;

Action act_reg, act;
logic [2:0] counter;

assign all_zero = !inf.id_valid && !inf.act_valid && !inf.amnt_valid && !inf.item_valid && !inf.num_valid;

// ======== act ========
always_comb begin
    if(inf.act_valid)       act = inf.D;
    else if(inf.out_valid)  act = No_action;
    else                    act = act_reg;
end
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n)
        act_reg <= No_action;
    else
        act_reg <= act;
end

// ======== wo_act ========
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n)
        detect_act <= 0;
    else if(act == No_action && inf.id_valid)
        detect_act <= 1;
    else if(inf.act_valid)
        detect_act <= 0;
    else
        detect_act <= detect_act;
end
always_ff @(posedge clk) begin
    if(!detect_act)
        wo_act <= 1;
    else if(detect_act && (inf.id_valid || inf.amnt_valid || inf.item_valid || inf.num_valid))
        wo_act <= 0;
    else
        wo_act <= wo_act;
end

// ======== wo_item ========
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n)
        detect_item <= 0;
    else if((act == Buy || act == Return) && inf.act_valid)
        detect_item <= 1;
    else if(inf.item_valid)
        detect_item <= 0;
    else
        detect_item <= detect_item;
end
always_ff @(posedge clk) begin
    if(!detect_item)
        wo_item <= 1;
    else if(detect_item && (inf.id_valid || inf.amnt_valid || inf.act_valid || inf.num_valid))
        wo_item <= 0;
    else
        wo_item <= wo_item;
end

// ======== wo_num ========
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n)
        detect_num <= 0;
    else if((act == Buy || act == Return) && inf.item_valid)
        detect_num <= 1;
    else if(inf.num_valid)
        detect_num <= 0;
    else
        detect_num <= detect_num;
end
always_ff @(posedge clk) begin
    if(!detect_num)
        wo_num <= 1;
    else if(detect_num && (inf.id_valid || inf.amnt_valid || inf.act_valid || inf.item_valid))
        wo_num <= 0;
    else
        wo_num <= wo_num;
end

// ======== wo_id ========
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n)
        detect_id <= 0;
    else if((act == Buy || act == Return) && inf.num_valid)
        detect_id <= 1;
    else if(act == Check && inf.act_valid)
        detect_id <= 1;
    else if(inf.id_valid || over_5_cycle)
        detect_id <= 0;
    else
        detect_id <= detect_id;
end
always_ff @(posedge clk) begin
    if(!detect_id)
        wo_id <= 1;
    else if(detect_id && (inf.num_valid || inf.amnt_valid || inf.act_valid || inf.item_valid))
        wo_id <= 0;
    else
        wo_id <= wo_id;
end

// ======== wo_amt ========
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n)
        detect_amt <= 0;
    else if(act == Deposit && inf.act_valid)
        detect_amt <= 1;
    else if(inf.amnt_valid)
        detect_amt <= 0;
    else
        detect_amt <= detect_amt;
end
always_ff @(posedge clk) begin
    if(!detect_amt)
        wo_amt <= 1;
    else if(detect_amt && (inf.num_valid || inf.id_valid || inf.act_valid || inf.item_valid))
        wo_amt <= 0;
    else
        wo_amt <= wo_amt;
end

// ======== over_5_cycle ========
assign over_5_cycle = (counter == 6);
always_ff @(posedge clk) begin
    if(act == Check)
        counter <= (counter == 7) ? counter : (counter + 1);
    else
        counter <= 0;
end

// ======== wait_out ========
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n)
        wait_out <= 0;
    else if((act == Buy || act == Return) && inf.id_valid)
        wait_out <= 1;
    else if((act == Check) && (inf.id_valid || over_5_cycle))
        wait_out <= 1;
    else if((act == Deposit) && inf.amnt_valid)
        wait_out <= 1;
    else if(inf.out_valid)
        wait_out <= 0;
    else
        wait_out <= wait_out;
end

assert_6a : assert property (@(posedge clk) (act == No_action && inf.id_valid) |=> all_zero ##[1:5] (inf.act_valid && wo_act))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6b : assert property (@(posedge clk) (act == No_action) |-> (!inf.act_valid && !inf.amnt_valid && !inf.item_valid && !inf.num_valid))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6c : assert property (@(posedge clk) ((act == Buy || act == Return) && inf.act_valid) |=> all_zero ##[1:5] (inf.item_valid && wo_item))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6d : assert property (@(posedge clk) ((act == Buy || act == Return) && inf.item_valid) |=> all_zero ##[1:5] (inf.num_valid && wo_num))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6e : assert property (@(posedge clk) ((act == Buy || act == Return) && inf.num_valid) |=> all_zero ##[1:5] (inf.id_valid && wo_id))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6f : assert property (@(posedge clk) (act == Check && inf.act_valid) |=> all_zero ##[1:5] ((inf.id_valid || over_5_cycle) && wo_id))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6g : assert property (@(posedge clk) (act == Deposit && inf.act_valid) |=> all_zero ##[1:5] (inf.amnt_valid && wo_amt))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6h : assert property (@(posedge clk) (wait_out) |-> (all_zero))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6j : assert property (@(posedge clk) $rose(inf.rst_n) |-> all_zero ##[1:5] inf.id_valid)
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

// ==============================================================
//                             Assert 7
//              Out_valid will be high for one cycle
// ==============================================================
assert_7 : assert property (@(posedge clk) (inf.out_valid) |=> (!inf.out_valid))
else begin
    $display("Assertion 7 is violated");
    $fatal; 
end

// ==============================================================
//                             Assert 8
//              Next operation will be valid 2-10 cycles 
//                      after out_valid fall
// ==============================================================
assert_8 : assert property (@(posedge clk) (inf.out_valid) |=> all_zero ##[1:9] (inf.id_valid || inf.act_valid))
else begin
    $display("Assertion 8 is violated");
    $fatal; 
end

// ==============================================================
//                             Assert 9
//       Latency should be < 10000 cycle for each operation.
// ==============================================================
logic [14:0] counter_10000;
logic counter_10000_flg;
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n)
        counter_10000 <= 0;
    else if(inf.id_valid || inf.act_valid || inf.item_valid || inf.num_valid || inf.amnt_valid)
        counter_10000 <= 0;
    else
        counter_10000 <= counter_10000 + 1;
end

assert_9 : assert property (@(posedge clk) (counter_10000 < 10000))
else begin
    $display("Assertion 9 is violated");
    $fatal; 
end

endmodule