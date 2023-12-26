//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      (C) Copyright NCTU OASIS Lab      
//            All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2022 ICLAB fall Course
//   Lab05          : SRAM, Matrix Multiplication with Systolic Array
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
/*
============================================================================

Date   : 2023/03/22
Author : EECS Lab

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Debuggging mode :
    Dump file for Debuging

Reference :
    

TO DO :
    Matrix operation
    Dump debugging files
    Check 
============================================================================
*/

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
//======================================
//          I/O PORTS
//======================================
output reg                clk;
output reg              rst_n;
output reg           in_valid;
output reg          in_valid2;
output reg [7:0]       matrix;
output reg [1:0]  matrix_size;
output reg [1:0]         mode;
output reg [4:0]   matrix_idx;

input               out_valid;
input signed [49:0] out_value;

//======================================
//      PARAMETERS & VARIABLES
//======================================
parameter PATNUM          = 1;
parameter CYCLE           = `CYCLE_TIME;
parameter DELAY           = 10000;
parameter OUT_NUM         = 1;
parameter MATRIX_NUM      = 32;
parameter MATRIX_IDX_NUM  = 3;
parameter MATRIX_CAL_NUM  = 10;
parameter MATRIX_MAX_SIZE = 16;
parameter EACH_ROW_MATRIX = 4; // for dump file
integer   SEED            = 122;

// PATTERN CONTROL
integer       i;
integer       j;
integer       k;
integer       m;
integer    stop;
integer     pat;
integer exe_lat;
integer out_lat;
integer tot_lat;

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
integer          vvMatrix[MATRIX_NUM-1:0][MATRIX_MAX_SIZE-1:0][MATRIX_MAX_SIZE-1:0]; // MATRIX_NUM x (nSize by nSize)
integer          vvIdx[MATRIX_CAL_NUM-1:0][MATRIX_IDX_NUM-1:0]; // Decide which matrix will do calculation
integer          vMode[MATRIX_CAL_NUM-1:0]; // Calculation mode
integer          nSize; // 2x2, 4x4, 8x8, 16x16
integer          itCalc; // Calculate matrix ten times

integer          vvCalcMatrix[MATRIX_CAL_NUM-1:0][MATRIX_IDX_NUM-1:0][MATRIX_MAX_SIZE-1:0][MATRIX_MAX_SIZE-1:0]; // Record the matrix before operation, after transpose (if it is needed)
integer          vvGoldMatrix[MATRIX_CAL_NUM-1:0][MATRIX_IDX_NUM-1:1][MATRIX_MAX_SIZE-1:0][MATRIX_MAX_SIZE-1:0]; // Record the matrix after  operation
reg signed[49:0] goldTrace   [MATRIX_CAL_NUM-1:0]; // Gold trace value
integer          idxN, idxM, idxR, idxC;

integer vvTempMatrix[MATRIX_MAX_SIZE-1:0][MATRIX_MAX_SIZE-1:0];
task transpose_matrix;
    input integer isTranspose;   // Transpose or not
    input integer iter;          // Iteration of calculation
    input integer idxCalcMatrix; // Index of calculation matrix
    input integer idxMatrix;     // Index of original matrix
begin
    if(isTranspose) begin
        for (idxR=0 ; idxR<nSize ; idxR=idxR+1)
            for (idxC=0 ; idxC<nSize ; idxC=idxC+1)
                vvCalcMatrix[iter][idxCalcMatrix][idxC][idxR] = vvMatrix[idxMatrix][idxR][idxC];
    end
    else begin
        for (idxR=0 ; idxR<nSize ; idxR=idxR+1)
            for (idxC=0; idxC<nSize ; idxC=idxC+1)
                vvCalcMatrix[iter][idxCalcMatrix][idxR][idxC] = vvMatrix[idxMatrix][idxR][idxC];
    end
end endtask

integer itMult;
task multiple_matrix;
    input integer iter;          // Iteration of calculation
    input integer idxCalcMatrix; // Index of calculation matrix
begin
    for (idxR=0 ; idxR<nSize ; idxR=idxR+1)
        for (idxC=0; idxC<nSize ; idxC=idxC+1)
            for (itMult=0; itMult<nSize ; itMult=itMult+1) begin
                if(idxCalcMatrix == 1)
                    vvGoldMatrix[iter][idxCalcMatrix][idxR][idxC] = vvGoldMatrix[iter][idxCalcMatrix][idxR][idxC] +  vvCalcMatrix[iter][idxCalcMatrix-1][idxR][itMult]*vvCalcMatrix[iter][idxCalcMatrix][itMult][idxC];
                else
                    vvGoldMatrix[iter][idxCalcMatrix][idxR][idxC] = vvGoldMatrix[iter][idxCalcMatrix][idxR][idxC] +  vvGoldMatrix[iter][idxCalcMatrix-1][idxR][itMult]*vvCalcMatrix[iter][idxCalcMatrix][itMult][idxC];
            end
end endtask

reg[MATRIX_IDX_NUM-1:0] modeFlag;
task run_main; begin
    // Reset the output
    for(idxN=0 ; idxN<MATRIX_CAL_NUM ; idxN=idxN+1) begin
        // Before calculation
        for(idxM=0 ; idxM<MATRIX_IDX_NUM ; idxM=idxM+1)
            for (idxR=0 ; idxR<MATRIX_MAX_SIZE ; idxR=idxR+1)
                for (idxC=0; idxC<MATRIX_MAX_SIZE ; idxC=idxC+1)
                    vvCalcMatrix[idxN][idxM][idxR][idxC] = 0;

        // After calculation
        for(idxM=1 ; idxM<MATRIX_IDX_NUM ; idxM=idxM+1)
            for (idxR=0 ; idxR<MATRIX_MAX_SIZE ; idxR=idxR+1)
                for (idxC=0; idxC<MATRIX_MAX_SIZE ; idxC=idxC+1)
                    vvGoldMatrix[idxN][idxM][idxR][idxC] = 0;

        // trace
        goldTrace[idxN] = 0;
    end
    for(idxN=0 ; idxN<MATRIX_CAL_NUM ; idxN=idxN+1) begin
        // Transpose
        case(vMode[idxN])
            2'b00: modeFlag = 3'b000;
            2'b01: modeFlag = 3'b001;
            2'b10: modeFlag = 3'b010;
            2'b11: modeFlag = 3'b100;
        endcase
        for(idxM=0 ; idxM<MATRIX_IDX_NUM ; idxM=idxM+1)
            transpose_matrix(modeFlag[idxM], idxN, idxM, vvIdx[idxN][idxM]);
        
        // Multiplication
        for(idxM=1 ; idxM<MATRIX_IDX_NUM ; idxM=idxM+1)
            multiple_matrix(idxN, idxM);
        
        // Calculate the trace
        for (idxR=0 ; idxR<nSize ; idxR=idxR+1)
            goldTrace[idxN] = goldTrace[idxN] + vvGoldMatrix[idxN][MATRIX_IDX_NUM-1][idxR][idxR];
    end
end endtask

integer dump_temp;
task dump_matrix; begin
    file_out = $fopen("Input_Matrix.txt", "w");

    // Pattern info
    $fwrite(file_out, "[PAT NO. %4d]\n\n", pat);
    $fwrite(file_out, "[Matrix size : %-2d]\n\n", nSize);

    // Matrix operation
    $fwrite(file_out, "[================]\n");
    $fwrite(file_out, "[Matrix Operation]\n");
    $fwrite(file_out, "[================]\n\n");
    $fwrite(file_out, "    idx1  idx2  idx3  mode\n");
    for(idxN=0 ; idxN<MATRIX_CAL_NUM ; idxN=idxN+1) begin
        $fwrite(file_out, "%-1d   ", idxN);
        for(idxR=0 ; idxR<MATRIX_IDX_NUM ; idxR=idxR+1) begin
            $fwrite(file_out, "%-5d ", vvIdx[idxN][idxR]);
        end
        case(vMode[idxN])
            2'b00: $fwrite(file_out, "ABC  ");
            2'b01: $fwrite(file_out, "A'BC ");
            2'b10: $fwrite(file_out, "AB'C ");
            2'b11: $fwrite(file_out, "ABC' ");
        endcase
        $fwrite(file_out, "(%-1d)\n", vMode[idxN]);
    end

    // Original matrix
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[======]\n");
    $fwrite(file_out, "[Matrix]\n");
    $fwrite(file_out, "[======]\n\n");
    /*
    for(idxN=0 ; idxN<MATRIX_NUM ; idxN=idxN+1) begin
        $fwrite(file_out, "[%2d] ",idxN);
        for(idxC=0 ; idxC<nSize ; idxC=idxC+1) $fwrite(file_out, "%4d ",idxC);
        $fwrite(file_out, "\n");
        $fwrite(file_out, "_____");
        for(idxC=0 ; idxC<nSize ; idxC=idxC+1) $fwrite(file_out, "_____");
        $fwrite(file_out, "\n");
        for(idxR=0 ; idxR<nSize ; idxR=idxR+1) begin
            $fwrite(file_out, "%3d| ",idxR);
            for(idxC=0 ; idxC<nSize ; idxC=idxC+1) begin
                $fwrite(file_out, "%4d ",vvMatrix[idxN][idxR][idxC]);
            end
            $fwrite(file_out, "\n");
        end
        $fwrite(file_out, "\n");
    end
    */
    if(MATRIX_NUM%EACH_ROW_MATRIX !== 0) dump_temp = 4;
    else                                 dump_temp = EACH_ROW_MATRIX;
    for(idxM=0 ; idxM<MATRIX_NUM/dump_temp ; idxM=idxM+1) begin
        // Column index
        for(idxN=0 ; idxN<dump_temp ; idxN=idxN+1) begin
            $fwrite(file_out, "[%2d] ",idxM*dump_temp+idxN);
            for(idxC=0 ; idxC<nSize ; idxC=idxC+1) $fwrite(file_out, "%4d ",idxC);
            $fwrite(file_out, "     ");
        end
        $fwrite(file_out, "\n");
        for(idxN=0 ; idxN<dump_temp ; idxN=idxN+1) begin
            $fwrite(file_out, "_____");
            for(idxC=0 ; idxC<nSize ; idxC=idxC+1) $fwrite(file_out, "_____");
            $fwrite(file_out, "     ");
        end
        $fwrite(file_out, "\n");

        for(idxR=0 ; idxR<nSize ; idxR=idxR+1) begin
            for(idxN=0 ; idxN<dump_temp ; idxN=idxN+1) begin
                $fwrite(file_out, "%3d| ",idxR);
                for(idxC=0 ; idxC<nSize ; idxC=idxC+1) begin
                    $fwrite(file_out, "%4d ",vvMatrix[idxM*dump_temp+idxN][idxR][idxC]);
                end
                $fwrite(file_out, "     ");
            end
            $fwrite(file_out, "\n");
        end
        $fwrite(file_out, "\n");
    end
    $fclose(file_out);

    file_out = $fopen("Output_Matrix.txt", "w");
    // Matrix before calculation
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[=========================]\n");
    $fwrite(file_out, "[Matrix Before Calculation]\n");
    $fwrite(file_out, "[=========================]\n\n");
    for(idxM=0 ; idxM<MATRIX_CAL_NUM ; idxM=idxM+1) begin
        $fwrite(file_out, "[%1d Calculation]  ", idxM);
        case(vMode[idxM])
            2'b00: $fwrite(file_out, "ABC  ");
            2'b01: $fwrite(file_out, "A'BC ");
            2'b10: $fwrite(file_out, "AB'C ");
            2'b11: $fwrite(file_out, "ABC' ");
        endcase
        $fwrite(file_out, "(%-1d)\n", vMode[idxM]);
        $fwrite(file_out, "Index : [ ");
        for(idxN=0 ; idxN<MATRIX_IDX_NUM ; idxN=idxN+1) begin
            $fwrite(file_out, "%-3d, ", vvIdx[idxM][idxN]);
        end
        $fwrite(file_out, "]\n\n");

        // Column index
        for(idxN=0 ; idxN<MATRIX_IDX_NUM ; idxN=idxN+1) begin
            $fwrite(file_out, "[%2d] ",idxN);
            for(idxC=0 ; idxC<nSize ; idxC=idxC+1) $fwrite(file_out, "%4d ",idxC);
            $fwrite(file_out, "     ");
        end
        $fwrite(file_out, "\n");
        for(idxN=0 ; idxN<MATRIX_IDX_NUM ; idxN=idxN+1) begin
            $fwrite(file_out, "_____");
            for(idxC=0 ; idxC<nSize ; idxC=idxC+1) $fwrite(file_out, "_____");
            $fwrite(file_out, "     ");
        end
        $fwrite(file_out, "\n");

        for(idxR=0 ; idxR<nSize ; idxR=idxR+1) begin
            for(idxN=0 ; idxN<MATRIX_IDX_NUM ; idxN=idxN+1) begin
                $fwrite(file_out, "%3d| ",idxR);
                for(idxC=0 ; idxC<nSize ; idxC=idxC+1) begin
                    $fwrite(file_out, "%4d ",vvCalcMatrix[idxM][idxN][idxR][idxC]);
                end
                $fwrite(file_out, "     ");
            end
            $fwrite(file_out, "\n");
        end
        $fwrite(file_out, "\n");
    end

    // Matrix after calculation
    $fwrite(file_out, "\n");
    $fwrite(file_out, "[========================]\n");
    $fwrite(file_out, "[Matrix after Calculation]\n");
    $fwrite(file_out, "[========================]\n\n");
    for(idxM=0 ; idxM<MATRIX_CAL_NUM ; idxM=idxM+1) begin
        $fwrite(file_out, "[%1d Calculation] ", idxM);
        $fwrite(file_out, " Gold trace : %16d\n\n", goldTrace[idxM]);
        // Column index
        for(idxN=0 ; idxN<MATRIX_IDX_NUM ; idxN=idxN+1) begin
            $fwrite(file_out, "[%8d] ",idxN);
            for(idxC=0 ; idxC<nSize ; idxC=idxC+1) $fwrite(file_out, "%10d ",idxC);
            $fwrite(file_out, "   ");
        end
        $fwrite(file_out, "\n");
        for(idxN=0 ; idxN<MATRIX_IDX_NUM ; idxN=idxN+1) begin
            $fwrite(file_out, "___________");
            for(idxC=0 ; idxC<nSize ; idxC=idxC+1) $fwrite(file_out, "___________");
            $fwrite(file_out, "   ");
        end
        $fwrite(file_out, "\n");

        for(idxR=0 ; idxR<nSize ; idxR=idxR+1) begin
            for(idxN=0 ; idxN<MATRIX_IDX_NUM ; idxN=idxN+1) begin
                $fwrite(file_out, "%9d| ",idxR);
                for(idxC=0 ; idxC<nSize ; idxC=idxC+1) begin
                    if(idxN==0) $fwrite(file_out, "           ");
                    else        $fwrite(file_out, "%10d ",vvGoldMatrix[idxM][idxN][idxR][idxC]);
                end
                $fwrite(file_out, "   ");
            end
            $fwrite(file_out, "\n");
        end
        $fwrite(file_out, "\n");
    end
    $fclose(file_out);
end endtask


//======================================
//              MAIN
//======================================
initial exe_task;

//======================================
//              Clock
//======================================
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;

//======================================
//              TASKS
//======================================
task exe_task; begin
    reset_task;
    for (pat=0 ; pat<PATNUM ; pat=pat+1) begin
        random_input_task;
        for(itCalc=0 ; itCalc<MATRIX_CAL_NUM ; itCalc=itCalc+1) begin
            input_task;
            cal_task;
            wait_task;
            check_task;
            // Print Pass Info and accumulate the total latency
            $display("%0sPASS PATTERN NO.%4d-%2d, %0sCycles: %3d%0s",txt_blue_prefix, pat, itCalc, txt_green_prefix, exe_lat, reset_color);
        end
    end
    pass_task;
end endtask

//**************************************
//      Reset Task
//**************************************
task reset_task; begin

    force clk   = 0;
    rst_n       = 1;
    in_valid    = 0;
    in_valid2   = 0;
    matrix      = 'dx;
    matrix_size = 'dx;
    mode        = 'dx;
    matrix_idx  = 'dx;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if(out_valid !== 0 || out_value !== 0) begin
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
//      Random Input Task
//**************************************
task random_input_task; begin
    // Random size
    nSize = 0;
    nSize = 2**({$random(SEED)} % 4 + 1);
    // $display("[Info] size : %d", nSize);

    // Random new set of matrix
    for(idxN=0 ; idxN<MATRIX_NUM ; idxN=idxN+1) begin
        for(idxR=0 ; idxR<nSize ; idxR=idxR+1) begin
            for(idxC=0 ; idxC<nSize ; idxC=idxC+1) begin
                if(pat < 10) vvMatrix[idxN][idxR][idxC] = $random(SEED) % 11; // simple
                else         vvMatrix[idxN][idxR][idxC] = {$random(SEED)} % 256 - 128;
            end
        end
    end

    // Random operation
    for(idxN=0 ; idxN<MATRIX_CAL_NUM ; idxN=idxN+1) begin
        vMode[idxN] = {$random(SEED)} % 4;
    end

    // Random index of matrix
    for(idxN=0 ; idxN<MATRIX_CAL_NUM ; idxN=idxN+1) begin
        for(idxR=0 ; idxR<MATRIX_IDX_NUM ; idxR=idxR+1) begin
            vvIdx[idxN][idxR] = {$random(SEED)} % MATRIX_NUM;
        end
    end
end endtask

//**************************************
//      Input Task
//**************************************
task input_task; begin
    if(itCalc == 0) begin
        repeat(({$random(SEED)} % 5 + 1)) @(negedge clk);
        // Give matrix size
        matrix_size = nSize == 2 ? 0 :
                      nSize == 4 ? 1 :
                      nSize == 8 ? 2 : 3;
        // Give matrix
        for(idxN=0 ; idxN<MATRIX_NUM ; idxN=idxN+1) begin
            for(idxR=0 ; idxR<nSize ; idxR=idxR+1) begin
                for(idxC=0 ; idxC<nSize ; idxC=idxC+1) begin
                    in_valid = 1;
                    matrix = vvMatrix[idxN][idxR][idxC];
                    @(negedge clk);
                    in_valid    = 0;
                    matrix_size = 'dx;
                    matrix      = 'dx;
                end
            end
        end
    end

    repeat(({$random(SEED)} % 3 + 1)) @(negedge clk);
    // Give mode
    mode = vMode[itCalc];
    // Give index
    for(idxN=0 ; idxN<MATRIX_IDX_NUM ; idxN=idxN+1) begin
        in_valid2  = 1;
        matrix_idx = vvIdx[itCalc][idxN];
        @(negedge clk);
        in_valid2  = 0;
        mode       = 'dx;
        matrix_idx = 'dx;
    end
end endtask

//**************************************
//      Calculation Task
//**************************************
task cal_task; begin
    run_main;
    dump_matrix;
end endtask

//**************************************
//      Wait Task
//**************************************
task wait_task; begin
    exe_lat = -1;
    while(out_valid !== 1) begin
        if(out_value !== 0) begin
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
            $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     when the out_valid is pulled down ");
            $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
            $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
            $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
            $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
            $display("                       `s--------------------------::::::::-----:o                                       ");
            $display("                       +:----------------------------------------y`                                      ");
            repeat(5) #(CYCLE);
            $finish;
        end
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");
            $display("                                `:/:-:::/-                              ");
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             "); 
            $display("                                +-:////+s/::--..                        ");
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);
            $display("    is over %5d   cycles    `:::--:/++:----------::/:.                ", DELAY);
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
//**************************************
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
        if(out_value !== goldTrace[itCalc]) begin
            $display("                                                                                ");
            $display("                                                   ./+oo+/.                     ");
            $display("    Trace is not correct!!!                       /s:-----+s`     at %-12d ps   ", $time*1000);
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
            $display("The current iteration : %-1d", itCalc);
            $display("Your trace is         : %16d", out_value);
            $display("Gold trace is         : %16d", goldTrace[itCalc]);
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
