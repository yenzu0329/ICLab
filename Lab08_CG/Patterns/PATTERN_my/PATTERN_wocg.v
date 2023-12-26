`ifdef RTL
	`timescale 1ns/10ps
	`include "SNN_wocg.v"
`endif
`ifdef GATE
	`timescale 1ns/10ps
	`include "SNN_SYN.v"
`endif
`define CYCLE_TIME 15

module PATTERN(
    // Output signals
    clk,
    rst_n,
    in_valid,
    img,
    ker,
    weight,

    // Input signals
    out_valid,
    out_data
);

// ===========================
//     Inputs & Outputs
// ===========================
output reg       clk;
output reg       rst_n;
output reg       in_valid;
output reg [7:0] img;
output reg [7:0] ker;
output reg [7:0] weight;

input            out_valid;
input [9:0]      out_data;

// ==============================
//     Parameters & Variables
// ==============================
// PATTERN operation
parameter WAIT_MAX_LAT    = 1000;
parameter OUT_MAX_LAT     = 1;

// PATTERN CONTROL
integer cycle;
integer latency;
integer total_latency;
integer patnum;
integer out_valid_time;

integer i_pat, i, rand_num;
integer in_img[71:0];
integer in_ker[8:0];
integer in_weight[3:0];

// FILE CONTROL
integer f, temp_in;
integer in_file;
integer out_file;

// ==============
//     Colors
// ==============
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

// ===================
//     Clock Cycle
// ===================
parameter CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;
always #(CYCLE) cycle = cycle+1;

// ===============
//     Initial
// ===============
initial begin
    reset_task;
    in_file  = $fopen("../00_TESTBED/input.txt" , "r");
    out_file = $fopen("../00_TESTBED/output.txt", "r");
    f = $fscanf(in_file, "pattern_num=%d\n", patnum);
    @(negedge clk);
    for(i_pat = 0; i_pat < patnum; i_pat = i_pat+1) begin
        idle_task;
        input_task;
        wait_out_valid_task;
        check_ans_task;
        $display("%0sPASS PATTERN NO. %3d, %0sLatency: %4d%0s",txt_blue_prefix, i_pat, txt_green_prefix, latency, reset_color);
    end
    YOU_PASS_task;
    $finish;
end

// =============
//     Tasks
// =============
task reset_task; begin
    rst_n       = 'b1;
    in_valid    = 'b0;
    img         = 'bx;
    ker         = 'bx;
    weight      = 'bx;

    total_latency = 0;
    cycle = 0;

    force clk = 0;
    #CYCLE; rst_n = 0; 
    #(CYCLE/2.0);
    if(out_valid !== 1'b0 || out_data !== 'b0) begin //out!==0
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("            output signals should be 0 after initial RESET          ");
        $display ("====================================================================");  
        $finish;
    end
    #(CYCLE/2.0); rst_n = 1;
	#CYCLE; release clk;
end endtask

task idle_task; begin
    rand_num = $urandom_range(2, 6);
    for(i = 0; i < rand_num; i = i+1) begin
        if(out_valid !== 1'b0 || out_data !== 'b0) begin //out!==0
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("                output signals should be 0 before INPUT             ", cycle);
            $display ("====================================================================");  
            $finish;
    	end
		@(negedge clk);
	end
end endtask

task input_task; begin
    in_valid = 1'b1;
    // read in_file
    for(i = 0; i < 72; i = i + 1) begin
		f = $fscanf(in_file, "%d", temp_in);
        in_img[i] = temp_in;
    end
    for(i = 0; i < 9; i = i + 1) begin
		f = $fscanf(in_file, "%d", temp_in);
        in_ker[i] = temp_in;
    end
    for(i = 0; i < 4; i = i + 1) begin
		f = $fscanf(in_file, "%d", temp_in);
        in_weight[i] = temp_in;
    end
    // start running
    for(i = 0; i < 72; i = i + 1) begin
        img                    = in_img[i];
        if(i < 9)       ker    = in_ker[i];
        else            ker    = 'bx;
        if(i < 4)       weight = in_weight[i];
        else            weight = 'bx;
		if(out_valid !== 1'b0 || out_data !== 'b0) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("           output signals should be 0 when in_valid is HIGH         ");
            $display ("====================================================================");  
            $finish;
        end
        @(negedge clk);
    end
    in_valid = 1'b0;
	img = 'bx;
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid === 1'b0) begin
        if(out_data !== 'b0) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("             out_data should be 0 when out_valid is LOW            ");
            $display ("====================================================================");  
            $finish;
        end
        if(latency == WAIT_MAX_LAT) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("          the execution latency is over %9d cycles                  ", WAIT_MAX_LAT);
            $display ("====================================================================");  
            $finish;
        end
	    latency = latency + 1;
        @(negedge clk);
    end
    if(out_valid !== 1'b1) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("             out_valid is DON'T CARE at %5d th cycle                ", cycle);
        $display ("====================================================================");  
        $finish;
    end
    total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    out_valid_time = 0;
    while(out_valid === 1) begin
        if(out_valid_time >= OUT_MAX_LAT) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("                out_valid should be high only %1d cycle             ", OUT_MAX_LAT);
            $display ("====================================================================");  
            $finish;
        end
        f = $fscanf(out_file, "%d", temp_in);
        if(out_data !== temp_in) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("                         PATTERN NO. %03d                           ", i_pat);
            $display ("                       your ans   =   %4d                           ", out_data);
            $display ("                       golden ans =   %4d                           ", temp_in);
            $display ("====================================================================");  
            $finish;
        end
        out_valid_time = out_valid_time + 1;
        @(negedge clk);
    end
    if(out_valid === 1'b0) begin
        if(out_data !== 'd0) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("              out_data should be 0 when out_valid is LOW           ");
            $display ("====================================================================");  
            $finish;
        end
    end
    else begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("             out_valid is DON'T CARE at %5d th cycle                ", cycle);
        $display ("====================================================================");  
        $finish;
    end
end endtask

task YOU_PASS_task; begin
    $display ("====================================================================");
    $display ("                           %0sCongratulation!!%0s                   ", txt_green_prefix, reset_color);
    $display ("                    You have passed all patterns!                   ");
    $display ("                    total latency = %6d cycles                      ", total_latency);
    $display ("====================================================================");  
    $finish;
end endtask

endmodule