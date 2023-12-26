module SUBWAY(
    //Input Port
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    //Output Port
    out_valid,
    out
);


input clk, rst_n;
input in_valid;
input [1:0] init;
input [1:0] in0, in1, in2, in3; 
output reg       out_valid;
output reg [1:0] out;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE  = 2'b00;
parameter IN1   = 2'b01;
parameter IN2   = 2'b10;	
parameter OUT   = 2'b11;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [1:0]   curr_state, next_state;
reg [5:0]   counter, next_counter;
reg [2:0]   id, next_id;

reg [1:0]   move_info [55:0];
reg [1:0]   in_move_info_0;

reg [3:0]   map_info  [5:0];
reg [3:0]   low_obs_info  [5:0];
reg [3:0]   in_map_info_0;
reg [3:0]   in_map_info_1;
reg [3:0]   in_map_info_2;
reg [3:0]   in_map_info_3;
reg [3:0]   in_map_info_4;
reg [3:0]   in_map_info_5;
reg [3:0]   pos, next_pos;
reg [3:0]   is_obs;
reg [3:0]   train_pos;
reg         is_obs_1, is_obs_2; // only change when id == 6
reg         change_flag;
reg [3:0]   filters[3:0];
reg [1:0]   i0, i1, i2, i3; 

//==============================================//
//                  design                      //
//==============================================//
// -----
//  FSM
// -----
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  curr_state <= IDLE;
    else        curr_state <= next_state;
end

always @(*) begin
    next_state = curr_state;
    case(curr_state)
        IDLE:   if(in_valid)        next_state = IN1;
        IN1:    if(counter >= 6)    next_state = IN2;
        IN2:    if(!in_valid)       next_state = OUT;
        OUT:    if(counter >= 62)   next_state = IDLE;
    endcase
end

// ---------
//  counter
// ---------
always @(posedge clk) begin
    counter <= next_counter;
end

always @(*) begin
    next_counter = counter + 1;
    case(curr_state)
        IDLE:   if(in_valid)        next_counter = 0;
        IN2:    if(!in_valid)       next_counter = 0;
    endcase
end
always @(*) begin 
    id = counter[2:0];
    next_id = next_counter[2:0];
end

// -----------
// input_block
// -----------
always @(posedge clk) begin
    if(next_state == OUT || next_state == IDLE) begin
        i0 <= 0;
        i1 <= 0;
        i2 <= 0;
        i3 <= 0;
    end
    else begin
        i0 <= in0;
        i1 <= in1;
        i2 <= in2;
        i3 <= in3;
    end
end

always @(posedge clk) begin
    is_obs <= {|i3, |i2, |i1, |i0};
    if(id == 6) begin
        is_obs_1 <= (i1 == 0) ? 0 : 1;
        is_obs_2 <= (i2 == 0) ? 0 : 1;
    end
    else begin
        is_obs_1 <= is_obs_1;
        is_obs_2 <= is_obs_2;
    end
end

// -----------
always @(posedge clk) begin
    low_obs_info[0] <= {i3[0], i2[0], i1[0], i0[0]};
    low_obs_info[1] <= low_obs_info[0];
    low_obs_info[2] <= low_obs_info[1];
    low_obs_info[3] <= low_obs_info[2];
    low_obs_info[4] <= low_obs_info[3];
    low_obs_info[5] <= low_obs_info[4];
end

// -----------
always @(posedge clk) begin
    map_info[0] <= in_map_info_0;
    map_info[1] <= in_map_info_1;
    map_info[2] <= in_map_info_2;
    map_info[3] <= in_map_info_3;
    map_info[4] <= in_map_info_4;
    map_info[5] <= in_map_info_5;
end

always @(*) begin
    if(curr_state == IDLE) 
        in_map_info_0 = 1 << init;
    else begin
        if(i0 == 'b00)         in_map_info_0[0] = map_info[0][0] | map_info[0][1];
        else if(i0 == 'b11)    in_map_info_0[0] = 0;
        else                   in_map_info_0[0] = map_info[0][0];
        if(i1 == 'b00)         in_map_info_0[1] = map_info[0][0] | map_info[0][1] | map_info[0][2];
        else if(i1 == 'b11)    in_map_info_0[1] = 0;
        else                   in_map_info_0[1] = map_info[0][1];
        if(i2 == 'b00)         in_map_info_0[2] = map_info[0][1] | map_info[0][2] | map_info[0][3];
        else if(i2 == 'b11)    in_map_info_0[2] = 0;
        else                   in_map_info_0[2] = map_info[0][2];
        if(i3 == 'b00)         in_map_info_0[3] = map_info[0][2] | map_info[0][3];
        else if(i3 == 'b11)    in_map_info_0[3] = 0;
        else                   in_map_info_0[3] = map_info[0][3];
    end
end

always @(*) begin
    in_map_info_1 = map_info[0] & (~is_obs);

    change_flag = ~(i3[0] & i2[0] & i1[0] & i0[0]);
    in_map_info_2 = (id == 2 && change_flag) ? {~i3[0], ~i2[0], ~i1[0], ~i0[0]} : map_info[1];
    train_pos = in_map_info_2;

    filters[0] = (train_pos[0]) ? 4'b0011 : 4'b0000;
    filters[1] = (train_pos[1]) ? 4'b0111 : 4'b0000;
    filters[2] = (train_pos[2]) ? 4'b1110 : 4'b0000;
    filters[3] = (train_pos[3]) ? 4'b1100 : 4'b0000;
    in_map_info_3 = (id == 2) ? (map_info[2] & (filters[0] | filters[1] | filters[2] | filters[3])) : map_info[2];

    if(id == 2) begin
        if(train_pos == 4'b0001)                    in_map_info_4 = {1'b0, map_info[3][2:0]};
        else if(train_pos == 4'b1000)               in_map_info_4 = {map_info[3][3:1], 1'b0};
        else                                        in_map_info_4 = map_info[3];
    end else                                        in_map_info_4 = map_info[3];

    if(id == 2) begin
        if(train_pos == 4'b0001 && is_obs_2)        in_map_info_5 = {1'b0, map_info[4][2:0]};
        else if(train_pos == 4'b1000 && is_obs_1)   in_map_info_5 = {map_info[4][3:1], 1'b0};
        else                                        in_map_info_5 = map_info[4];
    end else                                        in_map_info_5 = map_info[4];
end

// -----------
always @(posedge clk) begin
    pos <= next_pos;
    move_info[0] <= in_move_info_0;
end

reg [3:0] move_forward;
reg [3:0] move_right;
reg [3:0] move_left;
reg [3:0] move_jump;

always @(*) begin
    move_forward  = map_info[5] & pos;
    move_right    = map_info[5] & (pos << 1);
    move_left     = map_info[5] & (pos >> 1);
    move_jump     = low_obs_info[5] & pos;
end

always @(*) begin
    next_pos = pos;
    in_move_info_0 = 'bx;
    case(curr_state)
        IDLE:   next_pos = 1 << init;
        IN1:    next_pos = pos;
        default: begin
            if(move_forward > 0) begin
                next_pos = pos;
                in_move_info_0 = 0; // forward
            end
            else if(move_right > 0) begin
                next_pos = pos << 1;
                in_move_info_0 = 1; // right
            end
            else if(move_left > 0) begin
                next_pos = pos >> 1;
                in_move_info_0 = 2; // left
            end
            else begin
                next_pos = pos;
                if(move_jump > 0)   in_move_info_0 = 3; // jump
                else                in_move_info_0 = 0; // forward
            end
        end
    endcase
end

// ---------------
// shift registers
// ---------------
genvar i;
generate
    for(i = 1; i <= 55; i = i+1) begin : shift_reg
        always @(posedge clk) begin
            move_info[i] <= move_info[i-1];
        end
    end
endgenerate

// ------------
// output_block
// ------------
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 0;
    end
    else begin
        if (next_state == OUT) begin
            out_valid <= 1;
            out <= move_info[55];
        end
        else begin
            out_valid <= 0;
            out <= 0;
        end
    end
end

endmodule