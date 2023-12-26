`ifdef RTL
	`timescale 1ns/1ps
	`define CYCLE_TIME_clk1 15.5
	`define CYCLE_TIME_clk2 18.3
`endif
`ifdef GATE
	`timescale 1ns/1ps
	`define CYCLE_TIME_clk1 15.5
	`define CYCLE_TIME_clk2 18.3
`endif


module PATTERN #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Output Port
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

    //Input Port
    ready,
	out_valid,
	out,
	
); 
//================================================================
//   INPUT AND OUTPUT DECLARATION
//================================================================
output reg	rst_n, clk1, clk2, in_valid;
output reg [4:0]doraemon_id;
output reg [7:0]size;
output reg [7:0]iq_score;
output reg [7:0]eq_score;
output reg [2:0]size_weight,iq_weight,eq_weight;

input 	ready, out_valid;
input  [7:0] out;

//================================================================
//   clock
//================================================================
real CYCLE_clk1 = `CYCLE_TIME_clk1;
real CYCLE_clk2 = `CYCLE_TIME_clk2;
always #(CYCLE_clk1 / 2.0) clk1 = ~clk1;
always #(CYCLE_clk2 / 2.0) clk2 = ~clk2;

//================================================================
//   integer & parameter
//================================================================
integer seed = 2; // seed would only change the latency of first in_valid and change the delay from ready to in_valid.
				   // That is, seed would not change the value of any input.
integer PATNUM; // PATNUM would be set due to the first line of input.txt, so you don't need to give a value over here.
integer DELAY = 150; // DELAY is the upper limit of delay from ready to in_valid. If you want to test the functionality easily, you can modify it.
					 // default : 150
integer input_count;
integer output_count;
integer input_file;
integer output_file;
integer t;
integer f;
integer i;
integer sum_of_delay;
integer total_latency;

//================================================================
//   wire & reg
//================================================================
reg first_valid_has_been_raised;
reg [7:0] golden_out;
reg [7:0] delay_limit;
reg [7:0] delay_from_ready_to_in_valid;
reg counting_down;

//================================================================
//   100,000 latency check
//================================================================
always @(negedge clk2)
	if (first_valid_has_been_raised)
		total_latency = total_latency + 1;
		
always @(*)
	if (total_latency >= 100000) begin
		$display("*****************************************************************************");
		$display("*   The clock cycles from first in_valid to last out_valid is over 100000   *");
		$display("*****************************************************************************");
		$finish;
	end

//================================================================
//   check answer in clk2
//================================================================
always@(negedge clk2)
	if (out_valid === 1) begin
		if (output_count < PATNUM) begin
			f = $fscanf(output_file, "%d", golden_out[7:5]);
			f = $fscanf(output_file, "%d", golden_out[4:0]);
			if (out !== golden_out) begin
				$display("**************************************************************");
				$display("*                         YOU FAIL                           *");
				$display("**************************************************************");
				$display("No. %4d pattern is wrong", output_count);
				$display("Golden out = %b (in binary format)", golden_out);
				$display("Your out   = %b (in binary format)", out);
				$display("Please refer to the debug.txt");
				repeat(2) @(negedge clk2);
				$finish;
			end
			else if (out === golden_out) begin
				$display("No. %4d pattern pass", output_count);
				output_count = output_count + 1;
			end
		end
	end
	else if (output_count == PATNUM) begin
		YOU_PASS_task;
		$finish;
	end
	else if (out_valid === 0) begin
		if (out !== 0) begin
			$display("**************************************************************");
			$display("*            out should be 0 when out_valid is low           *");
			$display("**************************************************************");
			repeat(2) @(negedge clk2);
			$finish;
		end
	end


//================================================================
//   initial
//================================================================
initial begin
	initialize_task;
	reset_task;
	f = $fscanf(input_file, "%d", PATNUM);
	first_4_input_task;
	input_task;
end

//================================================================
//   task
//================================================================
task initialize_task; begin
	input_file = $fopen("../00_TESTBED/input.txt", "r");
	output_file = $fopen("../00_TESTBED/output.txt", "r");
	delay_limit = DELAY[7:0] + 1;
	total_latency = 0;
	first_valid_has_been_raised = 0;
	input_count = 0;
	output_count = 0;
	counting_down = 0;
	sum_of_delay = 1000;
end
endtask

task reset_task; begin
	rst_n = 1'b1;
	
	in_valid 	= 1'b0;
	doraemon_id = 5'bx;
	size 		= 8'bx;
	iq_score 	= 8'bx;
	eq_score 	= 8'bx;
	size_weight = 3'bx;
	iq_weight 	= 3'bx;
	eq_weight 	= 3'bx;
	
	force clk1 = 0;
	force clk2 = 0;
	
	#20; rst_n = 1'b0;
	#20; rst_n = 1'b1;
	
	if (ready !== 1'b0 || out_valid !== 1'b0 || out !== 8'b0) begin
		$display("**************************************************************");
		$display("*       Output signal should be 0 after initial RESET        *");
		$display("**************************************************************");
		#50;
		$finish;
	end
	
	#10;
	release clk1;
	release clk2;

end
endtask

task first_4_input_task; begin
	t = $random(seed) % 'd3 + 'd3; // from 3 ~ 5
	repeat(t) @(negedge clk1);
	
	in_valid = 1'b1;
	first_valid_has_been_raised = 1'b1;
	
	for (i = 0; i < 4; i = i + 1) begin
		f = $fscanf(input_file, "%d", doraemon_id);
		f = $fscanf(input_file, "%d", size);
		f = $fscanf(input_file, "%d", iq_score);
		f = $fscanf(input_file, "%d", eq_score);
		
		if (out_valid) begin
			$display("**************************************************************");
			$display("*       out_valid should be 0 before 5th input is given      *");
			$display("**************************************************************");
			repeat(2) @(negedge clk1);
			$finish;
		end
		
		@(negedge clk1);
	end
	
end
endtask

task input_task; begin
	while (input_count < PATNUM) begin
		if (ready) begin
			if (counting_down === 0) begin
				if (sum_of_delay < 150) begin
					delay_from_ready_to_in_valid = $random(seed) % {sum_of_delay + 1};
					sum_of_delay = sum_of_delay - delay_from_ready_to_in_valid;
				end
				else begin
					delay_from_ready_to_in_valid = $random(seed) % delay_limit; // from 0 to delay_limit (which is DELAY you set previously)
					sum_of_delay = sum_of_delay - delay_from_ready_to_in_valid;
				end
				if (delay_from_ready_to_in_valid == 0) begin
					counting_down = 1;
					in_valid = 1'b1;
					f = $fscanf(input_file, "%d", doraemon_id);
					f = $fscanf(input_file, "%d", size);
					f = $fscanf(input_file, "%d", iq_score);
					f = $fscanf(input_file, "%d", eq_score);
					f = $fscanf(input_file, "%d", size_weight);
					f = $fscanf(input_file, "%d", iq_weight);
					f = $fscanf(input_file, "%d", eq_weight);
					input_count = input_count + 1;
					@(negedge clk1);
				end
				else begin
					counting_down = 1;
					in_valid 	= 1'b0;
					doraemon_id = 5'bx;
					size 		= 8'bx;
					iq_score 	= 8'bx;
					eq_score 	= 8'bx;
					size_weight = 3'bx;
					iq_weight 	= 3'bx;
					eq_weight 	= 3'bx;
					@(negedge clk1);
				end
			end
			
			if (delay_from_ready_to_in_valid > 0) begin
				delay_from_ready_to_in_valid = delay_from_ready_to_in_valid - 1;
				@(negedge clk1);
			end
			
			if (delay_from_ready_to_in_valid === 0) begin
				in_valid = 1'b1;
				f = $fscanf(input_file, "%d", doraemon_id);
				f = $fscanf(input_file, "%d", size);
				f = $fscanf(input_file, "%d", iq_score);
				f = $fscanf(input_file, "%d", eq_score);
				f = $fscanf(input_file, "%d", size_weight);
				f = $fscanf(input_file, "%d", iq_weight);
				f = $fscanf(input_file, "%d", eq_weight);
				input_count = input_count + 1;
				@(negedge clk1);
			end
		end
		else begin
			counting_down = 0;
			in_valid 	= 1'b0;
			doraemon_id = 5'bx;
			size 		= 8'bx;
			iq_score 	= 8'bx;
			eq_score 	= 8'bx;
			size_weight = 3'bx;
			iq_weight 	= 3'bx;
			eq_weight 	= 3'bx;
			@(negedge clk1);
		end
	end
	in_valid 	= 1'b0;
	doraemon_id = 5'bx;
	size 		= 8'bx;
	iq_score 	= 8'bx;
	eq_score 	= 8'bx;
	size_weight = 3'bx;
	iq_weight 	= 3'bx;
	eq_weight 	= 3'bx;
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
