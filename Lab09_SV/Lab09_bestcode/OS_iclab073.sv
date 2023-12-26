//5/1 00:30 final
//10ns : 128881.370160 + 14892.292954
//5ns  : 137227.307471 + 14898.945755 => 760631.2661
//4ns  : 143397.779465 + 14932.209755 => 633319.9568 
module OS(input clk, INF.OS_inf inf);
import usertype::*;

///////////////////////////////////////////////////////////////////////
////////////////////////////declare////////////////////////////////////
///////////////////////////////////////////////////////////////////////
User_id current_user,interactor,D_user;
State current_state,next_state;
Error_Msg temp_errmsg;
Item_id item;
Shop_Info user_shopinfo,interactor_shopinfo;
User_Info user_userinfo,interactor_userinfo;

logic [2:0] cnt;
logic return_valid[255:0];
logic be_returned_valid[255:0];
logic finish,wait_data;
logic [1:0] whos_data;//0:user 1:interactor 2:finish
logic [5:0] item_num;
logic [6:0] fee;
logic [15:0] cost,total_price;
logic [15:0] deposit_money;
logic [6:0] total_num;
logic [5:0] seller_INV;
logic [11:0] target_exp;
logic [23:0] total_exp;
logic [16:0] total_money,money_after_deposit;
logic [7:0] C_data_r_part [7:0];
logic [63:0] C_data_w_mine;
logic user_change;
///////////////////////////////////////////////////////////////////////
/////////////////////////////design////////////////////////////////////
///////////////////////////////////////////////////////////////////////

//FSM
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) current_state <= S_idle;
    else current_state <= next_state;
end

//next_state
always_comb begin
    case(current_state) 
        S_idle: begin
            if(inf.act_valid) begin
                case(inf.D.d_act)
                    No_action:	next_state = current_state;
	                Buy:		next_state = S_buy;
	                Check:		next_state = S_check;
	                Deposit:	next_state = S_deposit;	 
	                Return:		next_state = S_return;
                    default:    next_state = current_state;
                endcase
            end
            else  next_state = current_state;
        end
        S_buy: begin
            if((cnt == 5)&&(temp_errmsg != No_Err)) next_state = S_idle; //error
            else if((cnt == 6)&&(whos_data == 2)) next_state = S_idle; //no error
            else next_state = current_state;
        end
        S_check: begin
            if(inf.id_valid) next_state = S_check_stock;
            else if(cnt == 6) next_state = S_check_deposit;
            else next_state = current_state;
        end
        S_check_deposit: begin
            if(whos_data == 1) next_state = S_idle;
            else next_state = current_state;
        end
        S_check_stock: begin
            if(whos_data == 1) next_state = S_idle;
            else next_state = current_state;
        end
        S_deposit: begin
            if((cnt == 3)&&(temp_errmsg != No_Err)) next_state = S_idle; //error
            else if((cnt == 4)&&(whos_data == 1)) next_state = S_idle; //no error
            else next_state = current_state;
        end
        S_return: begin
            if((cnt == 5)&&(temp_errmsg != No_Err)) next_state = S_idle; //error
            else if((cnt == 6)&&(whos_data == 2)) next_state = S_idle; //no error
            else next_state = current_state;
        end
        default : next_state = current_state;
    endcase
end

//counter
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) cnt <= 0;
    else begin
        case(current_state)
            S_idle,S_check_deposit,S_check_stock: begin
                cnt <= 0;
            end
            S_buy: begin 
                if(inf.item_valid || inf.num_valid || inf.id_valid) cnt <= cnt + 1; //0~3 get data
                else if((cnt == 3)&&(whos_data == 2)) cnt <= cnt + 1; //4:start calculation
                else if(cnt == 4) cnt <= cnt + 1;//5:got errmsg
                else if((cnt == 5)&&(temp_errmsg == No_Err)) cnt <= cnt + 1;//6:write
            end
            S_check: begin
                if(inf.id_valid) cnt <= 0;
                else if(cnt == 6) cnt <= 0;
                else cnt <= cnt + 1;
            end
            S_deposit: begin
                if(inf.amnt_valid) cnt <= cnt + 1; //1: get data
                else if(whos_data == 1) cnt <= cnt + 1; //2:start calculation
                else if(cnt == 2) cnt <= cnt + 1;//3:got errmsg
                else if((cnt == 3)&&(temp_errmsg == No_Err)) cnt <= cnt + 1;//4:write
            end
            S_return: begin
                if(inf.item_valid || inf.num_valid || inf.id_valid) cnt <= cnt + 1;//0~3 get data
                else if((cnt == 3)&&(whos_data == 2)) cnt <= cnt + 1; //4:start calculation
                else if(cnt == 4) cnt <= cnt + 1;//5:got errmsg
                else if((cnt == 5)&&(temp_errmsg == No_Err)) cnt <= cnt + 1;//6:write
            end
        endcase
    end
end

//current user 
always_ff@(posedge clk)begin
    if(current_state == S_idle) begin
        if(inf.id_valid) begin
            current_user <= inf.D.d_id;
        end
    end
end

//user_change
always_ff@(posedge clk)begin
    case(current_state)
        S_idle: begin
            if(inf.id_valid) begin user_change <= 1'b1; end
        end
        S_buy,S_check_deposit,S_deposit,S_return: begin 
            user_change <= 1'b0;
        end
    endcase
end

//interactor
always_ff@(posedge clk )begin
    case(current_state)
        S_buy: begin
            if(inf.id_valid) interactor <= inf.D.d_id;
        end
        S_check: begin
            if(inf.id_valid) interactor <= inf.D.d_id;
        end
        S_return: begin
            if(inf.id_valid) interactor <= inf.D.d_id;
        end
    endcase
end

//item
always_ff@(posedge clk )begin
    case(current_state)
        S_buy: begin
            if(inf.item_valid) item <= inf.D.d_item;
        end
        S_return: begin
            if(inf.item_valid) item <= inf.D.d_item;
        end
    endcase
end

//item_num
always_ff@(posedge clk )begin
    case(current_state)
        S_buy: begin
            if(inf.num_valid) item_num <= inf.D.d_item_num[5:0];
        end
        S_return: begin
            if(inf.num_valid) item_num <= inf.D.d_item;
        end
    endcase
end

//deposit_money
always_ff@(posedge clk )begin
    if(current_state == S_deposit) begin
        if(inf.amnt_valid) deposit_money <= inf.D.d_money;
    end
end

//return_flag
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) begin
        for(int i=0;i<256;i=i+1) begin
            return_valid[i] <= 1'b0;
            be_returned_valid[i] <= 1'b0;
        end
    end
    else begin
        case(current_state)
            S_buy: begin
                if((cnt == 5)&&(temp_errmsg == No_Err)) begin
                    return_valid[current_user] <= 1'b1;
                    be_returned_valid[interactor] <= 1'b1;
                    return_valid[interactor] <= 1'b0;
                    be_returned_valid[current_user] <= 1'b0;
                end
            end
            S_check_deposit: begin
                return_valid[current_user] <= 1'b0;
                be_returned_valid[current_user] <= 1'b0;
            end
            S_check_stock: begin
                return_valid[current_user] <= 1'b0;
                be_returned_valid[current_user] <= 1'b0;
                return_valid[interactor] <= 1'b0;
                be_returned_valid[interactor] <= 1'b0;
            end
            S_deposit: begin
                if((cnt == 3)&&(temp_errmsg == No_Err)) begin
                    return_valid[current_user] <= 1'b0;
                    be_returned_valid[current_user] <= 1'b0;
                end
            end
            S_return: begin
                if((cnt == 5)&&(temp_errmsg == No_Err)) begin
                    return_valid[current_user] <= 1'b0;
                    be_returned_valid[interactor] <= 1'b0;
                end
            end
        endcase
    end
end

//C_addr
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) inf.C_addr <= 0;
    else begin
        case(current_state)
            S_buy: begin
                if(cnt == 0) inf.C_addr <= current_user;
                else if(cnt == 3) inf.C_addr <= interactor;
                else if((cnt == 6)&&(whos_data == 0)) inf.C_addr <= current_user;
                else if((cnt == 6)&&(whos_data == 1)) inf.C_addr <= interactor;
            end
            S_check_deposit: begin
                inf.C_addr <= current_user;
            end
            S_check_stock: begin
                inf.C_addr <= interactor;
            end
            S_deposit: begin
                inf.C_addr <= current_user;
            end
            S_return: begin
                if((cnt == 0)&&(whos_data == 0)) inf.C_addr <= current_user;
                else if((cnt != 6)&&(whos_data == 1)) inf.C_addr <= user_userinfo.shop_history.seller_ID;
                else if((cnt == 6)&&(whos_data == 0)) inf.C_addr <= current_user;
                else if((cnt == 6)&&(whos_data == 1)) inf.C_addr <= interactor;
            end
        endcase
    end
end

//C_r_wb
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) inf.C_r_wb <= 1'b0;
    else begin
        case(current_state)
            S_buy: begin
                if(cnt == 0) inf.C_r_wb <= 1'b1;
                else if(cnt == 6) inf.C_r_wb <= 1'b0;
            end
            S_check_deposit: begin
                inf.C_r_wb <= 1'b1;
            end
            S_check_stock: begin
                inf.C_r_wb <= 1'b1;
            end
            S_deposit: begin
                if(cnt == 0) inf.C_r_wb <= 1'b1;
                else if(cnt == 4) inf.C_r_wb <= 1'b0;
            end
            S_return: begin
                if(cnt == 0) inf.C_r_wb <= 1'b1;
                else if(cnt == 6) inf.C_r_wb <= 1'b0;
            end
            default: inf.C_r_wb <= 1'b1;
        endcase
    end
end

//C_in_valid & wait_data
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) begin 
         inf.C_in_valid <= 1'b0;
         wait_data <= 1'b0;
    end
    else begin
        case(current_state)
            S_idle: begin
                inf.C_in_valid <= 1'b0;
                wait_data <= 1'b0;
            end
            S_buy: begin
                if(inf.C_in_valid) inf.C_in_valid <= 1'b0;
                else if((cnt == 0)&&(whos_data == 0)&&(!wait_data)) begin
                    inf.C_in_valid <= 1'b1;
                    wait_data <= 1'b1;
                end
                else if(((cnt == 3)||(cnt == 6))&&(!wait_data)&&(whos_data != 2)) begin 
                    inf.C_in_valid <= 1'b1;
                    wait_data <= 1'b1;
                end
                else if(inf.C_out_valid) begin
                    wait_data <= 1'b0;
                end
            end
            S_check_deposit: begin
                if(inf.C_in_valid) inf.C_in_valid <= 1'b0;
                else if((!wait_data)&&(whos_data == 0)) begin 
                    inf.C_in_valid <= 1'b1;
                    wait_data <= 1'b1;
                end
                else if(inf.C_out_valid) begin
                    wait_data <= 1'b0;
                end
            end
            S_check_stock: begin
                if(inf.C_in_valid) inf.C_in_valid <= 1'b0;
                else if((!wait_data)&&(whos_data == 0)) begin 
                    inf.C_in_valid <= 1'b1;
                    wait_data <= 1'b1;
                end
                else if(inf.C_out_valid) begin
                    wait_data <= 1'b0;
                end
            end
            S_deposit: begin
                if(inf.C_in_valid) inf.C_in_valid <= 1'b0;
                else if(((cnt == 0)||(cnt == 4))&&(!wait_data)&&(whos_data == 0)) begin 
                    inf.C_in_valid <= 1'b1;
                    wait_data <= 1'b1;
                end
                else if(inf.C_out_valid) begin
                    wait_data <= 1'b0;
                end
            end
            S_return: begin
                if(inf.C_in_valid) inf.C_in_valid <= 1'b0;
                else if(((cnt == 0)||(cnt == 1)||(cnt == 2)||(cnt == 3)||(cnt == 6))&&(!wait_data)&&(whos_data != 2)) begin 
                    inf.C_in_valid <= 1'b1;
                    wait_data <= 1'b1;
                end
                else if(inf.C_out_valid) begin
                    wait_data <= 1'b0;
                end
            end
        endcase
    end
end

//whos_data
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) whos_data <= 0;
    else begin
        case(current_state)
            S_idle: begin
                if(user_change) whos_data <= 0;
                else whos_data <= 1;
            end
            S_buy: begin
                if(inf.C_out_valid) whos_data <= whos_data + 1;
                else if (whos_data == 2) whos_data <= 0;
            end
            S_check_deposit: begin
                if(inf.C_out_valid) whos_data <= whos_data + 1;
                else if (whos_data == 1) whos_data <= 0;
            end
            S_check_stock: begin
                if(inf.C_out_valid) whos_data <= whos_data + 1;
                else if (whos_data == 1) whos_data <= 0;
            end
            S_deposit: begin
                if(inf.C_out_valid) whos_data <= whos_data + 1;
                else if (whos_data == 1) whos_data <= 0;
            end
            S_return: begin
                if(inf.C_out_valid) whos_data <= whos_data + 1;
                else if (((cnt == 3)||(cnt == 6))&&(whos_data == 2)) whos_data <= 0;
            end
            S_check: begin
                if(inf.id_valid) whos_data <= 0;
            end
        endcase
    end
end
always_comb begin
    inf.C_data_w[31:24] = C_data_w_mine[7:0];
    inf.C_data_w[23:16] = C_data_w_mine[15:8];
    inf.C_data_w[15:8]  = C_data_w_mine[23:16];
    inf.C_data_w[7:0]   = C_data_w_mine[31:24];
    inf.C_data_w[63:56] = C_data_w_mine[39:32];
    inf.C_data_w[55:48] = C_data_w_mine[47:40];
    inf.C_data_w[47:40] = C_data_w_mine[55:48];
    inf.C_data_w[39:32] = C_data_w_mine[63:56];
end
//C_data_w_mine [63:32] = user info & [31:0] = shop info
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) C_data_w_mine <= 0; 
    else begin
        case(current_state)
            S_buy: begin
                if((cnt == 6)&&(whos_data == 0)) C_data_w_mine <={user_userinfo,user_shopinfo};
                else if((cnt == 6)&&(whos_data == 1)) C_data_w_mine <={interactor_userinfo,interactor_shopinfo};
            end
            S_deposit: begin
                if((cnt == 3)&&(temp_errmsg == No_Err)) C_data_w_mine <={money_after_deposit,user_userinfo.shop_history,user_shopinfo};
            end
            S_return: begin
                if((cnt == 6)&&(whos_data == 0)) C_data_w_mine <={user_userinfo,user_shopinfo};
                else if((cnt == 6)&&(whos_data == 1)) C_data_w_mine <={interactor_userinfo,interactor_shopinfo};
            end
        endcase
    end
end

//target exp
always_comb begin
    case(user_shopinfo.level)
	    Gold:		target_exp = 4000;
	    Silver:		target_exp = 2500;
	    Copper:		target_exp = 1000;
        default:    target_exp = 0;
    endcase
end

//total exp
always_comb begin
    case(item)
	    Small: begin
            total_exp = 20 * item_num + user_shopinfo.exp;
        end
        Medium: begin
            total_exp = 40 * item_num + user_shopinfo.exp;
        end
        Large: begin
            total_exp = 60 * item_num + user_shopinfo.exp;
        end
        default: begin
            total_exp = 0;
        end
    endcase
end

always_comb begin
    total_money = interactor_userinfo.money + total_price;
end

always_comb begin
    C_data_r_part[0] = inf.C_data_r[7:0];
    C_data_r_part[1] = inf.C_data_r[15:8];
    C_data_r_part[2] = inf.C_data_r[23:16];
    C_data_r_part[3] = inf.C_data_r[31:24];
    C_data_r_part[4] = inf.C_data_r[39:32];
    C_data_r_part[5] = inf.C_data_r[47:40];
    C_data_r_part[6] = inf.C_data_r[55:48];
    C_data_r_part[7] = inf.C_data_r[63:56];
end

//C_data_r_inv is user_info = [31:0] ,shop_info = [63:32]
always_ff@(posedge clk)begin
    case(current_state)
        S_buy: begin
            if(inf.C_out_valid && (whos_data == 0) && (cnt != 6)) begin 
                user_shopinfo <= {C_data_r_part[0],C_data_r_part[1],C_data_r_part[2],C_data_r_part[3]};
                user_userinfo <= {C_data_r_part[4],C_data_r_part[5],C_data_r_part[6],C_data_r_part[7]};
            end
            else if(inf.C_out_valid && (whos_data == 1) && (cnt != 6)) begin 
                interactor_shopinfo <= {C_data_r_part[0],C_data_r_part[1],C_data_r_part[2],C_data_r_part[3]};
                interactor_userinfo <= {C_data_r_part[4],C_data_r_part[5],C_data_r_part[6],C_data_r_part[7]};
            end
            else if((cnt == 5)&&(temp_errmsg == No_Err)) begin //set data
                case(item) //for shop info
                    Small: begin
                        //user shop
                        user_shopinfo.small_num <= user_shopinfo.small_num + item_num;
                        if(user_shopinfo.level != Platinum) begin
                            if(total_exp >= target_exp) begin //level up
                                case(user_shopinfo.level) 
                                    Copper :    user_shopinfo.level <= Silver;
                                    Silver :    user_shopinfo.level <= Gold;
                                    Gold   :    user_shopinfo.level <= Platinum;
                                endcase
                                user_shopinfo.exp <= 0;
                            end 
                            else begin
                                user_shopinfo.exp <= total_exp;
                            end
                        end
                        //interactor shop
                        interactor_shopinfo.small_num <= interactor_shopinfo.small_num - item_num;
                    end
                    Medium: begin
                        //user shop
                        user_shopinfo.medium_num <= user_shopinfo.medium_num + item_num;
                        if(user_shopinfo.level != Platinum) begin
                            if(total_exp >= target_exp) begin //level up
                                case(user_shopinfo.level) 
                                    Copper :    user_shopinfo.level <= Silver;
                                    Silver :    user_shopinfo.level <= Gold;
                                    Gold   :    user_shopinfo.level <= Platinum;
                                endcase
                                user_shopinfo.exp <= 0;
                            end 
                            else begin
                                user_shopinfo.exp <= total_exp;
                            end
                        end
                        //interactor shop
                        interactor_shopinfo.medium_num <= interactor_shopinfo.medium_num - item_num;
                    end
                    Large: begin
                        //user shop
                        user_shopinfo.large_num <= user_shopinfo.large_num + item_num;
                        if(user_shopinfo.level != Platinum) begin
                            if(total_exp >= target_exp) begin //level up
                                case(user_shopinfo.level) 
                                    Copper :    user_shopinfo.level <= Silver;
                                    Silver :    user_shopinfo.level <= Gold;
                                    Gold   :    user_shopinfo.level <= Platinum;
                                endcase
                                user_shopinfo.exp <= 0;
                            end 
                            else begin
                                user_shopinfo.exp <= total_exp;
                            end
                        end
                        //interactor shop
                        interactor_shopinfo.large_num <= interactor_shopinfo.large_num - item_num;
                    end
                endcase
                //user userinfo
                user_userinfo.money <= user_userinfo.money - cost;
                user_userinfo.shop_history <= {item,item_num,interactor};
                //interactor userinfo
                if(total_money > 65535) interactor_userinfo.money <= 65535;
                else interactor_userinfo.money <= total_money;
                interactor_userinfo.shop_history <= {8'b0,current_user};
            end
        end
        S_check_deposit: begin
            if(inf.C_out_valid && (whos_data == 0)) begin 
                user_shopinfo <= {C_data_r_part[0],C_data_r_part[1],C_data_r_part[2],C_data_r_part[3]};
                user_userinfo <= {C_data_r_part[4],C_data_r_part[5],C_data_r_part[6],C_data_r_part[7]};
            end
        end
        S_check_stock: begin
            if(inf.C_out_valid && (whos_data == 0)) begin 
                interactor_shopinfo <= {C_data_r_part[0],C_data_r_part[1],C_data_r_part[2],C_data_r_part[3]};
                interactor_userinfo <= {C_data_r_part[4],C_data_r_part[5],C_data_r_part[6],C_data_r_part[7]};
            end
        end
        S_deposit: begin
            if(inf.C_out_valid && (whos_data == 0) && (cnt != 2) && (cnt != 4)) begin
                user_shopinfo <= {C_data_r_part[0],C_data_r_part[1],C_data_r_part[2],C_data_r_part[3]};
                user_userinfo <= {C_data_r_part[4],C_data_r_part[5],C_data_r_part[6],C_data_r_part[7]};
            end
            else if((cnt == 3)&&(temp_errmsg == No_Err)) begin
                user_userinfo <= {money_after_deposit,user_userinfo.shop_history};
            end
        end
        S_return: begin
            if(inf.C_out_valid && (whos_data == 0) && (cnt != 6)) begin 
                user_shopinfo <= {C_data_r_part[0],C_data_r_part[1],C_data_r_part[2],C_data_r_part[3]};
                user_userinfo <= {C_data_r_part[4],C_data_r_part[5],C_data_r_part[6],C_data_r_part[7]};
            end
            else if(inf.C_out_valid && (whos_data == 1) && (cnt != 6)) begin 
                interactor_shopinfo <= {C_data_r_part[0],C_data_r_part[1],C_data_r_part[2],C_data_r_part[3]};
                interactor_userinfo <= {C_data_r_part[4],C_data_r_part[5],C_data_r_part[6],C_data_r_part[7]};
            end
            else if((cnt == 5)&&(temp_errmsg == No_Err)) begin //set data
                case(item) //for shop info
                    Small: begin
                        //user shop
                        user_shopinfo.small_num <= user_shopinfo.small_num - item_num;
                        //interactor shop
                        interactor_shopinfo.small_num <= interactor_shopinfo.small_num + item_num;
                    end
                    Medium: begin
                        //user shop
                        user_shopinfo.medium_num <= user_shopinfo.medium_num - item_num;
                        //interactor shop
                        interactor_shopinfo.medium_num <= interactor_shopinfo.medium_num + item_num;
                    end
                    Large: begin
                        //user shop
                        user_shopinfo.large_num <= user_shopinfo.large_num - item_num;
                        //interactor shop
                        interactor_shopinfo.large_num <= interactor_shopinfo.large_num + item_num;
                    end
                endcase
                //user userinfo
                user_userinfo.money <= user_userinfo.money + total_price;
                //interactor userinfo
                interactor_userinfo.money <= interactor_userinfo.money - total_price;
            end
        end
    endcase
end

//fee
always_comb begin
    case(user_shopinfo.level)
        Platinum:	fee = 10;
	    Gold:		fee = 30;
	    Silver:		fee = 50;
	    Copper:		fee = 70;
        default:    fee = 0;
    endcase
end

//cost & total_num & seller_INV
always_comb begin
    case(item)
        Small: begin
            total_price = item_num * 100;
            cost = total_price + fee;
            total_num = user_shopinfo.small_num + item_num;
            seller_INV = interactor_shopinfo.small_num;
        end
        Medium: begin
            total_price = item_num * 200;
            cost = total_price + fee;
            total_num = user_shopinfo.medium_num + item_num;
            seller_INV = interactor_shopinfo.medium_num;
        end
        Large: begin
            total_price = item_num * 300;
            cost = total_price + fee;
            total_num = user_shopinfo.large_num + item_num;
            seller_INV = interactor_shopinfo.large_num;
        end
        default: begin
            total_price = 0;
            cost = 0;
            total_num = 0;
            seller_INV = 0;
        end
    endcase
end

//money after deposit
always_comb begin
    money_after_deposit = user_userinfo.money + deposit_money;
end

//temp_errmsg
always_ff@(posedge clk)begin
    case(current_state)
        S_buy: begin
            if(cnt == 4) begin
                if(total_num > 63) temp_errmsg <= INV_Full;
                else if(seller_INV < item_num) temp_errmsg <= INV_Not_Enough;
                else if(user_userinfo.money < cost) temp_errmsg <= Out_of_money;
                else temp_errmsg <= No_Err;
            end
        end
        S_check_deposit: begin
            temp_errmsg <= No_Err;
        end
        S_check_stock: begin
            temp_errmsg <= No_Err;
        end
        S_deposit: begin
            if(cnt == 2) begin
                if(money_after_deposit > 65535) temp_errmsg <= Wallet_is_Full;
                else temp_errmsg <= No_Err;
            end
        end
        S_return: begin
            if(cnt == 4) begin
                if(!return_valid[current_user]) temp_errmsg <= Wrong_act; //buyer do other operation
                else if(!be_returned_valid[user_userinfo.shop_history.seller_ID]) temp_errmsg <= Wrong_act; //B do other operation
                else if(interactor_userinfo.shop_history.seller_ID != current_user) temp_errmsg <= Wrong_act; //both OK but not recent buyer
                else if(user_userinfo.shop_history.seller_ID != interactor) temp_errmsg <= Wrong_ID;
                else if(user_userinfo.shop_history.item_num != item_num) temp_errmsg <= Wrong_Num;
                else if(user_userinfo.shop_history.item_ID != item) temp_errmsg <= Wrong_Item;
                else temp_errmsg <= No_Err;
            end 
        end
    endcase
end

//Out_valid & complete
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) begin
        inf.out_valid <= 1'b0;
        inf.complete <= 1'b0;
        inf.out_info <= 32'b0;
    end
    else begin
        case(current_state)
            S_idle: begin
                inf.out_valid <= 1'b0;
                inf.complete <= 1'b0;
                inf.out_info <= 32'b0;
            end
            S_buy: begin
                if((cnt == 5)&&(temp_errmsg != No_Err)) begin //error
                    inf.out_valid <= 1'b1;
                    inf.complete <= 1'b0;
                    inf.out_info <= 32'b0;
                end
                else if((cnt == 6)&&(whos_data == 2)) begin //no error
                    inf.out_valid <= 1'b1;
                    inf.complete <= 1'b1;
                    inf.out_info <= user_userinfo;
                end
            end
            S_check_deposit: begin
                if(whos_data == 1) begin
                    inf.out_valid <= 1'b1;
                    inf.complete <= 1'b1;
                    inf.out_info <= {16'b0,user_userinfo.money};
                end
            end
            S_check_stock: begin
                if(whos_data == 1) begin
                    inf.out_valid <= 1'b1;
                    inf.complete <= 1'b1;
                    inf.out_info <= {14'b0,interactor_shopinfo.large_num,interactor_shopinfo.medium_num,interactor_shopinfo.small_num};
                end
            end
            S_deposit: begin
                if((cnt == 3)&&(temp_errmsg != No_Err)) begin //error
                    inf.out_valid <= 1'b1;
                    inf.complete <= 1'b0;
                    inf.out_info <= 32'b0;
                end
                else if((cnt == 4)&&(whos_data == 1)) begin //no error
                    inf.out_valid <= 1'b1;
                    inf.complete <= 1'b1;
                    inf.out_info <= {16'b0,user_userinfo.money};
                end
            end
            S_return: begin
                if((cnt == 5)&&(temp_errmsg != No_Err)) begin //error
                    inf.out_valid <= 1'b1;
                    inf.complete <= 1'b0;
                    inf.out_info <= 32'b0;
                end
                else if((cnt == 6)&&(whos_data == 2)) begin //no error
                    inf.out_valid <= 1'b1;
                    inf.complete <= 1'b1;
                    inf.out_info <= {14'b0,user_shopinfo.large_num,user_shopinfo.medium_num,user_shopinfo.small_num};
                end
            end
        endcase
    end
end

//errmsg
always_comb begin
    if(inf.out_valid) inf.err_msg = temp_errmsg;
    else inf.err_msg = No_Err;
end
endmodule