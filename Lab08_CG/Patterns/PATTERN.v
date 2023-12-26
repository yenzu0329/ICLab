`define CYCLE_TIME 15


module PATTERN(
	// Output signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Input signals
	out_valid,
	out_data
);

output reg clk;
output reg rst_n;
output reg cg_en;
output reg in_valid;
output reg [7:0] img;
output reg [7:0] ker;
output reg [7:0] weight;

input out_valid;
input  [9:0] out_data;

//================================================================
// parameters & integer
//================================================================
real	  CYCLE = `CYCLE_TIME;
parameter PATNUM = 10; 
parameter LENGTH = 2; // 2 matrices                
integer   SEED = 123;
integer   SEED1 = 12345;
integer   CG_EN = 0;

parameter MAX_CYCLE = 1000;
parameter IN_SIZE = 6;
parameter scale_4x4 = 585225/255; //2295
parameter scale_4x1 = 130050/255;//510

//PATTERN CONTROL
integer patcount;
integer pat_delay;
integer cal_number;
integer x;
integer y;
integer k;

integer i;
integer j;
integer cycles;
integer total_cycles;
integer out_cycles;

integer total_latency;
// integer len,d[0:9],act;

// FILE CONTROL
integer file_out;
integer temp;

//================================================================
// Wire & Reg Declaration
//================================================================
integer check_count;

// INPUT INFO
reg [7:0] in_matrix[0:LENGTH-1][0:IN_SIZE-1][0:IN_SIZE-1]; //8 bits, 2 matrices, size = 6x6
reg [7:0] in_matrix_conv[0:LENGTH-1][0:2][0:2]; 

reg [7:0] kernel_matrix[0:2][0:2]; 

//convolution
reg [23:0] feature_map [0:LENGTH-1][0:IN_SIZE-1][0:IN_SIZE-1]; //24 bits, 2 matrices, size = 6x6
reg [7:0] quan_feature_map [0:LENGTH-1][0:IN_SIZE-1][0:IN_SIZE-1]; //8 bits, 2 matrices, size = 6x6,feature_map/scale,scale = 2295

reg [7:0] max_pool_map_pre [0:LENGTH-1][0:1][0:1];
reg [7:0] max_pool_map [0:LENGTH-1][0:1][0:1];
reg [7:0] weight_matrix[0:1][0:1];
reg [16:0]fully_conn_out [0:LENGTH-1][0:1][0:1];
reg [16:0]fully_conn_flat [0:LENGTH-1][0:3];

reg [7:0] quan_flat [0:LENGTH-1][0:3];
reg [9:0] L1_dist ; 
reg [9:0] act_L1_dist ; // L1<16,A(L1) = 0; L1>=16,A(L1) = L1

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
        input_task;

        cal_task;
        wait_task;
        check_task;
        // Print Pass Info and accumulate the total latency
	    $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %5d\033[m", patcount ,out_cycles);
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
	cg_en = CG_EN;
	img = 8'bx;
	ker = 8'bx;
	weight = 8'bx;

	total_cycles = 0;

 	total_latency = 0;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if (out_valid !== 0 || out_data !== 0) begin
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

	// random generate 6x6 input matrix element value
	for (i = 0; i < IN_SIZE; i=i+1) begin
		for (j = 0; j < IN_SIZE; j=j+1) begin
			if (patcount <5) begin
				in_matrix[0][i][j]= $random(SEED)%'d100; // 0 to 99
			end
			else begin
				in_matrix[0][i][j]= $random(SEED)%'d256; //0 to 255 
			end
		end
	end

	for (i = 0; i < IN_SIZE; i=i+1) begin
		for (j = 0; j < IN_SIZE; j=j+1) begin
			if (patcount <5) begin
				in_matrix[1][i][j]= $random(SEED1)%'d256; // 0 to 99
			end
			else begin
				in_matrix[1][i][j]= $random(SEED1)%'d256; //0 to 255 
			end
		end
	end
	// random generate 3x3 kernel matrix element value
	for (i = 0; i < 3; i=i+1) begin
		for (j = 0; j < 3; j=j+1) begin
			if (patcount <5) begin
				kernel_matrix[i][j]= $random(SEED1)%'d100; // 0 to 99
			end
			else begin
				kernel_matrix[i][j]= $random(SEED1)%'d256; //0 to 255 
			end
		end
	end

	// random generate 2x2 weight matrix element value
	for (i = 0; i < 2; i=i+1) begin
		for (j = 0; j < 2; j=j+1) begin
			if (patcount <5) begin
				weight_matrix[i][j]= $random(SEED1)%'d100; // 0 to 99
			end
			else begin
				weight_matrix[i][j]= $random(SEED1)%'d256; //0 to 255 
			end
		end
	end
end endtask

//**************************************
//      Input Task
//**************************************
task input_task; begin
    //-----------------
    // Transfer input
    //-----------------
    repeat(({$urandom(SEED)%4 + 2} )) @(negedge clk); //next input pattern will be triggered 2~5 cycles
    check_count = 0;
    //connect to matrix 
	for (x = 0; x < LENGTH; x=x+1) begin // 2 matrix
		for (i = 0; i < IN_SIZE; i=i+1) begin
			for (j = 0; j < IN_SIZE; j=j+1) begin
				in_valid = 1'b1;
				img = in_matrix[x][i][j];

				//9 cycles for ker signal
				if (x== 0 && i==0 && j<3) begin
					ker = kernel_matrix[i][j]; //ker[0][0],ker[0][1],ker[0][2]
				end
				else if (x== 0 && i==0 && j>=3 && j<=5) begin
					ker = kernel_matrix[1][j-3]; //ker[1][0],ker[1][1],ker[1][2]
				end
				else if (x== 0 && i==1 && j>=0 && j<=2) begin
					ker = kernel_matrix[2][j]; //ker[2][0],ker[2][1],ker[2][2]
				end
				else begin
					ker = 'dx;
				end

				//4 cycles for weight signal
				if (x== 0 && i==0 && j<2) begin
					weight = weight_matrix[i][j]; //weight[0][0],weight[0][1]
				end
				else if (x== 0 && i==0 && j>=2 && j<4) begin
					weight = weight_matrix[1][j-2]; //weight[1][0],weight[1][1]
				end
				else begin
					weight = 'dx;
				end
				check_count = check_count + 1;
				@(negedge clk);
			end
		end
	end

	dump_input_matrix_task; // record the generated matrix 


    in_valid = 1'b0;
    img = 'dx;
    ker = 'dx;
    weight = 'dx;

end endtask


// Dump decimal
task dump_input_matrix_task; begin

    file_out = $fopen("matrix_input.txt", "w");

    $fwrite(file_out, "[ PAT NO. %-1d ]\n\n", patcount);
    
    //=========================
    // Dump input: all matrix element
    //=========================
    $fwrite(file_out, "[image matrix element ]\n\n");
    for (x = 0; x < LENGTH; x=x+1) begin
    	$fwrite(file_out, "matrix index %d \n", x);
	    for(i=0 ; i < IN_SIZE ; i=i+1) begin
	        for(j=0 ; j < IN_SIZE ; j=j+1) begin
	            $fwrite(file_out, "%d ", in_matrix[x][i][j]);
	        end
	        $fwrite(file_out, "\n");
	    end
	   	$fwrite(file_out, "\n\n");
    end

    $fwrite(file_out, "[kernel matrix element ]\n\n");
    for(i=0 ; i < 3 ; i=i+1) begin
        for(j=0 ; j < 3 ; j=j+1) begin
            $fwrite(file_out, "%d ", kernel_matrix[i][j]);
        end
        $fwrite(file_out, "\n");
    end
   	$fwrite(file_out, "\n\n");

    $fwrite(file_out, "[weight matrix element ]\n\n");
    for(i=0 ; i < 2 ; i=i+1) begin
        for(j=0 ; j < 2 ; j=j+1) begin
            $fwrite(file_out, "%d ", weight_matrix[i][j]);
        end
        $fwrite(file_out, "\n");
    end
   	$fwrite(file_out, "\n\n");

    $fclose(file_out);

end endtask

//**************************************
//      Calculation Task
//**************************************
task cal_task; begin
    dump_cal_matrix_task;
end endtask




task dump_cal_matrix_task;
	begin

	//initialize the feature map & quantize feature map
	for (x = 0; x < LENGTH; x=x+1) begin
		for (i = 0; i < 5; i=i+1) begin
			for (j = 0; j < 5; j=j+1) begin
				feature_map[x][i][j] = 'd0;
				quan_feature_map[x][i][j] = 'd0;
			end
		end
	end

	for (x = 0; x < LENGTH; x=x+1) begin
		for (i = 0; i < 2; i=i+1) begin
			for (j = 0; j < 2; j=j+1) begin
				max_pool_map[x][i][j] = 'd0;
				max_pool_map_pre[x][i][j] = 'd0;
				fully_conn_out[x][i][j] = 'd0;
				in_matrix_conv[x][i][j] = 'd0;
			end
		end
	end

	for (x = 0; x < LENGTH; x=x+1) begin
		for (i = 0; i < 4; i=i+1) begin
			fully_conn_flat[x][i] = 'd0;
			quan_flat[x][i] = 'd0;
		end
	end
	L1_dist = 'd0;
	act_L1_dist = 'd0;

   	file_out = $fopen("matrix_calculate.txt", "w");

    $fwrite(file_out, "[ PAT NO. %-1d ]\n\n", patcount);

    $fwrite(file_out, "[1. calculate convolution ]\n\n"); //convolution

	$fwrite(file_out, "[ kernel_matrix ]\n");
	for (x = 0; x < 3; x=x+1) begin
		for (y = 0; y < 3; y=y+1) begin
			$fwrite(file_out, "%d ", kernel_matrix[x][y]);
		end
		$fwrite(file_out, "\n");
	end
	$fwrite(file_out, "\n\n");

	//matrix 0
	$fwrite(file_out, "[ in_matrix convolute kernel_matrix 0]\n\n");

	for (i = 0; i < 4; i=i+1) begin
		for (j = 0; j < 4; j=j+1) begin
			$fwrite(file_out, "feature_map 0 [%d][%d]\n",i,j);

			for (x = 0; x < 3; x=x+1) begin
	 			for (y = 0; y < 3; y=y+1) begin
	 				in_matrix_conv[0][x][y] = in_matrix[0][x+i][y+j];
	 				feature_map[0][i][j] = feature_map[0][i][j] + in_matrix_conv[0][x][y]*kernel_matrix[x][y];
	 				$fwrite(file_out, "%d ", in_matrix_conv[0][x][y]);
	 			end
	 			$fwrite(file_out, "\n");
	 		end
	 		$fwrite(file_out, "%d ", feature_map[0][i][j]);
	 		$fwrite(file_out, "\n\n");

		end
	end

	$fwrite(file_out, "\n\n");

	//matrix 1
	$fwrite(file_out, "[ in_matrix convolute kernel_matrix 1]\n\n");
	for (i = 0; i < 4; i=i+1) begin
		for (j = 0; j < 4; j=j+1) begin
			$fwrite(file_out, "feature_map 1 [%d][%d]\n",i,j);
			for (x = 0; x < 3; x=x+1) begin
	 			for (y = 0; y < 3; y=y+1) begin
	 				in_matrix_conv[1][x][y] = in_matrix[1][x+i][y+j];
	 				feature_map[1][i][j] = feature_map[1][i][j] + in_matrix_conv[1][x][y]*kernel_matrix[x][y];
	 				$fwrite(file_out, "%d ", in_matrix_conv[1][x][y]);
	 			end
	 			$fwrite(file_out, "\n");
	 		end
	 		$fwrite(file_out, "%d ", feature_map[1][i][j]);
	 		$fwrite(file_out, "\n\n");

		end
	end

	$fwrite(file_out, "\n\n");
	for (x = 0; x < LENGTH; x=x+1) begin
		$fwrite(file_out, "feature_map %d\n",x);
		for (i = 0; i < 4; i=i+1) begin
			for (j = 0; j < 4; j=j+1) begin
		 		$fwrite(file_out, "%d ", feature_map[x][i][j]);
			end
			$fwrite(file_out, "\n");
		end
		$fwrite(file_out, "\n\n");
	end


	$fwrite(file_out, "\n\n");

	for (x = 0; x < LENGTH; x=x+1) begin
		$fwrite(file_out, "quantize_feature_map %d\n",x);
		for (i = 0; i < 4; i=i+1) begin
			for (j = 0; j < 4; j=j+1) begin
				quan_feature_map[x][i][j] = feature_map[x][i][j]/scale_4x4;
		 		$fwrite(file_out, "%d ", quan_feature_map[x][i][j]);
			end
			$fwrite(file_out, "\n");
		end
		$fwrite(file_out, "\n\n");
	end


	$fwrite(file_out, "\n\n");

	for (x = 0; x < LENGTH; x=x+1) begin
		$fwrite(file_out, "max_pool_map %d\n",x);
		for (i = 0; i < 2; i=i+1) begin
			for (j = 0; j < 2; j=j+1) begin
				max_pool_map[x][i][j] = quan_feature_map[x][i*2][j*2];
				if (quan_feature_map[x][i*2][j*2+1] > max_pool_map[x][i][j]) begin
					max_pool_map[x][i][j] = quan_feature_map[x][i*2][j*2+1];
				end
				if (quan_feature_map[x][i*2+1][j*2] > max_pool_map[x][i][j]) begin
					max_pool_map[x][i][j] = quan_feature_map[x][i*2+1][j*2];
				end
				if (quan_feature_map[x][i*2+1][j*2+1] > max_pool_map[x][i][j]) begin
					max_pool_map[x][i][j] = quan_feature_map[x][i*2+1][j*2+1];
				end
		 		$fwrite(file_out, "%d ", max_pool_map[x][i][j]);
			end
			$fwrite(file_out, "\n");
		end
		$fwrite(file_out, "\n\n");
	end

	$fwrite(file_out, "\n\n");

	for (x = 0; x < LENGTH; x=x+1) begin
		$fwrite(file_out, "fully_conn_out %d\n",x);
		for (i = 0; i < 2; i=i+1) begin
			for (j = 0; j < 2; j=j+1) begin
				for (k = 0; k < 2; k=k+1) begin
					fully_conn_out[x][i][j] = fully_conn_out[x][i][j] + max_pool_map[x][i][k]*weight_matrix[k][j];
				end
		 		$fwrite(file_out, "%d ", fully_conn_out[x][i][j]);
			end
			$fwrite(file_out, "\n");
		end
		$fwrite(file_out, "\n\n");
	end


	$fwrite(file_out, "\n\n");

	for (x = 0; x < LENGTH; x=x+1) begin
		$fwrite(file_out, "fully_conn_flat %d\n",x);
		for (i = 0; i < 2; i=i+1) begin
			for (j = 0; j < 2; j=j+1) begin
				fully_conn_flat[x][i*2+j] = fully_conn_out[x][i][j];
		 		$fwrite(file_out, "%d ", fully_conn_flat[x][i*2+j]);
			end
		end
		$fwrite(file_out, "\n\n");
	end

	$fwrite(file_out, "\n\n");

	for (x = 0; x < LENGTH; x=x+1) begin
		$fwrite(file_out, "quan_flat %d\n",x);
		for (i = 0; i < 4; i=i+1) begin
			quan_flat[x][i] = fully_conn_flat[x][i] / scale_4x1;
		 	$fwrite(file_out, "%d ", quan_flat[x][i]);
		end
		$fwrite(file_out, "\n\n");
	end


	$fwrite(file_out, "\n\n");

	$fwrite(file_out, "L1_dist\n");
	for (i = 0; i < 4; i=i+1) begin
		if (quan_flat[0][i]>quan_flat[1][i]) begin
			L1_dist = L1_dist + (quan_flat[0][i] - quan_flat[1][i]) ;
		end
		else begin
			L1_dist = L1_dist +  (quan_flat[1][i] - quan_flat[0][i]) ;	
		end
	end
	$fwrite(file_out, "%d ", L1_dist);

	$fwrite(file_out, "\n\n");

	$fwrite(file_out, "act_L1_dist\n");
	if (L1_dist < 16) begin
		act_L1_dist = 0;
	end
	else begin
		act_L1_dist = L1_dist;
	end
	$fwrite(file_out, "%d ", act_L1_dist);

 	$fclose(file_out);

end endtask 


//**************************************
//      Wait Task
//**************************************
task wait_task; begin
    cycles = -1;
    while (out_valid === 0) begin
        if (out_data !== 0) begin
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
    while (out_valid === 1) begin
        if (out_cycles == 1) begin
        	$display("-------------------------------------------------------------");
            $display("    Out cycles is more than 1 cycles  at %-12d ps ", $time*1000);
        	$display("-------------------------------------------------------------");
            repeat(5) @(negedge clk);
            $finish;
        end

        if (out_data !== act_L1_dist) begin
        	$display("-------------------------------------------------------------");
        	$display("out_data is wrong\n");
        	$display("out_data should be %d", act_L1_dist);
        	$display("your out_data is %d", out_data);
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