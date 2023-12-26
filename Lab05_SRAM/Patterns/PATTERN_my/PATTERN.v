`ifdef RTL
	`timescale 1ns/10ps
	`include "MMT.v"
	`define CYCLE_TIME 4.3
`endif
`ifdef GATE
	`timescale 1ns/10ps
	`include "MMT_SYN.v"
	`define CYCLE_TIME 4.3
`endif

module PATTERN(
    // Output signals
    clk,
    rst_n,
    in_valid,
    in_valid2,
    matrix,
    matrix_size,
    matrix_idx,
    mode,
    // Input signals
    out_valid,
    out_value
);


// ===========================
//     Inputs & Outputs
// ===========================
output reg        clk;
output reg        rst_n;
output reg        in_valid;
output reg        in_valid2;
output reg [7:0]  matrix;
output reg [1:0]  matrix_size;
output reg [1:0]  mode;
output reg [4:0]  matrix_idx;

input               out_valid;
input signed [49:0] out_value;

// ==============================
//     Parameters & Variables
// ==============================
integer cycle;
integer latency;
integer total_latency;
integer patnum;
integer out_valid_time;
 
integer i_pat, j_pat, i, j, size, temp_in, rand_num, f;
integer in_file;
integer out_file;
integer matrix_data [255:0];
reg signed [49:0] golden_ans;
reg enter_loop;
reg negative;

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
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;
always #(CYCLE) cycle = cycle+1;

// ===============
//     Initial
// ===============
initial begin
    reset_task;
    in_file  = $fopen("input.txt" , "r");
    out_file = $fopen("output.txt", "r");
    f = $fscanf(in_file, "pattern_num=%d\n", patnum);
    @(negedge clk);
    for(i_pat = 0; i_pat < patnum; i_pat = i_pat+1) begin
        idle_task;
        input1_task;
        
        for(j_pat = 0; j_pat < 10; j_pat = j_pat+1) begin
            idle_task;
            input2_task;
            wait_out_valid_task;
            check_ans_task;
        end
        $display("%0sPASS PATTERN NO. %3d, %0sLatency: %4d%0s",txt_blue_prefix, i_pat, txt_green_prefix, latency, reset_color);
        f = $fscanf(in_file,  "\n---\n");
        f = $fscanf(out_file, "\n---\n");
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
    in_valid2   = 'b0;
    matrix      = 'bx;
    matrix_size = 'bx;
    mode        = 'bx;
    matrix_idx  = 'bx;

    total_latency = 0;
    cycle = 0;

    force clk = 0;
    #CYCLE; rst_n = 0; 
    #(CYCLE/2.0);
    if(out_valid !== 1'b0 || out_value !== 'b0) begin //out!==0
        $display ("====================================================================");
        $display ("                                FAIL!                               ");
        $display ("            output signals should be 0 after initial RESET           ");
        $display ("====================================================================");  
        $finish;
    end
    #(CYCLE/2.0); rst_n = 1;
	#CYCLE; release clk;
end endtask

task idle_task; begin
    rand_num = $urandom_range(1, 5);
    for(i = 0; i < rand_num; i = i+1) begin
        if(out_valid !== 1'b0 || out_value !== 'b0) begin //out!==0
            $display ("====================================================================");
            $display ("                                FAIL!                               ");
            $display ("           output signals should be 0 at cycle = %-d                 ",cycle);
            $display ("====================================================================");  
            $finish;
    	end
		@(negedge clk);
	end
end endtask

task input1_task; begin
    in_valid = 1'b1;
    f = $fscanf(in_file,  "#%d\n", temp_in);
    f = $fscanf(out_file, "#%d\n", temp_in);
    f = $fscanf(in_file, "matrix_size=%d\n", temp_in);
    case(temp_in)
        0:  size = 2;
        1:  size = 4;
        2:  size = 8;
        3:  size = 16;
    endcase
    for(i = 0; i < 32; i = i + 1) begin
		if(i === 0) matrix_size = temp_in;
		else        matrix_size = 'bx;
        
        f = $fscanf(in_file, "%d", temp_in);
        for(j = 0; j < size*size; j = j + 1) begin
            f = $fscanf(in_file, "%d", matrix);
            if(out_valid !== 1'b0 || out_value !== 'b0) begin
                $display ("====================================================================");
                $display ("                                FAIL!                               ");
                $display ("           output signals should be 0 when in_valid is high         ");
                $display ("====================================================================");  
                $finish;
            end
            @(negedge clk);
        end
    end
    in_valid = 1'b0;
	matrix = 'bx;
end endtask

task input2_task; begin
    in_valid2 = 1'b1;
    f = $fscanf(in_file, "%d ", temp_in);
    f = $fscanf(in_file, "transpose=%d ", temp_in);
    
    f = $fscanf(in_file, "id=");
    for(i = 0; i < 3; i = i + 1) begin
		if(i === 0) mode = temp_in;
		else        mode = 'bx;
        
        f = $fscanf(in_file, "%d", matrix_idx);
        if(out_valid !== 1'b0 || out_value !== 'b0) begin
            $display ("====================================================================");
            $display ("                                FAIL!                               ");
            $display ("           output signals should be 0 when in_valid2 is high        ");
            $display ("====================================================================");  
            $finish;
        end
        @(negedge clk);
    end
    in_valid2 = 1'b0;
	matrix_idx = 'bx;
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid === 1'b0) begin
        if(out_value !== 'b0) begin
            $display ("====================================================================");
            $display ("                                FAIL!                               ");
            $display ("             out_value should be 0 when out_valid is low            ");
            $display ("====================================================================");  
            $finish;
        end
        if(latency == 10000) begin
            $display ("====================================================================");
            $display ("                                FAIL!                               ");
            $display ("              the execution latency is over 10000 cycles            ");
            $display ("====================================================================");  
            $finish;
        end
	    latency = latency + 1;
        @(negedge clk);
    end
    if(out_valid !== 1'b1) begin
        $display ("====================================================================");
        $display ("                                FAIL!                               ");
        $display ("                  out_valid is don't care at %-d                     ",cycle);
        $display ("====================================================================");  
        $finish;
    end
    total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    out_valid_time = 0;
    while(out_valid === 1'b1) begin
        if(out_valid_time > 0) begin
            $display ("====================================================================");
            $display ("                                FAIL!                               ");
            $display ("                out_valid should be high only 1 cycle               ");
            $display ("====================================================================");  
            $finish;
        end
        f = $fscanf(out_file, "%d ", temp_in);
        golden_ans = 0;
        enter_loop = 1;
        negative = 0;
        while(enter_loop) begin
            f = $fscanf(out_file, "%c", temp_in);
            if(temp_in == 45)
                negative = 1;
            else if(temp_in < 48 || temp_in > 57)
                enter_loop = 0;
            else
                golden_ans = golden_ans*10 + (temp_in-48);
        end
        if(negative) golden_ans = -golden_ans;
        if(out_value !== golden_ans) begin
            $display ("====================================================================");
            $display ("                                FAIL!                               ");
            $display ("                        PATTERN NO. %3d [%1d]                       ", i_pat, j_pat);
            $display ("                         your ans = %d                              ", out_value);
            $display ("                       golden ans = %d                              ", golden_ans);
            $display ("====================================================================");  
            $finish;
        end
        out_valid_time = out_valid_time + 1;
        @(negedge clk);
    end
    if(out_valid === 1'b0) begin
        if(out_value !== 'd0) begin
            $display ("====================================================================");
            $display ("                                FAIL!                               ");
            $display ("              out_value should be 0 when out_valid is low           ");
            $display ("====================================================================");  
            $finish;
        end
    end
    else begin
        $display ("====================================================================");
        $display ("                                FAIL!                               ");
        $display ("                  out_valid is don't care at %-d                     ",cycle);
        $display ("====================================================================");  
        $finish;
    end
end endtask

task YOU_PASS_task; begin
    $display ("====================================================================");
    $display ("                           Congratulation!!                         ");
    $display ("                    You have passed all patterns!                   ");
    $display ("====================================================================");  
    $finish;
end endtask

endmodule