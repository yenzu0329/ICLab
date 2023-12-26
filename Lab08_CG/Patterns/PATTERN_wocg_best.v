/*
============================================================================

Date   : 2023/04/19
Author : EECS Lab

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Debuggging mode :
    Dump file for debugging

TODO : 
    

============================================================================
*/
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
//======================================
//          I/O PORTS
//======================================
output reg       clk;
output reg       rst_n;
output reg       in_valid;
output reg [7:0] img;
output reg [7:0] ker;
output reg [7:0] weight;

input            out_valid;
input [9:0]      out_data;

//======================================
//      PARAMETERS & VARIABLES
//======================================
// User modification
parameter PATNUM          = 10;
// parameter SIMPLE_PATNUM   = 100;
// parameter SIMPLE_MAX_VAL  = 120;
// parameter SIMPLE_MIN_VAL  = 0;
integer   SEED            = 587;
// PATTERN operation
parameter CYCLE           = `CYCLE_TIME;
parameter DELAY           = 1000;
parameter OUT_NUM         = 1;

// PATTERN CONTROL
integer       i;
integer       j;
integer       k;
integer       m;
integer    stop;
integer     pat;
integer exe_lat;
integer out_lat;
integer out_check_idx;
integer tot_lat;
integer input_delay;
integer each_delay;


// FILE CONTROL
integer file;
integer file_out;

// String control
// Should use %0s
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

reg[10*8:1] bkg_black_prefix  = "\033[40;1m";
reg[10*8:1] bkg_red_prefix    = "\033[41;1m";
reg[10*8:1] bkg_green_prefix  = "\033[42;1m";
reg[10*8:1] bkg_yellow_prefix = "\033[43;1m";
reg[10*8:1] bkg_blue_prefix   = "\033[44;1m";
reg[10*8:1] bkg_white_prefix  = "\033[47;1m";

//======================================
//      DATA MODEL
//======================================
parameter IN_BIT_WIDTH     = 8;
parameter IN_IMAGE_NUM     = 2;
parameter IN_IMAGE_SIZE    = 6;
parameter IN_KERNEL_SIZE   = 3;
parameter IN_WEIGHT_SIZE   = 2;
parameter CONV_SIZE        = IN_IMAGE_SIZE-2;
parameter MAX_POOL_SIZE    = CONV_SIZE/2;
parameter ENCODE_VEC_SIZE  = MAX_POOL_SIZE*MAX_POOL_SIZE;

parameter IN_VAL_MAX       = 2**IN_BIT_WIDTH - 1;
parameter QUAT_CONV_SCALE   = ((IN_VAL_MAX*IN_VAL_MAX)*IN_KERNEL_SIZE*IN_KERNEL_SIZE)/IN_VAL_MAX; // Convolution maximum
parameter QUAT_ENCODE_SCALE = ((IN_VAL_MAX*IN_VAL_MAX)*IN_WEIGHT_SIZE)/IN_VAL_MAX; // Matrix multiplication maximun
integer   num_idx;
integer   row_idx;
integer   col_idx;
integer   row_idx_t;
integer   col_idx_t;
integer   tmp_idx;
// input
reg[IN_BIT_WIDTH-1:0] data_input [IN_IMAGE_NUM-1:0][IN_IMAGE_SIZE-1:0][IN_IMAGE_SIZE-1:0]; // 2 input, size : 6 x 6
reg[IN_BIT_WIDTH-1:0] data_kernel[IN_KERNEL_SIZE-1:0][IN_KERNEL_SIZE-1:0]; // size : 3 x 3
reg[IN_BIT_WIDTH-1:0] data_weight[IN_WEIGHT_SIZE-1:0][IN_WEIGHT_SIZE-1:0]; // size : 2 x 2
// CNN
reg[IN_BIT_WIDTH*2+8-1:0] conv_map_before_qat[IN_IMAGE_NUM-1:0][CONV_SIZE-1:0][CONV_SIZE-1:0]; // conv = data_input (*) data_kernel
reg[IN_BIT_WIDTH-1:0]     conv_map_after_qat [IN_IMAGE_NUM-1:0][CONV_SIZE-1:0][CONV_SIZE-1:0]; // quant(conv)
reg[IN_BIT_WIDTH-1:0]     max_pool_map       [IN_IMAGE_NUM-1:0][MAX_POOL_SIZE-1:0][MAX_POOL_SIZE-1:0];
reg[IN_BIT_WIDTH*2+1-1:0] encode_before_qat  [IN_IMAGE_NUM-1:0][ENCODE_VEC_SIZE-1:0]; // encode = max_pool_map * data_weight
reg[IN_BIT_WIDTH-1:0]     encode_after_qat   [IN_IMAGE_NUM-1:0][ENCODE_VEC_SIZE-1:0]; // quant(encode)
// Encode
reg[IN_BIT_WIDTH-1+2:0]   L1_distance; // L1 distance
reg[IN_BIT_WIDTH-1+2:0]   gold_out;    // similarity score

// Convolution
integer temp_conv;
task conv_task; begin
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        for(row_idx=0 ; row_idx<CONV_SIZE ; row_idx=row_idx+1) begin
            for(col_idx=0 ; col_idx<CONV_SIZE ; col_idx=col_idx+1) begin
                temp_conv = 0;
                for(row_idx_t=0 ; row_idx_t<IN_KERNEL_SIZE ; row_idx_t=row_idx_t+1) begin
                    for(col_idx_t=0 ; col_idx_t<IN_KERNEL_SIZE ; col_idx_t=col_idx_t+1) begin
                        temp_conv = temp_conv + data_input[num_idx][row_idx+row_idx_t][col_idx+col_idx_t] * data_kernel[row_idx_t][col_idx_t];
                    end
                end
                conv_map_before_qat[num_idx][row_idx][col_idx] = temp_conv;
            end
        end
    end
end endtask

// Max pooling
integer temp_max;
task max_pool_task; begin
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        for(row_idx=0 ; row_idx<MAX_POOL_SIZE ; row_idx=row_idx+1) begin
            for(col_idx=0 ; col_idx<MAX_POOL_SIZE ; col_idx=col_idx+1) begin
                temp_max = 0;
                for(row_idx_t=0 ; row_idx_t<MAX_POOL_SIZE ; row_idx_t=row_idx_t+1) begin
                    for(col_idx_t=0 ; col_idx_t<MAX_POOL_SIZE ; col_idx_t=col_idx_t+1) begin
                        temp_max = temp_max > conv_map_after_qat[num_idx][MAX_POOL_SIZE*row_idx+row_idx_t][MAX_POOL_SIZE*col_idx+col_idx_t] ? temp_max : conv_map_after_qat[num_idx][MAX_POOL_SIZE*row_idx+row_idx_t][MAX_POOL_SIZE*col_idx+col_idx_t];
                    end
                end
                max_pool_map[num_idx][row_idx][col_idx] = temp_max;
            end
        end
    end
end endtask

// Fully connected
integer temp_full_con;
task full_con_task; begin
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        for(row_idx=0 ; row_idx<IN_WEIGHT_SIZE ; row_idx=row_idx+1) begin
            for(col_idx=0 ; col_idx<IN_WEIGHT_SIZE ; col_idx=col_idx+1) begin
                temp_full_con = 0;
                for(tmp_idx=0 ; tmp_idx<IN_WEIGHT_SIZE ; tmp_idx=tmp_idx+1) begin
                    temp_full_con = temp_full_con + max_pool_map[num_idx][row_idx][tmp_idx] * data_weight[tmp_idx][col_idx];
                end
                encode_before_qat[num_idx][row_idx*IN_WEIGHT_SIZE+col_idx] = temp_full_con;
            end
        end
    end
end endtask

// Quantization
task quant_task;
    input integer isConv;
        // isConv = 1 => convolution quantization
        // isConv = 0 => encode quantization
begin
    if(isConv == 1) begin
        for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
            for(row_idx=0 ; row_idx<CONV_SIZE ; row_idx=row_idx+1) begin
                for(col_idx=0 ; col_idx<CONV_SIZE ; col_idx=col_idx+1) begin
                    conv_map_after_qat[num_idx][row_idx][col_idx] = $floor(conv_map_before_qat[num_idx][row_idx][col_idx]/QUAT_CONV_SCALE);
                end
            end
        end
    end
    else if(isConv == 0) begin
        for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
            for(row_idx=0 ; row_idx<ENCODE_VEC_SIZE ; row_idx=row_idx+1) begin
                encode_after_qat[num_idx][row_idx] = $floor(encode_before_qat[num_idx][row_idx]/QUAT_ENCODE_SCALE);
            end
        end
    end

    else begin
        $display("[Error] Invalid quant_task input!!! Please check the flag!!!");
    end
end endtask

// L1 Distance
integer temp_L1;
task L1_dist_task; begin
    L1_distance = 0;
    for(row_idx=0 ; row_idx<ENCODE_VEC_SIZE ; row_idx=row_idx+1) begin
        temp_L1 = encode_after_qat[0][row_idx] - encode_after_qat[1][row_idx];
        temp_L1 = temp_L1 > 0 ? temp_L1 : -temp_L1;
        L1_distance = L1_distance + temp_L1;
    end
end endtask

// Activation
task acti_task; begin
    gold_out = L1_distance < 16 ? 0 : L1_distance;
end endtask

// Dump formate
reg[4*8:1] _line1  = "____";
reg[4*8:1] _space1 = "    ";
reg[7*8:1] _line2  = "_______";
reg[7*8:1] _space2 = "       ";
// Matrix Value : 
//    Index        : %2d
//    Before Quant : %3d
//    After Quant  : %6d
task dump_input_task; begin
    // [#0] **1 **2 **3
    // _________________
    //   0| **1 **2 **3
    file_out = $fopen("Input_Matrix.txt", "w");

    // Pattern info
    $fwrite(file_out, "[PAT NO. %4d]\n\n", pat);

    //------------------
    // Input Matrix
    //------------------
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[=======]\n");
    $fwrite(file_out, "[ Input ]\n");
    $fwrite(file_out, "[=======]\n\n");

    // [#0] **1 **2 **3
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "[%1d] ", num_idx);
        for(col_idx=0 ; col_idx<IN_IMAGE_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%3d ",col_idx);
        $fwrite(file_out, "%0s", _space1);
    end
    $fwrite(file_out, "\n");
    // _________________
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "%0s", _line1);
        for(col_idx=0 ; col_idx<IN_IMAGE_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%0s", _line1);
        $fwrite(file_out, "%0s", _space1);
    end
    $fwrite(file_out, "\n");
    //   0| **1 **2 **3
    for(row_idx=0 ; row_idx<IN_IMAGE_SIZE ; row_idx=row_idx+1) begin
        for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
            $fwrite(file_out, "%2d| ",row_idx);
            for(col_idx=0 ; col_idx<IN_IMAGE_SIZE ; col_idx=col_idx+1) begin
                $fwrite(file_out, "%3d ",data_input[num_idx][row_idx][col_idx]);
            end
            $fwrite(file_out, "%0s", _space1);
        end
        $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "\n");

    //------------------
    // Kernel Matrix
    //------------------
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[========]\n");
    $fwrite(file_out, "[ Kernel ]\n");
    $fwrite(file_out, "[========]\n\n");

    // [#0] **1 **2 **3
    $fwrite(file_out, "[K] ");
    for(col_idx=0 ; col_idx<IN_KERNEL_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%3d ",col_idx);
    $fwrite(file_out, "%0s", _space1);
    $fwrite(file_out, "\n");
    // _________________
    $fwrite(file_out, "%0s", _line1);
    for(col_idx=0 ; col_idx<IN_KERNEL_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%0s", _line1);
    $fwrite(file_out, "%0s", _space1);
    $fwrite(file_out, "\n");
    //   0| **1 **2 **3
    for(row_idx=0 ; row_idx<IN_KERNEL_SIZE ; row_idx=row_idx+1) begin
        $fwrite(file_out, "%2d| ",row_idx);
        for(col_idx=0 ; col_idx<IN_KERNEL_SIZE ; col_idx=col_idx+1) begin
            $fwrite(file_out, "%3d ",data_kernel[row_idx][col_idx]);
        end
        $fwrite(file_out, "%0s", _space1);
        $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "\n");

    //------------------
    // Weight Matrix
    //------------------
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[========]\n");
    $fwrite(file_out, "[ Weight ]\n");
    $fwrite(file_out, "[========]\n\n");

    // [#0] **1 **2 **3
    $fwrite(file_out, "[W] ");
    for(col_idx=0 ; col_idx<IN_WEIGHT_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%3d ",col_idx);
    $fwrite(file_out, "%0s", _space1);
    $fwrite(file_out, "\n");
    // _________________
    $fwrite(file_out, "%0s", _line1);
    for(col_idx=0 ; col_idx<IN_WEIGHT_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%0s", _line1);
    $fwrite(file_out, "%0s", _space1);
    $fwrite(file_out, "\n");
    //   0| **1 **2 **3
    for(row_idx=0 ; row_idx<IN_WEIGHT_SIZE ; row_idx=row_idx+1) begin
        $fwrite(file_out, "%2d| ",row_idx);
        for(col_idx=0 ; col_idx<IN_WEIGHT_SIZE ; col_idx=col_idx+1) begin
            $fwrite(file_out, "%3d ",data_weight[row_idx][col_idx]);
        end
        $fwrite(file_out, "%0s", _space1);
        $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "\n");

    $fclose(file_out);
end endtask

task dump_out_task; begin
    file_out = $fopen("Output.txt", "w");
    //---------------------------
    // Conv Before Quant %6d
    //---------------------------
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[===================]\n");
    $fwrite(file_out, "[ Conv Before Quant ]\n");
    $fwrite(file_out, "[===================]\n\n");

    // [#0] **1 **2 **3
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "[%1d] ", num_idx);
        for(col_idx=0 ; col_idx<CONV_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%6d ",col_idx);
        $fwrite(file_out, "%0s", _space2);
    end
    $fwrite(file_out, "\n");
    // _________________
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "%0s", _line1);
        for(col_idx=0 ; col_idx<CONV_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%0s", _line2);
        $fwrite(file_out, "%0s", _space2);
    end
    $fwrite(file_out, "\n");
    //   0| **1 **2 **3
    for(row_idx=0 ; row_idx<CONV_SIZE ; row_idx=row_idx+1) begin
        for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
            $fwrite(file_out, "%2d| ",row_idx);
            for(col_idx=0 ; col_idx<CONV_SIZE ; col_idx=col_idx+1) begin
                $fwrite(file_out, "%6d ",conv_map_before_qat[num_idx][row_idx][col_idx]);
            end
            $fwrite(file_out, "%0s", _space2);
        end
        $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "\n");

    //---------------------------
    // Conv After Quant %3d
    //---------------------------
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[==================]\n");
    $fwrite(file_out, "[ Conv After Quant ]\n");
    $fwrite(file_out, "[==================]\n\n");

    // [#0] **1 **2 **3
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "[%1d] ", num_idx);
        for(col_idx=0 ; col_idx<CONV_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%6d ",col_idx);
        $fwrite(file_out, "%0s", _space2);
    end
    $fwrite(file_out, "\n");
    // _________________
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "%0s", _line1);
        for(col_idx=0 ; col_idx<CONV_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%0s", _line2);
        $fwrite(file_out, "%0s", _space2);
    end
    $fwrite(file_out, "\n");
    //   0| **1 **2 **3
    for(row_idx=0 ; row_idx<CONV_SIZE ; row_idx=row_idx+1) begin
        for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
            $fwrite(file_out, "%2d| ",row_idx);
            for(col_idx=0 ; col_idx<CONV_SIZE ; col_idx=col_idx+1) begin
                $fwrite(file_out, "%6d ",conv_map_after_qat[num_idx][row_idx][col_idx]);
            end
            $fwrite(file_out, "%0s", _space2);
        end
        $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "\n");

    //---------------------------
    // Max pool %3d
    //---------------------------
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[===================]\n");
    $fwrite(file_out, "[    Max Pooling    ]\n");
    $fwrite(file_out, "[===================]\n\n");

    // [#0] **1 **2 **3
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "[%1d] ", num_idx);
        for(col_idx=0 ; col_idx<MAX_POOL_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%3d ",col_idx);
        $fwrite(file_out, "%0s", _space1);
    end
    $fwrite(file_out, "\n");
    // _________________
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "%0s", _line1);
        for(col_idx=0 ; col_idx<MAX_POOL_SIZE ; col_idx=col_idx+1) $fwrite(file_out, "%0s", _line1);
        $fwrite(file_out, "%0s", _space1);
    end
    $fwrite(file_out, "\n");
    //   0| **1 **2 **3
    for(row_idx=0 ; row_idx<MAX_POOL_SIZE ; row_idx=row_idx+1) begin
        for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
            $fwrite(file_out, "%2d| ",row_idx);
            for(col_idx=0 ; col_idx<MAX_POOL_SIZE ; col_idx=col_idx+1) begin
                $fwrite(file_out, "%3d ",max_pool_map[num_idx][row_idx][col_idx]);
            end
            $fwrite(file_out, "%0s", _space1);
        end
        $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "\n");

    //---------------------------
    // Fully Connected %6d
    // (Encoding Before Quant)
    //---------------------------
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[=====================]\n");
    $fwrite(file_out, "[ Encode Before Quant ]\n");
    $fwrite(file_out, "[=====================]\n\n");

    // [#0] **1 **2 **3
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "[%1d] ", num_idx);
        for(col_idx=0 ; col_idx<1 ; col_idx=col_idx+1) $fwrite(file_out, "%6d ",col_idx);
        $fwrite(file_out, "%0s", _space2);
    end
    $fwrite(file_out, "\n");
    // _________________
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "%0s", _line1);
        for(col_idx=0 ; col_idx<1 ; col_idx=col_idx+1) $fwrite(file_out, "%0s", _line2);
        $fwrite(file_out, "%0s", _space2);
    end
    $fwrite(file_out, "\n");
    //   0| **1 **2 **3
    for(row_idx=0 ; row_idx<ENCODE_VEC_SIZE ; row_idx=row_idx+1) begin
        for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
            $fwrite(file_out, "%2d| ",row_idx);
            $fwrite(file_out, "%6d ",encode_before_qat[num_idx][row_idx]);
            $fwrite(file_out, "%0s", _space2);
        end
        $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "\n");

    //---------------------------
    // Encoding After Quant %3d
    //---------------------------
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[====================]\n");
    $fwrite(file_out, "[ Encode After Quant ]\n");
    $fwrite(file_out, "[====================]\n\n");

    // [#0] **1 **2 **3
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "[%1d] ", num_idx);
        for(col_idx=0 ; col_idx<1 ; col_idx=col_idx+1) $fwrite(file_out, "%6d ",col_idx);
        $fwrite(file_out, "%0s", _space2);
    end
    $fwrite(file_out, "\n");
    // _________________
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        $fwrite(file_out, "%0s", _line1);
        for(col_idx=0 ; col_idx<1 ; col_idx=col_idx+1) $fwrite(file_out, "%0s", _line2);
        $fwrite(file_out, "%0s", _space2);
    end
    $fwrite(file_out, "\n");
    //   0| **1 **2 **3
    for(row_idx=0 ; row_idx<ENCODE_VEC_SIZE ; row_idx=row_idx+1) begin
        for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
            $fwrite(file_out, "%2d| ",row_idx);
            $fwrite(file_out, "%6d ",encode_after_qat[num_idx][row_idx]);
            $fwrite(file_out, "%0s", _space2);
        end
        $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "\n");

    //---------------------------
    // L1 Distance Value
    //---------------------------
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[==================]\n");
    $fwrite(file_out, "[    L1 Distance   ]\n");
    $fwrite(file_out, "[==================]\n\n");
    $fwrite(file_out, "[ %4d ]\n", L1_distance);

    //---------------------------
    // Similarity Score
    //---------------------------
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[==================]\n");
    $fwrite(file_out, "[ Similarity Score ]\n");
    $fwrite(file_out, "[==================]\n\n");
    $fwrite(file_out, "[ %4d ]\n", gold_out);

    $fclose(file_out);
end endtask

//======================================
//      MAIN
//======================================
initial exe_task;

//======================================
//      CLOCK
//======================================
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;

//======================================
//              TASKS
//======================================
task exe_task; begin
    reset_task;
    for (pat=0 ; pat<PATNUM ; pat=pat+1) begin
        input_task;
        cal_task;
        wait_task;
        check_task;
        $display("%0sPASS PATTERN NO.%4d, %0sCycles: %3d%0s",txt_blue_prefix, pat, txt_green_prefix, exe_lat, reset_color);
    end
    $finish;
    // pass_task;
end endtask

//**************************************
//      Reset Task
//**************************************
task reset_task; begin

    force clk = 0;
    rst_n     = 1;
    in_valid  = 0;
    img       = 'dx;
    ker       = 'dx;
    weight    = 'dx;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if(out_valid !== 0 || out_data !== 0) begin
        $display("                                           `:::::`                                                       ");
        $display("                                          .+-----++                                                      ");
        $display("                .--.`                    o:------/o                                                      ");
        $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
        $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
        $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
        $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
        $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
        $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
        $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
        $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
        $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
        $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
        $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
        $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
        $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
        $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
        $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
        $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
        $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
        $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
        $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
        $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
        $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
        $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
        $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
        $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
        $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     after the reset signal is asserted");
        $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
        $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
        $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
        $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
        $display("                       `s--------------------------::::::::-----:o                                       ");
        $display("                       +:----------------------------------------y`                                      ");
        repeat(5) #(CYCLE);
        $finish;
    end
    #(CYCLE/2.0) release clk;
end endtask

//**************************************
//      Input Task
//**************************************
integer input_max_val;
integer input_min_val;
integer cnt_temp;
task input_task; begin
    repeat(({$random(SEED)} % 4 + 2)) @(negedge clk);
    // if(pat < SIMPLE_PATNUM) begin
    //     input_max_val = SIMPLE_MAX_VAL;
    //     input_min_val = SIMPLE_MIN_VAL;
    //     // $display("[Info] Current pat is simple value : %d ~ %d", input_min_val, input_max_val);
    // end
    // else begin
    //     input_max_val = IN_VAL_MAX;
    //     input_min_val = 0;
    //     // $display("[Info] Current pat is full value   : %d ~ %d", input_min_val, input_max_val);
    // end

    input_max_val = IN_VAL_MAX;
    input_min_val = 0;

    // Randomize input
    // Input
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        for(row_idx=0 ; row_idx<IN_IMAGE_SIZE ; row_idx=row_idx+1) begin
            for(col_idx=0 ; col_idx<IN_IMAGE_SIZE ; col_idx=col_idx+1) begin
                data_input[num_idx][row_idx][col_idx] = {$random(SEED)} % (input_max_val - input_min_val + 1) + input_min_val;
            end
        end
    end
    // Kernel
    for(row_idx=0 ; row_idx<IN_KERNEL_SIZE ; row_idx=row_idx+1) begin
        for(col_idx=0 ; col_idx<IN_KERNEL_SIZE ; col_idx=col_idx+1) begin
            data_kernel[row_idx][col_idx] = {$random(SEED)} % (input_max_val - input_min_val + 1) + input_min_val;
        end
    end
    // Weight
    for(row_idx=0 ; row_idx<IN_WEIGHT_SIZE ; row_idx=row_idx+1) begin
        for(col_idx=0 ; col_idx<IN_WEIGHT_SIZE ; col_idx=col_idx+1) begin
            data_weight[row_idx][col_idx] = {$random(SEED)} % (input_max_val - input_min_val + 1) + input_min_val;
        end
    end

    // Send input
    cnt_temp = 0;
    for(num_idx=0 ; num_idx<IN_IMAGE_NUM ; num_idx=num_idx+1) begin
        for(row_idx=0 ; row_idx<IN_IMAGE_SIZE ; row_idx=row_idx+1) begin
            for(col_idx=0 ; col_idx<IN_IMAGE_SIZE ; col_idx=col_idx+1) begin
                in_valid = 1;
                img = data_input[num_idx][row_idx][col_idx];
                if(cnt_temp < IN_KERNEL_SIZE*IN_KERNEL_SIZE) ker = data_kernel[cnt_temp/IN_KERNEL_SIZE][cnt_temp%IN_KERNEL_SIZE];
                if(cnt_temp < IN_WEIGHT_SIZE*IN_WEIGHT_SIZE) weight = data_weight[cnt_temp/IN_WEIGHT_SIZE][cnt_temp%IN_WEIGHT_SIZE];
                @(negedge clk);
                in_valid = 0;
                img = 'dx;
                ker = 'dx;
                weight = 'dx;

                cnt_temp = cnt_temp + 1;
            end
        end
    end
end endtask

//**************************************
//      Calculation Task
//**************************************
task cal_task; begin
    conv_task;
    quant_task(1);
    max_pool_task;
    full_con_task;
    quant_task(0);
    L1_dist_task;
    acti_task;
    dump_input_task;
    dump_out_task;
end endtask

//**************************************
//      Wait Task
//**************************************
task wait_task; begin
    exe_lat = -1;
    while(out_valid !== 1) begin
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");
            $display("                                `:/:-:::/-                              ");
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             "); 
            $display("                                +-:////+s/::--..                        ");
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);
            $display("    is over %8d cycles   `:::--:/++:----------::/:.                ", DELAY);
            $display("                            -+:--:++////-------------::/-               ");
            $display("                            .+---------------------------:/--::::::.`   ");
            $display("                          `.+-----------------------------:o/------::.  ");
            $display("                       .-::-----------------------------:--:o:-------:  ");
            $display("                     -:::--------:/yy------------------/y/--/o------/-  ");
            $display("                    /:-----------:+y+:://:--------------+y--:o//:://-   ");
            $display("                   //--------------:-:+ssoo+/------------s--/. ````     ");
            $display("                   o---------:/:------dNNNmds+:----------/-//           ");
            $display("                   s--------/o+:------yNNNNNd/+--+y:------/+            ");
            $display("                 .-y---------o:-------:+sso+/-:-:yy:------o`            ");
            $display("              `:oosh/--------++-----------------:--:------/.            ");
            $display("              +ssssyy--------:y:---------------------------/            ");
            $display("              +ssssyd/--------/s/-------------++-----------/`           ");
            $display("              `/yyssyso/:------:+o/::----:::/+//:----------+`           ");
            $display("             ./osyyyysssso/------:/++o+++///:-------------/:            ");
            $display("           -osssssssssssssso/---------------------------:/.             ");
            $display("         `/sssshyssssssssssss+:---------------------:/+ss               ");
            $display("        ./ssssyysssssssssssssso:--------------:::/+syyys+               ");
            $display("     `-+sssssyssssssssssssssssso-----::/++ooooossyyssyy:                ");
            $display("     -syssssyssssssssssssssssssso::+ossssssssssssyyyyyss+`              ");
            $display("     .hsyssyssssssssssssssssssssyssssssssssyhhhdhhsssyssso`             ");
            $display("     +/yyshsssssssssssssssssssysssssssssyhhyyyyssssshysssso             ");
            $display("    ./-:+hsssssssssssssssssssssyyyyyssssssssssssssssshsssss:`           ");
            $display("    /---:hsyysyssssssssssssssssssssssssssssssssssssssshssssy+           ");
            $display("    o----oyy:-:/+oyysssssssssssssssssssssssssssssssssshssssy+-          ");
            $display("    s-----++-------/+sysssssssssssssssssssssssssssssyssssyo:-:-         ");
            $display("    o/----s-----------:+syyssssssssssssssssssssssyso:--os:----/.        ");
            $display("    `o/--:o---------------:+ossyysssssssssssyyso+:------o:-----:        ");
            $display("      /+:/+---------------------:/++ooooo++/:------------s:---::        ");
            $display("       `/o+----------------------------------------------:o---+`        ");
            $display("         `+-----------------------------------------------o::+.         ");
            $display("          +-----------------------------------------------/o/`          ");
            $display("          ::----------------------------------------------:-            ");
            repeat(5) @(negedge clk);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        @(negedge clk);
    end
end endtask

//**************************************
//      Check Task
//**************************************task check_task; begin
task check_task; begin
    out_lat = 0;
    while(out_valid === 1) begin
        if(out_lat == OUT_NUM) begin
            $display("                                                                                ");
            $display("                                                   ./+oo+/.                     ");
            $display("    Out cycles is more than %-2d                    /s:-----+s`     at %-12d ps ", OUT_NUM, $time*1000);
            $display("                                                  y/-------:y                   ");
            $display("                                             `.-:/od+/------y`                  ");
            $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
            $display("                              -m+:::::::---------------------::o+.              ");
            $display("                             `hod-------------------------------:o+             ");
            $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
            $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
            $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
            $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
            $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
            $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
            $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
            $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
            $display("                 s:----------------/s+///------------------------------o`       ");
            $display("           ``..../s------------------::--------------------------------o        ");
            $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
            $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
            $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
            $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
            $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
            $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
            $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
            $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
            $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
            $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
            $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
            $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
            $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
            $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
            $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
            $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
            $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
            $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
            $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
            $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
            $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
            $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
            $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   ");
            repeat(5) @(negedge clk);
            $finish;
        end
        //====================
        // Check
        //====================
        if(gold_out !== out_data) begin
            $display("                                                                                ");
            $display("                                                   ./+oo+/.                     ");
            $display("    Output is not correct!!!                      /s:-----+s`     at %-12d ps   ", $time*1000);
            $display("                                                  y/-------:y                   ");
            $display("                                             `.-:/od+/------y`                  ");
            $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
            $display("                              -m+:::::::---------------------::o+.              ");
            $display("                             `hod-------------------------------:o+             ");
            $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
            $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
            $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
            $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
            $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
            $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
            $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
            $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
            $display("                 s:----------------/s+///------------------------------o`       ");
            $display("           ``..../s------------------::--------------------------------o        ");
            $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
            $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
            $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
            $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
            $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
            $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
            $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
            $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
            $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
            $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
            $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
            $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
            $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
            $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
            $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
            $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
            $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
            $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
            $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
            $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
            $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
            $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
            $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
            $display("[Info] Dump debugging file...");
            $display("[Info] Your   similarity score : %4d", out_data);
            $display("[Info] Golden similarity score : %4d\n", gold_out);
            repeat(5) @(negedge clk);
            $finish;
        end

        out_lat = out_lat + 1;
        @(negedge clk);
    end

    if (out_lat<OUT_NUM) begin     
        $display("                                                                                ");
        $display("                                                   ./+oo+/.                     ");
        $display("    Out cycles is less than %-2d                    /s:-----+s`     at %-12d ps ", OUT_NUM, $time*1000);
        $display("                                                  y/-------:y                   ");
        $display("                                             `.-:/od+/------y`                  ");
        $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
        $display("                              -m+:::::::---------------------::o+.              ");
        $display("                             `hod-------------------------------:o+             ");
        $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
        $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
        $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
        $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
        $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
        $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
        $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
        $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
        $display("                 s:----------------/s+///------------------------------o`       ");
        $display("           ``..../s------------------::--------------------------------o        ");
        $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
        $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
        $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
        $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
        $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
        $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
        $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
        $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
        $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
        $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
        $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
        $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
        $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
        $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
        $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
        $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
        $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
        $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
        $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
        $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
        $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
        $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
        $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
        repeat(5) @(negedge clk);
        $finish;
    end
    tot_lat = tot_lat + exe_lat;
end endtask

//**************************************
//      PASS Task
//**************************************
task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulation!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o             \033[1;35m Total Latency : %-10d\033[1;0m                                ", tot_lat);
    $display("\033[1;33m              o+------/y--::::::+oso+:/y                                                                                     ");
    $display("\033[1;33m              s/-----:/:----------:+ooy+-                                                                                    ");
    $display("\033[1;33m             /o----------------/yhyo/::/o+/:-.`                                                                              ");
    $display("\033[1;33m            `ys----------------:::--------:::+yyo+                                                                           ");
    $display("\033[1;33m            .d/:-------------------:--------/--/hos/                                                                         ");
    $display("\033[1;33m            y/-------------------::ds------:s:/-:sy-                                                                         ");
    $display("\033[1;33m           +y--------------------::os:-----:ssm/o+`                                                                          ");
    $display("\033[1;33m          `d:-----------------------:-----/+o++yNNmms                                                                        ");
    $display("\033[1;33m           /y-----------------------------------hMMMMN.                                                                      ");
    $display("\033[1;33m           o+---------------------://:----------:odmdy/+.                                                                    ");
    $display("\033[1;33m           o+---------------------::y:------------::+o-/h                                                                    ");
    $display("\033[1;33m           :y-----------------------+s:------------/h:-:d                                                                    ");
    $display("\033[1;33m           `m/-----------------------+y/---------:oy:--/y                                                                    ");
    $display("\033[1;33m            /h------------------------:os++/:::/+o/:--:h-                                                                    ");
    $display("\033[1;33m         `:+ym--------------------------://++++o/:---:h/                                                                     ");
    $display("\033[1;31m        `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
    $display("\033[1;31m         shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
    $display("\033[1;31m         .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
    $display("\033[1;31m        `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
    $display("\033[1;31m        -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
    $display("\033[1;31m         hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
    $display("\033[1;31m         `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
    $display("\033[1;31m          dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
    $display("\033[1;31m         :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
    $display("\033[1;31m        /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
    $display("\033[1;31m      +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
    $display("\033[1;31m      -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
    $display("\033[1;31m       `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
    $display("\033[1;31m         os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
    $display("\033[1;33m         h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
    $display("\033[1;33m         m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
    $display("\033[1;33m        `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
    $display("\033[1;33m        .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
    $display("\033[1;33m        +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
    $display("\033[1;33m        h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
    $display("\033[1;33m       `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
    $display("\033[1;33m    `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
    $display("\033[1;33m   -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
    $display("\033[1;33m   s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
    $display("\033[1;33m   o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
    $display("\033[1;33m    :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
    $display("\033[1;33m       .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
    $display("\033[1;33m                                          `:+omy/---------------------+h:----:y+//so                                         ");
    $display("\033[1;33m                                              `-ys:-------------------+s-----+s///om                                         ");
    $display("\033[1;33m                                                 -os+::---------------/y-----ho///om                                         ");
    $display("\033[1;33m                                                    -+oo//:-----------:h-----h+///+d                                         ");
    $display("\033[1;33m                                                       `-oyy+:---------s:----s/////y                                         ");
    $display("\033[1;33m                                                           `-/o+::-----:+----oo///+s                                         ");
    $display("\033[1;33m                                                               ./+o+::-------:y///s:                                         ");
    $display("\033[1;33m                                                                   ./+oo/-----oo/+h                                          ");
    $display("\033[1;33m                                                                       `://++++syo`                                          ");
    $display("\033[1;0m"); 
    repeat(5) @(negedge clk);
    $finish;
end endtask

endmodule