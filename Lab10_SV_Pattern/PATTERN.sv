`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_OS.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters
//================================================================
parameter PAT_NUM = 400;
parameter CYCLE   = 10;
parameter RAND_SEED = 100;

// DRAM 
parameter DRAM_PATH             = "../00_TESTBED/DRAM/dram.dat";
parameter BASE_ADDR             = 'h10000; 
parameter USER_NUM              = 256;
parameter USER_INFO_SIZE        = 8;

//================================================================
// structs & classes
//================================================================
typedef struct packed {
    // input valid
    logic        buyer_valid;
    logic        seller_valid;
    logic        act_valid;
    logic        item_valid;
    logic        num_valid;
    logic        amnt_valid;
    // input data
	logic [8:0]  buyer_id;
    logic [8:0]  seller_id;
    Action       act;
    Item_id      item_type;
    Item_num     item_num;
    Money        money;
    // output data
    logic [3:0]  err_msg;
    logic [31:0] out_info;
    logic        complete;
}	Pattern;

class Dram;
    logic [16:0] DRAM_addr;
    logic [7:0]  data [((BASE_ADDR + USER_NUM * USER_INFO_SIZE)-1) : (BASE_ADDR)];

    function new();
        readDramFile();
    endfunction

    function void readDramFile();
        $readmemh(DRAM_PATH, data);
    endfunction

    function User readUserFromDram(User_id user_id);
        User user;
        DRAM_addr = {1'b1, 5'b0, user_id, 3'b0};
        // Shop info
        user.id = user_id;
        user.shop_info.large_num  = {data [DRAM_addr+0][7:2]};
        user.shop_info.medium_num = {data [DRAM_addr+0][1:0], data [DRAM_addr+1][7:4]}; 
        user.shop_info.small_num  = {data [DRAM_addr+1][3:0], data [DRAM_addr+2][7:6]};
        user.shop_info.level      = User_Level'({data [DRAM_addr+2][5:4]});
        user.shop_info.exp        = {data [DRAM_addr+2][3:0], data [DRAM_addr+3]};
        // User info
        user.user_info.money      = {data [DRAM_addr+4], data [DRAM_addr+5]};
        user.user_info.shop_history.item_ID   = Item_id'({data [DRAM_addr+6][7:6]});
        user.user_info.shop_history.item_num  = {data [DRAM_addr+6][5:0]};
        user.user_info.shop_history.seller_ID = {data [DRAM_addr+7]};
        return user;
    endfunction

    function void writeUserToDram(User user);
        DRAM_addr = {1'b1, 5'b0, user.id, 3'b0};
        // Shop info
        data [DRAM_addr+0] = {user.shop_info.large_num,       user.shop_info.medium_num[5:4]};
        data [DRAM_addr+1] = {user.shop_info.medium_num[3:0], user.shop_info.small_num [5:2]};
        data [DRAM_addr+2] = {user.shop_info.small_num [1:0], user.shop_info.level, user.shop_info.exp[11:8]};
        data [DRAM_addr+3] = {user.shop_info.exp[7:0]};
        // User info
        data [DRAM_addr+4] = {user.user_info.money[15:8]};
        data [DRAM_addr+5] = {user.user_info.money[7:0]};
        data [DRAM_addr+6] = {user.user_info.shop_history.item_ID, user.user_info.shop_history.item_num};
        data [DRAM_addr+7] = {user.user_info.shop_history.seller_ID};
    endfunction
endclass

class RandItem;
    rand Item_id      typ;
    rand Item_num     num;

    function new();
        this.srandom(RAND_SEED);
    endfunction

    constraint limit {
        typ inside {Large, Medium, Small};
        num inside {[1:2**6-1]};
    }
endclass

class RandMoney;
    rand Money      num;

    function new();
        this.srandom(RAND_SEED);
    endfunction

    constraint limit {
        num inside {[1:12000]};
    }
endclass

//================================================================
// variables
//================================================================
// coverage
integer complete_cnt;
integer uncomplete_cnt;

integer money_12000_cnt;
integer money_24000_cnt;
integer money_36000_cnt;
integer money_48000_cnt;
integer money_60000_cnt;

integer id_cnt, r;

integer INV_Not_Enough_cnt;
integer Out_of_money_cnt;
integer INV_Full_cnt;
integer Wallet_is_Full_cnt;
integer Wrong_ID_cnt;
integer Wrong_Num_cnt;
integer Wrong_Item_cnt;
integer Wrong_act_cnt;

// latency
integer latency;
integer total_latency;
integer i_pat;

Pattern  pat;
User_id  prev_buyer_id;
User     buyer, seller;
Dram     dram = new();
RandItem rand_item = new();
RandMoney rand_money = new();
User_id  buyer_his  [(USER_NUM-1) : 0];
User_id  seller_his [(USER_NUM-1) : 0];
logic [(USER_NUM-1) : 0] buyer_valid;
logic [(USER_NUM-1) : 0] seller_valid;


//================================================================
// initial
//================================================================
initial begin
    reset_task;
    for(i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat+1) begin
        gen_pattern_task;
        input_task;
        wait_out_valid_task;
        check_ans_task;
        idle_task;
    end
    $finish;
end

//================================================================
// tasks
//================================================================
task reset_task; begin
    inf.rst_n      = 'b1;
    inf.id_valid   = 'b0;
    inf.act_valid  = 'b0;
    inf.item_valid = 'b0;
    inf.num_valid  = 'b0;
    inf.amnt_valid = 'b0;
    inf.D          = 'bx;

    total_latency = 0;
    pat.buyer_id = 255;

    complete_cnt = 0;
    uncomplete_cnt = 0;

    money_12000_cnt = 0;
    money_24000_cnt = 0;
    money_36000_cnt = 0;
    money_48000_cnt = 0;
    money_60000_cnt = 0;

    id_cnt = 0;

    INV_Not_Enough_cnt = 0;
    Out_of_money_cnt = 0;
    INV_Full_cnt = 0;
    Wallet_is_Full_cnt = 0;
    Wrong_ID_cnt = 0;
    Wrong_Num_cnt = 0;
    Wrong_Item_cnt = 0;
    Wrong_act_cnt = 0;

    buyer_valid = 0;
    seller_valid = 0;

    force clk = 0;
    #CYCLE; inf.rst_n = 0; 
    #CYCLE; inf.rst_n = 1;
	#CYCLE; release clk;
    @(negedge clk);
end endtask

task input_task; begin
    if(pat.buyer_valid) begin
        inf.id_valid = 1'b1;
        inf.D = pat.buyer_id;
        @(negedge clk);
        inf.id_valid = 1'b0;
        inf.D = 'bx;
        @(negedge clk);
    end
    if(pat.act_valid) begin
        inf.act_valid = 1'b1;
        inf.D = pat.act;
        @(negedge clk);
        inf.act_valid = 1'b0;
        inf.D = 'bx;
        @(negedge clk);
    end
    if(pat.item_valid) begin
        inf.item_valid = 1'b1;
        inf.D = pat.item_type;
        @(negedge clk);
        inf.item_valid = 1'b0;
        inf.D = 'bx;
        @(negedge clk);
    end
    if(pat.num_valid) begin
        inf.num_valid = 1'b1;
        inf.D = pat.item_num;
        @(negedge clk);
        inf.num_valid = 1'b0;
        inf.D = 'bx;
        @(negedge clk);
    end
    if(pat.seller_valid) begin
        inf.id_valid = 1'b1;
        inf.D = pat.seller_id;
        @(negedge clk);
        inf.id_valid = 1'b0;
        inf.D = 'bx;
        @(negedge clk);
    end
    if(pat.amnt_valid) begin
        inf.amnt_valid = 1'b1;
        inf.D = pat.money;
        @(negedge clk);
        inf.amnt_valid = 1'b0;
        inf.D = 'bx;
        @(negedge clk);
    end
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(inf.out_valid === 1'b0) begin
	    latency = latency + 1;
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    if(inf.err_msg !== pat.err_msg || inf.complete !== pat.complete || inf.out_info !== pat.out_info) begin
        $display ("Wrong Answer");  
        $finish;
    end
end endtask

task idle_task; begin
    repeat(2) @(negedge clk);
end endtask

task gen_pattern_task; begin
    prev_buyer_id = pat.buyer_id;
    pat.seller_id = 256;
    if(i_pat <= 173) begin
        pattern_from_table1();
        id_cnt = 111;
    end
    else if(i_pat <= 207) begin
        r = rand_item.randomize();
        pat.act = Buy;
        pat.item_type = rand_item.typ;
        pat.item_num = rand_item.num;
        if(i_pat % 2 == 0) begin
            pat.buyer_id = id_cnt;
            pat.seller_id = id_cnt + 1;
        end
        else begin
            pat.buyer_id = id_cnt + 1;
            pat.seller_id = id_cnt;
            id_cnt = id_cnt + 2;
        end
    end
    else if(i_pat <= 232) begin
        r = rand_item.randomize();
        pat.act = Return;
        pat.buyer_id = 27;
        pat.seller_id = 26;
        pat.item_num = 1;
        pat.item_type = (i_pat % 2) ? Medium : Large;

        if(i_pat <= 211) begin
            pat.seller_id = id_cnt;
            if(i_pat % 2 == 1)
                id_cnt = id_cnt + 1;
        end
        else if(i_pat <= 217) begin
            pat.item_num = rand_item.num;
            if(pat.item_num == 1)
                pat.item_num = 2;
        end
    end
    else if(i_pat <= 368) begin
        pat.act = Check;
        pat.buyer_id = id_cnt;
        pat.seller_id = id_cnt + 1;
        id_cnt = id_cnt + 1;
        if(id_cnt >= 254)
            id_cnt = 254;
    end
    else if(i_pat < 390) begin
        pat.act = Deposit;
        pat.buyer_id = 9;
        rand_money.randomize();
        if(i_pat % 4 == 0)        pat.money = rand_money.num;
        else if(i_pat % 4 == 1)   pat.money = 12000 + rand_money.num;
        else if(i_pat % 4 == 2)   pat.money = 24000 + rand_money.num;
        else if(i_pat % 4 == 3)   pat.money = 36000 + rand_money.num;
    end
    else begin
        pattern_from_table2();
    end
    setInValid();
    buyer = dram.readUserFromDram(pat.buyer_id);
    seller = dram.readUserFromDram(pat.seller_id);
    case(pat.act)
        Buy:     runBuy();
        Check:   runCheck();
        Deposit: runDeposit();
        Return:  runReturn();
    endcase
    pat.complete = (pat.err_msg == No_Err);
    if(pat.complete)
        complete_cnt = complete_cnt + 1;
    else
        uncomplete_cnt = uncomplete_cnt + 1;
    updateHistory();
    
    dram.writeUserToDram(buyer);
    dram.writeUserToDram(seller);
end endtask

function void setInValid();
    if(prev_buyer_id == pat.buyer_id)
        pat.buyer_valid = 0;
    else
        pat.buyer_valid = 1;
    pat.act_valid = 1;
    case(pat.act) 
        Buy: begin
            pat.seller_valid = 1;
            pat.item_valid   = 1;
            pat.num_valid    = 1;
            pat.amnt_valid   = 0;
        end
        Check: begin
            if(pat.seller_id != 256)
                pat.seller_valid = 1;
            else
                pat.seller_valid = 0;
            pat.item_valid   = 0;
            pat.num_valid    = 0;
            pat.amnt_valid   = 0;
        end
        Deposit: begin
            pat.seller_valid = 0;
            pat.item_valid   = 0;
            pat.num_valid    = 0;
            pat.amnt_valid   = 1;
        end
        Return: begin
            pat.seller_valid = 1;
            pat.item_valid   = 1;
            pat.num_valid    = 1;
            pat.amnt_valid   = 0;
        end
    endcase
endfunction

function void runBuy();
    integer      price, fee, require_exp, reward_exp;
    integer      buyer_remain_stock, seller_stock;

    // get seller & buyer stocks
    case(pat.item_type)
        Large:   buyer_remain_stock = 63 - buyer.shop_info.large_num;
        Medium:  buyer_remain_stock = 63 - buyer.shop_info.medium_num;
        Small:   buyer_remain_stock = 63 - buyer.shop_info.small_num;
    endcase
    case(pat.item_type)
        Large:   seller_stock = seller.shop_info.large_num;
        Medium:  seller_stock = seller.shop_info.medium_num;
        Small:   seller_stock = seller.shop_info.small_num;
    endcase

    if(i_pat > 197 && i_pat <= 207)
        pat.item_num = (seller_stock < buyer_remain_stock) ? seller_stock : buyer_remain_stock;

    // compute price
    case(pat.item_type)
        Large:    price = pat.item_num*300;
        Medium:   price = pat.item_num*200;
        Small:    price = pat.item_num*100;
    endcase
    // compute fee
    case(buyer.shop_info.level)
        Platinum: fee = 10;
        Gold:     fee = 30;
        Silver:   fee = 50;
        Copper:   fee = 70;
    endcase
    // compute reward exp
    case(pat.item_type)
        Large:    reward_exp = pat.item_num*60;
        Medium:   reward_exp = pat.item_num*40;
        Small:    reward_exp = pat.item_num*20;
    endcase
    // compute require_exp
    case(buyer.shop_info.level)
        Gold:     require_exp = 4000;
        Silver:   require_exp = 2500;
        Copper:   require_exp = 1000;
    endcase


    if(pat.item_num > buyer_remain_stock) begin
        pat.err_msg = INV_Full;
        INV_Full_cnt = INV_Full_cnt + 1;
    end
    else if(pat.item_num > seller_stock) begin
        pat.err_msg = INV_Not_Enough;
        INV_Not_Enough_cnt = INV_Not_Enough_cnt + 1;
    end
    else if(buyer.user_info.money < price + fee) begin
        pat.err_msg = Out_of_money;
        Out_of_money_cnt = Out_of_money_cnt + 1;
    end
    else begin
        pat.err_msg = No_Err;
    end
    
    if(pat.err_msg == No_Err) begin
        // -----------------------
        //   update buyer's info
        // -----------------------
        buyer.user_info.money = buyer.user_info.money - price - fee;
        buyer.user_info.shop_history.item_ID = pat.item_type;
        buyer.user_info.shop_history.item_num = pat.item_num;
        buyer.user_info.shop_history.seller_ID = pat.seller_id;
        case(pat.item_type)
            Large:  buyer.shop_info.large_num = buyer.shop_info.large_num + pat.item_num;
            Medium: buyer.shop_info.medium_num = buyer.shop_info.medium_num + pat.item_num;
            Small:  buyer.shop_info.small_num = buyer.shop_info.small_num + pat.item_num;
        endcase
        if(buyer.shop_info.level != Platinum) begin
            if(buyer.shop_info.exp + reward_exp >= require_exp) begin
                buyer.shop_info.exp = 0;
                buyer.shop_info.level = User_Level'(buyer.shop_info.level - 1);
            end
            else
                buyer.shop_info.exp = buyer.shop_info.exp + reward_exp;
        end
        // -----------------------
        //   update seller's info
        // -----------------------
        if(seller.user_info.money + price >= 17'h10000)
            seller.user_info.money = 16'hFFFF;
        else
            seller.user_info.money = seller.user_info.money + price;
        case(pat.item_type)
            Large:  seller.shop_info.large_num = seller.shop_info.large_num - pat.item_num;
            Medium: seller.shop_info.medium_num = seller.shop_info.medium_num - pat.item_num;
            Small:  seller.shop_info.small_num = seller.shop_info.small_num - pat.item_num;
        endcase
        // out_info
        pat.out_info = buyer.user_info;
    end
    else begin
        pat.out_info = 0;
    end
endfunction

function void runCheck();
    pat.err_msg = No_Err;
    if(pat.seller_valid)
        pat.out_info = {seller.shop_info.large_num, seller.shop_info.medium_num, seller.shop_info.small_num};
    else
        pat.out_info = buyer.user_info.money;
endfunction

function void runDeposit();
    integer remain_money;
    remain_money = 16'hFFFF - buyer.user_info.money;
    if(pat.money > remain_money) begin
        pat.err_msg = Wallet_is_Full;
        Wallet_is_Full_cnt = Wallet_is_Full_cnt + 1;
    end
    else begin
        pat.err_msg = No_Err;
    end

    if(pat.money <= 12000)      money_12000_cnt = money_12000_cnt + 1;
    else if(pat.money <= 24000) money_24000_cnt = money_24000_cnt + 1;
    else if(pat.money <= 36000) money_36000_cnt = money_36000_cnt + 1;
    else if(pat.money <= 48000) money_48000_cnt = money_48000_cnt + 1;
    else if(pat.money <= 60000) money_60000_cnt = money_60000_cnt + 1;

    if(pat.err_msg == No_Err) begin
        buyer.user_info.money = buyer.user_info.money + pat.money;
        pat.out_info = buyer.user_info.money;
    end
    else begin
        pat.out_info = 0;
    end
endfunction

function void runReturn();
    integer    price;
    if(!buyer_valid[pat.buyer_id] || !seller_valid[buyer_his[pat.buyer_id]]) begin
        pat.err_msg = Wrong_act;
        Wrong_act_cnt = Wrong_act_cnt + 1;
    end
    else if(seller_his[buyer_his[pat.buyer_id]] != pat.buyer_id) begin
        pat.err_msg = Wrong_act;
        Wrong_act_cnt = Wrong_act_cnt + 1;
    end
    else if(buyer_his[pat.buyer_id] != pat.seller_id) begin
        pat.err_msg = Wrong_ID;
        Wrong_ID_cnt = Wrong_ID_cnt + 1;
    end
    else if(pat.item_num != buyer.user_info.shop_history.item_num) begin
        pat.err_msg = Wrong_Num;
        Wrong_Num_cnt = Wrong_Num_cnt + 1;
    end
    else if(pat.item_type != buyer.user_info.shop_history.item_ID) begin
        pat.err_msg = Wrong_Item;
        Wrong_Item_cnt = Wrong_Item_cnt + 1;
    end
    else begin
        pat.err_msg = No_Err;
    end
    
    // compute price
    case(pat.item_type)
        Large:    price = pat.item_num*300;
        Medium:   price = pat.item_num*200;
        Small:    price = pat.item_num*100;
    endcase
    if(pat.err_msg == No_Err) begin
        // -----------------------
        //   update buyer's info
        // -----------------------
        buyer.user_info.money = buyer.user_info.money + price;
        case(pat.item_type)
            Large:  buyer.shop_info.large_num = buyer.shop_info.large_num - pat.item_num;
            Medium: buyer.shop_info.medium_num = buyer.shop_info.medium_num - pat.item_num;
            Small:  buyer.shop_info.small_num = buyer.shop_info.small_num - pat.item_num;
        endcase
        // -----------------------
        //   update seller's info
        // -----------------------
        seller.user_info.money = seller.user_info.money - price;
        case(pat.item_type)
            Large:  seller.shop_info.large_num = seller.shop_info.large_num + pat.item_num;
            Medium: seller.shop_info.medium_num = seller.shop_info.medium_num + pat.item_num;
            Small:  seller.shop_info.small_num = seller.shop_info.small_num + pat.item_num;
        endcase
        // out_info
        pat.out_info = {buyer.shop_info.large_num, buyer.shop_info.medium_num, buyer.shop_info.small_num};
    end 
    else begin
        pat.out_info = 0;
    end
endfunction

function void updateHistory();
    if(pat.err_msg == No_Err) begin
        if(pat.act == Buy) begin
            buyer_his[pat.buyer_id] = pat.seller_id;
            buyer_valid[pat.buyer_id] = 1;
            buyer_valid[pat.seller_id] = 0;

            seller_his[pat.seller_id] = pat.buyer_id;
            seller_valid[pat.seller_id] = 1;
            seller_valid[pat.buyer_id] = 0;
        end
        else if(pat.act == Return || (pat.act == Check && pat.seller_valid)) begin
            buyer_valid[pat.buyer_id] = 0;
            buyer_valid[pat.seller_id] = 0;
            seller_valid[pat.seller_id] = 0;
            seller_valid[pat.buyer_id] = 0;
        end
        else begin
            buyer_valid[pat.buyer_id] = 0;
            seller_valid[pat.buyer_id] = 0;
        end
    end
endfunction

function void pattern_from_table1();
    case(i_pat)
        0  : begin  pat.act = Return ; pat.buyer_id  = 0; pat.seller_id = 1; pat.item_type = Large ; pat.item_num = 3;  end
        1  : begin  pat.act = Buy    ; pat.buyer_id  = 0; pat.seller_id = 1; pat.item_type = Small ; pat.item_num = 7;  end
        2  : begin  pat.act = Buy    ; pat.buyer_id  = 0; pat.seller_id = 1; pat.item_type = Large ; pat.item_num = 1;  end
        3  : begin  pat.act = Buy    ; pat.buyer_id  = 0; pat.seller_id = 2; pat.item_type = Medium; pat.item_num = 10;  end
        4  : begin  pat.act = Check  ; pat.buyer_id  = 1;  end
        5  : begin  pat.act = Buy    ; pat.buyer_id  = 4; pat.seller_id = 3; pat.item_type = Small ; pat.item_num = 20;  end
        6  : begin  pat.act = Deposit; pat.buyer_id  = 6; pat.money     = 50000;  end
        7  : begin  pat.act = Check  ; pat.buyer_id  = 8; pat.seller_id = 2;  end
        8  : begin  pat.act = Buy    ; pat.buyer_id  = 4; pat.seller_id = 5; pat.item_type = Medium; pat.item_num = 1;  end
        9  : begin  pat.act = Return ; pat.buyer_id  = 0; pat.seller_id = 2; pat.item_type = Medium; pat.item_num = 10;  end
        10 : begin  pat.act = Return ; pat.buyer_id  = 4; pat.seller_id = 3; pat.item_type = Small ; pat.item_num = 20;  end
        11 : begin  pat.act = Deposit; pat.buyer_id  = 6; pat.money     = 45535;  end
        12 : begin  pat.act = Return ; pat.buyer_id  = 4; pat.seller_id = 5; pat.item_type = Medium; pat.item_num = 1;  end
        13 : begin  pat.act = Check  ; pat.buyer_id  = 7; pat.seller_id = 8;  end
        14 : begin  pat.act = Return ; pat.buyer_id  = 4; pat.seller_id = 5; pat.item_type = Medium; pat.item_num = 1;  end
        15 : begin  pat.act = Deposit; pat.buyer_id  = 9; pat.money     = 1;  end
        16 : begin  pat.act = Buy    ; pat.buyer_id  = 10; pat.seller_id = 9; pat.item_type = Large ; pat.item_num = 37;  end
        17 : begin  pat.act = Deposit; pat.buyer_id  = 11; pat.money     = 20000;  end
        18 : begin  pat.act = Buy    ; pat.buyer_id  = 12; pat.seller_id = 13; pat.item_type = Small ; pat.item_num = 5;  end
        19 : begin  pat.act = Buy    ; pat.buyer_id  = 11; pat.seller_id = 10; pat.item_type = Medium; pat.item_num = 37;  end
        20 : begin  pat.act = Return ; pat.buyer_id  = 12; pat.seller_id = 13; pat.item_type = Small ; pat.item_num = 5;  end
        21 : begin  pat.act = Check  ; pat.buyer_id  = 14;  end
        22 : begin  pat.act = Buy    ; pat.buyer_id  = 16; pat.seller_id = 15; pat.item_type = Medium; pat.item_num = 11;  end
        23 : begin  pat.act = Buy    ; pat.buyer_id  = 12; pat.seller_id = 13; pat.item_type = Small ; pat.item_num = 5;  end
        24 : begin  pat.act = Check  ; pat.buyer_id  = 16; pat.seller_id = 14;  end
        25 : begin  pat.act = Return ; pat.buyer_id  = 18; pat.seller_id = 19; pat.item_type = Large ; pat.item_num = 10;  end
        26 : begin  pat.act = Buy    ; pat.buyer_id  = 17; pat.seller_id = 15; pat.item_type = Large ; pat.item_num = 60;  end
        27 : begin  pat.act = Return ; pat.buyer_id  = 12; pat.seller_id = 13; pat.item_type = Medium; pat.item_num = 20;  end
        28 : begin  pat.act = Return ; pat.buyer_id  = 17; pat.seller_id = 15; pat.item_type = Small ; pat.item_num = 60;  end
        29 : begin  pat.act = Buy    ; pat.buyer_id  = 18; pat.seller_id = 19; pat.item_type = Small ; pat.item_num = 45;  end
        30 : begin  pat.act = Return ; pat.buyer_id  = 16; pat.seller_id = 15; pat.item_type = Medium; pat.item_num = 11;  end
        31 : begin  pat.act = Check  ; pat.buyer_id  = 20; pat.seller_id = 7;  end
        32 : begin  pat.act = Return ; pat.buyer_id  = 17; pat.seller_id = 15; pat.item_type = Large ; pat.item_num = 60;  end
        33 : begin  pat.act = Check  ; pat.buyer_id  = 15;  end
        34 : begin  pat.act = Check  ; pat.buyer_id  = 17; pat.seller_id = 15;  end
        35 : begin  pat.act = Deposit; pat.buyer_id  = 20; pat.money     = 54321;  end
        36 : begin  pat.act = Buy    ; pat.buyer_id  = 21; pat.seller_id = 22; pat.item_type = Medium; pat.item_num = 10;  end
        37 : begin  pat.act = Check  ; pat.buyer_id  = 20;  end
        38 : begin  pat.act = Buy    ; pat.buyer_id  = 25; pat.seller_id = 24; pat.item_type = Medium; pat.item_num = 15;  end
        39 : begin  pat.act = Buy    ; pat.buyer_id  = 22; pat.seller_id = 23; pat.item_type = Large ; pat.item_num = 20;  end
        40 : begin  pat.act = Deposit; pat.buyer_id  = 25; pat.money     = 10;  end
        41 : begin  pat.act = Buy    ; pat.buyer_id  = 25; pat.seller_id = 24; pat.item_type = Medium; pat.item_num = 63;  end
        42 : begin  pat.act = Buy    ; pat.buyer_id  = 27; pat.seller_id = 26; pat.item_type = Small ; pat.item_num = 1;  end
        43 : begin  pat.act = Return ; pat.buyer_id  = 27; pat.seller_id = 26; pat.item_type = Large ; pat.item_num = 1;  end
        44 : begin  pat.act = Return ; pat.buyer_id  = 27; pat.seller_id = 23; pat.item_type = Medium; pat.item_num = 12;  end
        45 : begin  pat.act = Return ; pat.buyer_id  = 27; pat.seller_id = 72; pat.item_type = Large ; pat.item_num = 1;  end
        46 : begin  pat.act = Return ; pat.buyer_id  = 27; pat.seller_id = 72; pat.item_type = Small ; pat.item_num = 3;  end
        47 : begin  pat.act = Return ; pat.buyer_id  = 27; pat.seller_id = 26; pat.item_type = Small ; pat.item_num = 15;  end
        48 : begin  pat.act = Return ; pat.buyer_id  = 27; pat.seller_id = 26; pat.item_type = Medium; pat.item_num = 1;  end
        49 : begin  pat.act = Deposit; pat.buyer_id  = 28; pat.money     = 37500;  end
        50 : begin  pat.act = Return ; pat.buyer_id  = 21; pat.seller_id = 23; pat.item_type = Medium; pat.item_num = 12;  end
        51 : begin  pat.act = Return ; pat.buyer_id  = 22; pat.seller_id = 23; pat.item_type = Large ; pat.item_num = 20;  end
        52 : begin  pat.act = Deposit; pat.buyer_id  = 28; pat.money     = 13452;  end
        53 : begin  pat.act = Return ; pat.buyer_id  = 27; pat.seller_id = 26; pat.item_type = Large ; pat.item_num = 35;  end
        54 : begin  pat.act = Return ; pat.buyer_id  = 27; pat.seller_id = 26; pat.item_type = Small ; pat.item_num = 15;  end
        55 : begin  pat.act = Check  ; pat.buyer_id  = 30; pat.seller_id = 29;  end
        56 : begin  pat.act = Buy    ; pat.buyer_id  = 33; pat.seller_id = 31; pat.item_type = Medium; pat.item_num = 63;  end
        57 : begin  pat.act = Buy    ; pat.buyer_id  = 32; pat.seller_id = 31; pat.item_type = Medium; pat.item_num = 20;  end
        58 : begin  pat.act = Check  ; pat.buyer_id  = 29; pat.seller_id = 30;  end
        59 : begin  pat.act = Deposit; pat.buyer_id  = 33; pat.money     = 52936;  end
        60 : begin  pat.act = Buy    ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Large ; pat.item_num = 2;  end
        61 : begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 31; pat.item_type = Small ; pat.item_num = 50;  end
        62 : begin  pat.act = Return ; pat.buyer_id  = 27; pat.seller_id = 31; pat.item_type = Medium; pat.item_num = 3;  end
        63 : begin  pat.act = Buy    ; pat.buyer_id  = 35; pat.seller_id = 36; pat.item_type = Small ; pat.item_num = 51;  end
        64 : begin  pat.act = Check  ; pat.buyer_id  = 36; pat.seller_id = 35;  end
        65 : begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 26; pat.item_type = Large ; pat.item_num = 40;  end
        66 : begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Small ; pat.item_num = 3;  end
        67 : begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Medium; pat.item_num = 2;  end
        68 : begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Medium; pat.item_num = 63;  end
        69 : begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Small ; pat.item_num = 2;  end
        70 : begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 52; pat.item_type = Small ; pat.item_num = 5;  end
        71 : begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Small ; pat.item_num = 3;  end
        72 : begin  pat.act = Deposit; pat.buyer_id  = 37; pat.money     = 39451;  end
        73 : begin  pat.act = Return ; pat.buyer_id  = 32; pat.seller_id = 31; pat.item_type = Medium; pat.item_num = 20;  end
        74 : begin  pat.act = Check  ; pat.buyer_id  = 38; pat.seller_id = 31;  end
        75 : begin  pat.act = Deposit; pat.buyer_id  = 39; pat.money     = 200;  end
        76 : begin  pat.act = Check  ; pat.buyer_id  = 147; pat.seller_id = 39;  end
        77 : begin  pat.act = Check  ; pat.buyer_id  = 40; pat.seller_id = 37;  end
        78 : begin  pat.act = Check  ; pat.buyer_id  = 42; pat.seller_id = 40;  end
        79 : begin  pat.act = Deposit; pat.buyer_id  = 41; pat.money     = 30000;  end
        80 : begin  pat.act = Check  ; pat.buyer_id  = 38; pat.seller_id = 41;  end
        81 : begin  pat.act = Deposit; pat.buyer_id  = 42; pat.money     = 58845;  end
        82 : begin  pat.act = Check  ; pat.buyer_id  = 43; pat.seller_id = 44;  end
        83 : begin  pat.act = Buy    ; pat.buyer_id  = 46; pat.seller_id = 45; pat.item_type = Medium; pat.item_num = 21;  end
        84 : begin  pat.act = Deposit; pat.buyer_id  = 47; pat.money     = 1;  end
        85 : begin  pat.act = Buy    ; pat.buyer_id  = 46; pat.seller_id = 45; pat.item_type = Medium; pat.item_num = 13;  end
        86 : begin  pat.act = Buy    ; pat.buyer_id  = 47; pat.seller_id = 48; pat.item_type = Small ; pat.item_num = 10;  end
        87 : begin  pat.act = Deposit; pat.buyer_id  = 48; pat.money     = 50042;  end
        88 : begin  pat.act = Deposit; pat.buyer_id  = 49; pat.money     = 42011;  end
        89 : begin  pat.act = Return ; pat.buyer_id  = 44; pat.seller_id = 43; pat.item_type = Large ; pat.item_num = 12;  end
        90 : begin  pat.act = Deposit; pat.buyer_id  = 49; pat.money     = 23501;  end
        91 : begin  pat.act = Check  ; pat.buyer_id  = 50; pat.seller_id = 51;  end
        92 : begin  pat.act = Buy    ; pat.buyer_id  = 51; pat.seller_id = 50; pat.item_type = Large ; pat.item_num = 18;  end
        93 : begin  pat.act = Deposit; pat.buyer_id  = 52; pat.money     = 25451;  end
        94 : begin  pat.act = Deposit; pat.buyer_id  = 52; pat.money     = 37112;  end
        95 : begin  pat.act = Return ; pat.buyer_id  = 53; pat.seller_id = 54; pat.item_type = Large ; pat.item_num = 10;  end
        96 : begin  pat.act = Buy    ; pat.buyer_id  = 55; pat.seller_id = 56; pat.item_type = Medium; pat.item_num = 48;  end
        97 : begin  pat.act = Buy    ; pat.buyer_id  = 53; pat.seller_id = 54; pat.item_type = Large ; pat.item_num = 10;  end
        98 : begin  pat.act = Check  ; pat.buyer_id  = 56; pat.seller_id = 55;  end
        99 : begin  pat.act = Buy    ; pat.buyer_id  = 57; pat.seller_id = 58; pat.item_type = Small ; pat.item_num = 14;  end
        100: begin  pat.act = Check  ; pat.buyer_id  = 58; pat.seller_id = 57;  end
        101: begin  pat.act = Buy    ; pat.buyer_id  = 59; pat.seller_id = 60; pat.item_type = Large ; pat.item_num = 20;  end
        102: begin  pat.act = Check  ; pat.buyer_id  = 60; pat.seller_id = 59;  end
        103: begin  pat.act = Buy    ; pat.buyer_id  = 61; pat.seller_id = 62; pat.item_type = Large ; pat.item_num = 3;  end
        104: begin  pat.act = Check  ; pat.buyer_id  = 62; pat.seller_id = 61;  end
        105: begin  pat.act = Buy    ; pat.buyer_id  = 64; pat.seller_id = 63; pat.item_type = Medium; pat.item_num = 20;  end
        106: begin  pat.act = Check  ; pat.buyer_id  = 64; pat.seller_id = 65;  end
        107: begin  pat.act = Return ; pat.buyer_id  = 64; pat.seller_id = 63;  end
        108: begin  pat.act = Check  ; pat.buyer_id  = 76; pat.seller_id = 77;  end
        109: begin  pat.act = Check  ; pat.buyer_id  = 65;  end
        110: begin  pat.act = Deposit; pat.buyer_id  = 68; pat.money     = 26400;  end
        111: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 66; pat.item_type = Medium; pat.item_num = 20;  end
        112: begin  pat.act = Deposit; pat.buyer_id  = 67; pat.money     = 13222;  end
        113: begin  pat.act = Deposit; pat.buyer_id  = 71; pat.money     = 51234;  end
        114: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 70; pat.item_type = Small ; pat.item_num = 64;  end
        115: begin  pat.act = Deposit; pat.buyer_id  = 69; pat.money     = 50111;  end
        116: begin  pat.act = Deposit; pat.buyer_id  = 68; pat.money     = 43229;  end
        117: begin  pat.act = Return ; pat.buyer_id  = 71; pat.seller_id = 70; pat.item_type = Large ; pat.item_num = 5;  end
        118: begin  pat.act = Deposit; pat.buyer_id  = 73; pat.money     = 51234;  end
        119: begin  pat.act = Deposit; pat.buyer_id  = 69; pat.money     = 36000;  end
        120: begin  pat.act = Return ; pat.buyer_id  = 75; pat.seller_id = 74; pat.item_type = Medium; pat.item_num = 12;  end
        121: begin  pat.act = Deposit; pat.buyer_id  = 73; pat.money     = 51234;  end
        122: begin  pat.act = Deposit; pat.buyer_id  = 75; pat.money     = 36789;  end
        123: begin  pat.act = Check  ; pat.buyer_id  = 76; pat.seller_id = 74;  end
        124: begin  pat.act = Check  ; pat.buyer_id  = 65; pat.seller_id = 64;  end
        125: begin  pat.act = Deposit; pat.buyer_id  = 77; pat.money     = 25195;  end
        126: begin  pat.act = Buy    ; pat.buyer_id  = 78; pat.seller_id = 79; pat.item_type = Small ; pat.item_num = 20;  end
        127: begin  pat.act = Deposit; pat.buyer_id  = 83; pat.money     = 53536;  end
        128: begin  pat.act = Buy    ; pat.buyer_id  = 80; pat.seller_id = 79; pat.item_type = Medium; pat.item_num = 45;  end
        129: begin  pat.act = Deposit; pat.buyer_id  = 78; pat.money     = 37120;  end
        130: begin  pat.act = Buy    ; pat.buyer_id  = 81; pat.seller_id = 82; pat.item_type = Large ; pat.item_num = 55;  end
        131: begin  pat.act = Deposit; pat.buyer_id  = 80; pat.money     = 215;  end
        132: begin  pat.act = Buy    ; pat.buyer_id  = 83; pat.seller_id = 82; pat.item_type = Medium; pat.item_num = 60;  end
        133: begin  pat.act = Deposit; pat.buyer_id  = 81; pat.money     = 56789;  end
        134: begin  pat.act = Return ; pat.buyer_id  = 85; pat.seller_id = 84; pat.item_type = Medium; pat.item_num = 20;  end
        135: begin  pat.act = Check  ; pat.buyer_id  = 84; pat.seller_id = 85;  end
        136: begin  pat.act = Check  ; pat.buyer_id  = 86; pat.seller_id = 87;  end
        137: begin  pat.act = Return ; pat.buyer_id  = 87; pat.seller_id = 86; pat.item_type = Large ; pat.item_num = 14;  end
        138: begin  pat.act = Check  ; pat.buyer_id  = 88; pat.seller_id = 89;  end
        139: begin  pat.act = Return ; pat.buyer_id  = 89; pat.seller_id = 88; pat.item_type = Small ; pat.item_num = 20;  end
        140: begin  pat.act = Check  ; pat.buyer_id  = 90; pat.seller_id = 91;  end
        141: begin  pat.act = Return ; pat.buyer_id  = 91; pat.seller_id = 90; pat.item_type = Medium; pat.item_num = 14;  end
        142: begin  pat.act = Check  ; pat.buyer_id  = 92; pat.seller_id = 93;  end
        143: begin  pat.act = Return ; pat.buyer_id  = 93; pat.seller_id = 92; pat.item_type = Large ; pat.item_num = 1;  end
        144: begin  pat.act = Buy    ; pat.buyer_id  = 97; pat.seller_id = 96; pat.item_type = Medium; pat.item_num = 10;  end
        145: begin  pat.act = Return ; pat.buyer_id  = 95; pat.seller_id = 94; pat.item_type = Large ; pat.item_num = 50;  end
        146: begin  pat.act = Buy    ; pat.buyer_id  = 102; pat.seller_id = 101; pat.item_type = Large ; pat.item_num = 50;  end
        147: begin  pat.act = Return ; pat.buyer_id  = 97; pat.seller_id = 96; pat.item_type = Medium; pat.item_num = 10;  end
        148: begin  pat.act = Buy    ; pat.buyer_id  = 95; pat.seller_id = 94; pat.item_type = Large ; pat.item_num = 50;  end
        149: begin  pat.act = Return ; pat.buyer_id  = 102; pat.seller_id = 101; pat.item_type = Large ; pat.item_num = 50;  end
        150: begin  pat.act = Buy    ; pat.buyer_id  = 104; pat.seller_id = 103; pat.item_type = Medium; pat.item_num = 10;  end
        151: begin  pat.act = Return ; pat.buyer_id  = 67; pat.seller_id = 66; pat.item_type = Small ; pat.item_num = 12;  end
        152: begin  pat.act = Buy    ; pat.buyer_id  = 104; pat.seller_id = 103; pat.item_type = Medium; pat.item_num = 10;  end
        153: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 98; pat.item_type = Small ; pat.item_num = 8;  end
        154: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 98; pat.item_type = Medium; pat.item_num = 60;  end
        155: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 99; pat.item_type = Large ; pat.item_num = 21;  end
        156: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 99; pat.item_type = Small ; pat.item_num = 22;  end
        157: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 100; pat.item_type = Medium; pat.item_num = 23;  end
        158: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 100; pat.item_type = Large ; pat.item_num = 24;  end
        159: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Medium; pat.item_num = 19;  end
        160: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Large ; pat.item_num = 21;  end
        161: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Small ; pat.item_num = 22;  end
        162: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Medium; pat.item_num = 23;  end
        163: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Large ; pat.item_num = 20;  end
        164: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Small ; pat.item_num = 20;  end
        165: begin  pat.act = Return ; pat.buyer_id  = 34; pat.seller_id = 32; pat.item_type = Large ; pat.item_num = 20;  end
        166: begin  pat.act = Check  ; pat.buyer_id  = 105; pat.seller_id = 106;  end
        167: begin  pat.act = Deposit; pat.buyer_id  = 106; pat.money     = 20841;  end
        168: begin  pat.act = Check  ; pat.buyer_id  = 105; pat.seller_id = 108;  end
        169: begin  pat.act = Deposit; pat.buyer_id  = 108; pat.money     = 567;  end
        170: begin  pat.act = Check  ; pat.buyer_id  = 107; pat.seller_id = 109;  end
        171: begin  pat.act = Deposit; pat.buyer_id  = 109; pat.money     = 8910;  end
        172: begin  pat.act = Check  ; pat.buyer_id  = 32;  end
        173: begin  pat.act = Deposit; pat.buyer_id  = 110; pat.money     = 1122;  end
    endcase
endfunction

function void pattern_from_table2();
    case(i_pat)
        390:  begin  pat.act = Check;   pat.buyer_id = 27;  end  
        391:  begin  pat.act = Return;  pat.buyer_id = 34;  pat.seller_id = 32;  end
        392:  begin  pat.act = Return;  pat.buyer_id = 27;  pat.seller_id = 26;  end
        393:  begin  pat.act = Buy;     pat.buyer_id = 27;  pat.seller_id = 26;  pat.item_type = Large;   pat.item_num = 50; end
        394:  begin  pat.act = Buy;     pat.buyer_id = 21;  pat.seller_id = 22;  pat.item_type = Medium;   pat.item_num = 10;  end
        395:  begin  pat.act = Check;   pat.buyer_id = 22;  pat.seller_id = 107; end
        396:  begin  pat.act = Return;  pat.buyer_id = 21;  pat.seller_id = 22;  end
        397:  begin  pat.act = Buy;     pat.buyer_id = 21;  pat.seller_id = 22;  pat.item_type = Medium;   pat.item_num = 10;  end
        398:  begin  pat.act = Check;   pat.buyer_id = 110; pat.seller_id = 21;  end
        399:  begin  pat.act = Return;  pat.buyer_id = 21;  pat.seller_id = 22;  end  
    endcase
endfunction
endprogram