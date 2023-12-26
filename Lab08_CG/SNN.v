// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SNN(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input cg_en;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE  = 2'b00;
parameter IN_1  = 2'b01;
parameter IN_2  = 2'b10;
parameter CALCU = 2'b11;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg  [1:0]  state, next_state;
reg  [5:0]  counter;
wire [4:0]  counter_18;
reg  [7:0]  in_mat[17:0];
reg  [7:0]  in_ker[8:0];
reg  [7:0]  in_weight[3:0];

// convolution
wire [19:0] conv_result;
wire [7:0]  q1_result;
reg  [7:0]  mul[8:0];
reg  [7:0]  max_pool[3:0];

// fully connected
reg  [7:0]  fc1, fc2, w1, w2;
wire [16:0] fc_result;
wire [7:0]  q2_result;
reg  [7:0]  encode[3:0];

wire [9:0]  temp_out;
reg  [9:0]  ttout_data;

//==============================================//
//                 GATED_OR                     //
//==============================================//
wire   state_sleep_ctrl;
wire   state_clk;
assign state_sleep_ctrl = cg_en && ~(counter == 35 || out_valid || state == IDLE);
GATED_OR GATED_state (
	.CLOCK(clk),
	.SLEEP_CTRL(state_sleep_ctrl),
	.RST_N(rst_n),
	.CLOCK_GATED(state_clk)
);


wire   ans_sleep_ctrl;
wire   ans_clk;
assign ans_sleep_ctrl = cg_en && ~(state == CALCU && (counter >= 38 || counter <= 3));
GATED_OR GATED_ans (
	.CLOCK(clk),
	.SLEEP_CTRL(ans_sleep_ctrl),
	.RST_N(rst_n),
	.CLOCK_GATED(ans_clk)
);

wire   max0_sleep_ctrl;
wire   max0_clk;
wire   max0_in;
assign max0_in = (counter == 15 || counter == 16 || counter == 21 || counter == 22);
assign max0_sleep_ctrl = cg_en && ~max0_in;
GATED_OR GATED_max0 (
	.CLOCK(clk),
	.SLEEP_CTRL(max0_sleep_ctrl),
	.RST_N(rst_n),
	.CLOCK_GATED(max0_clk)
);

wire   max1_sleep_ctrl;
wire   max1_clk;
wire   max1_in;
assign max1_in = (counter == 17 || counter == 18 || counter == 23 || counter == 24);
assign max1_sleep_ctrl = cg_en && ~max1_in;
GATED_OR GATED_max1 (
	.CLOCK(clk),
	.SLEEP_CTRL(max1_sleep_ctrl),
	.RST_N(rst_n),
	.CLOCK_GATED(max1_clk)
);

wire   max2_sleep_ctrl;
wire   max2_clk;
wire   max2_in;
assign max2_in = (counter == 27 || counter == 28 || counter == 33 || counter == 34);
assign max2_sleep_ctrl = cg_en && ~max2_in;
GATED_OR GATED_max2 (
	.CLOCK(clk),
	.SLEEP_CTRL(max2_sleep_ctrl),
	.RST_N(rst_n),
	.CLOCK_GATED(max2_clk)
);

wire   max3_sleep_ctrl;
wire   max3_clk;
wire   max3_in;
assign max3_in = (counter == 29 || counter == 30 || counter == 35 || counter == 36);
assign max3_sleep_ctrl = cg_en && ~max3_in;
GATED_OR GATED_max3 (
	.CLOCK(clk),
	.SLEEP_CTRL(max3_sleep_ctrl),
	.RST_N(rst_n),
	.CLOCK_GATED(max3_clk)
);

//==============================================//
//                  design                      //
//==============================================//
// FSM
always @(*) begin
	next_state = state;
	case(state)
		IDLE:	if(in_valid)      next_state = IN_1;
		IN_1:	if(counter == 35) next_state = IN_2;
		IN_2:	if(counter == 35) next_state = CALCU;
		CALCU:  if(out_valid)     next_state = IDLE;
	endcase
end
always @(posedge state_clk, negedge rst_n) begin
	if(!rst_n)  state <= IDLE;
	else        state <= next_state;
end

// counter
always @(posedge clk) begin
	if(next_state == IDLE)  counter <= 0;
	else if(counter == 38)  counter <= 3;
	else                    counter <= counter + 1;
end
assign counter_18 = counter % 18;

// in_mat
genvar im;
generate
	for(im = 0; im < 18; im = im + 1) begin: gen_in_mat
		wire   mat_sleep_ctrl;
		wire   mat_clk;
		wire   mat_in;
		assign mat_in = (counter_18 == im);
		assign mat_sleep_ctrl = cg_en && ~mat_in;
		GATED_OR GATED_mat (
			.CLOCK(clk),
			.SLEEP_CTRL(mat_sleep_ctrl),
			.RST_N(rst_n),
			.CLOCK_GATED(mat_clk)
		);
		always @(posedge mat_clk) begin
			if(mat_in) begin
				in_mat[im] <= img; 
			end
			else begin
				in_mat[im] <= in_mat[im]; 
			end
		end
	end
endgenerate

// in_ker
genvar ik;
generate
	for(ik = 0; ik < 9; ik = ik + 1) begin: gen_in_ker
		wire   ker_sleep_ctrl;
		wire   ker_clk;
		wire   ker_in;
		assign ker_in = (next_state <= IN_1 && counter == ik);
		assign ker_sleep_ctrl = cg_en && ~ker_in;
		GATED_OR GATED_ker (
			.CLOCK(clk),
			.SLEEP_CTRL(ker_sleep_ctrl),
			.RST_N(rst_n),
			.CLOCK_GATED(ker_clk)
		);
		always @(posedge ker_clk) begin
			if(ker_in) begin
				in_ker[ik] <= ker; 
			end
			else begin
				in_ker[ik] <= in_ker[ik]; 
			end
		end
	end
endgenerate

// in_weight
genvar iw;
generate
	for(iw = 0; iw < 4; iw = iw + 1) begin: gen_in_weight
		wire   w_sleep_ctrl;
		wire   w_clk;
		wire   w_in;
		assign w_in = (next_state <= IN_1 && counter == iw);
		assign w_sleep_ctrl = cg_en && ~w_in;
		GATED_OR GATED_w (
			.CLOCK(clk),
			.SLEEP_CTRL(w_sleep_ctrl),
			.RST_N(rst_n),
			.CLOCK_GATED(w_clk)
		);
		always @(posedge w_clk) begin
			if(w_in) begin
				in_weight[iw] <= weight; 
			end
			else begin
				in_weight[iw] <= in_weight[iw]; 
			end
		end
	end
endgenerate

// convolution
genvar ic, jc;
generate
	for(ic = 0; ic < 3; ic = ic + 1) begin: gen_mul_outter
		for(jc = 0; jc < 3; jc = jc + 1) begin: gen_mul_inner
			always @(*) begin
				mul[ic*3 + jc] = 0;
				case(counter)
					15: mul[ic*3 + jc] = in_mat[(ic*6 + jc +  0)%18];
					16: mul[ic*3 + jc] = in_mat[(ic*6 + jc +  1)%18];
					17: mul[ic*3 + jc] = in_mat[(ic*6 + jc +  2)%18];
					18: mul[ic*3 + jc] = in_mat[(ic*6 + jc +  3)%18];
					21: mul[ic*3 + jc] = in_mat[(ic*6 + jc +  6)%18];
					22: mul[ic*3 + jc] = in_mat[(ic*6 + jc +  7)%18];
					23: mul[ic*3 + jc] = in_mat[(ic*6 + jc +  8)%18];
					24: mul[ic*3 + jc] = in_mat[(ic*6 + jc +  9)%18];
					27: mul[ic*3 + jc] = in_mat[(ic*6 + jc + 12)%18];
					28: mul[ic*3 + jc] = in_mat[(ic*6 + jc + 13)%18];
					29: mul[ic*3 + jc] = in_mat[(ic*6 + jc + 14)%18];
					30: mul[ic*3 + jc] = in_mat[(ic*6 + jc + 15)%18];
					33: mul[ic*3 + jc] = in_mat[(ic*6 + jc + 18)%18];
					34: mul[ic*3 + jc] = in_mat[(ic*6 + jc + 19)%18];
					35: mul[ic*3 + jc] = in_mat[(ic*6 + jc + 20)%18];
					36: mul[ic*3 + jc] = in_mat[(ic*6 + jc + 21)%18];
				endcase
			end
		end
	end
	assign conv_result = mul[0] * in_ker[0] + mul[1] * in_ker[1] + mul[2] * in_ker[2] 
			           + mul[3] * in_ker[3] + mul[4] * in_ker[4] + mul[5] * in_ker[5] 
				       + mul[6] * in_ker[6] + mul[7] * in_ker[7] + mul[8] * in_ker[8];
	assign q1_result = conv_result / 2295;
endgenerate

always @(posedge max0_clk) begin
	if(counter == 15 || counter == 16 || counter == 21 || counter == 22)
		max_pool[0] <= (q1_result > max_pool[0] || counter == 15) ? (q1_result) : (max_pool[0]);
	else
		max_pool[0] <= max_pool[0];
end

always @(posedge max1_clk) begin
	if(counter == 17 || counter == 18 || counter == 23 || counter == 24)
		max_pool[1] <= (q1_result > max_pool[1] || counter == 17) ? (q1_result) : (max_pool[1]);
	else
		max_pool[1] <= max_pool[1];
end

always @(posedge max2_clk) begin
	if(counter == 27 || counter == 28 || counter == 33 || counter == 34)
		max_pool[2] <= (q1_result > max_pool[2] || counter == 27) ? (q1_result) : (max_pool[2]);
	else
		max_pool[2] <= max_pool[2];
end

always @(posedge max3_clk) begin
	if(counter == 29 || counter == 30 || counter == 35 || counter == 36)
		max_pool[3] <= (q1_result > max_pool[3] || counter == 29) ? (q1_result) : (max_pool[3]);
	else
		max_pool[3] <= max_pool[3];
end

// fully connected
always @(*) begin
	if(counter == 35 || counter == 36)
		fc1 = max_pool[0];
	else if(counter == 37 || counter == 38)
		fc1 = max_pool[2];
	else
		fc1 = 0;
end
always @(*) begin
	if(counter == 35 || counter == 36)
		fc2 = max_pool[1];
	else if(counter == 37 || counter == 38)
		fc2 = max_pool[3];
	else
		fc2 = 0;
end
always @(*) begin
	if(counter == 35 || counter == 37)
		w1 = in_weight[0];
	else if(counter == 36 || counter == 38)
		w1 = in_weight[1];
	else
		w1 = 0;
end
always @(*) begin
	if(counter == 35 || counter == 37)
		w2 = in_weight[2];
	else if(counter == 36 || counter == 38)
		w2 = in_weight[3];
	else
		w2 = 0;
end
assign fc_result = fc1 * w1 + fc2 * w2;
assign q2_result = fc_result / 510;

// compute encode
genvar ie;
generate
	for(ie = 0; ie < 4; ie = ie + 1) begin: gen_encode
		wire   encode_sleep_ctrl;
		wire   encode_clk;
		wire   encode_in;
		assign encode_in = (counter == 35+ie);
		assign encode_sleep_ctrl = cg_en && ~encode_in;
		GATED_OR GATED_encode (
			.CLOCK(clk),
			.SLEEP_CTRL(encode_sleep_ctrl),
			.RST_N(rst_n),
			.CLOCK_GATED(encode_clk)
		);
		always @(posedge encode_clk) begin
			if(encode_in) begin
				if(next_state == IN_2)
					encode[ie] <= q2_result;
				else
					encode[ie] <= (q2_result > encode[ie]) ? (q2_result - encode[ie]) : (encode[ie] - q2_result);
			end
			else begin
				encode[ie] <= encode[ie];
			end
		end
	end
endgenerate

// output
assign temp_out = encode[0] + encode[1] + encode[2] + encode[3];
always @(posedge ans_clk, negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else begin
		if(state == CALCU && counter == 38) begin
			out_valid <= 1;
		end
		else begin
			out_valid <= 0;
		end
	end 
end
always @(*) begin
	if(out_valid)
		out_data = (temp_out >= 16) ? temp_out : 0;
	else
		out_data = 0;
end

endmodule