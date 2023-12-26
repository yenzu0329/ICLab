//synopsys translate_off
`include "DW_div.v"
`include "DW_div_seq.v"
`include "DW_div_pipe.v"
//synopsys translate_on

module TRIANGLE(
    clk,
    rst_n,
    in_valid,
    in_length,
    out_cos,
    out_valid,
    out_tri
);
input wire clk, rst_n, in_valid;
input wire [7:0] in_length;

output reg out_valid;
output reg [15:0] out_cos;
output reg [1:0] out_tri;


//================================================================
//  Parameters
//================================================================
parameter IDLE  = 'b000;
parameter IN    = 'b001;
parameter CALCU = 'b010;
parameter OUT1  = 'b100;
parameter OUT2  = 'b101;
parameter OUT3  = 'b110;
   
//================================================================
//  Wires & Registers 
//================================================================
reg [2:0] state, next_state;
// input
reg [7:0] a, b, c;
// output
wire [15:0] theta_a, theta_b, theta_c;
reg [1:0]  tri_type;
// operants
wire signed [17:0] ab_2, bc_2, ac_2;
wire signed [17:0] top_a, top_b, top_c;
wire signed [30:0] quo_a, quo_b, quo_c;
wire signed [17:0] rem_a, rem_b, rem_c;
// flags
wire out_flag;
wire div_start_flag;
wire a_finish_flag, b_finish_flag, c_finish_flag;

//================================================================
//  Design 
//================================================================
// FSM
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  state <= IDLE;
    else        state <= next_state;
end

always @(*) begin
    next_state = state;
    case(state)
        IDLE:   if(in_valid)        next_state = IN;
        IN:     if(!in_valid)       next_state = CALCU;
        CALCU:  if(out_flag)        next_state = OUT1;
        OUT1:                       next_state = OUT2;
        OUT2:                       next_state = OUT3;
        OUT3:                       next_state = IDLE;
    endcase
end

// output block
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_cos <= 0;
        out_tri <= 0;
    end
    else begin
        if (next_state == OUT1) begin
            out_valid <= 1;
            out_cos <= theta_a;
            out_tri <= tri_type;
        end
        else if (next_state == OUT2) begin
            out_valid <= 1;
            out_cos <= theta_b;
            out_tri <= 0;
        end
        else if (next_state == OUT3) begin
            out_valid <= 1;
            out_cos <= theta_c;
            out_tri <= 0;
        end
        else begin
            out_valid <= 0;
            out_cos <= 0;
            out_tri <= 0;
        end
    end
end

// input_block
always @(posedge clk) begin
    if(in_valid) begin
        a <= b;
        b <= c;
        c <= in_length;
    end
    else begin
        a <= a;
        b <= b;
        c <= c;
    end
end

// culculate 2ab, 2bc, 2ac
assign ab_2 = 2 * a * b;
assign bc_2 = 2 * b * c;
assign ac_2 = 2 * a * c;

// culculate top_a, top_b, top_c
assign top_a = b*b + c*c - a*a;
assign top_b = a*a + c*c - b*b;
assign top_c = a*a + b*b - c*c;

// culculate theta_a, theta_b, theta_c
assign div_start_flag = (state == IN) && (next_state == CALCU);
DW_div_seq  #(.a_width(31), .b_width(18),  .tc_mode(1), .num_cyc(18),     .rst_mode(0), .input_mode(0), .output_mode(1),    .early_start(0))
     cal_theta_a(.clk(clk), .rst_n(rst_n), .hold(1'b0), .start(div_start_flag), .a({top_a , 13'd0}), .b(bc_2),  .complete(a_finish_flag), .quotient(quo_a), .remainder(rem_a)); 
DW_div_seq  #(.a_width(31), .b_width(18),  .tc_mode(1), .num_cyc(18),     .rst_mode(0), .input_mode(0), .output_mode(1),    .early_start(0))
     cal_theta_b(.clk(clk), .rst_n(rst_n), .hold(1'b0), .start(div_start_flag), .a({top_b , 13'd0}), .b(ac_2),  .complete(b_finish_flag), .quotient(quo_b), .remainder(rem_b)); 
DW_div_seq  #(.a_width(31), .b_width(18),  .tc_mode(1), .num_cyc(18),     .rst_mode(0), .input_mode(0), .output_mode(1),    .early_start(0))
     cal_theta_c(.clk(clk), .rst_n(rst_n), .hold(1'b0), .start(div_start_flag), .a({top_c , 13'd0}), .b(ab_2),  .complete(c_finish_flag), .quotient(quo_c), .remainder(rem_c));

assign theta_a = quo_a;
assign theta_b = quo_b;
assign theta_c = quo_c;

// check triangle type
assign out_flag = (state == CALCU) && a_finish_flag;
always @(*) begin
    if(theta_a == 0 || theta_b == 0 || theta_c == 0)   tri_type = 2'b11;
    else if(theta_a[15] || theta_b[15] || theta_c[15]) tri_type = 2'b01;
    else                                               tri_type = 2'b00;
end

endmodule
