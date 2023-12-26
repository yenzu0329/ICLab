`include "../00_TESTBED/PATTERN_API.sv"
`include "../00_TESTBED/Usertype_OS.sv"
import usertype::*;

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
// ==============================
//     Parameters & Variables
// ==============================
parameter PAT_NUM         = 10000;  // max:100000
parameter WAIT_MAX_LAT    = 10000;
parameter OUT_MAX_LAT     = 1;
parameter CYCLE           = 5.0;

int unsigned latency;
int unsigned total_latency;
int unsigned out_valid_time;
int unsigned i, i_pat, interval;
int unsigned r, rand_num;

logic   last_in, is_red;
Pattern pat;
RandInterval rand_interval = new();
ShopPlatform shop = new();

// ==============
//     Colors
// ==============
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

// ==============
//     String
// ==============
string success_str;
string action_str;

// ===============
//      Main 
// ===============
initial begin
    reset_task;
    @(negedge clk);
    for(i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat+1) begin
        idle_task;
        input_task;
        wait_out_valid_task;
        check_ans_task;
        show_result_task;
    end
    YOU_PASS_task;
    $finish;
end

// =============
//     Tasks
// =============
task show_result_task; begin
    if(pat.complete)  success_str = "[v]";
    else              success_str = "[ ]";
    case(pat.act)
        Buy     :     action_str  = "Buy    ";
        Check   :     action_str  = "Check  ";
        Deposit :     action_str  = "Deposit";
        Return  :     action_str  = "Return ";
    endcase
    if(is_red) begin
        if(pat.seller_valid)
            $display("%0s%s  NO.%05d | %s | %03d | %03d, Latency: %-d%0s",txt_red_prefix, success_str, i_pat, action_str, pat.buyer_id, pat.seller_id, latency, reset_color);
        else
            $display("%0s%s  NO.%05d | %s | %03d | ---, Latency: %-d%0s",txt_red_prefix, success_str, i_pat, action_str, pat.buyer_id, latency, reset_color);
    end
    else begin
        if(pat.seller_valid)
            $display("%0s%s  NO.%05d | %s | %03d | %03d, %0sLatency: %-d%0s",txt_blue_prefix, success_str, i_pat, action_str, pat.buyer_id, pat.seller_id, txt_green_prefix, latency, reset_color);
        else
            $display("%0s%s  NO.%05d | %s | %03d | ---, %0sLatency: %-d%0s",txt_blue_prefix, success_str, i_pat, action_str, pat.buyer_id, txt_green_prefix, latency, reset_color);
    end
end endtask

task reset_task; begin
    inf.rst_n      = 'b1;
    inf.id_valid   = 'b0;
    inf.act_valid  = 'b0;
    inf.item_valid = 'b0;
    inf.num_valid  = 'b0;
    inf.amnt_valid = 'b0;
    inf.D          = 'bx;

    total_latency = 0;

    force clk = 0;
    #CYCLE; inf.rst_n = 0; 
    #(CYCLE/2.0);
    if(inf.out_valid !== 1'b0 || inf.err_msg !== 'b0 || inf.complete !== 'b0 || inf.out_info != 0) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("            output signals should be 0 after initial RESET          ");
        $display ("====================================================================");  
        $finish;
    end
    #(CYCLE/2.0); inf.rst_n = 1;
	#CYCLE; release clk;
end endtask

task idle_task; begin
    rand_num = $urandom_range(2, 10);
    for(i = 0; i < rand_num; i = i+1) begin
        if(inf.out_valid !== 1'b0 || inf.err_msg !== 'b0 || inf.complete !== 'b0 || inf.out_info != 0) begin //out!==0
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("                output signals should be 0 before INPUT             ");
            $display ("====================================================================");  
            $finish;
    	end
		@(negedge clk);
	end
end endtask

task input_check_task; begin
    r = rand_interval.randomize();
    interval = (last_in) ? 0 : rand_interval.interval;
    for(i = 0; i < interval; i = i+1) begin
        if(inf.out_valid !== 1'b0 || inf.err_msg !== 'b0 || inf.complete !== 'b0 || inf.out_info != 0) begin //out!==0
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("           output signals should be 0 when in_valid is HIGH         ");
            $display ("====================================================================");  
            $finish;
        end
        @(negedge clk);
    end
end endtask

task input_task; begin
	pat = shop.getPatten();
    last_in = 0;
    if(pat.buyer_valid) begin
        inf.id_valid = 1'b1;
        inf.D = pat.buyer_id;
        @(negedge clk);
        inf.id_valid = 1'b0;
        inf.D = 'bx;
        input_check_task;
    end
    if(pat.act_valid) begin
        inf.act_valid = 1'b1;
        inf.D = pat.act;
        @(negedge clk);
        inf.act_valid = 1'b0;
        inf.D = 'bx;
        input_check_task;
    end
    if(pat.item_valid) begin
        inf.item_valid = 1'b1;
        inf.D = pat.item_type;
        @(negedge clk);
        inf.item_valid = 1'b0;
        inf.D = 'bx;
        input_check_task;
    end
    if(pat.num_valid) begin
        inf.num_valid = 1'b1;
        inf.D = pat.item_num;
        @(negedge clk);
        inf.num_valid = 1'b0;
        inf.D = 'bx;
        input_check_task;
    end
    last_in = 1;
    if(pat.seller_valid) begin
        inf.id_valid = 1'b1;
        inf.D = pat.seller_id;
        @(negedge clk);
        inf.id_valid = 1'b0;
        inf.D = 'bx;
        input_check_task;
    end
    if(pat.amnt_valid) begin
        inf.amnt_valid = 1'b1;
        inf.D = pat.money;
        @(negedge clk);
        inf.amnt_valid = 1'b0;
        inf.D = 'bx;
        input_check_task;
    end
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(inf.out_valid === 1'b0) begin
        if(inf.err_msg !== 'b0 || inf.complete !== 'b0 || inf.out_info != 0) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("             out datas should be 0 when out_valid is LOW            ");
            $display ("====================================================================");  
            $finish;
        end
        if(latency == WAIT_MAX_LAT) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("             the execution latency is over %5d cycles               ", WAIT_MAX_LAT);
            $display ("====================================================================");  
            $finish;
        end
	    latency = latency + 1;
        @(negedge clk);
    end
    if(inf.out_valid !== 1'b1) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("                      out_valid is DON'T CARE                       ");
        $display ("====================================================================");  
        $finish;
    end
    total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    out_valid_time = 0;
    while(inf.out_valid === 1) begin
        if(out_valid_time >= OUT_MAX_LAT) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("                out_valid should be high only %1d cycle             ", OUT_MAX_LAT);
            $display ("====================================================================");  
            $finish;
        end
        if(inf.err_msg !== pat.err_msg || inf.complete != pat.complete || inf.out_info != pat.out_info) begin
            is_red = 1;
            show_result_task;
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("                         PATTERN NO. %05d                           ", i_pat);
            $display ("   --------------------------------------------------------------   ");
            $display ("                golden ans                      your ans            ");
            $display ("   --------------------------------------------------------------   ");
            $display ("       complete  =  %1d                 complete  =  %1d            ", pat.complete, inf.complete);
            $display ("       err_msg   =  %s    err_msg   =  %s   "                        , getErrMsgStr(pat.err_msg), getErrMsgStr(inf.err_msg));
            $display ("       out_info  =  %8H          out_info  =  %8H         "          , pat.out_info, inf.out_info);
            $display ("   --------------------------------------------------------------   ");
            $display ("====================================================================");  
            $finish;
        end
        out_valid_time = out_valid_time + 1;
        @(negedge clk);
    end
    if(inf.out_valid === 1'b0) begin
        if(inf.err_msg !== 'b0 || inf.complete !== 'b0 || inf.out_info != 0) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("             out datas should be 0 when out_valid is LOW            ");
            $display ("====================================================================");  
            $finish;
        end
    end
    else begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("                      out_valid is DON'T CARE                       ");
        $display ("====================================================================");  
        $finish;
    end
end endtask

function string getErrMsgStr(Error_Msg msg);
    string err_msg_str;
    case(msg)
        No_Err         : err_msg_str = "No_Err        ";
        INV_Not_Enough : err_msg_str = "INV_Not_Enough";
        Out_of_money   : err_msg_str = "Out_of_money  ";
        INV_Full       : err_msg_str = "INV_Full      ";
        Wallet_is_Full : err_msg_str = "Wallet_is_Full";
        Wrong_ID       : err_msg_str = "Wrong_ID      ";
        Wrong_Num      : err_msg_str = "Wrong_Num     ";
        Wrong_Item     : err_msg_str = "Wrong_Item    ";
        Wrong_act      : err_msg_str = "Wrong_act     ";
    endcase
    return err_msg_str;
endfunction

task YOU_PASS_task; begin
    $display ("====================================================================");
    $display ("                           %0sCongratulation!!%0s                   ", txt_green_prefix, reset_color);
    $display ("                    You have passed all patterns!                   ");
    $display ("                    total latency = %6d cycles                      ", total_latency);
    $display ("====================================================================");  
    $finish;
end endtask

endprogram