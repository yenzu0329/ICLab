`include "../00_TESTBED/Usertype_OS.sv"
import usertype::*;

// ===============
//   Parameters
// ===============
// pattern
parameter GEN_DRAM_FILE         = 0;
parameter CHANGE_BUYER_PERCENT  = 30;
parameter CHANGE_SELLER_PERCENT = 60;
// ---
parameter BUY_PERCENT           = 30;
parameter CHECK_PERCENT         = 20;
parameter DEP_PERCENT           = 20;
parameter RETURN_PERCENT        = 30;
// ---    
parameter EXTRA_BUY_PERCENT     = 50;
parameter ERR_PERCENT           = 50;
// random 
parameter RAND_SEED             = 125;
// DRAM 
parameter DRAM_PATH             = "../00_TESTBED/DRAM/dram.dat";
parameter BASE_ADDR             = 'h10000; 
parameter USER_NUM              = 256;
parameter USER_INFO_SIZE        = 8;

int unsigned r;

typedef struct packed {
    // input valid
    logic        buyer_valid;
    logic        seller_valid;
    logic        act_valid;
    logic        item_valid;
    logic        num_valid;
    logic        amnt_valid;
    // input data
	User_id      buyer_id;
    User_id      seller_id;
    Action       act;
    Item_id      item_type;
    Item_num     item_num;
    Money        money;
    // output data
    Error_Msg    err_msg;
    logic [31:0] out_info;
    logic        complete;
}	Pattern;

class RandPattern;
    rand User_id      buyer_id;
    rand User_id      seller_id;
    rand Action       act;
    rand Item_id      item_type;
    rand Item_num     item_num;
    rand Money        money;
    rand bit          change_buyer;
    rand bit          change_seller;
    rand bit          check_stock;
    rand bit          gen_buy_action;
    rand Error_Msg    err_msg;

    function new();
        this.srandom(RAND_SEED);
    endfunction

    constraint limit {
        buyer_id != seller_id;
        act dist {
            Buy     := BUY_PERCENT,
            Check   := CHECK_PERCENT, 
            Deposit := DEP_PERCENT, 
            Return  := RETURN_PERCENT
        };
        item_type      inside {Large, Medium, Small};
        item_num       inside {[1:2**6-1]};
        money          inside {[1:2**16-1]};
        change_buyer   dist   {1:=CHANGE_BUYER_PERCENT, 0:=100-CHANGE_BUYER_PERCENT};
        change_seller  dist   {1:=CHANGE_SELLER_PERCENT, 0:=100-CHANGE_SELLER_PERCENT};
        gen_buy_action dist   {1:=EXTRA_BUY_PERCENT, 0:=100-EXTRA_BUY_PERCENT};
        // Error Msg
        (act == Buy)     -> err_msg dist {No_Err:=100-ERR_PERCENT, INV_Not_Enough:=ERR_PERCENT/3, INV_Full:=ERR_PERCENT/3, Out_of_money:=ERR_PERCENT/3};
        (act == Check)   -> err_msg dist {No_Err};
        (act == Deposit) -> err_msg dist {No_Err:=100-ERR_PERCENT, Wallet_is_Full:=ERR_PERCENT};
        (act == Return)  -> err_msg dist {No_Err:=100-ERR_PERCENT, [1:5]:/ERR_PERCENT};
        // === Return ===
        // 1: Wrong_act (A was not buyer or B was not seller)
        // 2: Wrong_act (B's buyer is not A)
        // 3: Wrong_ID  (A's seller is not B)
        // 4: Wrong_Num
        // 5: Wrong_Item
    }
endclass
    
class RandUser;
    // Shop info
    rand Item_num       large_num;
    rand Item_num       medium_num;
    rand Item_num       small_num;
    rand User_Level     level;
    rand EXP            exp;
    
    // User info
    rand Money          money;
    rand Item_id        his_item_ID;
	rand Item_num       his_item_num;
	rand User_id        his_seller_ID;

    function new();
        this.srandom(RAND_SEED+1);
    endfunction

    constraint limit {
        // Shop info
        large_num     inside {[0:2**6-1]};
        medium_num    inside {[0:2**6-1]};
        small_num     inside {[0:2**6-1]};
        level         dist   {Platinum:=10, Gold:=20, Silver:=30, Copper:=40};
        // exp
        (level == Platinum) -> exp inside {0};
        (level == Gold)     -> exp inside {[0:4000-1]};
        (level == Silver)   -> exp inside {[0:2500-1]};
        (level == Copper)   -> exp inside {[0:1000-1]};
        // User info
        money         inside {[0:2**16-1]};
        his_item_num  inside {[0:2**6-1]};
        his_seller_ID inside {[0:USER_NUM-1]};
        his_item_ID   inside {Large, Medium, Small};
    }
endclass

class RandInterval;
    rand int unsigned interval;
    function new();
        this.srandom(RAND_SEED+2);
    endfunction
    constraint limit { interval inside {[1:5]}; }
endclass

class RandNum;
    rand int unsigned num;
    function new();
        this.srandom(RAND_SEED+3);
    endfunction
endclass

class Dram;
    logic [16:0] DRAM_addr;
    logic [7:0]  data [((BASE_ADDR + USER_NUM * USER_INFO_SIZE)-1) : (BASE_ADDR)];

    function new();
        if(GEN_DRAM_FILE) begin
            genDramFile();
        end
        readDramFile();
    endfunction

    function void genDramFile();
        int unsigned dfile, i;
        logic [7:0] temp_data [3:0];
        RandUser rand_user = new();

        dfile = $fopen(DRAM_PATH, "w");
        for(i = 0; i < USER_NUM; i = i+1) begin
            r = rand_user.randomize();
            // Shop info
            temp_data[0] = {rand_user.large_num,       rand_user.medium_num[5:4]};
            temp_data[1] = {rand_user.medium_num[3:0], rand_user.small_num [5:2]};
            temp_data[2] = {rand_user.small_num [1:0], rand_user.level, rand_user.exp[11:8]};
            temp_data[3] = {rand_user.exp[7:0]};

            $fwrite(dfile, "@%5H\n", BASE_ADDR + i*8);
            $fwrite(dfile, "%H %H %H %H\n", temp_data[0], temp_data[1], temp_data[2], temp_data[3]);

            // User info
            temp_data[0] = {rand_user.money[15:8]};
            temp_data[1] = {rand_user.money[7:0]};
            temp_data[2] = {rand_user.his_item_ID, rand_user.his_item_num};
            temp_data[3] = {rand_user.his_seller_ID};

            $fwrite(dfile, "@%5H\n", BASE_ADDR + i*8 + 4);
            $fwrite(dfile, "%H %H %H %H\n", temp_data[0], temp_data[1], temp_data[2], temp_data[3]);
        end
        $fclose(dfile);
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

class ShopPlatform;
    RandPattern  rand_pat = new();
    RandNum      rand_num = new();
    Pattern      pat, next_pat;
    Dram         dram = new();
    User         buyer, seller;
    logic        pat_from_next_pat;

    User_id      buyer_his  [(USER_NUM-1) : 0];
    User_id      seller_his [(USER_NUM-1) : 0];
    logic [(USER_NUM-1) : 0] buyer_valid;
    logic [(USER_NUM-1) : 0] seller_valid;

    function new();
        int unsigned i;
        r = rand_pat.randomize();
        rand_pat.change_buyer = 1;
        pat = 0;
        next_pat = 0;
        buyer_valid = 0;
        seller_valid = 0;
        pat_from_next_pat = 0;
    endfunction

    function Pattern getPatten();
        if(next_pat != 0) begin
            pat = next_pat;
            next_pat = 0;
            pat_from_next_pat = 1;
        end
        else begin
            pat_from_next_pat = 0;
        end
        setPattern();
        if(pat.act == Return && !pat_from_next_pat && rand_pat.gen_buy_action) begin
            next_pat = pat;
            pat.act = Buy;
            pat.err_msg = No_Err;
        end
        else begin
            r = rand_pat.randomize();
        end
        buyer = dram.readUserFromDram(pat.buyer_id);
        seller = dram.readUserFromDram(pat.seller_id);
        
        case(pat.act)
            Buy:     runBuy();
            Check:   runCheck();
            Deposit: runDeposit();
            Return:  runReturn();
        endcase
        pat.complete = (pat.err_msg == No_Err);
        updateHistory();
        
        dram.writeUserToDram(buyer);
        dram.writeUserToDram(seller);
        return pat;
    endfunction

    function void setPattern();
        if(rand_pat.change_buyer)
            pat.buyer_id = rand_pat.buyer_id;
        if(rand_pat.change_seller || pat.buyer_id == pat.seller_id)
            pat.seller_id = (pat.buyer_id == rand_pat.seller_id)?(rand_pat.buyer_id):(rand_pat.seller_id);

        pat.act       = rand_pat.act;
        pat.item_type = rand_pat.item_type;
        pat.item_num  = rand_pat.item_num;
        pat.money     = rand_pat.money;
        pat.err_msg   = rand_pat.err_msg;

        pat.buyer_valid = rand_pat.change_buyer;
        pat.act_valid = 1;
        case(pat.act) 
            Buy: begin
                pat.seller_valid = 1;
                pat.item_valid   = 1;
                pat.num_valid    = 1;
                pat.amnt_valid   = 0;
            end
            Check: begin
                pat.seller_valid = rand_pat.check_stock;
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
        int unsigned      price, fee, require_exp, reward_exp;
        int unsigned      buyer_remain_stock, seller_stock, temp_stock;

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

        if(pat.err_msg == INV_Full) begin
            if(buyer_remain_stock == 63) begin
                if(pat.item_num > seller_stock)
                    pat.err_msg = INV_Not_Enough;
                else
                    pat.err_msg = No_Err;
            end
            else if(pat.item_num <= buyer_remain_stock) begin
                r = rand_num.randomize();
                pat.item_num = buyer_remain_stock + rand_num.num % (63 - buyer_remain_stock) + 1;
            end
        end
        else if(pat.err_msg == INV_Not_Enough) begin
            if(seller_stock == 63)
                pat.err_msg = No_Err;
            else if(pat.item_num <= seller_stock) begin
                r = rand_num.randomize();
                pat.item_num = seller_stock + rand_num.num % (63 - seller_stock) + 1;
            end
            if(pat.item_num > buyer_remain_stock) begin
                pat.err_msg = INV_Full;
            end
        end
        else begin
            if(buyer_remain_stock == 0)
                pat.err_msg = INV_Full;
            else if(seller_stock == 0) begin
                r = rand_num.randomize();
                pat.item_num = (rand_num.num % buyer_remain_stock) + 1;
                pat.err_msg = INV_Not_Enough;
            end
            else begin
                temp_stock = (seller_stock < buyer_remain_stock) ? seller_stock : buyer_remain_stock;
                if(pat.item_num > temp_stock) begin
                    r = rand_num.randomize();
                    pat.item_num = (rand_num.num % temp_stock) + 1;
                end
            end
        end
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

        // Out_of_money
        if(pat.err_msg == No_Err && buyer.user_info.money < price + fee)
            pat.err_msg = Out_of_money;
        else if(pat.err_msg == Out_of_money && buyer.user_info.money >= price + fee)
            pat.err_msg = No_Err;
        
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
        if(pat.seller_valid)
            pat.out_info = {seller.shop_info.large_num, seller.shop_info.medium_num, seller.shop_info.small_num};
        else
            pat.out_info = buyer.user_info.money;
    endfunction

    function void runDeposit();
        int unsigned remain_money;
        remain_money = 16'hFFFF - buyer.user_info.money;
        if(pat.err_msg == Wallet_is_Full) begin
            if(pat.money <= remain_money) begin
                r = rand_num.randomize();
                pat.money = remain_money + 1 + rand_num.num % (16'hFFFF - remain_money);
            end
        end
        else begin
            if(remain_money == 0)
                pat.err_msg = Wallet_is_Full;
            else if(pat.money > remain_money) begin
                r = rand_num.randomize();
                pat.money = rand_num.num % (remain_money + 1);
            end
        end

        if(pat.err_msg == No_Err) begin
            buyer.user_info.money = buyer.user_info.money + pat.money;
            pat.out_info = buyer.user_info.money;
        end
        else begin
            pat.out_info = 0;
        end
    endfunction

    function void runReturn();
        logic      is_find;
        int unsigned    price;
        if(pat.err_msg == 1) begin // A was not buyer or B was not seller
            genErrMsg1();
        end
        else if(pat.err_msg == 2) begin // B's buyer is not A
            is_find = findMismatchTrade(pat.buyer_id);
            if(!is_find)
                genErrMsg1();
        end
        else begin
            is_find = findMatchTrade(pat.buyer_id);
            if(!is_find)
                genErrMsg1();
            else begin
                if(pat.err_msg == 3) begin // A's seller is not B
                    r = rand_num.randomize();
                    pat.seller_id = pat.seller_id + rand_num.num % 255 + 1;
                end
                else if(pat.err_msg == 4) begin // Wrong_Num
                    r = rand_num.randomize();
                    pat.item_num = buyer.user_info.shop_history.item_num;
                    pat.item_num = pat.item_num + rand_num.num % 63 + 1;
                end
                else if(pat.err_msg == 5) begin // Wrong_Item
                    r = rand_num.randomize();
                    pat.item_num = buyer.user_info.shop_history.item_num;
                    pat.item_type = buyer.user_info.shop_history.item_ID;
                    if(pat.item_type == Small)
                        pat.item_type = Item_id'(1 + rand_num.num % 2);
                    else if(pat.item_type == Medium)
                        pat.item_type = Item_id'(1 + (rand_num.num % 2) * 2);
                    else
                        pat.item_type = Item_id'(2 + rand_num.num % 2);
                end
                else begin
                    pat.err_msg = No_Err;
                    pat.item_num = buyer.user_info.shop_history.item_num;
                    pat.item_type = buyer.user_info.shop_history.item_ID;
                end
            end
        end
        case(pat.err_msg)
            1: pat.err_msg = Wrong_act;
            2: pat.err_msg = Wrong_act;
            3: pat.err_msg = Wrong_ID;
            4: pat.err_msg = Wrong_Num;
            5: pat.err_msg = Wrong_Item;
        endcase
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

    function void genErrMsg1();
        if(buyer_valid[pat.buyer_id] && seller_valid[buyer_his[pat.buyer_id]]) begin
            // swap id
            pat.buyer_id = buyer_his[pat.buyer_id];
            pat.buyer_valid = 1;
            pat.seller_id = pat.buyer_id;
            // swap user
            buyer = dram.readUserFromDram(pat.buyer_id);
            seller = dram.readUserFromDram(pat.seller_id);
        end
        pat.err_msg = Wrong_act;
    endfunction

    function logic findMismatchTrade(User_id bid);
        int unsigned i, j;
        int unsigned temp_bid = pat.buyer_id;
        User_id sid;
        for(i = 0; i < 256; i = i+1) begin
            if(buyer_valid[bid]) begin
                sid = buyer_his[bid];
                if(seller_valid[sid] && seller_his[sid] != bid) begin
                    pat.buyer_id = bid;
                    pat.seller_id = sid;
                    buyer = dram.readUserFromDram(pat.buyer_id);
                    seller = dram.readUserFromDram(pat.seller_id);
                    if(bid != temp_bid)
                        pat.buyer_valid = 1;
                    return 1;
                end
            end
            bid = bid + 1;
        end
        return 0;
    endfunction

    function logic findMatchTrade(User_id bid);
        int unsigned i, j;
        int unsigned temp_bid = pat.buyer_id;
        User_id sid;
        for(i = 0; i < 256; i = i+1) begin
            if(buyer_valid[bid]) begin
                sid = buyer_his[bid];
                if(seller_valid[sid] && seller_his[sid] == bid) begin
                    pat.buyer_id = bid;
                    pat.seller_id = sid;
                    buyer = dram.readUserFromDram(pat.buyer_id);
                    seller = dram.readUserFromDram(pat.seller_id);
                    if(bid != temp_bid)
                        pat.buyer_valid = 1;
                    return 1;
                end
            end
            bid = bid + 1;
        end
        return 0;
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
endclass
