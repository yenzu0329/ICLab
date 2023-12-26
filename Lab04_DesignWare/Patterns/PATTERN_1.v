`ifdef RTL
	`include "NN.v"  
	`define CYCLE_TIME 50.0
`endif
`ifdef GATE
	`include "NN_SYN.v"
	`define CYCLE_TIME 50.0
`endif

// synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_fp_dp3.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_add.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_mult.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_exp.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_recip.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_sub.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_cmp.v"
// synopsys translate_on

module PATTERN(
	// Output signals
	clk,
	rst_n,
	in_valid,
	data_x,
	data_h,
	weight_u,
	weight_w,
	weight_v,
	// Input signals
	out_valid,
	out
);
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter PATNUM = 100;
integer seed = 66;

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg clk,rst_n,in_valid;
output reg [inst_sig_width + inst_exp_width:0] weight_u, weight_w, weight_v, data_x,data_h;
input out_valid;
input [inst_sig_width + inst_exp_width:0] out;

//================================================================
// parameters & integer
//================================================================
integer t;
integer i;
integer patcount;
integer lat;
//================================================================
// wire & reg
//================================================================
reg sign;
reg [inst_exp_width - 1:0] exp;
reg [inst_sig_width - 1:0] frac;
reg [inst_exp_width + inst_sig_width:0] u[8:0];
reg [inst_exp_width + inst_sig_width:0] w[8:0];
reg [inst_exp_width + inst_sig_width:0] v[8:0];
reg [inst_exp_width + inst_sig_width:0] x[8:0];
reg [inst_exp_width + inst_sig_width:0] h[2:0];
wire [inst_exp_width + inst_sig_width:0] ux1[2:0];
wire [inst_exp_width + inst_sig_width:0] wh0[2:0];
wire [inst_exp_width + inst_sig_width:0] ux1_plus_wh0[2:0];
wire [inst_exp_width + inst_sig_width:0] multpoint1[8:0];
reg [inst_exp_width + inst_sig_width:0] h1[2:0];
wire [inst_exp_width + inst_sig_width:0] vh1[2:0];
wire [inst_exp_width + inst_sig_width:0] neg_vh1[2:0];
wire [inst_exp_width + inst_sig_width:0] exp_vh1[2:0];
wire [inst_exp_width + inst_sig_width:0] exp_vh1_plus1[2:0];
wire [inst_exp_width + inst_sig_width:0] y[8:0];
 
wire [inst_exp_width + inst_sig_width:0] ux2[2:0];
wire [inst_exp_width + inst_sig_width:0] wh1[2:0];
wire [inst_exp_width + inst_sig_width:0] ux2_plus_wh1[2:0];
reg [inst_exp_width + inst_sig_width:0] h2[2:0];
wire [inst_exp_width + inst_sig_width:0] vh2[2:0];
wire [inst_exp_width + inst_sig_width:0] neg_vh2[2:0];
wire [inst_exp_width + inst_sig_width:0] exp_vh2[2:0];
wire [inst_exp_width + inst_sig_width:0] exp_vh2_plus1[2:0];
 
wire [inst_exp_width + inst_sig_width:0] ux3[2:0];
wire [inst_exp_width + inst_sig_width:0] wh2[2:0];
wire [inst_exp_width + inst_sig_width:0] ux3_plus_wh2[2:0];
reg [inst_exp_width + inst_sig_width:0] h3[2:0];
wire [inst_exp_width + inst_sig_width:0] vh3[2:0];
wire [inst_exp_width + inst_sig_width:0] neg_vh3[2:0];
wire [inst_exp_width + inst_sig_width:0] exp_vh3[2:0];
wire [inst_exp_width + inst_sig_width:0] exp_vh3_plus1[2:0];

wire [inst_exp_width + inst_sig_width:0] out_sub_y;
wire [inst_exp_width + inst_sig_width:0] y_sub_out;

reg [10:0] valid_time;
wire violate1, violate2;
//================================================================
// clock
//================================================================
real CYCLE = `CYCLE_TIME;
always #(CYCLE / 2.0) clk = ~clk;

//================================================================
// IP core
//================================================================

// start of y1
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux1_idx0 (.a(u[0]),
																			.b(x[0]),
																			.c(u[1]),
																			.d(x[1]),
																			.e(u[2]),
																			.f(x[2]),
																			.rnd(3'b000),
																			.z(ux1[0])
																			);
																	   
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux1_idx1 (.a(u[3]),
																			.b(x[0]),
																			.c(u[4]),
																			.d(x[1]),
																			.e(u[5]),
																			.f(x[2]),
																			.rnd(3'b000),
																			.z(ux1[1])
																			);																	   

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux1_idx2 (.a(u[6]),
																			.b(x[0]),
																			.c(u[7]),
																			.d(x[1]),
																			.e(u[8]),
																			.f(x[2]),
																			.rnd(3'b000),
																			.z(ux1[2])
																			);
																			
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) wh0_idx0 (.a(w[0]),
																			.b(h[0]),
																			.c(w[1]),
																			.d(h[1]),
																			.e(w[2]),
																			.f(h[2]),
																			.rnd(3'b000),
																			.z(wh0[0])
																			);
																	   
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) wh0_idx1 (.a(w[3]),
																			.b(h[0]),
																			.c(w[4]),
																			.d(h[1]),
																			.e(w[5]),
																			.f(h[2]),
																			.rnd(3'b000),
																			.z(wh0[1])
																			);																	   

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) wh0_idx2 (.a(w[6]),
																			.b(h[0]),
																			.c(w[7]),
																			.d(h[1]),
																			.e(w[8]),
																			.f(h[2]),
																			.rnd(3'b000),
																			.z(wh0[2])
																			);

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux1_plus_wh0_idx0 (
																					.a(ux1[0]),
																					.b(wh0[0]),
																					.rnd(3'b000),
																					.z(ux1_plus_wh0[0])
																					);
																					
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux1_plus_wh0_idx1 (
																					.a(ux1[1]),
																					.b(wh0[1]),
																					.rnd(3'b000),
																					.z(ux1_plus_wh0[1])
																					);
																					
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux1_plus_wh0_idx2 (
																					.a(ux1[2]),
																					.b(wh0[2]),
																					.rnd(3'b000),
																					.z(ux1_plus_wh0[2])
																					);
																					
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) multpoint1_idx0 (
																					.a(ux1_plus_wh0[0]),
																					.b(32'b00111101110011001100110011001101),
																					.rnd(3'b000),
																					.z(multpoint1[0])
																					);
																					 
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) multpoint1_idx1 (
																					.a(ux1_plus_wh0[1]),
																					.b(32'b00111101110011001100110011001101),
																					.rnd(3'b000),
																					.z(multpoint1[1])
																					);

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) multpoint1_idx2 (
																					.a(ux1_plus_wh0[2]),
																					.b(32'b00111101110011001100110011001101),
																					.rnd(3'b000),
																					.z(multpoint1[2])
																					);
																					
always @(*)
	if (ux1_plus_wh0[0][31] == 1)
		h1[0] = multpoint1[0];
	else
		h1[0] = ux1_plus_wh0[0];
		
always @(*)
	if (ux1_plus_wh0[1][31] == 1)
		h1[1] = multpoint1[1];
	else
		h1[1] = ux1_plus_wh0[1];
		
always @(*)
	if (ux1_plus_wh0[2][31] == 1)
		h1[2] = multpoint1[2];
	else
		h1[2] = ux1_plus_wh0[2];
		
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) vh1_idx0 (.a(v[0]),
                                                                             .b(h1[0]),
                                                                             .c(v[1]),
                                                                             .d(h1[1]),
                                                                             .e(v[2]),
                                                                             .f(h1[2]),
                                                                             .rnd(3'b000),
                                                                             .z(vh1[0])
		                                                                     );
																			
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) vh1_idx1 (.a(v[3]),
                                                                             .b(h1[0]),
                                                                             .c(v[4]),
                                                                             .d(h1[1]),
                                                                             .e(v[5]),
                                                                             .f(h1[2]),
                                                                             .rnd(3'b000),
                                                                             .z(vh1[1])
		                                                                     );

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) vh1_idx2 (.a(v[6]),
                                                                             .b(h1[0]),
                                                                             .c(v[7]),
                                                                             .d(h1[1]),
                                                                             .e(v[8]),
                                                                             .f(h1[2]),
                                                                             .rnd(3'b000),
                                                                             .z(vh1[2])
		                                                                     );
																			 
assign neg_vh1[0] = {{~vh1[0][31]}, {vh1[0][30:0]}};
assign neg_vh1[1] = {{~vh1[1][31]}, {vh1[1][30:0]}};
assign neg_vh1[2] = {{~vh1[2][31]}, {vh1[2][30:0]}};

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh1_idx0 (.a(neg_vh1[0]),
																				 .z(exp_vh1[0])
																				 );
																				 
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh1_idx1 (.a(neg_vh1[1]),
																				 .z(exp_vh1[1])
																				 );

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh1_idx2 (.a(neg_vh1[2]),
																				 .z(exp_vh1[2])
																				 );
																				 
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh1_plus1_idx0 (.a(exp_vh1[0]),
																					   .b(32'b00111111100000000000000000000000),
																					   .rnd(3'b000),
																					   .z(exp_vh1_plus1[0])
																					   );
																					   
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh1_plus1_idx1 (.a(exp_vh1[1]),
																					   .b(32'b00111111100000000000000000000000),
																					   .rnd(3'b000),
																					   .z(exp_vh1_plus1[1])
																					   );
																					   
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh1_plus1_idx2 (.a(exp_vh1[2]),
																					   .b(32'b00111111100000000000000000000000),
																					   .rnd(3'b000),
																					   .z(exp_vh1_plus1[2])
																					   );
																					   
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) y_idx0 (.a(exp_vh1_plus1[0]),
																			.rnd(3'b000),
																			.z(y[0])
																			);
																			 
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) y_idx1 (.a(exp_vh1_plus1[1]),
																			.rnd(3'b000),
																			.z(y[1])
																			);
																			 
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) y_idx2 (.a(exp_vh1_plus1[2]),
																			.rnd(3'b000),
																			.z(y[2])
																			);
// end of y1
// start of y2
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux2_idx0 (.a(u[0]),
																			.b(x[3]),
																			.c(u[1]),
																			.d(x[4]),
																			.e(u[2]),
																			.f(x[5]),
																			.rnd(3'b000),
																			.z(ux2[0])
																			);
																	   
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux2_idx1 (.a(u[3]),
																			.b(x[3]),
																			.c(u[4]),
																			.d(x[4]),
																			.e(u[5]),
																			.f(x[5]),
																			.rnd(3'b000),
																			.z(ux2[1])
																			);																	   

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux2_idx2 (.a(u[6]),
																			.b(x[3]),
																			.c(u[7]),
																			.d(x[4]),
																			.e(u[8]),
																			.f(x[5]),
																			.rnd(3'b000),
																			.z(ux2[2])
																			);
																			
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) wh1_idx0 (.a(w[0]),
																			.b(h1[0]),
																			.c(w[1]),
																			.d(h1[1]),
																			.e(w[2]),
																			.f(h1[2]),
																			.rnd(3'b000),
																			.z(wh1[0])
																			);
																	   
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) wh1_idx1 (.a(w[3]),
																			.b(h1[0]),
																			.c(w[4]),
																			.d(h1[1]),
																			.e(w[5]),
																			.f(h1[2]),
																			.rnd(3'b000),
																			.z(wh1[1])
																			);																	   

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) wh1_idx2 (.a(w[6]),
																			.b(h1[0]),
																			.c(w[7]),
																			.d(h1[1]),
																			.e(w[8]),
																			.f(h1[2]),
																			.rnd(3'b000),
																			.z(wh1[2])
																			);

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux2_plus_wh1_idx0 (
																					.a(ux2[0]),
																					.b(wh1[0]),
																					.rnd(3'b000),
																					.z(ux2_plus_wh1[0])
																					);
																					
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux2_plus_wh1_idx1 (
																					.a(ux2[1]),
																					.b(wh1[1]),
																					.rnd(3'b000),
																					.z(ux2_plus_wh1[1])
																					);
																					
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux2_plus_wh1_idx2 (
																					.a(ux2[2]),
																					.b(wh1[2]),
																					.rnd(3'b000),
																					.z(ux2_plus_wh1[2])
																					);
																					
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) multpoint1_idx3 (
																					.a(ux2_plus_wh1[0]),
																					.b(32'b00111101110011001100110011001101),
																					.rnd(3'b000),
																					.z(multpoint1[3])
																					);
																					 
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) multpoint1_idx4 (
																					.a(ux2_plus_wh1[1]),
																					.b(32'b00111101110011001100110011001101),
																					.rnd(3'b000),
																					.z(multpoint1[4])
																					);

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) multpoint1_idx5 (
																					.a(ux2_plus_wh1[2]),
																					.b(32'b00111101110011001100110011001101),
																					.rnd(3'b000),
																					.z(multpoint1[5])
																					);
																					
always @(*)
	if (ux2_plus_wh1[0][31] == 1)
		h2[0] = multpoint1[3];
	else
		h2[0] = ux2_plus_wh1[0];
		
always @(*)
	if (ux2_plus_wh1[1][31] == 1)
		h2[1] = multpoint1[4];
	else
		h2[1] = ux2_plus_wh1[1];
		
always @(*)
	if (ux2_plus_wh1[2][31] == 1)
		h2[2] = multpoint1[5];
	else
		h2[2] = ux2_plus_wh1[2];
		
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) vh2_idx0 (
																			.a(v[0]),
                                                                            .b(h2[0]),
                                                                            .c(v[1]),
                                                                            .d(h2[1]),
                                                                            .e(v[2]),
                                                                            .f(h2[2]),
                                                                            .rnd(3'b000),
                                                                            .z(vh2[0])
		                                                                    );
																			
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) vh2_idx1 (.a(v[3]),
                                                                            .b(h2[0]),
                                                                            .c(v[4]),
                                                                            .d(h2[1]),
                                                                            .e(v[5]),
                                                                            .f(h2[2]),
                                                                            .rnd(3'b000),
                                                                            .z(vh2[1])
		                                                                    );

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) vh2_idx2 (.a(v[6]),
                                                                            .b(h2[0]),
                                                                            .c(v[7]),
                                                                            .d(h2[1]),
                                                                            .e(v[8]),
                                                                            .f(h2[2]),
                                                                            .rnd(3'b000),
                                                                            .z(vh2[2])
		                                                                    );
																			 
assign neg_vh2[0] = {{~vh2[0][31]}, {vh2[0][30:0]}};
assign neg_vh2[1] = {{~vh2[1][31]}, {vh2[1][30:0]}};
assign neg_vh2[2] = {{~vh2[2][31]}, {vh2[2][30:0]}};

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh2_idx0 (.a(neg_vh2[0]),
																				 .z(exp_vh2[0])
																				 );
																				 
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh2_idx1 (.a(neg_vh2[1]),
																				 .z(exp_vh2[1])
																				 );

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh2_idx2 (.a(neg_vh2[2]),
																				 .z(exp_vh2[2])
																				 );
																				 
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh2_plus1_idx0 (.a(exp_vh2[0]),
																					   .b(32'b00111111100000000000000000000000),
																					   .rnd(3'b000),
																					   .z(exp_vh2_plus1[0])
																					   );
																					   
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh2_plus1_idx1 (.a(exp_vh2[1]),
																					   .b(32'b00111111100000000000000000000000),
																					   .rnd(3'b000),
																					   .z(exp_vh2_plus1[1])
																					   );
																					   
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh2_plus1_idx2 (.a(exp_vh2[2]),
																					   .b(32'b00111111100000000000000000000000),
																					   .rnd(3'b000),
																					   .z(exp_vh2_plus1[2])
																					   );
																					   
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) y_idx3 (.a(exp_vh2_plus1[0]),
																			.rnd(3'b000),
																			.z(y[3])
																			);
																			 
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) y_idx4 (.a(exp_vh2_plus1[1]),
																			.rnd(3'b000),
																			.z(y[4])
																			);
																			 
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) y_idx5 (.a(exp_vh2_plus1[2]),
																			.rnd(3'b000),
																			.z(y[5])
																			);
// end of y2
// start of y3
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux3_idx0 (.a(u[0]),
																			.b(x[6]),
																			.c(u[1]),
																			.d(x[7]),
																			.e(u[2]),
																			.f(x[8]),
																			.rnd(3'b000),
																			.z(ux3[0])
																			);
																	   
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux3_idx1 (.a(u[3]),
																			.b(x[6]),
																			.c(u[4]),
																			.d(x[7]),
																			.e(u[5]),
																			.f(x[8]),
																			.rnd(3'b000),
																			.z(ux3[1])
																			);																	   

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux3_idx2 (.a(u[6]),
																			.b(x[6]),
																			.c(u[7]),
																			.d(x[7]),
																			.e(u[8]),
																			.f(x[8]),
																			.rnd(3'b000),
																			.z(ux3[2])
																			);
																			
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) wh2_idx0 (.a(w[0]),
																			.b(h2[0]),
																			.c(w[1]),
																			.d(h2[1]),
																			.e(w[2]),
																			.f(h2[2]),
																			.rnd(3'b000),
																			.z(wh2[0])
																			);
																	   
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) wh2_idx1 (.a(w[3]),
																			.b(h2[0]),
																			.c(w[4]),
																			.d(h2[1]),
																			.e(w[5]),
																			.f(h2[2]),
																			.rnd(3'b000),
																			.z(wh2[1])
																			);																	   

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) wh2_idx2 (.a(w[6]),
																			.b(h2[0]),
																			.c(w[7]),
																			.d(h2[1]),
																			.e(w[8]),
																			.f(h2[2]),
																			.rnd(3'b000),
																			.z(wh2[2])
																			);

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux3_plus_wh2_idx0 (
																					.a(ux3[0]),
																					.b(wh2[0]),
																					.rnd(3'b000),
																					.z(ux3_plus_wh2[0])
																					);
																					
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux3_plus_wh2_idx1 (
																					.a(ux3[1]),
																					.b(wh2[1]),
																					.rnd(3'b000),
																					.z(ux3_plus_wh2[1])
																					);
																					
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ux3_plus_wh2_idx2 (
																					.a(ux3[2]),
																					.b(wh2[2]),
																					.rnd(3'b000),
																					.z(ux3_plus_wh2[2])
																					);
																					
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) multpoint1_idx6 (
																					.a(ux3_plus_wh2[0]),
																					.b(32'b00111101110011001100110011001101),
																					.rnd(3'b000),
																					.z(multpoint1[6])
																					);
																					 
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) multpoint1_idx7 (
																					.a(ux3_plus_wh2[1]),
																					.b(32'b00111101110011001100110011001101),
																					.rnd(3'b000),
																					.z(multpoint1[7])
																					);

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) multpoint1_idx8 (
																					.a(ux3_plus_wh2[2]),
																					.b(32'b00111101110011001100110011001101),
																					.rnd(3'b000),
																					.z(multpoint1[8])
																					);
																					
always @(*)
	if (ux3_plus_wh2[0][31] == 1)
		h3[0] = multpoint1[6];
	else
		h3[0] = ux3_plus_wh2[0];
		
always @(*)
	if (ux3_plus_wh2[1][31] == 1)
		h3[1] = multpoint1[7];
	else
		h3[1] = ux3_plus_wh2[1];
		
always @(*)
	if (ux3_plus_wh2[2][31] == 1)
		h3[2] = multpoint1[8];
	else
		h3[2] = ux3_plus_wh2[2];
		
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) vh3_idx0 (
																			.a(v[0]),
                                                                            .b(h3[0]),
                                                                            .c(v[1]),
                                                                            .d(h3[1]),
                                                                            .e(v[2]),
                                                                            .f(h3[2]),
                                                                            .rnd(3'b000),
                                                                            .z(vh3[0])
		                                                                    );
																			
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) vh3_idx1 (.a(v[3]),
                                                                            .b(h3[0]),
                                                                            .c(v[4]),
                                                                            .d(h3[1]),
                                                                            .e(v[5]),
                                                                            .f(h3[2]),
                                                                            .rnd(3'b000),
                                                                            .z(vh3[1])
		                                                                    );

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) vh3_idx2 (.a(v[6]),
                                                                            .b(h3[0]),
                                                                            .c(v[7]),
                                                                            .d(h3[1]),
                                                                            .e(v[8]),
                                                                            .f(h3[2]),
                                                                            .rnd(3'b000),
                                                                            .z(vh3[2])
		                                                                    );
																			 
assign neg_vh3[0] = {{~vh3[0][31]}, {vh3[0][30:0]}};
assign neg_vh3[1] = {{~vh3[1][31]}, {vh3[1][30:0]}};
assign neg_vh3[2] = {{~vh3[2][31]}, {vh3[2][30:0]}};

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh3_idx0 (.a(neg_vh3[0]),
																				 .z(exp_vh3[0])
																				 );
																				 
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh3_idx1 (.a(neg_vh3[1]),
																				 .z(exp_vh3[1])
																				 );

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh3_idx2 (.a(neg_vh3[2]),
																				 .z(exp_vh3[2])
																				 );
																				 
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh3_plus1_idx0 (.a(exp_vh3[0]),
																					   .b(32'b00111111100000000000000000000000),
																					   .rnd(3'b000),
																					   .z(exp_vh3_plus1[0])
																					   );
																					   
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh3_plus1_idx1 (.a(exp_vh3[1]),
																					   .b(32'b00111111100000000000000000000000),
																					   .rnd(3'b000),
																					   .z(exp_vh3_plus1[1])
																					   );
																					   
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp_vh3_plus1_idx2 (.a(exp_vh3[2]),
																					   .b(32'b00111111100000000000000000000000),
																					   .rnd(3'b000),
																					   .z(exp_vh3_plus1[2])
																					   );
																					   
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) y_idx6 (.a(exp_vh3_plus1[0]),
																			.rnd(3'b000),
																			.z(y[6])
																			);
																			 
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) y_idx7 (.a(exp_vh3_plus1[1]),
																			.rnd(3'b000),
																			.z(y[7])
																			);
																			 
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) y_idx8 (.a(exp_vh3_plus1[2]),
																			.rnd(3'b000),
																			.z(y[8])
																			);

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ysubout 	(.a(y[valid_time]),
																			 .b(out),
																			 .rnd(3'b000),
																			 .z(y_sub_out)
																			 );
																			 
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) cmp_error1 	(.a(y_sub_out),
																				.b(32'b00111010000000110001001001101111),
																				.agtb(violate1)
																				);
																					   
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) cmp_error2 	(.a(y_sub_out),
																				.b(32'b10111010000000110001001001101111),
																				.altb(violate2)
																				);

																			
//================================================================
// initial block
//================================================================
initial begin	
	reset_task;
	for (patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
		input_task;
		wait_out_valid_task;
		check_ans_task;
	end
	YOU_PASS_task;
	$finish;
end

//================================================================
// task
//================================================================
task reset_task; begin
	rst_n = 1;
	in_valid = 0;
	weight_u = 32'bx;
	data_x = 32'bx;
	data_h = 32'bx;
	
	force clk = 0;
	#CYCLE; rst_n = 0;
	#CYCLE; rst_n = 1;
	
	if (out_valid !== 0 || out !== 0) begin
		$display("**************************************************************");
		$display("*   Output signal should be 0 after initial RESET            *");
		$display("**************************************************************");
		$finish;
	end
	
	#CYCLE; release clk;
end
endtask

task input_task; begin
	// t is latency between 2 diff patterns
	t = 1;
	for (i = 0; i < t; i = i + 1)begin
		@(negedge clk);
	end
	
	in_valid = 1'b1;
	
	for (i = 0; i < 9; i = i + 1) begin
		// generate weight_u 
		sign = $random(seed) % 'd2;
		exp = ($random(seed) % 'd5) + 'd125; // from 129 ~ 125
		frac = $random(seed);
		weight_u = {sign, exp, frac};
		u[i] = weight_u;
		
		// generate weight_w
		sign = $random(seed) % 'd2;
		exp = ($random(seed) % 'd5) + 'd125; // from 129 ~ 125
		frac = $random(seed);
		weight_w = {sign, exp, frac};
		w[i] = weight_w;
		
		// generate weight_v
		sign = $random(seed) % 'd2;
		exp = ($random(seed) % 'd5) + 'd125; // from 129 ~ 125
		frac = $random(seed);
		weight_v = {sign, exp, frac};
		v[i] = weight_v;
		
		// generate data_x
		sign = $random(seed) % 'd2;
		exp = ($random(seed) % 'd5) + 'd125; // from 129 ~ 125
		frac = $random(seed);
		data_x = {sign, exp, frac};
		x[i] = data_x;
		
		// generate data_h
		if (i < 3) begin
			sign = $random(seed) % 'd2;
			exp = ($random(seed) % 'd5) + 'd125; // from 129 ~ 125
			frac = $random(seed);
			data_h = {sign, exp, frac};
			h[i] = data_h;
		end
		else begin
			data_h = 32'bx;
		end
		
		// go to next clk
		@(negedge clk);
	end
	
	// set all input as unknown
	in_valid = 0;
	weight_u = 32'bx;
	weight_w = 32'bx;
	weight_v = 32'bx;
	data_x = 32'bx;
	data_h = 32'bx;
	
end
endtask

task wait_out_valid_task; begin
	lat = -1;
	while (out_valid !== 1) begin
		lat = lat + 1;
		if (lat === 100) begin
			$display("***************************************************************");
			$display("*         The execution latency are over 100 cycles.          *");
			$display("***************************************************************");
			$finish;
		end
		@(negedge clk);
	end
	
end
endtask

task check_ans_task; begin
	valid_time = 0;
	while (out_valid) begin
		if (valid_time > 8) begin
			$display("***************************************************************");
			$display("*         out_valid are over 9 cycles.                       *");
			$display("***************************************************************");
			repeat(2)@(negedge clk);
			$finish;
		end
		
		if (valid_time >= 0 && valid_time <= 8) begin
			#(1);
			if (violate1 || violate2) begin
				$display ("--------------------------------------------------------------------");
				$display ("                      No.%1d Out is wrong                            ", valid_time);		
				$display ("--------------------------------------------------------------------");
				repeat(2)@(negedge clk);
				$finish;
			end
		end
		
		// go to next clk
		valid_time = valid_time + 1;
		@(negedge clk);
	end
	
	if (out !== 0) begin
		$display("***************************************************************");
		$display("*         out should be zero when out_valid is low           *");
		$display("***************************************************************");
		repeat(2)@(negedge clk);
		$finish;
	end
	
	if (valid_time < 8) begin
		$display("***************************************************************");
		$display("*         out_valid is less than 9 cycles           			*");
		$display("***************************************************************");
		repeat(2)@(negedge clk);
		$finish;
	end
	
	
end
endtask

task YOU_PASS_task; begin
$display("\033[37m                                                                                                                                          ");        
$display("\033[37m                                                                                \033[32m      :BBQvi.                                              ");        
$display("\033[37m                                                              .i7ssrvs7         \033[32m     BBBBBBBBQi                                           ");        
$display("\033[37m                        .:r7rrrr:::.        .::::::...   .i7vr:.      .B:       \033[32m    :BBBP :7BBBB.                                         ");        
$display("\033[37m                      .Kv.........:rrvYr7v7rr:.....:rrirJr.   .rgBBBBg  Bi      \033[32m    BBBB     BBBB                                         ");        
$display("\033[37m                     7Q  :rubEPUri:.       ..:irrii:..    :bBBBBBBBBBBB  B      \033[32m   iBBBv     BBBB       vBr                               ");        
$display("\033[37m                    7B  BBBBBBBBBBBBBBB::BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB :R     \033[32m   BBBBBKrirBBBB.     :BBBBBB:                            ");        
$display("\033[37m                   Jd .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: Bi    \033[32m  rBBBBBBBBBBBR.    .BBBM:BBB                             ");        
$display("\033[37m                  uZ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B    \033[32m  BBBB   .::.      EBBBi :BBU                             ");        
$display("\033[37m                 7B .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  B    \033[32m MBBBr           vBBBu   BBB.                             ");        
$display("\033[37m                .B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: JJ   \033[32m i7PB          iBBBBB.  iBBB                              ");        
$display("\033[37m                B. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  Lu             \033[32m  vBBBBPBBBBPBBB7       .7QBB5i                ");        
$display("\033[37m               Y1 KBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi XBBBBBBBi :B            \033[32m :RBBB.  .rBBBBB.      rBBBBBBBB7              ");        
$display("\033[37m              :B .BBBBBBBBBBBBBsRBBBBBBBBBBBrQBBBBB. UBBBRrBBBBBBr 1BBBBBBBBB  B.          \033[32m    .       BBBB       BBBB  :BBBB             ");        
$display("\033[37m              Bi BBBBBBBBBBBBBi :BBBBBBBBBBE .BBK.  .  .   QBBBBBBBBBBBBBBBBBB  Bi         \033[32m           rBBBr       BBBB    BBBU            ");        
$display("\033[37m             .B .BBBBBBBBBBBBBBQBBBBBBBBBBBB       \033[38;2;242;172;172mBBv \033[37m.LBBBBBBBBBBBBBBBBBBBBBB. B7.:ii:   \033[32m           vBBB        .BBBB   :7i.            ");        
$display("\033[37m            .B  PBBBBBBBBBBBBBBBBBBBBBBBBBBBBbYQB. \033[38;2;242;172;172mBB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBB  Jr:::rK7 \033[32m             .7  BBB7   iBBBg                  ");        
$display("\033[37m           7M  PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBB..i   .   v1                  \033[32mdBBB.   5BBBr                 ");        
$display("\033[37m          sZ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBB iD2BBQL.                 \033[32m ZBBBr  EBBBv     YBBBBQi     ");        
$display("\033[37m  .7YYUSIX5 .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBBBY.:.      :B                 \033[32m  iBBBBBBBBD     BBBBBBBBB.   ");        
$display("\033[37m LB.        ..BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB. \033[38;2;242;172;172mBB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBMBBB. BP17si                 \033[32m    :LBBBr      vBBBi  5BBB   ");        
$display("\033[37m  KvJPBBB :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: \033[38;2;242;172;172mZB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBsiJr .i7ssr:                \033[32m          ...   :BBB:   BBBu  ");        
$display("\033[37m i7ii:.   ::BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBj \033[38;2;242;172;172muBi \033[37mQBBBBBBBBBBBBBBBBBBBBBBBBi.ir      iB                \033[32m         .BBBi   BBBB   iMBu  ");        
$display("\033[37mDB    .  vBdBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBg \033[38;2;242;172;172m7Bi \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBB rBrXPv.                \033[32m          BBBX   :BBBr        ");        
$display("\033[37m :vQBBB. BQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQ \033[38;2;242;172;172miB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .L:ii::irrrrrrrr7jIr   \033[32m          .BBBv  :BBBQ        ");        
$display("\033[37m :7:.   .. 5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBr \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBB:            ..... ..YB. \033[32m           .BBBBBBBBB:        ");        
$display("\033[37mBU  .:. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mB7 \033[37mgBBBBBBBBBBBBBBBBBBBBBBBBBB. gBBBBBBBBBBBBBBBBBB. BL \033[32m             rBBBBB1.         ");        
$display("\033[37m rY7iB: BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: \033[38;2;242;172;172mB7 \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBB. QBBBBBBBBBBBBBBBBBi  v5                                ");        
$display("\033[37m     us EBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB \033[38;2;242;172;172mIr \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBgu7i.:BBBBBBBr Bu                                 ");        
$display("\033[37m      B  7BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB.\033[38;2;242;172;172m:i \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBv:.  .. :::  .rr    rB                                  ");        
$display("\033[37m      us  .BBBBBBBBBBBBBQLXBBBBBBBBBBBBBBBBBBBBBBBBq  .BBBBBBBBBBBBBBBBBBBBBBBBBv  :iJ7vri:::1Jr..isJYr                                   ");        
$display("\033[37m      B  BBBBBBB  MBBBM      qBBBBBBBBBBBBBBBBBBBBBB: BBBBBBBBBBBBBBBBBBBBBBBBBB  B:           iir:                                       ");        
$display("\033[37m     iB iBBBBBBBL       BBBP. :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  B.                                                       ");        
$display("\033[37m     P: BBBBBBBBBBB5v7gBBBBBB  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: Br                                                        ");        
$display("\033[37m     B  BBBs 7BBBBBBBBBBBBBB7 :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B                                                         ");        
$display("\033[37m    .B :BBBB.  EBBBBBQBBBBBJ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB. B.                                                         ");        
$display("\033[37m    ij qBBBBBg          ..  .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B                                                          ");        
$display("\033[37m    UY QBBBBBBBBSUSPDQL...iBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBK EL                                                          ");        
$display("\033[37m    B7 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: B:                                                          ");        
$display("\033[37m    B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBYrBB vBBBBBBBBBBBBBBBBBBBBBBBB. Ls                                                          ");        
$display("\033[37m    B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi_  /UBBBBBBBBBBBBBBBBBBBBBBBBB. :B:                                                        ");        
$display("\033[37m   rM .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  ..IBBBBBBBBBBBBBBBBQBBBBBBBBBB  B                                                        ");        
$display("\033[37m   B  BBBBBBBBBdZBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBPBBBBBBBBBBBBEji:..     sBBBBBBBr Br                                                       ");        
$display("\033[37m  7B 7BBBBBBBr     .:vXQBBBBBBBBBBBBBBBBBBBBBBBBBQqui::..  ...i:i7777vi  BBBBBBr Bi                                                       ");        
$display("\033[37m  Ki BBBBBBB  rY7vr:i....  .............:.....  ...:rii7vrr7r:..      7B  BBBBB  Bi                                                       ");        
$display("\033[37m  B. BBBBBB  B:    .::ir77rrYLvvriiiiiiirvvY7rr77ri:..                 bU  iQBB:..rI                                                      ");        
$display("\033[37m.S: 7BBBBP  B.                                                          vI7.  .:.  B.                                                     ");        
$display("\033[37mB: ir:.   :B.                                                             :rvsUjUgU.                                                      ");        
$display("\033[37mrMvrrirJKur                                                                                                                               \033[m");
end
endtask

endmodule