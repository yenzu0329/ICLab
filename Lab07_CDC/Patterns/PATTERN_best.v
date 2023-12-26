/*
============================================================================

Date   : 2023/04/13
Author : EECS Lab

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Debuggging mode :
    
TODO : 
    fork join

============================================================================
*/

`ifdef RTL
    `timescale 1ns/1ps
    `define CYCLE_TIME_clk1 4
    `define CYCLE_TIME_clk2 24
`endif
`ifdef GATE
    `timescale 1ns/1ps
    `define CYCLE_TIME_clk1 4
    `define CYCLE_TIME_clk2 24
`endif


module PATTERN #(parameter DSIZE = 8, parameter ASIZE = 4)(
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
//======================================
//          I/O PORTS
//======================================
output reg       rst_n;
output reg       clk1;
output reg       clk2;
output reg       in_valid;
output reg [4:0] doraemon_id;
output reg [7:0] size;
output reg [7:0] iq_score;
output reg [7:0] eq_score;
output reg [2:0] size_weight;
output reg [2:0] iq_weight;
output reg [2:0] eq_weight;

input            ready;
input            out_valid;
input [7:0]      out;

//======================================
//      PARAMETERS & VARIABLES
//======================================
// User modification
parameter PATNUM            = 6000; // TA : 6000
// Make sure not to set the too large PATNUM.
// It's because that the memory usage issue.
integer   SEED              = 587;
// PATTERN operation
parameter CYCLE1            = `CYCLE_TIME_clk1;
parameter CYCLE2            = `CYCLE_TIME_clk2;
parameter DELAY             = 100000;
parameter READY_DELAY       = 150;
parameter MAX_INPUT_DELAY   = 1000;


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
parameter D_ID_NUM     = 32;
parameter D_INFO_MAX   = 200;
parameter D_INFO_MIN   = 50;
parameter N_WEIGHT_MAX = 7;
parameter N_WEIGHT_MIN = 0;
parameter IN_NUM_DEF   = 5;
parameter OUTNUM       = PATNUM-IN_NUM_DEF+1;
// Input
integer d_idx;
integer doraemon_id_data[PATNUM-1:0];
integer size_data       [PATNUM-1:0];
integer iq_score_data   [PATNUM-1:0];
integer eq_score_data   [PATNUM-1:0];
integer w_idx;
integer size_weight_data[OUTNUM-1:0];
integer iq_weight_data  [OUTNUM-1:0];
integer eq_weight_data  [OUTNUM-1:0];
// Output
integer out_finish_flag; // show the last output has been finished
integer out_idx1;
integer out_idx2;
integer gold_out [OUTNUM-1:0];
integer score_out[OUTNUM-1:0][IN_NUM_DEF-1:0];
integer door2pat  [OUTNUM-1:0][IN_NUM_DEF-1:0];

// Generate doraemon info
task gen_dora_info; begin
    // Randomize doraemon info
    for(d_idx=0 ; d_idx<PATNUM ; d_idx=d_idx+1) begin
        doraemon_id_data[d_idx] = {$random(SEED)} % D_ID_NUM;
        size_data       [d_idx] = {$random(SEED)} % (D_INFO_MAX-D_INFO_MIN+1) + D_INFO_MIN;
        iq_score_data   [d_idx] = {$random(SEED)} % (D_INFO_MAX-D_INFO_MIN+1) + D_INFO_MIN;
        eq_score_data   [d_idx] = {$random(SEED)} % (D_INFO_MAX-D_INFO_MIN+1) + D_INFO_MIN;
    end
end endtask

// Generate the weight of nobi
task gen_nobi_weight; begin
    for(w_idx=0 ; w_idx<OUTNUM ; w_idx=w_idx+1) begin
        size_weight_data[w_idx] = {$random(SEED)} % (N_WEIGHT_MAX-N_WEIGHT_MIN+1) + N_WEIGHT_MIN;
        iq_weight_data  [w_idx] = {$random(SEED)} % (N_WEIGHT_MAX-N_WEIGHT_MIN+1) + N_WEIGHT_MIN;
        eq_weight_data  [w_idx] = {$random(SEED)} % (N_WEIGHT_MAX-N_WEIGHT_MIN+1) + N_WEIGHT_MIN;
    end
end endtask

// Calculate the golden output
integer max_val;
integer max_idx2;
integer temp;
task cal_gold_out; begin
    // Set the door id for 0~(IN_NUM_DEF-1) input
    for(out_idx2=0 ; out_idx2<IN_NUM_DEF ; out_idx2=out_idx2+1) begin
        door2pat[0][out_idx2] = out_idx2;
    end

    for(out_idx1=0 ; out_idx1<OUTNUM ; out_idx1=out_idx1+1) begin

        // Calculate the door score
        for(out_idx2=0 ; out_idx2<IN_NUM_DEF ; out_idx2=out_idx2+1) begin
            temp = door2pat[out_idx1][out_idx2];
            score_out[out_idx1][out_idx2] = 
                size_data[temp]*size_weight_data[out_idx1] +
                iq_score_data[temp]*iq_weight_data[out_idx1] +
                eq_score_data[temp]*eq_weight_data[out_idx1];
        end

        // Determine the gold out
        max_val = -1;
        max_idx2 = -1;
        for(out_idx2=0 ; out_idx2<IN_NUM_DEF ; out_idx2=out_idx2+1) begin
            temp = door2pat[out_idx1][out_idx2];
            if(score_out[out_idx1][out_idx2] > max_val) begin
                gold_out[out_idx1] = {out_idx2[2:0], doraemon_id_data[temp][4:0]};
                max_val = score_out[out_idx1][out_idx2];
                max_idx2 = out_idx2;
            end
            else if(score_out[out_idx1][out_idx2] == max_val) begin
                if(out_idx2 < gold_out[out_idx1][7:5]) begin
                    gold_out[out_idx1] = {out_idx2[2:0], doraemon_id_data[temp][4:0]};
                    max_idx2 = out_idx2;
                end
            end
        end

        // Update the dora table for the next output
        if(out_idx1<(OUTNUM-1)) begin
            for(out_idx2=0 ; out_idx2<IN_NUM_DEF ; out_idx2=out_idx2+1) begin
                if(out_idx2 != max_idx2) begin
                    door2pat[out_idx1+1][out_idx2] = door2pat[out_idx1][out_idx2];
                end
                else begin
                    door2pat[out_idx1+1][out_idx2] = out_idx1+IN_NUM_DEF;
                end
            end
        end
    end
end endtask

// Show the corresponding input and output
// dora info   : 0,1,2,3,4
// nobi weight : 0
// output      : 0
// out_check_idx + IN_NUM_DEF - 1
task show_output;
    input integer idx;
begin
    $display("[ In Pat    No. ] : %4d~%4d", idx, idx+IN_NUM_DEF-1);
    $display("[ In Weight No. ] : %4d", idx);
    $display("[ Out       No. ] : %4d\n", idx);
    $display("[ Weight Info ] : ");
    $display("    Size : %2d", size_weight_data[idx]);
    $display("    IQ   : %2d", iq_weight_data[idx]);
    $display("    EQ   : %2d", eq_weight_data[idx]);
    $display("\n[ Doraemon Info ] : ");
    $display("    [ Door Id ] | [ Dora Id ] [ Size ] [  IQ ] [  EQ ] | [ Score ]");
    for(out_idx2=0 ; out_idx2<IN_NUM_DEF ; out_idx2=out_idx2+1) begin
        $display("    [ %7d ] | [ %7d ] [ %4d ] [ %3d ] [ %3d ] | [ %5d ]",
                out_idx2,
                doraemon_id_data[door2pat[idx][out_idx2]],
                size_data[door2pat[idx][out_idx2]],
                iq_score_data[door2pat[idx][out_idx2]],
                eq_score_data[door2pat[idx][out_idx2]],
                score_out[idx][out_idx2]
            );
    end
    $display("\n[   Gold output ] : ");
    $display("    {%d, %d}\n", gold_out[idx][7:5], gold_out[idx][4:0]);
    $display("\n[   Your output ] : ");
    $display("    {%d, %d}\n", out[7:5], out[4:0]);
end endtask


//======================================
//              MAIN
//======================================
initial exe_task;

//======================================
//              Clock
//======================================
initial clk1 = 0;
always #(CYCLE1/2.0) clk1 = ~clk1;

initial clk2 = 0;
always #(CYCLE2/2.0) clk2 = ~clk2;

//======================================
//              TASKS
//======================================
task exe_task; begin
    reset_task;
    data_task;
    fork
        input_task;
        wait_task;
        check_task;
    join
    check_out_valid_task;
    pass_task;
end endtask

//**************************************
//      Reset Task
//**************************************
task reset_task; begin

    force clk1  = 0;
    force clk2  = 0;
    rst_n       = 1;
    in_valid    = 0;
    doraemon_id = 'dx;

    size        = 'dx;
    iq_score    = 'dx;
    eq_score    = 'dx;

    size_weight = 'dx;
    iq_weight   = 'dx;
    eq_weight   = 'dx;


    tot_lat    = 0;
    input_delay = 0;
    #(CYCLE1/2.0) rst_n = 0;
    #(CYCLE1)
    #(CYCLE1/2.0) rst_n = 1;
    if(out_valid !== 0 || out !== 0 || ready !== 0) begin
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
        repeat(5) #(CYCLE1);
        $finish;
    end
    #(CYCLE1/2.0);

    release clk1;
    release clk2;
end endtask

//**************************************
//      Data Task
//**************************************
task data_task; begin
    gen_dora_info;
    gen_nobi_weight;
    cal_gold_out;
end endtask

//**************************************
//      Input Task
//**************************************
integer delay_flag;
integer delay_temp;
integer delay_random;
task input_task; begin
    repeat(({$random(SEED)} % 3 + 3)) @(negedge clk1);
    pat = 0;
    delay_flag = 0;
    while(pat<PATNUM) begin
        if(ready==0) delay_flag = 1;
        if(pat < (IN_NUM_DEF-1)) begin
            in_valid    = 1;
            doraemon_id = doraemon_id_data[pat];
            size        = size_data[pat];
            iq_score    = iq_score_data[pat];
            eq_score    = eq_score_data[pat];

            pat=pat+1;
            if(ready == 1)  delay_flag = 0;
            else            delay_flag = 1;
        end
        // else if(pat == (IN_NUM_DEF-1)) begin
        //     in_valid    = 1;
        //     doraemon_id = doraemon_id_data[pat];
        //     size        = size_data[pat];
        //     iq_score    = iq_score_data[pat];
        //     eq_score    = eq_score_data[pat];

        //     size_weight = size_weight_data[pat-IN_NUM_DEF+1];
        //     iq_weight   = iq_weight_data[pat-IN_NUM_DEF+1];
        //     eq_weight   = eq_weight_data[pat-IN_NUM_DEF+1];

        //     pat=pat+1;
        // end
        else if(ready) begin
            if(delay_flag==1 && input_delay < MAX_INPUT_DELAY) begin
                delay_random = (MAX_INPUT_DELAY-input_delay)<READY_DELAY ? (MAX_INPUT_DELAY-input_delay) : READY_DELAY;
                each_delay  = ({$random(SEED)} % delay_random);
                input_delay = input_delay + each_delay;
                repeat(each_delay) @(negedge clk1);
            end
            in_valid    = 1;
            doraemon_id = doraemon_id_data[pat];
            size        = size_data[pat];
            iq_score    = iq_score_data[pat];
            eq_score    = eq_score_data[pat];

            size_weight = size_weight_data[pat-IN_NUM_DEF+1];
            iq_weight   = iq_weight_data[pat-IN_NUM_DEF+1];
            eq_weight   = eq_weight_data[pat-IN_NUM_DEF+1];

            delay_flag = 0;
            pat=pat+1;
        end
        @(negedge clk1);
        in_valid    = 0;
        doraemon_id = 'dx;
        size        = 'dx;
        iq_score    = 'dx;
        eq_score    = 'dx;

        size_weight = 'dx;
        iq_weight   = 'dx;
        eq_weight   = 'dx;
    end
end endtask

//**************************************
//      Wait Task
//**************************************
task wait_task; begin
    exe_lat = -1;
    wait(in_valid);
    while (out_finish_flag !== 1) begin
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");
            $display("                                `:/:-:::/-                              ");
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             "); 
            $display("                                +-:////+s/::--..                        ");
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);
            $display("    is over %6d   cycles   `:::--:/++:----------::/:.                ", DELAY);
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
            repeat(5) @(negedge clk2);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        @(negedge clk2);
    end
end endtask

//**************************************
//      Check Task
//**************************************
task check_task; begin
    out_check_idx = 0;
    out_finish_flag = 0;
    while(out_finish_flag !== 1) begin
        //====================
        // Check
        //====================
        if(out_valid === 1) begin
            if(out_check_idx >= (pat-IN_NUM_DEF+1)) begin
                $display("                                                                                ");
                $display("                                                   ./+oo+/.                     ");
                $display("    Your output is too fast!!!                    /s:-----+s`     at %-12d ps   ", $time*1000);
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
                show_output(out_check_idx);
                repeat(5) @(negedge clk2);
                $finish;
            end
            if(out !== gold_out[out_check_idx]) begin
                $display("                                                                                ");
                $display("                                                   ./+oo+/.                     ");
                $display("    Your output is not correct!!!                 /s:-----+s`     at %-12d ps   ", $time*1000);
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
                show_output(out_check_idx);
                repeat(5) @(negedge clk2);
                $finish;
            end
            else begin
                $display("%0sPASS PATTERN NO.%4d, %0s Current Cycles: %3d%0s",txt_blue_prefix, out_check_idx, txt_green_prefix, exe_lat, reset_color);
                out_check_idx = out_check_idx + 1;
            end
        end
        
        // Check the finish condition or not
        if(out_check_idx == OUTNUM) out_finish_flag = 1;
        @(negedge clk2);
    end
end endtask

//**************************************
//      Check out_valid Task
//**************************************
task check_out_valid_task; begin
    if(out_valid === 1) begin
        $display("                                                                                ");
        $display("                                                   ./+oo+/.                     ");
        $display("    Your out_valid should be low!!!               /s:-----+s`     at %-12d ps   ", $time*1000);
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
        repeat(5) @(negedge clk2);
        $finish;
    end
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
    repeat(5) @(negedge clk2);
    $finish;
end endtask

endmodule