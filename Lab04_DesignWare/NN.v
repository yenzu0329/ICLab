module NN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	data_h,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 1; // area optimized
parameter round = 3'b000;

// FSM
parameter IDLE    = 3'b000;
parameter STATE_1 = 3'b001;
parameter STATE_2 = 3'b010;
parameter STATE_3 = 3'b011;
parameter STATE_4 = 3'b100;

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x,data_h;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
// FSM + cycle control
reg  [2:0] state, next_state;
reg  [1:0] loop, next_loop;
reg  [1:0] counter, next_counter;
wire change_state_flag;

// block IP in & out
reg  [inst_sig_width+inst_exp_width:0] mac1_a, mac1_b, mac1_c;
reg  [inst_sig_width+inst_exp_width:0] mac2_a, mac2_b, mac2_c;
reg  [inst_sig_width+inst_exp_width:0] mac3_a, mac3_b, mac3_c;
reg  [inst_sig_width+inst_exp_width:0] mult_a, mult_b;
reg  [inst_sig_width+inst_exp_width:0] add_a,  add_b;
reg  [inst_sig_width+inst_exp_width:0] exp_in;
reg  [inst_sig_width+inst_exp_width:0] recip_in;

reg  [inst_sig_width+inst_exp_width:0] mac1_z_reg;
reg  [inst_sig_width+inst_exp_width:0] mac2_z_reg;
reg  [inst_sig_width+inst_exp_width:0] mac3_z_reg;

wire [inst_sig_width+inst_exp_width:0] m1_z, m2_z, m3_z;
wire [inst_sig_width+inst_exp_width:0] mac1_z, mac2_z, mac3_z;
wire [inst_sig_width+inst_exp_width:0] mult_z;
wire [inst_sig_width+inst_exp_width:0] add_z;
wire [inst_sig_width+inst_exp_width:0] exp_out;
wire [inst_sig_width+inst_exp_width:0] recip_out;

wire [7:0] m1_status, m2_status, m3_status;
wire [7:0] mac1_status, mac2_status, mac3_status;
wire [7:0] mult_status, add_status;
wire [7:0] exp_status, recip_status;

// vector registers
reg [inst_sig_width+inst_exp_width:0] x0[2:0];
reg [inst_sig_width+inst_exp_width:0] x1[2:0];
reg [inst_sig_width+inst_exp_width:0] x2[2:0];

reg [inst_sig_width+inst_exp_width:0] h0[2:0];
reg [inst_sig_width+inst_exp_width:0] h1[2:0];
reg [inst_sig_width+inst_exp_width:0] h2[2:0];
reg [inst_sig_width+inst_exp_width:0] h3[2:0];

reg [inst_sig_width+inst_exp_width:0] v0[2:0];
reg [inst_sig_width+inst_exp_width:0] v1[2:0];
reg [inst_sig_width+inst_exp_width:0] v2[2:0];

reg [inst_sig_width+inst_exp_width:0] w[8:0];
reg [inst_sig_width+inst_exp_width:0] u[8:0];

reg [inst_sig_width+inst_exp_width:0] wh0, wh1, wh2, ux0, ux1, ux2, vh0, v2h1_0;

//---------------------------------------------------------------------
//   HARDWARE DESIGN
//---------------------------------------------------------------------
// ===================
// FSM + Cycle control
// ===================
// state
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  state <= IDLE;
    else 		state <= next_state;
end

assign change_state_flag = (loop >= 2) && (counter == 2);
always @(*) begin
    next_state = state;
	case(state)
		IDLE   : 	if(in_valid)   			next_state = STATE_1;
        STATE_1:    if(change_state_flag)	next_state = STATE_2;
        STATE_2:    if(change_state_flag)   next_state = STATE_3;
        STATE_3:    if(change_state_flag)   next_state = STATE_4;
        STATE_4:    if(change_state_flag)	next_state = IDLE;
    endcase
end

// loop
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  loop <= 0;
	else		loop <= next_loop;
end

always @(*) begin
	if(change_state_flag && state != STATE_2)	next_loop = 0;
	else if(counter == 2)						next_loop = loop + 1;
	else										next_loop = loop;
end

// counter
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)  counter <= 0;
    else		counter <= next_counter;
end
always @(*) begin
	if(state == IDLE)														next_counter = 0;
	else if(change_state_flag && (state == STATE_2 || state == STATE_3))	next_counter = counter + 1;
	else if(counter == 2)													next_counter = 0;
	else																	next_counter = counter + 1;
end

// ======
// output
// ======
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 0;
    end
    else begin
        if(state == STATE_4 && counter != 3) begin
            out_valid <= 1;
            out <= recip_out;
        end
        else begin
            out_valid <= 0;
            out <= 0;
        end
    end
end

// =======================
// input & shift registers
// =======================
// data_x
always @(posedge clk) begin
    if(next_state == STATE_1 && next_loop == 0)	x0[0] <= data_x;
	else										x0[0] <= x0[1];
end
always @(posedge clk) begin
    if(next_state == STATE_1 && next_loop == 1)	x1[0] <= data_x;
	else										x1[0] <= x1[1];
end
always @(posedge clk) begin
    if(next_state == STATE_1 && next_loop == 2)	x2[0] <= data_x;
	else										x2[0] <= x2[1];
end

always @(posedge clk) begin
    x0[1] <= x0[2];
	x0[2] <= x0[0];
end
always @(posedge clk) begin
    x1[1] <= x1[2];
	x1[2] <= x1[0];
end
always @(posedge clk) begin
	x2[1] <= x2[2];
	x2[2] <= x2[0];
end

// data_h
always @(posedge clk) begin
    if(next_state == STATE_1 && next_loop == 0)	h0[0] <= data_h;
	else										h0[0] <= h0[1];
end
always @(posedge clk) begin
	h0[1] <= h0[2];
	h0[2] <= h0[0];
end

// weight w
always @(posedge clk) begin
    if(next_state == STATE_1)				w[0] <= weight_w;
	else									w[0] <= w[1];
end
genvar i_w;
generate
	for(i_w = 1; i_w < 8; i_w = i_w + 1) begin: shift_reg_w
		always @(posedge clk) begin
			w[i_w] <= w[i_w+1];
		end
	end
endgenerate
always @(posedge clk) begin
	w[8] <= w[0];
end

// weight u
always @(posedge clk) begin
    if(next_state == STATE_1)				u[0] <= weight_u;
	else									u[0] <= u[1];
end
genvar i_u;
generate
	for(i_u = 1; i_u < 8; i_u = i_u + 1) begin: shift_reg_u
		always @(posedge clk) begin
			u[i_u] <= u[i_u+1];
		end
	end
endgenerate
always @(posedge clk) begin
	u[8] <= u[0];
end

// weight v
always @(posedge clk) begin
    if(next_state == STATE_1 && next_loop == 0)	v0[0] <= weight_v;
	else										v0[0] <= v0[1];
end
always @(posedge clk) begin
    if(next_state == STATE_1 && next_loop == 1)	v1[0] <= weight_v;
	else										v1[0] <= v1[1];
end
always @(posedge clk) begin
    if(next_state == STATE_1 && next_loop == 2)	v2[0] <= weight_v;
	else										v2[0] <= v2[1];
end

always @(posedge clk) begin
    v0[1] <= v0[2];
	v0[2] <= v0[0];
end
always @(posedge clk) begin
    v1[1] <= v1[2];
	v1[2] <= v1[0];
end
always @(posedge clk) begin
	v2[1] <= v2[2];
	v2[2] <= v2[0];
end

// ======================
// setting block IP input
// ======================
// -------- mac1 ----------
always @(*) begin
	mac1_a = 'bx;
	case(state)
		STATE_1:					mac1_a = h0[0];
		STATE_2:		
			if(loop < 2)			mac1_a = h1[0];
			else					mac1_a = h2[0];
		STATE_3:					mac1_a = h2[0];
		STATE_4:				
			if(loop == 0 && (counter == 0 || counter == 3))
									mac1_a = h2[0];
			else					mac1_a = h3[0];
	endcase
end

always @(*) begin
	mac1_b = 'bx;
	case(state)
		STATE_1:					mac1_b = w[0];
		STATE_2:		
			if(loop == 0)			mac1_b = w[0]; // loop == 0 || loop == 2
			else if(loop == 1)		mac1_b = v0[0];
			else					mac1_b = w[6];
		STATE_3:
			if(counter != 2)		mac1_b = w[6];
			else					mac1_b = v0[0];
		STATE_4:					mac1_b = v0[0];
	endcase
end

always @(*) begin
	mac1_c = 'bx;
	if(state < STATE_3) begin
		if(counter == 0)			mac1_c = 0;
		else						mac1_c = mac1_z_reg;
	end
	else if(state == STATE_3) begin
		if(counter >= 2)			mac1_c = 0;
		else						mac1_c = mac1_z_reg;
	end
	else begin
		if(counter == 1)			mac1_c = 0;
		else						mac1_c = mac1_z_reg;
	end
end

// -------- mac2 ----------
always @(*) begin
	mac2_a = 'bx;
	case(state)
		STATE_1:					mac2_a = x0[0];
		STATE_2:		
			if(loop < 2)			mac2_a = h1[0];
			else					mac2_a = h2[0];
		STATE_3:					mac2_a = h1[0];
		STATE_4:				
			if(loop == 0 && counter != 2)
									mac2_a = h2[0];
			else					mac2_a = h3[0];
	endcase
end

always @(*) begin
	mac2_b = 'bx;
	case(state)
		STATE_1:					mac2_b = u[0];
		STATE_2: 					mac2_b = w[3];
		STATE_3:
			if(counter == 3)		mac2_b = v2[0];
			else					mac2_b = v1[0];
		STATE_4:					mac2_b = v1[0];
	endcase
end

always @(*) begin
	mac2_c = 'bx;
	if(state < STATE_3) begin
		if(counter == 0)			mac2_c = 0;
		else						mac2_c = mac2_z_reg;
	end
	else if(state == STATE_3) begin
		if(counter == 0 || counter == 3)
									mac2_c = 0;
		else						mac2_c = mac2_z_reg;
	end
	else begin
		if(counter >= 2)			mac2_c = 0;
		else						mac2_c = mac2_z_reg;
	end
end

// -------- mac3 ----------
always @(*) begin
	mac3_a = 'bx;
	case(state)
		STATE_1:					mac3_a = x1[0];
		STATE_2:		
			if(loop < 1)			mac3_a = x1[0];
			else					mac3_a = x2[0];
		STATE_3:
			if(counter != 2)		mac3_a = x2[0];
			else					mac3_a = h1[1];
		STATE_4:				
			if(loop == 0 && counter == 3)
									mac3_a = h1[1];
			else if(loop == 0)		mac3_a = h2[0];
			else					mac3_a = h3[0];
	endcase
end

always @(*) begin
	mac3_b = 'bx;
	case(state)
		STATE_1:					mac3_b = u[6];
		STATE_2: 					mac3_b = u[6];
		STATE_3:
			if(counter != 2)		mac3_b = u[6];
			else					mac3_b = v2[1];
		STATE_4:
			if(loop == 0 && counter == 3)
									mac3_b = v2[1];
			else					mac3_b = v2[0];
	endcase
end

always @(*) begin
	mac3_c = 'bx;
	if(state < STATE_3) begin
		if(counter == 0)			mac3_c = 0;
		else						mac3_c = mac3_z_reg;
	end
	else if(state == STATE_3) begin
		if(counter == 3) 			mac3_c = 0;
		else if(counter == 2)		mac3_c = v2h1_0;
		else						mac3_c = mac3_z_reg;
	end
	else begin
		if(counter == 0)			mac3_c = 0;
		else						mac3_c = mac3_z_reg;
	end
end

// -------- add ----------
always @(*) begin
	add_a = 'bx;
	case(state)
		STATE_1:
			if(loop <= 1) 			add_a = wh0;
			else 					add_a = wh1;
		STATE_2:
			if(loop == 0)			add_a = wh2;
			else if(counter == 1)	add_a = wh0;
			else if(counter == 2)	add_a = wh1;
			else					add_a = wh2;
		STATE_3:
			if(counter == 1)		add_a = wh1;
			else if(counter == 2)	add_a = wh2;
			else					add_a = wh0;
		STATE_4: 					add_a = wh0;
	endcase
end

always @(*) begin
	add_b = 'bx;
	case(state)
		STATE_1:
			if(loop <= 1) 			add_b = ux0;
			else 					add_b = ux1;
		STATE_2:
			if(loop == 0)			add_b = ux2;
			else if(counter == 1)	add_b = ux0;
			else if(counter == 2)	add_b = ux1;
			else					add_b = ux2;
		STATE_3:
			if(counter == 1)		add_b = ux1;
			else if(counter == 2)	add_b = ux2;
			else					add_b = ux0;
		STATE_4: 					add_b = 'h3f800000; // =1
	endcase
end

// -------- mult ----------
always @(*) begin
	mult_a = add_z;
	if(add_z[31] == 0 || state == STATE_4)	mult_b = 'h3f800000; // =1
	else									mult_b = 'h3dcccccd; // =0.1
end

// -------- exp ----------
always @(*) begin
	if(state != STATE_4)			exp_in = {~vh0[31], vh0[30:0]};
	else begin
		if(counter == 0)			exp_in = {~mac3_z_reg[31], mac3_z_reg[30:0]};
		else if(counter == 1)		exp_in = {~mac1_z_reg[31], mac1_z_reg[30:0]};
		else 						exp_in = {~mac2_z_reg[31], mac2_z_reg[30:0]};
	end
end

// -------- mult ----------
always @(*) begin
	recip_in = vh0;
end
// =======================
// setting block IP output
// =======================
// wh0, wh1, wh2, ux0, ux1, ux2, vh0, v2h1_0
always @(posedge clk) begin
	mac1_z_reg <= mac1_z;
	mac2_z_reg <= mac2_z;
	mac3_z_reg <= mac3_z;
end

always @(posedge clk) begin
	if (state == STATE_1) 											wh0 <= mac1_z;
	else if(state == STATE_2 && loop == 0)							wh0 <= mac1_z;
	else if(state == STATE_2 && loop > 1)							wh0 <= mac2_z;
	else if((state == STATE_3 && counter == 2) || state == STATE_4) wh0 <= exp_out;
	else															wh0 <= wh0;
end

always @(posedge clk) begin
	if (state == STATE_1) 											wh1 <= mac1_z;
	else if(state == STATE_2 && loop == 0)							wh1 <= mac2_z;
	else if(state == STATE_2 && loop > 1)							wh1 <= mac1_z;
	else															wh1 <= wh1;
end		

always @(posedge clk) begin		
	if (state == STATE_1) 											wh2 <= mac1_z;
	else if(state == STATE_2 && loop <= 1)							wh2 <= mac2_z;
	else if(state == STATE_3 && counter == 1) 						wh2 <= mac1_z;
	else															wh2 <= wh2;
end		

always @(posedge clk) begin		
	if (state == STATE_1 && loop == 0) 								ux0 <= mac2_z;
	else if (state == STATE_1 && loop <= 1) 						ux0 <= mac3_z;
	else if(state == STATE_2 && loop == 1 && counter == 2)			ux0 <= mac3_z;
	else															ux0 <= ux0;
end		

always @(posedge clk) begin		
	if (state == STATE_1 && loop <= 1) 								ux1 <= mac2_z;
	else if(state == STATE_1)										ux1 <= mac3_z;
	else if(state == STATE_2 && loop > 1)							ux1 <= mac3_z;
	else															ux1 <= ux1;
end		

always @(posedge clk) begin		
	if (state == STATE_1) 											ux2 <= mac2_z;
	else if(state == STATE_2 && loop == 0)							ux2 <= mac3_z;
	else if(state == STATE_3 && counter == 1)						ux2 <= mac3_z;
	else															ux2 <= ux2;
end		

always @(posedge clk) begin		
	if (state == STATE_2 && loop <= 1) 								vh0 <= mac1_z;
	else if(state == STATE_4)										vh0 <= mult_z;
	else															vh0 <= vh0;
end

always @(posedge clk) begin		
	if (state == STATE_3 && counter == 3)							v2h1_0 <= mac2_z;
	else															v2h1_0 <= v2h1_0;
end

// h1[2:0]
always @(posedge clk) begin		
	if (state == STATE_1 && loop == 1 && counter == 0)				h1[2] <= mult_z;
	else															h1[2] <= h1[0];
end			
always @(posedge clk) begin					
	if (state == STATE_1 && loop == 2 && counter == 0)				h1[0] <= mult_z;
	else															h1[0] <= h1[1];
end			
always @(posedge clk) begin					
	if (state == STATE_2 && loop == 0 && counter == 0)				h1[1] <= mult_z;
	else															h1[1] <= h1[2];
end

// h2[2:0]
always @(posedge clk) begin		
	if (state == STATE_2 && ((loop < 2) || (loop == 2 && counter == 0)))
																	h2[1] <= mult_z;
	else															h2[1] <= h2[2];
end

always @(posedge clk) begin		
	h2[0] <= h2[1];
	h2[2] <= h2[0];
end

// h3[2:0]
always @(posedge clk) begin		
	if (state == STATE_3) 											h3[1] <= mult_z;
	else															h3[1] <= h3[2];
end

always @(posedge clk) begin		
	h3[0] <= h3[1];
	h3[2] <= h3[0];
end

// ========
// block IP
// ========
// mac1
DW_fp_mult   #(inst_sig_width, inst_exp_width, inst_ieee_compliance) m1(.a(mac1_a), .b(mac1_b), .rnd(round), .z(m1_z),   .status(m1_status));
DW_fp_add    #(inst_sig_width, inst_exp_width, inst_ieee_compliance) a1(.a(m1_z),   .b(mac1_c), .rnd(round), .z(mac1_z), .status(mac1_status));
// mac2
DW_fp_mult   #(inst_sig_width, inst_exp_width, inst_ieee_compliance) m2(.a(mac2_a), .b(mac2_b), .rnd(round), .z(m2_z),   .status(m2_status));
DW_fp_add    #(inst_sig_width, inst_exp_width, inst_ieee_compliance) a2(.a(m2_z),   .b(mac2_c), .rnd(round), .z(mac2_z), .status(mac2_status));
// mac3
DW_fp_mult   #(inst_sig_width, inst_exp_width, inst_ieee_compliance) m3(.a(mac3_a), .b(mac3_b), .rnd(round), .z(m3_z),   .status(m3_status));
DW_fp_add    #(inst_sig_width, inst_exp_width, inst_ieee_compliance) a3(.a(m3_z),   .b(mac3_c), .rnd(round), .z(mac3_z), .status(mac3_status));
 
DW_fp_add   #(inst_sig_width, inst_exp_width, inst_ieee_compliance) add (.a(add_a), .b(add_b), .rnd(round), .z(add_z), .status(add_status));
DW_fp_mult  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) mult(.a(mult_a), .b(mult_b), .rnd(round), .z(mult_z), .status(mult_status));

DW_fp_exp   #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) exp(.a(exp_in), .z(exp_out), .status(exp_status));
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0)       recip(.a(recip_in), .rnd(round), .z(recip_out), .status(recip_status));

endmodule