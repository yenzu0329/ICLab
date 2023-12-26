/*
============================================================================

Date   : 2023/04/03
Author : EECS Lab

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Debuggging mode :
    Dump file
TO Check :
    Default value in GLCM dram

============================================================================
*/
`ifdef RTL
    `define CYCLE_TIME 10
`endif
`ifdef GATE
    `define CYCLE_TIME 10
`endif

`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM.v"

module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=32, ADDR_WIDTH=32)(
    // Output signals
    clk,
    rst_n,
    in_addr_M,
    in_addr_G,
    in_dir,
    in_dis,
    in_valid,
    // Input signals
    out_valid,
    // AXI
    awid_s_inf,
    awaddr_s_inf,
    awsize_s_inf,
    awburst_s_inf,
    awlen_s_inf,
    awvalid_s_inf,
    awready_s_inf,

    wdata_s_inf,
    wlast_s_inf,
    wvalid_s_inf,
    wready_s_inf,

    bid_s_inf,
    bresp_s_inf,
    bvalid_s_inf,
    bready_s_inf,

    arid_s_inf,
    araddr_s_inf,
    arlen_s_inf,
    arsize_s_inf,
    arburst_s_inf,
    arvalid_s_inf,

    arready_s_inf,
    rid_s_inf,
    rdata_s_inf,
    rresp_s_inf,
    rlast_s_inf,
    rvalid_s_inf,
    rready_s_inf
);
//======================================
//      I/O PORTS
//======================================
output reg                  clk;
output reg                  rst_n;
// IO port
output reg [ADDR_WIDTH-1:0] in_addr_M;
output reg [ADDR_WIDTH-1:0] in_addr_G;
output reg [1:0]            in_dir;
output reg [3:0]            in_dis;
output reg                  in_valid;
input                       out_valid;
// -------------------------------------------
// axi write address channel 
input wire [ID_WIDTH-1:0]    awid_s_inf;
input wire [ADDR_WIDTH-1:0]  awaddr_s_inf;
input wire [2:0]             awsize_s_inf;
input wire [1:0]             awburst_s_inf;
input wire [3:0]             awlen_s_inf;
input wire                   awvalid_s_inf;
output wire                  awready_s_inf;
// -------------------------------------------
// axi write data channel 
input wire [DATA_WIDTH-1:0]  wdata_s_inf;
input wire                   wlast_s_inf;
input wire                   wvalid_s_inf;
output wire                  wready_s_inf;
// -------------------------------------------
// axi write response channel
output wire [ID_WIDTH-1:0]   bid_s_inf;
output wire [1:0]            bresp_s_inf;
output wire                  bvalid_s_inf;
input wire                   bready_s_inf;
// -------------------------------------------
// axi read address channel 
input wire [ID_WIDTH-1:0]    arid_s_inf;
input wire [ADDR_WIDTH-1:0]  araddr_s_inf;
input wire [3:0]             arlen_s_inf;
input wire [2:0]             arsize_s_inf;
input wire [1:0]             arburst_s_inf;
input wire                   arvalid_s_inf;
output wire                  arready_s_inf;
// -------------------------------------------
// axi read data channel 
output wire [ID_WIDTH-1:0]   rid_s_inf;
output wire [DATA_WIDTH-1:0] rdata_s_inf;
output wire [1:0]            rresp_s_inf;
output wire                  rlast_s_inf;
output wire                  rvalid_s_inf;
input wire                   rready_s_inf;
// -------------------------------------------
reg [ADDR_WIDTH-1:0]      gold_addr_G;

//======================================
//      DRAM CONNECTION
//======================================
pseudo_DRAM u_DRAM(

    .clk(clk),
    .rst_n(rst_n),

    .awid_s_inf(awid_s_inf),
    .awaddr_s_inf(awaddr_s_inf),
    .awsize_s_inf(awsize_s_inf),
    .awburst_s_inf(awburst_s_inf),
    .awlen_s_inf(awlen_s_inf),
    .awvalid_s_inf(awvalid_s_inf),
    .awready_s_inf(awready_s_inf),

    .wdata_s_inf(wdata_s_inf),
    .wlast_s_inf(wlast_s_inf),
    .wvalid_s_inf(wvalid_s_inf),
    .wready_s_inf(wready_s_inf),

    .bid_s_inf(bid_s_inf),
    .bresp_s_inf(bresp_s_inf),
    .bvalid_s_inf(bvalid_s_inf),
    .bready_s_inf(bready_s_inf),

    .arid_s_inf(arid_s_inf),
    .araddr_s_inf(araddr_s_inf),
    .arlen_s_inf(arlen_s_inf),
    .arsize_s_inf(arsize_s_inf),
    .arburst_s_inf(arburst_s_inf),
    .arvalid_s_inf(arvalid_s_inf),
    .arready_s_inf(arready_s_inf), 

    .rid_s_inf(rid_s_inf),
    .rdata_s_inf(rdata_s_inf),
    .rresp_s_inf(rresp_s_inf),
    .rlast_s_inf(rlast_s_inf),
    .rvalid_s_inf(rvalid_s_inf),
    .rready_s_inf(rready_s_inf)
);

//======================================
//      PARAMETERS & VARIABLES
//======================================
// User modification
parameter PATNUM            = 100;
integer   SEED_DRAM         = 520;
integer   SEED_PAT          = 520;
// PATTERN operation
parameter CYCLE             = `CYCLE_TIME;
parameter DELAY             = 100000;
parameter OUT_NUM           = 1;
// DRAM Address
parameter IS_RUN_RAND_DRAM  = 1;
parameter IS_RUN_SIMPLE     = 1; // Random value from DRAM_SIMPLE_VAL
parameter DRAM_SIMPLE_VAL   = 5;
reg[34*8:1] DRAM_PATH       = "../00_TESTBED/DRAM/pseudo_DRAM.dat";
parameter INPUT_ADDR_OFFSET = 'h1000;
parameter INPUT_ADDR_MAX    = 'h1FFF;
parameter INPUT_VAL_MAX     = 32;
parameter INPUT_SIZE        = 16; // 16 x 16 matrix, Value : 5 bit
parameter GLCM_ADDR_OFFSET  = 'h2000;
parameter GLCM_ADDR_MAX     = 'h2FFF;
parameter GLCM_VAL_MAX      = 256;
parameter GLCM_SIZE         = 32; // 32 x 32 GLCM (5 bit => 0 ~ 31), Value : 8 bit (16 x 16 = 256)

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
// DRAM random
integer addr;
integer data;
integer file_dram;
// Input
integer data_addr_m, data_addr_g;
integer data_dir,    data_dis;
integer row_offset,  col_offset;
/*
    dir :
        1 => (dist, 0   )
        2 => (0   , dist)
        3 => (dist, dist)
*/
integer row_idx, col_idx;
integer input_matrix[0:INPUT_SIZE-1][0:INPUT_SIZE-1];
integer your_glcm_matrix[0:GLCM_SIZE-1][0:GLCM_SIZE-1];
integer gold_glcm_matrix[0:GLCM_SIZE-1][0:GLCM_SIZE-1];
reg[8*28:1] debug_file_name="Midterm2023_debug_matrix.txt";
integer file_debug;

task load_input_fr_dram; begin
    for(row_idx=0 ; row_idx<INPUT_SIZE ; row_idx=row_idx+1) begin
        for(col_idx=0 ; col_idx<INPUT_SIZE ; col_idx=col_idx+1) begin
            input_matrix[row_idx][col_idx] = u_DRAM.DRAM_r[data_addr_m + row_idx*INPUT_SIZE + col_idx];
        end
    end
end endtask

task load_glcm_fr_dram; begin
    // for(row_idx=0 ; row_idx<GLCM_SIZE ; row_idx=row_idx+1) begin
        // for(col_idx=0 ; col_idx<GLCM_SIZE ; col_idx=col_idx+1) begin
            // your_glcm_matrix[row_idx][col_idx] = 0;
        // end
    // end
    for(row_idx=0 ; row_idx<GLCM_SIZE ; row_idx=row_idx+1) begin
        for(col_idx=0 ; col_idx<GLCM_SIZE ; col_idx=col_idx+1) begin
            your_glcm_matrix[row_idx][col_idx] = u_DRAM.DRAM_r[data_addr_g + row_idx*GLCM_SIZE + col_idx];
        end
    end
end endtask

task check_glcm;
    output integer isCorrect;
begin
    isCorrect = 1;
    for(row_idx=0 ; row_idx<GLCM_SIZE ; row_idx=row_idx+1) begin
        for(col_idx=0 ; col_idx<GLCM_SIZE ; col_idx=col_idx+1) begin
            if(your_glcm_matrix[row_idx][col_idx] !== gold_glcm_matrix[row_idx][col_idx]) isCorrect = 0;
        end
    end
end endtask

integer ref;
integer corr;
task calc_gold_glcm; begin
    // Reset gold GLCM
    for(row_idx=0 ; row_idx<GLCM_SIZE ; row_idx=row_idx+1) begin
        for(col_idx=0 ; col_idx<GLCM_SIZE ; col_idx=col_idx+1) begin
            gold_glcm_matrix[row_idx][col_idx] = 0;
        end
    end
    // Calculate gold GLCM
    for(row_idx=0 ; row_idx<INPUT_SIZE ; row_idx=row_idx+1) begin
        for(col_idx=0 ; col_idx<INPUT_SIZE ; col_idx=col_idx+1) begin
            ref = input_matrix[row_idx][col_idx];
            if((row_idx+row_offset) < INPUT_SIZE && (col_idx+col_offset) < INPUT_SIZE) begin
                corr = input_matrix[row_idx+row_offset][col_idx+col_offset];
                gold_glcm_matrix[ref][corr] = gold_glcm_matrix[ref][corr] + 1;
            end
            
        end
    end
end endtask

task dump_task; begin

    file_debug = $fopen(debug_file_name, "w");
    $fwrite(file_debug, "[ PATNUM        ] : %-d\n", pat);
    if(IS_RUN_SIMPLE == 1) $fwrite(file_debug, "[ Current DRAM  ] : %-d\n\n", DRAM_SIMPLE_VAL);
    else                   $fwrite(file_debug, "[ Current DRAM  ] : %-d\n\n", INPUT_VAL_MAX);

    //----------------
    // Dir & Dis
    //----------------
    $fwrite(file_debug, "                    (row, col)\n");
    case(data_dir)
        2'b01: $fwrite(file_debug, "[ Dir & Dis     ] : (%-3d, 0  )\n", data_dis);
        2'b10: $fwrite(file_debug, "[ Dir & Dis     ] : (0  , %-3d)\n", data_dis);
        2'b11: $fwrite(file_debug, "[ Dir & Dis     ] : (%-3d, %-3d)\n", data_dis, data_dis);
        default: $fwrite(file_debug, "[Error] Non-support direction. Please check PATTERN.\n");
    endcase

    //----------------
    // Input Matrix
    //----------------
    $fwrite(file_debug, "[ Input Address ] : fr %-h\n", data_addr_m);
    $fwrite(file_debug, "[ Input Address ] : to %-h\n\n", data_addr_m + INPUT_SIZE*INPUT_SIZE - 1);
    // Column index
    $fwrite(file_debug, "     ");
    for(col_idx=0 ; col_idx<INPUT_SIZE ; col_idx=col_idx+1)
        $fwrite(file_debug, "%3d ", col_idx);
    $fwrite(file_debug, "\n");

    $fwrite(file_debug, "_____");
    for(col_idx=0 ; col_idx<INPUT_SIZE ; col_idx=col_idx+1)
        $fwrite(file_debug, "____");
    $fwrite(file_debug, "\n");
    // Value & Row index
    for(row_idx=0 ; row_idx<INPUT_SIZE ; row_idx=row_idx+1) begin
        $fwrite(file_debug, "%3d |", row_idx);
        for(col_idx=0 ; col_idx<INPUT_SIZE ; col_idx=col_idx+1)
            $fwrite(file_debug, "%3d ", input_matrix[row_idx][col_idx]);
        $fwrite(file_debug, "\n");
    end
    $fwrite(file_debug, "\n\n");


    $fwrite(file_debug, "[ GLCM  Address ] : fr %-h\n", data_addr_g);
    $fwrite(file_debug, "[ GLCM  Address ] : to %-h\n\n", data_addr_g + GLCM_SIZE*GLCM_SIZE - 1);
    //----------------
    // Gold GLCM
    //----------------
    $fwrite(file_debug, "[ Gold GLCM     ]\n\n");
    // Column index
    $fwrite(file_debug, "     ");
    for(col_idx=0 ; col_idx<GLCM_SIZE ; col_idx=col_idx+1)
        $fwrite(file_debug, "%4d ", col_idx);
    $fwrite(file_debug, "\n");

    $fwrite(file_debug, "_____");
    for(col_idx=0 ; col_idx<GLCM_SIZE ; col_idx=col_idx+1)
        $fwrite(file_debug, "_____");
    $fwrite(file_debug, "\n");
    // Value & Row index
    for(row_idx=0 ; row_idx<GLCM_SIZE ; row_idx=row_idx+1) begin
        $fwrite(file_debug, "%3d |", row_idx);
        for(col_idx=0 ; col_idx<GLCM_SIZE ; col_idx=col_idx+1)
            $fwrite(file_debug, "%4d ", gold_glcm_matrix[row_idx][col_idx]);
        $fwrite(file_debug, "\n");
    end
    $fwrite(file_debug, "\n\n");
    //----------------
    // Your GLCM
    //----------------
    $fwrite(file_debug, "[ Your GLCM     ]\n\n");
    // Column index
    $fwrite(file_debug, "     ");
    for(col_idx=0 ; col_idx<GLCM_SIZE ; col_idx=col_idx+1)
        $fwrite(file_debug, "%4d ", col_idx);
    $fwrite(file_debug, "\n");

    $fwrite(file_debug, "_____");
    for(col_idx=0 ; col_idx<GLCM_SIZE ; col_idx=col_idx+1)
        $fwrite(file_debug, "_____");
    $fwrite(file_debug, "\n");
    // Value & Row index
    for(row_idx=0 ; row_idx<GLCM_SIZE ; row_idx=row_idx+1) begin
        $fwrite(file_debug, "%3d |", row_idx);
        for(col_idx=0 ; col_idx<GLCM_SIZE ; col_idx=col_idx+1) begin
            if(your_glcm_matrix[row_idx][col_idx] !== gold_glcm_matrix[row_idx][col_idx])
                $fwrite(file_debug, "*%3d ", your_glcm_matrix[row_idx][col_idx]);
            else
                $fwrite(file_debug, "%4d ", your_glcm_matrix[row_idx][col_idx]);
        end
        $fwrite(file_debug, "\n");
    end
    $fwrite(file_debug, "\n\n");
    

    $fclose(file_debug);
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
    random_dram_task;
    reset_task;
    for (pat=0 ; pat<PATNUM ; pat=pat+1) begin
        input_task;
        cal_task;
        wait_task;
        check_task;
        $display("%0sPASS PATTERN NO.%4d, %0sCycles: %3d%0s",txt_blue_prefix, pat, txt_green_prefix, exe_lat, reset_color);
    end
    pass_task;
end endtask

//**************************************
//      Random DRAM Task
//**************************************
integer RANDOM_VAL;
task random_dram_task; begin
    if(IS_RUN_RAND_DRAM == 1) begin
        $display("[Info] Randomize the DRAM data");
        $display("[Info] File Path   : %0s", DRAM_PATH);
        $display("[Info] Random SEED : %-1d", SEED_DRAM);
        file_dram = $fopen(DRAM_PATH,"w");
        // Input matrix
        RANDOM_VAL = IS_RUN_SIMPLE==1 ? DRAM_SIMPLE_VAL : INPUT_VAL_MAX;
        for(addr=INPUT_ADDR_OFFSET ; addr<=INPUT_ADDR_MAX ; addr=addr+'h4) begin
            $fwrite(file_dram, "@%5h\n", addr);

            data = {$random(SEED_DRAM)} % RANDOM_VAL;
            $fwrite(file_dram, "%h ", data[7:0]);

            data = {$random(SEED_DRAM)} % RANDOM_VAL;
            $fwrite(file_dram, "%h ", data[7:0]);

            data = {$random(SEED_DRAM)} % RANDOM_VAL;
            $fwrite(file_dram, "%h ", data[7:0]);

            data = {$random(SEED_DRAM)} % RANDOM_VAL;
            $fwrite(file_dram, "%h\n", data[7:0]);
        end
        // GLCM matrix
        for(addr=GLCM_ADDR_OFFSET ; addr<=GLCM_ADDR_MAX ; addr=addr+'h4) begin
            $fwrite(file_dram, "@%5h\n", addr);

            data = {$random(SEED_DRAM)} % GLCM_VAL_MAX;
            $fwrite(file_dram, "%h ", data[7:0]);

            data = {$random(SEED_DRAM)} % GLCM_VAL_MAX;
            $fwrite(file_dram, "%h ", data[7:0]);

            data = {$random(SEED_DRAM)} % GLCM_VAL_MAX;
            $fwrite(file_dram, "%h ", data[7:0]);

            data = {$random(SEED_DRAM)} % GLCM_VAL_MAX;
            $fwrite(file_dram, "%h\n", data[7:0]);
        end
    
        $fclose(file_dram);
    end
end endtask

//**************************************
//      Reset Task
//**************************************
task reset_task; begin
    force clk = 0;
    rst_n     = 1;
    in_valid  = 0;
    in_addr_M = 'dx;
    in_addr_G = 'dx;
    in_dir    = 'dx;
    in_dis    = 'dx;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if(out_valid !== 0) begin
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
task input_task; begin
    repeat(({$random(SEED_PAT)} % 3 + 2)) @(negedge clk);
    data_dir = {$random(SEED_PAT)}%3  + 1;
    data_dis = {$random(SEED_PAT)}%15 + 1;
    case(data_dir)
        2'b01: begin
            row_offset = data_dis;
            col_offset = 0;
        end
        2'b10: begin
            row_offset = 0;
            col_offset = data_dis;
        end
        2'b11: begin
            row_offset = data_dis;
            col_offset = data_dis;
        end
        default: begin
            $fwrite(file_debug, "[Error] Non-support direction. Please check PATTERN.\n");
            $finish;
        end
    endcase
    data_addr_m = {$random(SEED_PAT)}%(INPUT_ADDR_MAX - INPUT_SIZE*INPUT_SIZE + 2 - INPUT_ADDR_OFFSET) + INPUT_ADDR_OFFSET;
    data_addr_g = {$random(SEED_PAT)}%(GLCM_ADDR_MAX - GLCM_SIZE*GLCM_SIZE + 2 - GLCM_ADDR_OFFSET) + GLCM_ADDR_OFFSET;

    in_valid  = 1;
    in_addr_G = data_addr_g;
    in_addr_M = data_addr_m;
    in_dir    = data_dir;
    in_dis    = data_dis;
    @(negedge clk);
    in_valid  = 0;
    in_addr_G = 'dx;
    in_addr_M = 'dx;
    in_dir    = 'dx;
    in_dis    = 'dx;
end endtask

//**************************************
//      Calculation Task
//**************************************
task cal_task; begin
    load_input_fr_dram;
    calc_gold_glcm;
    dump_task;
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
integer check_flag;
task check_task; begin
    out_lat = 0;
    load_glcm_fr_dram;
    check_glcm(check_flag);
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
        if(check_flag == 0) begin
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
            $display("[Info] The debugging is dumped with the name (%0s)", debug_file_name);
            $display("[Info] The \"*\" denotes the difference between your GLCM and the golden GLCM\n\n");
            dump_task;
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

