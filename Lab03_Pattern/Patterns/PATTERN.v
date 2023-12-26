`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif
`define PAT_NUM 300
`define RAND_SEED 100

module PATTERN(
    // Output Signals
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    // Input Signals
    out_valid,
    out
);


/* Input for design */
output reg       clk, rst_n;
output reg       in_valid;
output reg [1:0] init;
output reg [1:0] in0, in1, in2, in3; 

/* Output for pattern */
input            out_valid;
input      [1:0] out; 

/*global*/
integer latency;
integer total_latency;
integer cost;
integer total_cost;
integer patnum = `PAT_NUM;
 
integer i_pat, i, j, x_pos, y_pos, prev_map_info;
integer rand_num;
integer rand_seed = `RAND_SEED;

reg [3:0] train_pos;
reg [1:0] map [63:0][3:0];
reg [1:0] start_pos;

/* define clock cycle */
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

initial begin
    // start
    reset_task;
    @(negedge clk);
    for(i_pat = 0; i_pat < patnum; i_pat = i_pat+1) begin
        generate_pattern_task;
        idle_task;
        input_task;
        wait_out_valid_task;
        check_ans_task;
    end
    $finish;
end

task reset_task; begin
    rst_n = 'b1;
    in_valid = 'b0;
    init = 'bx;
    in0 = 'bx;
    in1 = 'bx;
    in2 = 'bx;
    in3 = 'bx;
    total_latency = 0;
    total_cost = 0;
    rand_num = $urandom(rand_seed);

    force clk = 0;
    #CYCLE; rst_n = 0; 
    #(CYCLE/2.0);
    if(out_valid !== 1'b0 || out !== 'b0) begin //out!==0
        $display("SPEC 3 IS FAIL!");
        $finish;
    end
    #(CYCLE/2.0); rst_n = 1;
	#CYCLE; release clk;
end endtask

task generate_pattern_task; begin
    for(i = 0; i < 8; i = i+1) begin
        train_pos = $urandom()%14 + 1;
        x_pos = 8*i;
        for(j = 0; j < 4; j = j+1) begin
            map[x_pos+0][j] = (train_pos[j]) ? 2'b11 : 2'b00;
            map[x_pos+1][j] = (train_pos[j]) ? 2'b11 : 2'b00;
            map[x_pos+3][j] = (train_pos[j]) ? 2'b11 : 2'b00;
        end
        for(j = 0; j < 4; j = j+1) begin
            rand_num = $urandom()%3;
            map[x_pos+2][j] = (train_pos[j]) ? 2'b11 : rand_num;
        end
        for(j = 0; j < 4; j = j+1) begin
            map[x_pos+5][j] = 2'b00;
            map[x_pos+7][j] = 2'b00;
        end
        for(j = 0; j < 4; j = j+1) begin
            rand_num = $urandom()%3;
            map[x_pos+4][j] = rand_num;
            rand_num = $urandom()%3;
            map[x_pos+6][j] = rand_num;
        end
    end
    start_pos = $urandom()%4;
    while(map[0][start_pos]) begin
        start_pos = start_pos + 1;
    end
end endtask

task idle_task; begin
    for(i = 0; i < 3; i = i+1) begin
        if(out_valid === 1'b0) begin //out!==0
            if(out !== 'b0) begin
                $display("SPEC 4 IS FAIL!");
    	        $finish;
            end
    	end
        else if(out_valid === 1'b1) begin
            check_ans_task;
            generate_pattern_task;
        end
        else begin
            $display("SPEC X IS FAIL!");
            $finish;
        end
		@(negedge clk);
	end
end endtask

task input_task; begin
    in_valid = 1'b1;
    for(i = 0; i < 64; i = i + 1) begin
		if(i === 0) init = start_pos;
		else        init = 'bx;
        in0 = map[i][0];
        in1 = map[i][1];
        in2 = map[i][2];
        in3 = map[i][3];
        if(out_valid === 1'b0) begin //out!==0
            if(out !== 'b0) begin
                $display("SPEC 4 IS FAIL!");
    	        $finish;
            end
    	end
        else if(out_valid === 1'b1) begin
            $display("SPEC 5 IS FAIL!");
            $finish;
        end
        else begin
            $display("SPEC X IS FAIL!");
            $finish;
        end
        @(negedge clk);
    end
    in_valid = 1'b0;
	in0 = 'bx;
    in1 = 'bx;
    in2 = 'bx;
    in3 = 'bx;
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid === 1'b0) begin
        if(out !== 'b0) begin
            $display("SPEC 4 IS FAIL!");
            $finish;
        end
        if(latency == 3000) begin
            $display("SPEC 6 IS FAIL!");
            $finish;
        end
	    latency = latency + 1;
        @(negedge clk);
    end
    if(out_valid !== 1'b1) begin
        $display("SPEC X IS FAIL!");
        $finish;
    end
    total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    y_pos = start_pos;
    x_pos = 0;
    cost = 0;
    while(out_valid === 1'b1 && x_pos < 63) begin
        prev_map_info = map[x_pos][y_pos];
        // move and compute cost
        x_pos = x_pos + 1;
        if(out === 'd0) begin  //forward
            y_pos = y_pos;
            cost = cost + 1;
        end
        else if(out === 'd1) begin  //right
            y_pos = y_pos + 1;
            cost = cost + 2;
        end
        else if(out === 'd2) begin  //left
            y_pos = y_pos - 1;
            cost = cost + 2;
        end
        else if(out === 'd3) begin  //jump
            y_pos = y_pos;
            cost = cost + 4;
        end
        else begin
            $display("SPEC 7 IS FAIL!");
            $finish;
        end
        // check spec 8-1 ~ 8-5
        if(y_pos < 0 || y_pos > 3) begin
            $display("SPEC 8-1 IS FAIL!");
            $finish;
        end
        if(map[x_pos][y_pos] === 2'b01 && out !== 'd3) begin
            $display("SPEC 8-2 IS FAIL!");
            $finish;
        end
        if(map[x_pos][y_pos] === 2'b10 && out !== 'd0) begin
            $display("SPEC 8-3 IS FAIL!");
            $finish;
        end
        if(map[x_pos][y_pos] === 2'b11) begin
            $display("SPEC 8-4 IS FAIL!");
            $finish;
        end
        if(prev_map_info == 2'b01 && out === 'd3) begin
            $display("SPEC 8-5 IS FAIL!");
            $finish;
        end
        @(negedge clk);
    end
    if(out_valid === 1'b0) begin
        if(out !== 'd0) begin
            $display("SPEC 4 IS FAIL!");
            $finish;
        end
        else begin
            if(x_pos !== 63) begin
                $display("SPEC 7 IS FAIL!");
                $finish;
            end
        end
    end
    else if(out_valid === 1'b1) begin
        $display("SPEC 7 IS FAIL!");
        $finish;
    end
    else begin
        $display("SPEC X IS FAIL!");
        $finish;
    end
    total_cost = total_cost + cost;
end endtask

endmodule