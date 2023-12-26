//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      (C) Copyright NCTU OASIS Lab      
//            All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2022 ICLAB fall Course
//   Lab05			: SRAM, Matrix Multiplication with Systolic Array
//   Author         : Jia Fu-Tsao (jiafutsao.ee10g@nctu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : v1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`ifdef RTL
	`timescale 1ns/10ps
	`include "MMT.v"
	`define CYCLE_TIME 20.0
`endif
`ifdef GATE
	`timescale 1ns/10ps
	`include "MMT_SYN.v"
	`define CYCLE_TIME 20.0
`endif

module PATTERN(
// output signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
// input signals
    out_valid,
    out_value
);
//================================================================
//   parameters & integers
//================================================================
real	CYCLE = `CYCLE_TIME;
parameter PATNUM = 10; 
parameter LENGTH = 32; // 32 matrices                
integer SEED = 123;
parameter CAL_NUM = 10;
parameter MAX_SIZE = 16;
parameter MAX_CYCLE = 10000;


//PATTERN CONTROL
integer patcount;
integer pat_delay;
integer cal_number;
integer x;
integer i;
integer j;
integer cycles;
integer total_cycles;
integer out_cycles;
integer ten_out_cycles;

integer total_latency;
// integer len,d[0:9],act;

// FILE CONTROL
integer file_out;
integer temp;
//======================================
//      DATA MODEL
//======================================
// INPUT INFO
reg [7:0]matrix_element[0:LENGTH-1][0:MAX_SIZE-1][0:MAX_SIZE-1]; //2*2 or 4*4 or 8*8 or 16*16

reg signed [7:0]matrix_A [0:MAX_SIZE-1][0:MAX_SIZE-1]; 
reg signed [7:0]matrix_AT [0:MAX_SIZE-1][0:MAX_SIZE-1]; 
reg signed [7:0]matrix_B [0:MAX_SIZE-1][0:MAX_SIZE-1]; 
reg signed [7:0]matrix_BT [0:MAX_SIZE-1][0:MAX_SIZE-1]; 
reg signed [7:0]matrix_C [0:MAX_SIZE-1][0:MAX_SIZE-1]; 
reg signed [7:0]matrix_CT [0:MAX_SIZE-1][0:MAX_SIZE-1]; 

reg signed [49:0]matrix_AB [0:MAX_SIZE-1][0:MAX_SIZE-1]; 
reg signed [49:0]matrix_ABC [0:MAX_SIZE-1][0:MAX_SIZE-1]; 

reg signed [49:0] golen_out; 

integer rand_size; //random 1 to 4
integer input_size; // 2**rand_size connect to input
reg [4:0] matrix_idx_reg[0:CAL_NUM-1][0:2]; // random choose 3 matrix_index & then repeat choose 10 times
reg [4:0] index_reg0, index_reg1, index_reg2; // random choose 3 matrix_index

reg [1:0] mode_reg [0:CAL_NUM-1]; //random choose 10 modes
//2'b00: ABC, 2'b01: tranpose(A) BC, 2'b10: A transpose(B)C, 2'b11: AB transpose(C)


integer check_count;

//used for transpose
reg [7:0] matrix_in [0:MAX_SIZE-1][0:MAX_SIZE-1];
reg [7:0] matrix_out [0:MAX_SIZE-1][0:MAX_SIZE-1];
  





//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg 		  clk, rst_n, in_valid, in_valid2;
output reg [7:0] matrix;
output reg [1:0]  matrix_size,mode;
output reg [4:0]  matrix_idx;

input 				out_valid;
input signed [49:0] out_value;



//================================================================
//    clock
//================================================================
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;
//======================================
//              MAIN
//======================================
initial exe_task;
//======================================
//              TASKS
//======================================
task exe_task; begin
    reset_task;
    for (patcount=0 ; patcount<PATNUM ; patcount=patcount+1) begin
        rand_input_task;
        input1_task;
        ten_out_cycles = 0;
        for (cal_number = 0; cal_number < CAL_NUM; cal_number=cal_number+1) begin
			input2_task;
        	cal_task;
        	wait_task;
        	check_task;
		end
        // Print Pass Info and accumulate the total latency
	    $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %5d\033[m", patcount ,ten_out_cycles);
    end
     pass_task;
end endtask

//**************************************
//      Reset Task
//**************************************
task reset_task; begin

    force clk = 0;
    rst_n     = 1;

	in_valid = 1'b0;
	in_valid2 = 1'b0;
	matrix = 8'bx;
	matrix_size = 2'bx;
	mode = 2'bx;
	matrix_idx = 2'bx;

	total_cycles = 0;
 	total_latency = 0;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if (out_valid !== 0 || out_value !== 0) begin
        $display("-------------------------------------------------------------");
        $display("  Output signal should be 0         ");
        $display("  after the reset signal is asserted at %4d ps ", $time*1000);
        $display("-------------------------------------------------------------");
        repeat(5) #(CYCLE);
        $finish;
    end
    #(CYCLE/2.0) release clk;
end endtask

//**************************************
//      Random Input Task
//**************************************
task rand_input_task; begin
	rand_size = $urandom_range(1,4);
	input_size = (2**rand_size);
	// random generate element value
	for (x = 0; x < LENGTH; x=x+1) begin // 32 matrix
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				if (patcount <5) begin
					matrix_element[x][i][j]= $random(SEED)%10; // -9 to 9
				end
				else begin
					matrix_element[x][i][j]= $random(SEED)%128; //-127 to 127 
				end
			end
		end
	end

	//random generate 3 matrix_index
	for (x = 0; x < CAL_NUM; x=x+1) begin
		for (i = 0; i < 3; i=i+1) begin
			matrix_idx_reg[x][i] = $random(SEED)%'d32; // 0 to 31
		end
	end

	//random generate 10 modes
	for (x = 0; x < CAL_NUM; x=x+1) begin
		mode_reg[x] = $random(SEED)% 'd4; // 0 to 3
	end



end endtask

//**************************************
//      Input Task
//**************************************
task input1_task; begin
    //-----------------
    // Transfer input
    //-----------------
    repeat(({$random(SEED)} % 3 + 3)) @(negedge clk); //next input pattern will be triggered 1~5 cycles
    // repeat(2)@(negedge clk);

    check_count = 0;
    //connect to matrix 
	for (x = 0; x < LENGTH; x=x+1) begin // 32 matrix
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				in_valid = 1'b1;
				matrix = matrix_element[x][i][j];
				if (x== 0 && i==0 && j== 0) begin
					matrix_size = rand_size-1; // ran_size from 1 to 4
					//2'b00: 2x2, 2'b01: 4x4, 2'b10: 8x8, 2'b11: 16x16
				end
				else begin
					matrix_size = 'dx;
				end
				check_count = check_count + 1;
				@(negedge clk);
			end
		end
	end

	dump_all_matrix_task; // record the generated matrix 


    in_valid = 1'b0;
    matrix = 'dx;
    matrix_size = 'dx;

    in_valid2 = 1'b0;
    matrix_idx = 'dx;
    mode   = 'dx;

end endtask

task input2_task; begin
    //-----------------
    // Transfer input
    //-----------------
    @(negedge clk); 
    //in_valid2 signal will be triggered for total 10 times(for three cycles) 
    //after in_valid is tied low in a single pattern.

    //connect to matrix 
	for (x = 0; x < 3; x=x+1) begin // three cycles
		in_valid2 = 1'b1;
		matrix_idx = matrix_idx_reg[cal_number][x];
		if (x== 0 ) begin
			mode = mode_reg[cal_number]; // 
		end
		else begin
			mode = 'dx;
		end
		@(negedge clk);

	end


    // in_valid = 1'b0;
    // matrix = 'dx;
    // matrix_size = 'dx;
    in_valid2 = 1'b0;
    matrix_idx = 'dx;
    mode   = 'dx;

end endtask

//**************************************
//      Calculation Task
//**************************************
task cal_task; begin
    dump_choose_matrix_task;
    dump_cal_matrix_task;
end endtask

// Dump decimal
task dump_all_matrix_task; begin

    file_out = $fopen("matrix_all.txt", "w");

    $fwrite(file_out, "[ PAT NO. %-1d ]\n\n", patcount);
    
    //=========================
    // Dump input: all matrix element
    //=========================
    $fwrite(file_out, "[ matrix element ]\n\n");
    for (x = 0; x < LENGTH; x=x+1) begin
    	$fwrite(file_out, "matrix index %d \n", x);
	    for(i=0 ; i < input_size ; i=i+1) begin
	        for(j=0 ; j < input_size ; j=j+1) begin
	            $fwrite(file_out, "%d ", $signed(matrix_element[x][i][j]));
	        end
	        $fwrite(file_out, "\n");
	    end
	   	$fwrite(file_out, "\n\n");
    end
    $fclose(file_out);



end endtask


// Dump decimal
task dump_choose_matrix_task; begin
	// for (x = 0; x < CAL_NUM; x=x+1) begin
	// 	for (i = 0; i < 3; i=i+1) begin
	// 		matrix_idx_reg[x][i] = $random(SEED)%'d32; // 0 to 31
	// 	end
	// end
    file_out = $fopen("matrix_choose.txt", "w");

    $fwrite(file_out, "[ PAT NO. %-1d ]\n\n", patcount);

    $fwrite(file_out, "[ choose matrix index ]\n\n");
    index_reg0 = matrix_idx_reg[cal_number][0];
    index_reg1 = matrix_idx_reg[cal_number][1];
    index_reg2 = matrix_idx_reg[cal_number][2];

    $fwrite(file_out, "matrix index %d \n", index_reg0);
    for(i=0 ; i < input_size ; i=i+1) begin
        for(j=0 ; j < input_size ; j=j+1) begin
            $fwrite(file_out, "%d ", $signed(matrix_element[index_reg0][i][j]));
            matrix_A[i][j] = matrix_element[index_reg0][i][j];
        end
        $fwrite(file_out, "\n");
    end

    $fwrite(file_out, "matrix index %d \n", index_reg1);
    for(i=0 ; i < input_size ; i=i+1) begin
        for(j=0 ; j < input_size ; j=j+1) begin
            $fwrite(file_out, "%d ", $signed(matrix_element[index_reg1][i][j]));
            matrix_B[i][j] = matrix_element[index_reg1][i][j];
        end
        $fwrite(file_out, "\n");
    end

    $fwrite(file_out, "matrix index %d \n", index_reg2);
    for(i=0 ; i < input_size ; i=i+1) begin
        for(j=0 ; j < input_size ; j=j+1) begin
            $fwrite(file_out, "%d ", $signed(matrix_element[index_reg2][i][j]));
            matrix_C[i][j] = matrix_element[index_reg2][i][j];
        end
        $fwrite(file_out, "\n");
    end

	$fwrite(file_out, "\n\n");

	if (mode_reg[cal_number] == 1) begin
		$fwrite(file_out, "[ transpose A ]\n\n");
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				matrix_AT[i][j] = matrix_A[j][i];
				$fwrite(file_out, "%d ", $signed(matrix_AT[i][j]));
			end
        	$fwrite(file_out, "\n");
		end
	end
	else if (mode_reg[cal_number] == 2) begin
		$fwrite(file_out, "[ transpose B ]\n\n");
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				matrix_BT[i][j] = matrix_B[j][i];
				$fwrite(file_out, "%d ", $signed(matrix_BT[i][j]));
			end
        	$fwrite(file_out, "\n");
		end
	end
	else if (mode_reg[cal_number] == 3) begin
		$fwrite(file_out, "[ transpose C ]\n\n");

		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				matrix_CT[i][j] = matrix_C[j][i];
				$fwrite(file_out, "%d ", $signed(matrix_CT[i][j]));
			end
        	$fwrite(file_out, "\n");
		end
	end
    $fclose(file_out);

end endtask

task dump_cal_matrix_task;
	begin

	//initialize the value
	for (i = 0; i < input_size; i=i+1) begin
		for (j = 0; j < input_size; j=j+1) begin
			matrix_AB[i][j] = 'd0;
			matrix_ABC[i][j] = 'd0;
		end
	end
	golen_out = 'd0;

   	file_out = $fopen("matrix_calculate.txt", "w");

    $fwrite(file_out, "[ PAT NO. %-1d ]\n\n", patcount);

    $fwrite(file_out, "[ calculate matrix AB ]\n\n");

	if ((mode_reg[cal_number] == 0) || (mode_reg[cal_number] == 3)) begin
		$fwrite(file_out, "[ AxB ]\n\n");
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				for (x = 0; x < input_size; x=x+1) begin
					matrix_AB[i][j] = matrix_AB[i][j] + matrix_A[i][x]*matrix_B[x][j];
					// $fwrite(file_out, "%d ", $signed(matrix_AB[i][j]));
				end
				$fwrite(file_out, "%d ", $signed(matrix_AB[i][j]));

			end
        	$fwrite(file_out, "\n");
		end
	end
	else if (mode_reg[cal_number] == 1) begin
		$fwrite(file_out, "[ ATxB ]\n\n");
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				for (x = 0; x < input_size; x=x+1) begin
					matrix_AB[i][j] = matrix_AB[i][j] + matrix_AT[i][x]*matrix_B[x][j];
					// $fwrite(file_out, "%d ", $signed(matrix_AB[i][j]));
				end
				$fwrite(file_out, "%d ", $signed(matrix_AB[i][j]));
			end
        	$fwrite(file_out, "\n");
		end
	end
	else if (mode_reg[cal_number] == 2) begin
		$fwrite(file_out, "[ AxBT ]\n\n");
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				for (x = 0; x < input_size; x=x+1) begin
					matrix_AB[i][j] = matrix_AB[i][j] + matrix_A[i][x]*matrix_BT[x][j];
				end
				$fwrite(file_out, "%d ", $signed(matrix_AB[i][j]));

			end
        	$fwrite(file_out, "\n");
		end
	end

	$fwrite(file_out, "\n\n");

	//calculate ABC
    $fwrite(file_out, "[ calculate matrix ABC ]\n\n");

	if (mode_reg[cal_number] == 0) begin
		$fwrite(file_out, "[ AxBxC ]\n\n");
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				for (x = 0; x < input_size; x=x+1) begin
					matrix_ABC[i][j] = matrix_ABC[i][j] + matrix_AB[i][x]*matrix_C[x][j];
				end
				$fwrite(file_out, "%d ", $signed(matrix_ABC[i][j]));
			end
        	$fwrite(file_out, "\n");
		end
	end
	else if (mode_reg[cal_number] == 1) begin
		$fwrite(file_out, "[ ATxBxC ]\n\n");
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				for (x = 0; x < input_size; x=x+1) begin
					matrix_ABC[i][j] = matrix_ABC[i][j] + matrix_AB[i][x]*matrix_C[x][j];
				end
				$fwrite(file_out, "%d ", $signed(matrix_ABC[i][j]));
			end
        	$fwrite(file_out, "\n");
		end
	end
	else if (mode_reg[cal_number] == 2) begin
		$fwrite(file_out, "[ AxBTxC ]\n\n");
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				for (x = 0; x < input_size; x=x+1) begin
					matrix_ABC[i][j] = matrix_ABC[i][j] + matrix_AB[i][x]*matrix_C[x][j];
				end
				$fwrite(file_out, "%d ", $signed(matrix_ABC[i][j]));

			end
        	$fwrite(file_out, "\n");
		end
	end
	else if (mode_reg[cal_number] == 3) begin
		$fwrite(file_out, "[ AxBxCT ]\n\n");
		for (i = 0; i < input_size; i=i+1) begin
			for (j = 0; j < input_size; j=j+1) begin
				for (x = 0; x < input_size; x=x+1) begin
					matrix_ABC[i][j] = matrix_ABC[i][j] + matrix_AB[i][x]*matrix_CT[x][j];
				end
				$fwrite(file_out, "%d ", $signed(matrix_ABC[i][j]));

			end
        	$fwrite(file_out, "\n");
		end
	end
    $fwrite(file_out, "\n\n");

    $fclose(file_out);
    //calculate the transpose
	for (i = 0; i < input_size; i=i+1) begin
		golen_out = golen_out + matrix_ABC[i][i];
	end

end endtask 

//**************************************
//      Wait Task
//**************************************
task wait_task; begin
    cycles = -1;
    while (out_valid !== 1) begin
        if (out_value !== 0) begin
        	$display("---------------------------------- ");
            $display(" Output signal should be 0         ");
            $display("                                   ");
            $display(" when the out_valid is pulled down ");
        	$display("---------------------------------- ");
            repeat(5) #(CYCLE);
            $finish;
        end
        if (cycles == MAX_CYCLE) begin
         	$display("---------------------------------- ");
            $display("                                                   ");
            $display("    The execution latency     at %-12d ps  ", $time*1000);
            $display("    is over %6d   cycles               ", MAX_CYCLE);
            $display("---------------------------------- ");

            repeat(5) @(negedge clk);
            $finish; 
        end
        cycles = cycles + 1;
        @(negedge clk);
    end
end endtask

//**************************************
//     Check answer Task
//**************************************
task check_task;begin
	out_cycles = 0;
    i = 1;
    j = 0;
    while (out_valid === 1) begin
        if (out_cycles == 1) begin
        	$display("-------------------------------------------------------------");
            $display("    Out cycles is more than 1 cycles  at %-12d ps ", $time*1000);
        	$display("-------------------------------------------------------------");
            repeat(5) @(negedge clk);
            $finish;
        end

        if (out_value !== golen_out) begin
        	$display("-------------------------------------------------------------");
        	$display("out value is wrong\n");
        	$display("out_value should be %d", $signed(golen_out));
        	$display("your out_value is %d", $signed(out_value));
        	$display("-------------------------------------------------------------");
            repeat(5) @(negedge clk);
            $finish;
        end
    	out_cycles = out_cycles+1;
    	@(negedge clk);
	end


	if (out_cycles < 1) begin 
		$display("    Out cycles is less than 1 cycles at %-12d ps ", $time*1000);
        repeat(5) @(negedge clk);
        $finish;
	end
	ten_out_cycles = ten_out_cycles + cycles;
    total_cycles = total_cycles + out_cycles;

end endtask 


//**************************************
//      PASS Task
//**************************************
task pass_task; begin
	total_latency = total_cycles * CYCLE;
    $display("-------------------------------------------------------------");
    $display("Congratulation!!! ");
    $display("PASS This Lab........Maybe ");
    $display("Total cycles : %d", cycles);
    $display("Total Latency : %d", total_latency);
    $display("-------------------------------------------------------------");

    repeat(5) @(negedge clk);
    $finish;
end endtask


endmodule

