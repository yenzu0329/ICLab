module MMT(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [7:0]  matrix;
input [1:0]  matrix_size,mode;
input [4:0]  matrix_idx;

output reg       	     out_valid;
output reg signed [49:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter IDLE    = 0;
parameter IN1     = 1;
parameter IN2     = 2;
parameter COMPUTE = 3;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [1:0]  state, next_state;
wire update_block_flag;
wire reset_block_flag;
wire reset_col_flag;
wire reset_row_flag;
wire reset_double_col_flag;

// counter
reg [1:0]  counter;
reg [2:0]  block;
reg [2:0]  col;
reg [2:0]  row;
reg [2:0]  double_col;
reg [4:0]  mat_counter;

// input info
reg [2:0]  mat_max_size;
reg [4:0]  mat_a_idx;
reg [4:0]  mat_b_idx;
reg [4:0]  mat_c_idx;
reg [1:0]  mat_mode;

// registers
reg signed [7:0]  in_mat;
reg signed [7:0]  a_vec [3:0];
reg signed [7:0]  b_vec [3:0];
reg signed [7:0]  c_vec [3:0];
reg signed [7:0]  stanby_vec [3:0];
reg signed [7:0]  next_b_vec [3:0];
reg signed [7:0]  next_c_vec [3:0];
reg signed [7:0]  next_stanby_vec [3:0];

reg signed [7:0]  a0, a1;
reg signed [7:0]  b0, b1;
reg signed [15:0] ab0, ab1;
reg signed [7:0] c;
reg signed [16:0] sum_ab, next_sum_ab;
reg signed [22:0] abc, next_abc;
reg signed [33:0] ans, next_ans;
reg state_d1, state_d2;
reg finish, finish_d1, finish_d2;

// SRAM
wire [1:0]  wen_control;
reg  [3:0]  wen;
reg  [10:0] addr;
reg  signed [7:0]  data_in;
wire signed [7:0]  data_out [3:0];

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
// =============
// FSM & counter
// =============
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  state <= IDLE;
    else 		state <= next_state;
end

always @(*) begin
    next_state = state;
	case(state)
		IDLE    : if(in_valid)       next_state = IN1;
                  else if(in_valid2) next_state = IN2;
        IN1     : if(!in_valid)      next_state = IDLE;
        IN2     : if(!in_valid2)     next_state = COMPUTE;
        COMPUTE : if(finish_d2)      next_state = IDLE;
    endcase
end

// ------ counter ------ 
always @(posedge clk) begin
    if(state == IDLE && ! in_valid2)  counter <= 0;
    else                   counter <= counter + 1;
end

assign update_block_flag = (state == IN1) ? (counter[0]) : (&counter);
assign reset_block_flag  = ((block == mat_max_size) && update_block_flag) || state == IDLE;
assign reset_col_flag    = ((col == mat_max_size) && reset_block_flag) || state == IDLE;
assign reset_row_flag    = ((row == mat_max_size) && reset_col_flag) || state == IDLE;
assign reset_double_col_flag = ((double_col == mat_max_size) && col[0] && reset_block_flag) || state == IDLE;

// ------ block ------ 
always @(posedge clk) begin
    if(reset_block_flag)       block <= 0;
    else if(update_block_flag) block <= block + 1;
    else                       block <= block;
end

// ------ col ------ 
always @(posedge clk) begin
    if(reset_col_flag)         col <= 0;
    else if(reset_block_flag)  col <= col + 1;
    else                       col <= col;
end

// ------ row ------ 
always @(posedge clk) begin
    if(reset_row_flag)         row <= 0;
    else if(reset_col_flag)    row <= row + 1;
    else                       row <= row;
end

// ------ double_col ------ 
always @(posedge clk) begin
    if(reset_double_col_flag)              double_col <= 0;
    else if(col[0] && reset_block_flag)    double_col <= double_col + 1;
    else                                   double_col <= double_col;
end

// ------ mat_counter ------
always @(posedge clk) begin
    if(state == IDLE)                      mat_counter <= 0;
    else if(mat_max_size == 0 && counter == 3) mat_counter <= mat_counter + 1;
    else if(reset_double_col_flag)         mat_counter <= mat_counter + 1;
    else                                   mat_counter <= mat_counter;
end

// ======
// output
// ======
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_value <= 0;
    end
    else begin
        if(finish_d2) begin
            out_valid <= 1;
            out_value <= ans;
        end
        else begin
            out_valid <= 0;
            out_value <= 0;
        end
    end
end

// ======
// input1
// ======
always @(posedge clk) begin
    if(state == IDLE && next_state == IN1) begin
        case(matrix_size)
            0 : mat_max_size <= 0;  // 2x2
            1 : mat_max_size <= 1;  // 4x4
            2 : mat_max_size <= 3;  // 8x8
            3 : mat_max_size <= 7;  // 16x16
        endcase
    end 
    else
        mat_max_size <= mat_max_size;
end

always @(posedge clk) begin
    in_mat <= matrix;
end

assign wen_control = (mat_max_size == 0) ? (counter) : ({col[0], counter[0]});
always @(*) begin
    data_in = in_mat;
    wen = 4'b1111;
    if(in_valid || state == IN1) begin
        case(wen_control)
            'b00: wen = 4'b1110;
            'b01: wen = 4'b1101;
            'b10: wen = 4'b1011;
            'b11: wen = 4'b0111;
        endcase
    end
end

always @(*) begin
    if(in_valid || state == IN1) begin
        addr = {mat_counter, double_col, block};
    end
    else begin
        if(counter == 1)         addr = {mat_a_idx, row, col};
        else if(counter == 2)    addr = {mat_b_idx, col, block};
        else                     addr = {mat_c_idx, block, row};
        
        if(mat_mode == counter)  addr = {addr[10:6], addr[2:0], addr[5:3]};
    end
end

// ======
// input2
// ======
always @(posedge clk) begin
    if(in_valid2 && counter == 0)  mat_a_idx <= matrix_idx;
    else                           mat_a_idx <= mat_a_idx;
end
always @(posedge clk) begin
    if(in_valid2 && counter == 0)  mat_mode <= mode;
    else                           mat_mode <= mat_mode;
end
always @(posedge clk) begin
    if(in_valid2 && counter == 1)  mat_b_idx <= matrix_idx;
    else                           mat_b_idx <= mat_b_idx;
end
always @(posedge clk) begin
    if(in_valid2 && counter == 2)  mat_c_idx <= matrix_idx;
    else                           mat_c_idx <= mat_c_idx;
end

// =========
// read SRAM
// =========
always @(*) begin
    next_stanby_vec[0] = stanby_vec[0];
    next_stanby_vec[1] = stanby_vec[1];
    next_stanby_vec[2] = stanby_vec[2];
    next_stanby_vec[3] = stanby_vec[3];
    if(counter == 2) begin
        if(mat_mode == 1) begin                  // traspose A
            next_stanby_vec[0] = data_out[0];
            next_stanby_vec[1] = data_out[2];
            next_stanby_vec[2] = data_out[1];
            next_stanby_vec[3] = data_out[3];
        end
        else begin
            next_stanby_vec[0] = data_out[0];
            next_stanby_vec[1] = data_out[1];
            next_stanby_vec[2] = data_out[2];
            next_stanby_vec[3] = data_out[3];
        end
    end
end

always @(*) begin
    next_b_vec[0] = b_vec[0];
    next_b_vec[1] = b_vec[1];
    next_b_vec[2] = b_vec[2];
    next_b_vec[3] = b_vec[3];
    if(counter == 3) begin
        if(mat_mode == 2) begin                  // traspose B
            next_b_vec[0] = data_out[0];
            next_b_vec[1] = data_out[2];
            next_b_vec[2] = data_out[1];
            next_b_vec[3] = data_out[3];
        end
        else begin
            next_b_vec[0] = data_out[0];
            next_b_vec[1] = data_out[1];
            next_b_vec[2] = data_out[2];
            next_b_vec[3] = data_out[3];
        end
    end
end

always @(*) begin
    next_c_vec[0] = c_vec[0];
    next_c_vec[1] = c_vec[1];
    next_c_vec[2] = c_vec[2];
    next_c_vec[3] = c_vec[3];
    if(counter == 0) begin
        if(mat_mode == 3) begin                  // traspose C
            next_c_vec[0] = data_out[0];
            next_c_vec[1] = data_out[2];
            next_c_vec[2] = data_out[1];
            next_c_vec[3] = data_out[3];
        end
        else begin
            next_c_vec[0] = data_out[0];
            next_c_vec[1] = data_out[1];
            next_c_vec[2] = data_out[2];
            next_c_vec[3] = data_out[3];
        end
    end
end

always @(posedge clk) begin
    stanby_vec[0] <= next_stanby_vec[0];
    stanby_vec[1] <= next_stanby_vec[1];
    stanby_vec[2] <= next_stanby_vec[2];
    stanby_vec[3] <= next_stanby_vec[3];
end

always @(posedge clk) begin
    a_vec[0] <= stanby_vec[0];
    a_vec[1] <= stanby_vec[1];
    a_vec[2] <= stanby_vec[2];
    a_vec[3] <= stanby_vec[3];
end

always @(posedge clk) begin
    b_vec[0] <= next_b_vec[0];
    b_vec[1] <= next_b_vec[1];
    b_vec[2] <= next_b_vec[2];
    b_vec[3] <= next_b_vec[3];
end

always @(posedge clk) begin
    c_vec[0] <= next_c_vec[0];
    c_vec[1] <= next_c_vec[1];
    c_vec[2] <= next_c_vec[2];
    c_vec[3] <= next_c_vec[3];
end

// =======
// compute
// =======
always @(*) begin
    if(counter[0] == 0)   a0 = a_vec[0];
    else                  a0 = a_vec[2];
end
always @(*) begin
    if(counter[0] == 0)   a1 = a_vec[1];
    else                  a1 = a_vec[3];
end

always @(*) begin
    if(counter[1] == 0)   b0 = b_vec[0];
    else                  b0 = b_vec[1];
end
always @(*) begin
    if(counter[1] == 0)   b1 = b_vec[2];
    else                  b1 = b_vec[3];
end

always @(*) begin
    case(counter)
        0: c = c_vec[3];
        1: c = c_vec[0];
        2: c = c_vec[1];
        3: c = c_vec[2];
    endcase
end

// layer 1
always @(*) begin
    ab0 = a0 * b0;
    ab1 = a1 * b1;
    next_sum_ab = ab0 + ab1;
end

always @(posedge clk) begin
    sum_ab <= next_sum_ab;
end

// layer 2
always @(*) begin
    next_abc = sum_ab * c;
end

always @(posedge clk) begin
    abc <= next_abc;
end

// layer 3
always @(*) begin
    next_ans = ans + abc;
end

always @(posedge clk) begin
    state_d1 <= state[0];
    state_d2 <= state_d1;
end

always @(posedge clk) begin
    if(state_d2)    ans <= next_ans;
    else            ans <= 0;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        finish <= 0;
        finish_d1 <= 0;
        finish_d2 <= 0;
    end
    else begin
        finish <= (state == COMPUTE) && (counter == 3) && (block == 0) && (col == 0) && (row == 0);
        finish_d1 <= finish;
        finish_d2 <= finish_d1;
    end
end

// =======
// SRAM IP
// =======
MEM_8_16 mem0 (.A(addr), .D(data_in), .Q(data_out[0]), .CLK(clk), .CEN(1'b0), .WEN(wen[0]), .OEN(1'b0));
MEM_8_16 mem1 (.A(addr), .D(data_in), .Q(data_out[1]), .CLK(clk), .CEN(1'b0), .WEN(wen[1]), .OEN(1'b0));
MEM_8_16 mem2 (.A(addr), .D(data_in), .Q(data_out[2]), .CLK(clk), .CEN(1'b0), .WEN(wen[2]), .OEN(1'b0));
MEM_8_16 mem3 (.A(addr), .D(data_in), .Q(data_out[3]), .CLK(clk), .CEN(1'b0), .WEN(wen[3]), .OEN(1'b0));

endmodule
