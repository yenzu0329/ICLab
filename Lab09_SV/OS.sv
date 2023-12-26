module OS(input clk, INF.OS_inf inf);
import usertype::*;

// =========================
//   Parameters & Integers
// =========================
logic         rst_n;

OS_State      state, next_state;
logic [2:0]   counter;
logic         check_buyer;
logic         check_seller;
logic         seller_is_valid, next_seller_is_valid;
logic [3:0]   out_msg;
 
Money         in_money;
User_id       in_buyer_id;
User_id       in_seller_id;
Action        in_act;
Item_id       in_item_type;
Item_num_ext  in_item_num;
logic         in_seller_flg;
logic         in_buyer_flg;
 
User          buyer, next_buyer;
User          seller, next_seller;
logic [63:0]  buyer_data_64b;
logic [63:0]  seller_data_64b;
logic         first_buyer;
logic         first_seller;
logic         w_buyer_flg, r_buyer_flg, temp_buyer_flg;
logic         w_seller_flg, r_seller_flg, temp_seller_flg;
logic         bridge_valid;

logic         overwrite_seller_flg;
logic         overwrite_buyer_flg;

logic [255:0] is_buyer;
logic [255:0] is_seller;

logic [14:0]  price;
logic [11:0]  reward_exp;
logic [6:0]   fee;
User_id       true_seller_id;
logic         true_seller_valid, true_seller_valid_d1;
logic         true_seller_flg;

// ==========
//   Design
// ==========
assign rst_n = inf.rst_n;
// FSM
always_comb begin
    next_state = state;
    next_seller_is_valid = seller_is_valid;
    check_buyer = 0;
    check_seller = 0;
    case(state)
        S_IN_ACT: begin
            if(inf.act_valid) next_state = S_IN;
        end
        S_IN: begin
            case(in_act)
                Buy:
                    if(inf.id_valid)        check_seller = 1;
                Check:  
                    if(inf.id_valid)        check_seller = 1;
                    else if(counter >= 5)   check_buyer  = 1;
                Deposit:   
                    if(inf.amnt_valid)      check_buyer  = 1;
                Return:    
                    if(inf.id_valid)        check_seller = 1;
            endcase
            if(check_buyer) begin
                next_seller_is_valid = 0;
                if(in_buyer_id != next_buyer.id || first_buyer)
                    next_state = S_WAIT;
                else
                    next_state = S_EXEC;
            end
            else if(check_seller) begin
                next_seller_is_valid = 1;
                if(in_act == Return) begin
                    if(buyer.id == in_buyer_id && seller.id == true_seller_id)
                        next_state = S_EXEC;
                    else
                        next_state = S_WAIT;
                end
                else begin
                    if((inf.D != in_seller_id || first_seller)) begin
                        next_state = S_WAIT;
                    end
                    else if(r_buyer_flg) begin
                        if(!w_buyer_flg && inf.C_out_valid)
                            next_state = S_EXEC;
                        else
                            next_state = S_WAIT;
                    end
                    else begin
                        next_state = S_EXEC;
                    end
                end
            end
        end
        S_WAIT: begin
            if(in_act == Return) begin
                if(buyer.id == in_buyer_id && seller.id == true_seller_id || first_buyer && inf.C_out_valid)
                    next_state = S_EXEC;
            end
            else begin
                if(!temp_seller_flg && !temp_buyer_flg && inf.C_out_valid)   
                    next_state = S_EXEC;
            end
        end
        S_EXEC: begin
            next_state = S_IN_ACT;
        end
    endcase
end
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)  state <= S_IN_ACT;
    else        state <= next_state;
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)  seller_is_valid <= 0;
    else        seller_is_valid <= next_seller_is_valid;
end

// counter
always_ff @(posedge clk) begin
    if(state == S_IN)  counter <= counter + 1;
    else               counter <= 0;
end

// ----------
//   Inputs
// ----------
assign in_buyer_flg = inf.id_valid && state == S_IN_ACT;
assign in_seller_flg = inf.id_valid && state == S_IN;
always_ff @(posedge clk) begin
    if(inf.amnt_valid) in_money <= inf.D;
    else               in_money <= in_money;
end

always_ff @(posedge clk) begin
    if(in_buyer_flg)   in_buyer_id <= inf.D;
    else               in_buyer_id <= in_buyer_id;
end

always_ff @(posedge clk) begin
    if(in_buyer_flg && inf.D == in_seller_id)
        in_seller_id <= in_buyer_id;
    else if(in_seller_flg)  
        in_seller_id <= inf.D;
    else if(inf.out_valid && in_act == Return)
        in_seller_id <= true_seller_id;
    else               
        in_seller_id <= in_seller_id;
end

always_ff @(posedge clk) begin
    if(inf.act_valid)  in_act <= inf.D;
    else               in_act <= in_act;
end

always_ff @(posedge clk) begin
    if(inf.item_valid) in_item_type <= inf.D;
    else               in_item_type <= in_item_type;
end

always_ff @(posedge clk) begin
    if(inf.num_valid)  in_item_num <= inf.D;
    else               in_item_num <= in_item_num;
end

// ----------
//   Bridge
// ----------
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) 
        bridge_valid <= 1;
    else if(inf.C_in_valid)
        bridge_valid <= 0;
    else if(inf.C_out_valid)
        bridge_valid <= 1;
    else
        bridge_valid <= bridge_valid;
end

always_comb begin
    inf.C_in_valid = bridge_valid && (w_buyer_flg | r_buyer_flg | w_seller_flg | r_seller_flg);
    if(w_buyer_flg) begin
        inf.C_r_wb = 0;
        inf.C_data_w = buyer_data_64b;
        inf.C_addr = buyer.id;
    end
    else if(r_buyer_flg) begin
        inf.C_r_wb = 1;
        inf.C_data_w = buyer_data_64b;
        inf.C_addr = in_buyer_id;
    end
    else if(w_seller_flg) begin
        inf.C_r_wb = 0;
        inf.C_data_w = seller_data_64b;
        inf.C_addr = seller.id;
    end
    else if(r_seller_flg) begin
        inf.C_r_wb = 1;
        inf.C_data_w = seller_data_64b;
        inf.C_addr = (in_act == Return) ? true_seller_id : in_seller_id;
    end
    else begin
        inf.C_r_wb = 0;
        inf.C_data_w = 0;
        inf.C_addr = 0;
    end
end

// ---------------
//   Computation
// ---------------
always_comb begin
    price = in_item_num * 100;
    case(in_item_type)
        Large:   price = in_item_num * 300;
        Medium:  price = in_item_num * 200;
        Small:   price = in_item_num * 100;
    endcase
end

always_comb begin
    reward_exp = in_item_num * 20;
    case(in_item_type)
        Large:   reward_exp = in_item_num * 60;
        Medium:  reward_exp = in_item_num * 40;
        Small:   reward_exp = in_item_num * 20;
    endcase
end

always_comb begin
    fee = 10;
    case(buyer.shop_info.level)
        Platinum: fee = 10;
        Gold:     fee = 30;
        Silver:   fee = 50;
        Copper:   fee = 70;      
    endcase
end

// ---------
//   Buyer
// ---------
always_comb begin
    buyer_data_64b = {
        buyer.user_info.shop_history.seller_ID,
        buyer.user_info.shop_history.item_ID,
        buyer.user_info.shop_history.item_num,
        buyer.user_info.money[7:0],
        buyer.user_info.money[15:8],
        buyer.shop_info.exp[7:0],
        buyer.shop_info.small_num[1:0],
        buyer.shop_info.level, 
        buyer.shop_info.exp[11:8],
        buyer.shop_info.medium_num[3:0],
        buyer.shop_info.small_num[5:2],
        buyer.shop_info.large_num, 
        buyer.shop_info.medium_num[5:4]
    };
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) 
        first_buyer <= 1;
    else begin
        if(inf.out_valid && in_act != Check)
            first_buyer <= 0;
        else 
            first_buyer <= first_buyer;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        temp_buyer_flg <= 0;
    end
    else begin
        if(in_buyer_flg) begin
            if(first_buyer) begin
                temp_buyer_flg <= 1;
            end
            else if(inf.D != in_buyer_id && inf.D != in_seller_id) begin
                temp_buyer_flg <= 1;
            end
            else begin
                temp_buyer_flg <= 0;
            end
        end
        else if(inf.C_in_valid) begin
            if(w_buyer_flg) begin
                temp_buyer_flg <= 1;
            end
            else if(r_buyer_flg) begin
                temp_buyer_flg <= 0;
            end
            else begin
                temp_buyer_flg <= temp_buyer_flg;
            end
        end
        else begin
            temp_buyer_flg <= temp_buyer_flg;
        end
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        w_buyer_flg <= 0;
        r_buyer_flg <= 0;
    end
    else begin
        if(in_buyer_flg) begin
            if(first_buyer) begin
                w_buyer_flg <= 0;
                r_buyer_flg <= 1;
            end
            else if(inf.D != in_buyer_id && inf.D != in_seller_id) begin
                w_buyer_flg <= overwrite_buyer_flg;
                r_buyer_flg <= 1;
            end
            else begin
                w_buyer_flg <= 0;
                r_buyer_flg <= 0;
            end
        end
        else if(inf.C_out_valid) begin
            if(w_buyer_flg) begin
                w_buyer_flg <= 0;
                r_buyer_flg <= 1;
            end
            else if(r_buyer_flg) begin
                w_buyer_flg <= 0;
                r_buyer_flg <= 0;
            end
            else begin
                w_buyer_flg <= w_buyer_flg;
                r_buyer_flg <= r_buyer_flg;
            end
        end
        else begin
            w_buyer_flg <= w_buyer_flg;
            r_buyer_flg <= r_buyer_flg;
        end
    end
end

always_comb begin
    next_buyer = buyer;
    if(inf.C_out_valid && r_buyer_flg && !w_buyer_flg) begin
        next_buyer.id = in_buyer_id;
        next_buyer.user_info.money                  = {inf.C_data_r[39:32], inf.C_data_r[47:40]};
        next_buyer.user_info.shop_history.item_ID   = inf.C_data_r[55:54];
        next_buyer.user_info.shop_history.item_num  = inf.C_data_r[53:48];
        next_buyer.user_info.shop_history.seller_ID = inf.C_data_r[63:56];
        next_buyer.shop_info.large_num              = inf.C_data_r[7:2];
        next_buyer.shop_info.medium_num             = {inf.C_data_r[1:0], inf.C_data_r[15:12]};
        next_buyer.shop_info.small_num              = {inf.C_data_r[11:8], inf.C_data_r[23:22]};
        next_buyer.shop_info.level                  = inf.C_data_r[21:20];
        next_buyer.shop_info.exp                    = {inf.C_data_r[19:16], inf.C_data_r[31:24]};
    end
    else if(in_buyer_flg && inf.D == in_seller_id)
        next_buyer = seller;
    else if(state == S_EXEC && out_msg == No_Err) begin
        case(in_act)
            Buy: begin
                next_buyer.user_info.money = buyer.user_info.money - price - fee;
                next_buyer.user_info.shop_history.item_ID = in_item_type;
                next_buyer.user_info.shop_history.item_num = in_item_num;
                next_buyer.user_info.shop_history.seller_ID = in_seller_id;

                if(in_item_type == Large)
                    next_buyer.shop_info.large_num = buyer.shop_info.large_num + in_item_num;
                else if(in_item_type == Medium)
                    next_buyer.shop_info.medium_num = buyer.shop_info.medium_num + in_item_num;
                else
                    next_buyer.shop_info.small_num = buyer.shop_info.small_num + in_item_num;

                case(buyer.shop_info.level)
                    Gold:
                        if(buyer.shop_info.exp + reward_exp >= 4000) begin
                            next_buyer.shop_info.exp = 0;
                            next_buyer.shop_info.level = Platinum;
                        end
                        else 
                            next_buyer.shop_info.exp = buyer.shop_info.exp + reward_exp;
                    Silver:
                        if(buyer.shop_info.exp + reward_exp >= 2500) begin
                            next_buyer.shop_info.exp = 0;
                            next_buyer.shop_info.level = Gold;
                        end
                        else 
                            next_buyer.shop_info.exp = buyer.shop_info.exp + reward_exp;
                    Copper:  
                        if(buyer.shop_info.exp + reward_exp >= 1000) begin
                            next_buyer.shop_info.exp = 0;
                            next_buyer.shop_info.level = Silver;
                        end 
                        else 
                            next_buyer.shop_info.exp = buyer.shop_info.exp + reward_exp;
                endcase
            end
            Deposit: begin
                next_buyer.user_info.money = buyer.user_info.money + in_money;
            end
            Return: begin
                next_buyer.user_info.money = buyer.user_info.money + price;
                if(in_item_type == Large)
                    next_buyer.shop_info.large_num = buyer.shop_info.large_num - in_item_num;
                else if(in_item_type == Medium)
                    next_buyer.shop_info.medium_num = buyer.shop_info.medium_num - in_item_num;
                else
                    next_buyer.shop_info.small_num = buyer.shop_info.small_num - in_item_num;
            end
        endcase
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)      buyer <= 0;
    else            buyer <= next_buyer;
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        is_buyer <= 0;
    else begin
        if(inf.complete) begin
            if(in_act == Buy)
                is_buyer <= (is_buyer | (1 << buyer.id)) & ~(1 << seller.id);
            else if(seller_is_valid)
                is_buyer <= is_buyer & ~(1 << buyer.id) & ~(1 << seller.id);
            else 
                is_buyer <= is_buyer & ~(1 << buyer.id);
        end
        else 
            is_buyer <= is_buyer;
    end
end

// ----------
//   Seller
// ----------
always_comb begin
    seller_data_64b = {
        seller.user_info.shop_history.seller_ID,
        seller.user_info.shop_history.item_ID,
        seller.user_info.shop_history.item_num,
        seller.user_info.money[7:0],
        seller.user_info.money[15:8],
        seller.shop_info.exp[7:0],
        seller.shop_info.small_num[1:0],
        seller.shop_info.level, 
        seller.shop_info.exp[11:8],
        seller.shop_info.medium_num[3:0],
        seller.shop_info.small_num[5:2],
        seller.shop_info.large_num, 
        seller.shop_info.medium_num[5:4]
    };
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) 
        first_seller <= 1;
    else begin
        if(inf.out_valid && in_act != Check && in_act != Deposit)
            first_seller <= 0;
        else 
            first_seller <= first_seller;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        temp_seller_flg <= 0;
    end
    else begin
        if(true_seller_flg) begin
            if(first_seller) begin
                temp_seller_flg <= 0;
            end
            else if(seller.id == true_seller_id) begin
                temp_seller_flg <= 0;
            end
            else begin
                temp_seller_flg <= 1;
            end
        end
        else if(in_act != Return && in_seller_flg) begin
            if(first_seller) begin
                temp_seller_flg <= 1;
            end
            else if(inf.D != in_seller_id) begin
                temp_seller_flg <= 1;
            end
            else begin
                temp_seller_flg <= temp_seller_flg;
            end
        end
        else if(inf.C_in_valid && !r_buyer_flg) begin
            if(w_seller_flg) begin
                temp_seller_flg <= 1;
            end
            else if(r_seller_flg) begin
                temp_seller_flg <= 0;
            end
            else begin
                temp_seller_flg <= temp_seller_flg;
            end
        end
        else begin
            temp_seller_flg <= temp_seller_flg;
        end
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        w_seller_flg <= 0;
        r_seller_flg <= 0;
    end
    else begin
        if(true_seller_flg) begin
            if(first_seller) begin
                w_seller_flg <= 0;
                r_seller_flg <= 0;
            end
            else if(seller.id == true_seller_id) begin
                w_seller_flg <= 0;
                r_seller_flg <= 0;
            end
            else begin
                w_seller_flg <= overwrite_seller_flg;
                r_seller_flg <= 1;
            end
        end
        else if(in_act != Return && in_seller_flg) begin
            if(first_seller) begin
                w_seller_flg <= 0;
                r_seller_flg <= 1;
            end
            else if(inf.D != in_seller_id) begin
                w_seller_flg <= overwrite_seller_flg;
                r_seller_flg <= 1;
            end
            else begin
                w_seller_flg <= w_seller_flg;
                r_seller_flg <= r_seller_flg;
            end
        end
        else if(inf.C_out_valid && !r_buyer_flg) begin
            if(w_seller_flg) begin
                w_seller_flg <= 0;
                r_seller_flg <= 1;
            end
            else if(r_seller_flg) begin
                w_seller_flg <= 0;
                r_seller_flg <= 0;
            end
            else begin
                w_seller_flg <= w_seller_flg;
                r_seller_flg <= r_seller_flg;
            end
        end
        else begin
            w_seller_flg <= w_seller_flg;
            r_seller_flg <= r_seller_flg;
        end
    end
end

always_comb begin
    next_seller = seller;
    if(inf.C_out_valid && !r_buyer_flg && !w_seller_flg) begin
        next_seller.id = (in_act == Return) ? true_seller_id : in_seller_id;
        next_seller.user_info.money                  = {inf.C_data_r[39:32], inf.C_data_r[47:40]};
        next_seller.user_info.shop_history.item_ID   = inf.C_data_r[55:54];
        next_seller.user_info.shop_history.item_num  = inf.C_data_r[53:48];
        next_seller.user_info.shop_history.seller_ID = inf.C_data_r[63:56];
        next_seller.shop_info.large_num              = inf.C_data_r[7:2];
        next_seller.shop_info.medium_num             = {inf.C_data_r[1:0], inf.C_data_r[15:12]};
        next_seller.shop_info.small_num              = {inf.C_data_r[11:8], inf.C_data_r[23:22]};
        next_seller.shop_info.level                  = inf.C_data_r[21:20];
        next_seller.shop_info.exp                    = {inf.C_data_r[19:16], inf.C_data_r[31:24]};
    end
    else if(in_buyer_flg && inf.D == in_seller_id)
        next_seller = buyer;
    else if(state == S_EXEC && out_msg == No_Err) begin
        case(in_act)
            Buy: begin
                if(seller.user_info.money + price >= 17'b10000000000000000)
                    next_seller.user_info.money = 16'b1111111111111111;
                else
                    next_seller.user_info.money = seller.user_info.money + price;
                
                next_seller.user_info.shop_history.item_ID = in_item_type;
                next_seller.user_info.shop_history.item_num = in_item_num;
                next_seller.user_info.shop_history.seller_ID = buyer.id;

                if(in_item_type == Large)
                    next_seller.shop_info.large_num = seller.shop_info.large_num - in_item_num;
                else if(in_item_type == Medium)
                    next_seller.shop_info.medium_num = seller.shop_info.medium_num - in_item_num;
                else
                    next_seller.shop_info.small_num = seller.shop_info.small_num - in_item_num;
            end
            Return: begin
                next_seller.user_info.money = seller.user_info.money - price;
                if(in_item_type == Large)
                    next_seller.shop_info.large_num = seller.shop_info.large_num + in_item_num;
                else if(in_item_type == Medium)
                    next_seller.shop_info.medium_num = seller.shop_info.medium_num + in_item_num;
                else
                    next_seller.shop_info.small_num = seller.shop_info.small_num + in_item_num;
            end
        endcase
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)      seller <= 0;
    else            seller <= next_seller;
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        is_seller <= 0;
    else begin
        if(inf.complete) begin
            if(in_act == Buy)
                is_seller <= (is_seller | (1 << seller.id)) & ~(1 << buyer.id);
            else if(seller_is_valid)
                is_seller <= is_seller & ~(1 << seller.id) & ~(1 << buyer.id);
            else
                is_seller <= is_seller & ~(1 << buyer.id);
        end
        else 
            is_seller <= is_seller;
    end
end

// ------------
//   Err Msg
// ------------
assign true_seller_id = buyer.user_info.shop_history.seller_ID;
assign true_seller_valid = state >= S_IN && in_act == Return && buyer.id == in_buyer_id;
always_ff @(posedge clk) begin
    true_seller_valid_d1 <= true_seller_valid;
end
assign true_seller_flg = true_seller_valid && ~true_seller_valid_d1;
always_comb begin
    out_msg = No_Err;
    if(state == S_EXEC) begin
        case(in_act)
            Buy: begin
                // priority 3
                if(buyer.user_info.money < price+fee)
                    out_msg = Out_of_money;
                // priority 1 & 2
                if(in_item_type == Large) begin
                    if(buyer.shop_info.large_num + in_item_num >= 7'b1000000)
                        out_msg = INV_Full;
                    else if(seller.shop_info.large_num < in_item_num)
                        out_msg = INV_Not_Enough;
                end
                else if(in_item_type == Medium) begin
                    if(buyer.shop_info.medium_num + in_item_num >= 7'b1000000)
                        out_msg = INV_Full;
                    else if(seller.shop_info.medium_num < in_item_num)
                        out_msg = INV_Not_Enough;
                end
                else begin
                    if(buyer.shop_info.small_num + in_item_num >= 7'b1000000)
                        out_msg = INV_Full;
                    else if(seller.shop_info.small_num < in_item_num)
                        out_msg = INV_Not_Enough;
                end
            end
            Deposit: begin
                if(buyer.user_info.money + in_money >= 17'b10000000000000000)
                    out_msg = Wallet_is_Full;
            end
            Return: begin
                if(!is_buyer[buyer.id] || !is_seller[seller.id])
                    out_msg = Wrong_act;
                else if(seller.user_info.shop_history.seller_ID != buyer.id)
                    out_msg = Wrong_act;
                else if(true_seller_id != in_seller_id)
                    out_msg = Wrong_ID;
                else if(in_item_num != buyer.user_info.shop_history.item_num)
                    out_msg = Wrong_Num;
                else if(in_item_type != buyer.user_info.shop_history.item_ID)
                    out_msg = Wrong_Item;
            end
        endcase
    end
end

// -----------
//   Output
// -----------
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        inf.out_valid <= 0;
        inf.err_msg <= No_Err;
        inf.complete <= 0;
        inf.out_info <= 0;
    end
    else if(state == S_EXEC) begin
        inf.out_valid <= 1;
        inf.err_msg <= out_msg;
        if(out_msg == No_Err) begin
            inf.complete <= 1;
            case(in_act)
                Buy:       
                    inf.out_info <= next_buyer.user_info;
                Check:     
                    if(seller_is_valid)  inf.out_info <= {next_seller.shop_info.large_num, next_seller.shop_info.medium_num, next_seller.shop_info.small_num};
                    else                 inf.out_info <= {next_buyer.user_info.money};
                Deposit:   
                    inf.out_info <= {next_buyer.user_info.money};
                default:
                    inf.out_info <= {next_buyer.shop_info.large_num, next_buyer.shop_info.medium_num, next_buyer.shop_info.small_num};
            endcase
        end
        else begin
            inf.complete <= 0;
            inf.out_info <= 0;
        end
    end
    else begin
        inf.out_valid <= 0;
        inf.err_msg <= No_Err;
        inf.complete <= 0;
        inf.out_info <= 0;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)  overwrite_seller_flg <= 0;
    else if(in_buyer_flg && inf.D == in_seller_id)
        overwrite_seller_flg <= 1;
    else if(state == S_EXEC && in_act != Check && in_act != Deposit && out_msg == No_Err)
        overwrite_seller_flg <= 1;
    else if(w_seller_flg)
        overwrite_seller_flg <= 0;
    else overwrite_seller_flg <= overwrite_seller_flg;
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)  overwrite_buyer_flg <= 0;
    else if(in_buyer_flg && inf.D == in_seller_id)
        overwrite_buyer_flg <= 1;
    else if(state == S_EXEC && in_act != Check && out_msg == No_Err)
        overwrite_buyer_flg <= 1;
    else if(w_buyer_flg)
        overwrite_buyer_flg <= 0;
    else overwrite_buyer_flg <= overwrite_buyer_flg;
end


endmodule