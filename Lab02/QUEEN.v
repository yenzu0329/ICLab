module QUEEN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    col,
    row,

    in_valid_num,
    in_num,

    out_valid,
    out,

    );

input               clk, rst_n, in_valid,in_valid_num;
input       [3:0]   col,row;
input       [2:0]   in_num;

output reg          out_valid;
output reg  [3:0]   out;

//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter IDLE  = 3'b000;
parameter IN    = 3'b001;
parameter PUSH  = 3'b010;
parameter POP   = 3'b011;	
parameter OUT   = 3'b100;

//==============================================//
//                 reg declaration              //
//==============================================//
reg [2:0]   current_state;
reg [3:0]   counter;
reg [3:0]   stack      [11:0];

reg [2:0]   next_state;
reg [3:0]   next_counter;
reg [3:0]   next_stack [11:0];

// input
reg [3:0]   in_col;
reg [3:0]   in_row;

// stack control signal
reg         pop;
reg         full;

// x
reg [3:0]   x_num;
reg [11:0]  x_filter;
reg [11:0]  x_postfix_or;
reg [11:0]  x_next;
reg [3:0]   x_next_num;
reg [11:0]  x_prev;
reg [3:0]   x_prev_num;
reg [3:0]   x_footprint;
reg [3:0]   next_x_footprint;
reg [4:0]   row_plus_col;
reg [4:0]   row_min_col;

// y
reg [11:0]  y;
reg [3:0]   y_num;
reg [11:0]  y_footprint;
reg [11:0]  y_filter;
reg [11:0]  x_plus_y_filter;
reg [11:0]  x_min_y_filter;
reg [22:0]  x_plus_y;
reg [22:0]  x_min_y;

reg [11:0]  next_y_footprint;
reg [11:0]  next_y_filter;
reg [22:0]  next_x_plus_y;
reg [22:0]  next_x_min_y;

//==============================================//
//            FSM State Declaration             //
//==============================================//
//current_state
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  current_state <= IDLE;
    else        current_state <= next_state;
end

//next_state
always @(*) begin
    next_state = current_state;
    case(current_state)
        IDLE:
            if(in_valid)        next_state = IN;
        IN:     
            if(!in_valid)       next_state = PUSH;
        PUSH:   
            if (full)           next_state = OUT;
            else if(pop)        next_state = POP;
        POP:    
            if(!pop)            next_state = PUSH;
        OUT: 
            if(counter >= 11)   next_state = IDLE;
    endcase
end

//==============================================//
//                  Input Block                 //
//==============================================//
always @(posedge clk) begin
    in_col <= col;
    in_row <= row;
end

always @(posedge clk) begin
    if(next_state == IDLE)       x_filter <= 0;
    else if(next_state == IN)    x_filter <= x_filter | (1 << col);
    else                         x_filter <= x_filter;
end

always @(posedge clk) begin
    y_filter <= next_y_filter;
    x_plus_y <= next_x_plus_y;
    x_min_y  <= next_x_min_y;
end

always @(posedge clk) begin
    if(~next_state[1]) begin // next_state == IDLE, IN, OUT
        y_footprint  <= 0;
        x_footprint  <= 0;
    end
    else begin
        y_footprint  <= next_y_footprint;
        x_footprint  <= next_x_footprint;
    end
end

reg [3:0]  sel_col, sel_row;
reg [11:0] sel_col_decoder;

always @(*) begin
    // IN: 2'b01, PUSH: 2'b10
    sel_row = (current_state[1]) ? y_num : in_row;
    sel_col = (current_state[1]) ? x_num : in_col;
    row_plus_col = sel_row + sel_col;
    row_min_col  = sel_row - sel_col + 11;
end

always @(*) begin
    // IN: 2'b01, PUSH: 2'b10
    sel_col_decoder = 12'b0;
    case(sel_row)
        0 : sel_col_decoder[0]  = 1;
        1 : sel_col_decoder[1]  = 1;
        2 : sel_col_decoder[2]  = 1;
        3 : sel_col_decoder[3]  = 1;
        4 : sel_col_decoder[4]  = 1;
        5 : sel_col_decoder[5]  = 1;
        6 : sel_col_decoder[6]  = 1;
        7 : sel_col_decoder[7]  = 1;
        8 : sel_col_decoder[8]  = 1;
        9 : sel_col_decoder[9]  = 1;
        10: sel_col_decoder[10] = 1;
        11: sel_col_decoder[11] = 1;
    endcase
end

always @(*) begin
    next_y_filter = y_filter;
    next_x_plus_y = x_plus_y;
    next_x_min_y  = x_min_y;
    case(current_state[1:0])
        IDLE: begin
            next_y_filter = 0;
            next_x_plus_y = 0;
            next_x_min_y  = 0;
        end
        IN: begin
            next_y_filter = y_filter | sel_col_decoder;
            next_x_plus_y = x_plus_y | (1 << row_plus_col);
            next_x_min_y  = x_min_y  | (1 << row_min_col);
        end
        PUSH: begin
            if (!pop) begin
                next_y_filter = y_filter | sel_col_decoder;
                next_x_plus_y = x_plus_y | (1 << row_plus_col);
                next_x_min_y  = x_min_y  | (1 << row_min_col);
            end
        end
        POP: begin
            next_y_filter = y_filter & ~sel_col_decoder;
            next_x_plus_y = x_plus_y & ~(1 << row_plus_col);
            next_x_min_y  = x_min_y  & ~(1 << row_min_col);
        end
    endcase
end

always @(*) begin
    next_x_footprint = x_footprint;
    next_y_footprint = y_footprint;
    
    if(current_state == POP && !pop) begin
        next_x_footprint = x_num;
        next_y_footprint = ~(12'hFFF << (stack[x_num]+1));
    end
end

always @(*) begin
    x_plus_y_filter = 12'dx;
    case(x_num)
        0 : x_plus_y_filter = x_plus_y[11:0];
        1 : x_plus_y_filter = x_plus_y[12:1];
        2 : x_plus_y_filter = x_plus_y[13:2];
        3 : x_plus_y_filter = x_plus_y[14:3];
        4 : x_plus_y_filter = x_plus_y[15:4];
        5 : x_plus_y_filter = x_plus_y[16:5];
        6 : x_plus_y_filter = x_plus_y[17:6];
        7 : x_plus_y_filter = x_plus_y[18:7];
        8 : x_plus_y_filter = x_plus_y[19:8];
        9 : x_plus_y_filter = x_plus_y[20:9];
        10: x_plus_y_filter = x_plus_y[21:10];
        11: x_plus_y_filter = x_plus_y[22:11];
    endcase
end
always @(*) begin
    x_min_y_filter = 12'dx;
    case(x_num)
        0 : x_min_y_filter = x_min_y[22:11];
        1 : x_min_y_filter = x_min_y[21:10];
        2 : x_min_y_filter = x_min_y[20:9];
        3 : x_min_y_filter = x_min_y[19:8];
        4 : x_min_y_filter = x_min_y[18:7];
        5 : x_min_y_filter = x_min_y[17:6];
        6 : x_min_y_filter = x_min_y[16:5];
        7 : x_min_y_filter = x_min_y[15:4];
        8 : x_min_y_filter = x_min_y[14:3];
        9 : x_min_y_filter = x_min_y[13:2];
        10: x_min_y_filter = x_min_y[12:1];
        11: x_min_y_filter = x_min_y[11:0];
    endcase
end

always @(*) begin 
    if(x_footprint == x_num)    y = y_filter | x_plus_y_filter | x_min_y_filter | y_footprint;
    else                        y = y_filter | x_plus_y_filter | x_min_y_filter;
    y_num = stack[x_num];
    if(current_state == PUSH) begin
        if     (y[0] == 0)    y_num = 0;
        else if(y[1] == 0)    y_num = 1;
        else if(y[2] == 0)    y_num = 2;
        else if(y[3] == 0)    y_num = 3;
        else if(y[4] == 0)    y_num = 4;
        else if(y[5] == 0)    y_num = 5;
        else if(y[6] == 0)    y_num = 6;
        else if(y[7] == 0)    y_num = 7;
        else if(y[8] == 0)    y_num = 8;
        else if(y[9] == 0)    y_num = 9;
        else if(y[10] == 0)   y_num = 10;
        else if(y[11] == 0)   y_num = 11;
    end
end

//==============================================//
//                  Output Block                //
//==============================================//
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 0;
    end
    else begin
        if (next_state == OUT) begin
            out_valid <= 1;
            out <= stack[next_counter];
        end
        else begin
            out_valid <= 0;
            out <= 0;
        end
    end
end

//==============================================//
//                     Stack                    //
//==============================================//
always @(*) begin
    full = (x_num > 11) ? 1 : 0;
    pop = &y;
end

always @(posedge clk) begin
    stack[0]  <= next_stack[0];
    stack[1]  <= next_stack[1];
    stack[2]  <= next_stack[2];
    stack[3]  <= next_stack[3];
    stack[4]  <= next_stack[4];
    stack[5]  <= next_stack[5];
    stack[6]  <= next_stack[6];
    stack[7]  <= next_stack[7];
    stack[8]  <= next_stack[8];
    stack[9]  <= next_stack[9];
    stack[10] <= next_stack[10];
    stack[11] <= next_stack[11];
end
always @(*) begin
    next_stack[0]  = stack[0];
    next_stack[1]  = stack[1];
    next_stack[2]  = stack[2];
    next_stack[3]  = stack[3];
    next_stack[4]  = stack[4];
    next_stack[5]  = stack[5];
    next_stack[6]  = stack[6];
    next_stack[7]  = stack[7];
    next_stack[8]  = stack[8];
    next_stack[9]  = stack[9];
    next_stack[10] = stack[10];
    next_stack[11] = stack[11];
    case(current_state)
        IDLE: begin
            next_stack[0]  = 4'bx;
            next_stack[1]  = 4'bx;
            next_stack[2]  = 4'bx;
            next_stack[3]  = 4'bx;
            next_stack[4]  = 4'bx;
            next_stack[5]  = 4'bx;
            next_stack[6]  = 4'bx;
            next_stack[7]  = 4'bx;
            next_stack[8]  = 4'bx;
            next_stack[9]  = 4'bx;
            next_stack[10] = 4'bx;
            next_stack[11] = 4'bx;
        end
        IN:         next_stack[in_col] = in_row;
        PUSH:       next_stack[x_num] = y_num;
    endcase
end

//==============================================//
//                    Counter                   //
//==============================================//
// counter
always @(posedge clk) begin
    counter <= next_counter;
end

always @(*) begin
    next_counter = counter + 1;
    case(current_state)
        IDLE:
            if(in_valid)    next_counter = x_next_num;
        IN:
            if(!in_valid)   next_counter = x_next_num;
        PUSH:
            if(full)        next_counter = 0;
            else if(pop)    next_counter = x_prev_num;
            else            next_counter = x_next_num;
        POP:    
            if(!pop)        next_counter = counter;
            else            next_counter = x_prev_num;
    endcase
end

always @(*) begin
    x_num = counter;
end

always @(*) begin
    if(~current_state[1])   x_postfix_or = 12'b000000000000;
    else                    x_postfix_or = ~(12'hFFF << (x_num+1));
end

always @(*) begin
    x_next = x_postfix_or | x_filter;
    x_prev = (~(x_postfix_or >> 1)) | x_filter;
    if     (x_next[0] == 0)    x_next_num = 0;
    else if(x_next[1] == 0)    x_next_num = 1;
    else if(x_next[2] == 0)    x_next_num = 2;
    else if(x_next[3] == 0)    x_next_num = 3;
    else if(x_next[4] == 0)    x_next_num = 4;
    else if(x_next[5] == 0)    x_next_num = 5;
    else if(x_next[6] == 0)    x_next_num = 6;
    else if(x_next[7] == 0)    x_next_num = 7;
    else if(x_next[8] == 0)    x_next_num = 8;
    else if(x_next[9] == 0)    x_next_num = 9;
    else if(x_next[10] == 0)   x_next_num = 10;
    else if(x_next[11] == 0)   x_next_num = 11;
    else                       x_next_num = 12;

    if     (x_prev[11] == 0)   x_prev_num = 11;
    else if(x_prev[10] == 0)   x_prev_num = 10;
    else if(x_prev[9] == 0)    x_prev_num = 9;
    else if(x_prev[8] == 0)    x_prev_num = 8;
    else if(x_prev[7] == 0)    x_prev_num = 7;
    else if(x_prev[6] == 0)    x_prev_num = 6;
    else if(x_prev[5] == 0)    x_prev_num = 5;
    else if(x_prev[4] == 0)    x_prev_num = 4;
    else if(x_prev[3] == 0)    x_prev_num = 3;
    else if(x_prev[2] == 0)    x_prev_num = 2;
    else if(x_prev[1] == 0)    x_prev_num = 1;
    else                       x_prev_num = 0;
end
endmodule 