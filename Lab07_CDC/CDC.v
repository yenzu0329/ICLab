`include "AFIFO.v"

module CDC #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Input Port
	rst_n,
	clk1,
    clk2,
	in_valid,
    doraemon_id,
    size,
    iq_score,
    eq_score,
    size_weight,
    iq_weight,
    eq_weight,
    //Output Port
	ready,
    out_valid,
	out,
    
); 
//---------------------------------------------------------------------
//   CALCU AND OUTPUT DECLARATION
//---------------------------------------------------------------------
output reg [7:0] out;
output reg       out_valid;
output reg       ready;

input        rst_n, clk1, clk2, in_valid;
input  [4:0] doraemon_id;
input  [7:0] size;
input  [7:0] iq_score;
input  [7:0] eq_score;
input  [2:0] size_weight,iq_weight,eq_weight;

//---------------------------------------------------------------------
//   PARAMETERS
//---------------------------------------------------------------------
parameter S_IDLE   = 3'b101;
parameter S_WAIT   = 3'b110;
parameter S_C0     = 3'b000;
parameter S_C1     = 3'b001;
parameter S_C2     = 3'b010;
parameter S_C3     = 3'b011;
parameter S_C4     = 3'b100;
parameter S_FINISH = 3'b111;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg  [2:0]  state, next_state;
reg  [13:0] counter;

reg  [2:0]  door_num;
reg  [4:0]  ids     [4:0];

reg  [7:0]  size_s  [4:0];
reg  [7:0]  iq_s    [4:0];
reg  [7:0]  eq_s    [4:0];
reg  [2:0]  size_w, iq_w, eq_w;

reg  [11:0] prefer;
reg  [11:0] best_prefer;
reg  [2:0]  best_door_num;

// for AFIFO
reg  [7:0]  wdata;
reg         write_in;
wire [7:0]  rdata;
wire        full, empty;

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
// FSM
always @(*) begin
    next_state = state;
    case(state)
        S_IDLE: 
            if(door_num == 4) begin
                if(in_valid)
                    next_state = S_C0;
                else
                    next_state = S_WAIT;
            end
        S_WAIT:
            if(in_valid)
                next_state = S_C0;
        S_C4:
            if(counter == 6000)
                next_state = S_FINISH;
            else if(in_valid)
                next_state = S_C0;
            else 
                next_state = S_WAIT;
        S_FINISH:
            next_state = state;
        default:
            next_state = state + 1;
    endcase
end
always @(posedge clk1, negedge rst_n) begin
    if(!rst_n)  state <= S_IDLE;
    else        state <= next_state;
end

// counter
always @(posedge clk1, negedge rst_n) begin
    if(!rst_n)          counter <= 0;
    else if(in_valid)   counter <= counter + 1;
    else                counter <= counter;
end

// door_num
always @(posedge clk1, negedge rst_n) begin
    if(!rst_n) begin
        door_num <= 0;
    end
    else if(state == S_IDLE && in_valid) begin
        door_num <= door_num + 1;
    end
    else if(state == S_C4) begin
        door_num <= (prefer > best_prefer) ? S_C4 : best_door_num;
    end
    else begin
        door_num <= door_num;
    end
end

// ids
genvar iid;
generate
    for(iid = 0; iid < 5; iid = iid + 1) begin : gen_ids
        always @(posedge clk1) begin
            if(in_valid && door_num == iid)
                ids[iid] <= doraemon_id;
            else
                ids[iid] <= ids[iid];
        end
    end
endgenerate

// size_s
genvar is;
generate
    for(is = 0; is < 5; is = is + 1) begin : gen_sizes
        always @(posedge clk1) begin
            if(in_valid && door_num == is)
                size_s[is] <= size - 5;
            else if(state <= S_C4)
                size_s[is] <= size_s[(is + 1) % 5];
            else
                size_s[is] <= size_s[is];
        end
    end
endgenerate

// iq_s
genvar iiq;
generate
    for(iiq = 0; iiq < 5; iiq = iiq + 1) begin : gen_iq_score
        always @(posedge clk1) begin
            if(in_valid && door_num == iiq)
                iq_s[iiq] <= iq_score - 5;
            else if(state <= S_C4)
                iq_s[iiq] <= iq_s[(iiq + 1) % 5];
            else
                iq_s[iiq] <= iq_s[iiq];
        end
    end
endgenerate

// eq_s
genvar ie;
generate
    for(ie = 0; ie < 5; ie = ie + 1) begin : gen_eq_score
        always @(posedge clk1) begin
            if(in_valid && door_num == ie)
                eq_s[ie] <= eq_score - 5;
            else if(state <= S_C4)
                eq_s[ie] <= eq_s[(ie + 1) % 5];
            else
                eq_s[ie] <= eq_s[ie];
        end
    end
endgenerate

// weights
always @(posedge clk1) begin
    if(in_valid) begin
        size_w <= size_weight;
        iq_w   <= iq_weight;
        eq_w   <= eq_weight;
    end
    else begin
        size_w <= size_w;
        iq_w   <= iq_w;
        eq_w   <= eq_w;
    end
end

// compute preference
always @(*) begin
    prefer = size_s[0] * size_w + iq_s[0] * iq_w + eq_s[0] * eq_w;
end

always @(posedge clk1) begin
    if(state == S_WAIT)  
        best_prefer <= 0;
    else if(prefer > best_prefer)
        best_prefer <= prefer;
    else
        best_prefer <= best_prefer;
end

always @(posedge clk1) begin
    if(state == S_WAIT)  
        best_door_num <= 0;
    else if(prefer > best_prefer)
        best_door_num <= state;
    else
        best_door_num <= best_door_num;
end

// out_valid, out, ready
always @(posedge clk2, negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 0;
    end
    else if(empty) begin
        out_valid <= 0;
        out <= 0;
    end
    else begin
        out_valid <= 1;
        out <= rdata;
    end
end
always @(posedge clk1, negedge rst_n) begin
    if(!rst_n)
        ready <= 0;
    else
        ready <= (next_state == S_WAIT);
end

// AFIFO
always @(posedge clk1, negedge rst_n) begin
    if(!rst_n)  write_in <= 0;
    else        write_in <= (state == S_C4);
end
always @(*) begin
    wdata = {best_door_num, ids[best_door_num]};
end
AFIFO fifo (.rst_n(rst_n), .rclk(clk2), .rinc(1'b1), .wclk(clk1), .winc(write_in), .wdata(wdata), .rempty(empty), .rdata(rdata), .wfull(full)); 

endmodule