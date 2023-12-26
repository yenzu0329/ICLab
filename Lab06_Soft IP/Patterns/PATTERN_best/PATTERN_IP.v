//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      (C) Copyright Optimum Application-Specific Integrated System Laboratory
//      All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : PATTERN_IP.v
//   	Module Name : PATTERN_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
/*
============================================================================

Date   : 2023/03/30
Author : EECS Lab

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Debuggging mode :
    Display
Notice :
    IP_WIDTH should not be large than 32
    The reason is that the task use integer to calculate the gcd.

============================================================================
*/
`ifdef RTL
    `define CYCLE_TIME 60.0
`endif

`ifdef GATE
    `define CYCLE_TIME 60.0
`endif

module PATTERN_IP #(parameter IP_WIDTH = 6) (
    // Output signals
    IN_1,
    IN_2,
    // Input signals
    OUT_INV
);
//======================================
//          I/O PORTS
//======================================
// The larger one should be 
output reg [IP_WIDTH-1:0]    IN_1;
output reg [IP_WIDTH-1:0]    IN_2;
input      [IP_WIDTH-1:0] OUT_INV;

//======================================
//      PARAMETERS & VARIABLES
//======================================
parameter PATNUM     = 10;
parameter IS_RUN_ALL = 1;
/*
    IS_RUN_ALL = 1 => run all the prime number and do all the possible inversion
    IS_RUN_ALL = 0 => run the PATNUM and it will randomize the input based on IP_WIDTH
*/
parameter MAX_IN_RANGE = 2**IP_WIDTH;
parameter CYCLE        = `CYCLE_TIME;
integer   SEED         = 122;

// PATTERN CONTROL
integer         i;
integer         j;
integer         k;
integer         m;
integer      stop;
integer       pat;
integer pat_prime;
integer   pat_num;
integer   exe_lat;
integer   out_lat;
integer   tot_lat;

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
//      Data Model
//======================================
reg clk;
// Prime list
// Construct list of prime number
integer prime_list[0:MAX_IN_RANGE-1];
integer        prime_flag; // show whether the number is prime or not
integer         num_prime; // how many prime number
integer sel_prime, sel_num;
integer     gold_x, gold_y;


// Prime checker
//    Check whether the "in_num" is prime or not
//    0 ==> not prime
//    1 ==> prime
integer flag;
integer numIter;
task prime_check;
    input  integer in_num;
    output integer isPrime;
begin
    flag = 0;
    for(numIter=2 ; numIter*numIter<=in_num ; numIter=numIter+1) begin
        if((in_num%numIter) === 0 && flag === 0 ) begin
            flag = 1;
            isPrime = 0;
        end
    end
    if(flag == 0) isPrime = 1;
    if(in_num == 1) isPrime = 0;
end endtask

// Find the greatest common divisor
integer gcd_q, gcd_r, b_temp, a_temp;
task gcd;
    input  integer a;
    input  integer b;
    output integer c;
begin
    a_temp = a;
    b_temp = b;
    // loop till remainder is 0
    while (b_temp > 0) begin
        gcd_q = a_temp / b_temp; // quotient
        gcd_r = a_temp - gcd_q * b_temp; // remainder
        a_temp = b_temp;
        b_temp = gcd_r;
    end
    c = a_temp;
end endtask

// Find ax + by = gcd(a,b)
integer euc_q, euc_r;
integer euc_a, euc_b;

integer cur_x, cur_y;
integer pre_x, pre_y;
integer tmp_x, tmp_y;
task ext_euclid;
    input  integer isShowLog;
    input  integer a; // prime number
    input  integer b; // do inversion
    output integer x;
    output integer y;
begin
    euc_r = a%b;
    euc_q = (a-euc_r)/b;
    
    euc_a = b;
    euc_b = euc_r;
    
    cur_x = 1;
    cur_y = -euc_q;
    pre_x = 0;
    pre_y = 1;
    if(isShowLog == 1) begin
        $display("[Info] Show the calculation process");
        $display("[Rem], [Quo], [X], [Y]");
        $display("[%1d], [-], [1], [0]", a);
        $display("[%1d], [-], [0], [1]", b);
        $display("[%1d], [%1d], [%1d], [%1d]", euc_r, euc_q, cur_x, cur_y);
    end
    while(euc_r !== 0) begin
        euc_r = euc_a%euc_b;
        euc_q = (euc_a-euc_r)/euc_b;
        
        euc_a = euc_b;
        euc_b = euc_r;
        
        tmp_x = cur_x;
        tmp_y = cur_y;
        cur_x = pre_x - cur_x*euc_q;
        cur_y = pre_y - cur_y*euc_q;
        pre_x = tmp_x;
        pre_y = tmp_y;
        if(isShowLog == 1) begin
            $display("[%1d], [%1d], [%1d], [%1d]", euc_r, euc_q, cur_x, cur_y);
        end
    end
    if(pre_x < 0) x = pre_x + b;
    else          x = pre_x;
    if(pre_y < 0) y = pre_y + a;
    else          y = pre_y;
end endtask

//================================================================
//      CLOCK
//================================================================
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
//      MAIN
//================================================================
initial exe_task;

//================================================================
//      TASK DECLARATION
//================================================================
task exe_task; begin
    reset_task;
    prime_task;
    if(IS_RUN_ALL==1) begin
        for (pat_prime=0 ; pat_prime<num_prime ; pat_prime=pat_prime+1) begin
            for (pat_num=1 ; pat_num<prime_list[pat_prime] ; pat_num=pat_num+1) begin
                data_task;
                check_task;
                $display("%0sPASS PATTERN, %0s IN1 : %1d IN2 : %1d%0s",txt_blue_prefix, txt_green_prefix, IN_1, IN_2, reset_color);
            end
        end
    end
    else begin
        for (pat=0 ; pat<PATNUM ; pat=pat+1) begin
            data_task;
            check_task;
            $display("%0sPASS PATTERN NO.%4d, %0s IN1 : %1d IN2 : %1d%0s",txt_blue_prefix, pat, txt_green_prefix, IN_1, IN_2, reset_color);
        end
    end
    pass_task;
end endtask

//**************************************
//      Reset Task
//**************************************
task reset_task; begin
    // Check IP_WIDTH
    if(IP_WIDTH > 32) begin
        $display("[Error] The IP_WIDTH should be less than 32 for this PATTERN");
        $finish;
    end

    force clk = 0;
    IN_1 = 0;
    IN_2 = 0;

    release clk;
    if(IS_RUN_ALL==1) $display("[Info] Run all possible pattern");
    else $display("[Info] Run your specific number of pattern by random");
end endtask

//**************************************
//      Prime Task
//**************************************
task prime_task; begin
    // $display("[Info] IP_WIDHT : %-1d, MAXIMUM of this width %-1d", IP_WIDTH, MAX_IN_RANGE);

    // Construct the list of prime number
    num_prime = 0;
    for(i=2 ; i<MAX_IN_RANGE ; i=i+1) begin
        prime_check(i, prime_flag);
        if(prime_flag == 1) begin
            prime_list[num_prime] = i;
            num_prime = num_prime + 1;
            // $display("[Info] (Prime, idx) = (%-1d, %-1d)", i, num_prime);
        end
    end
end endtask

//**************************************
//      Data Task
//**************************************
task data_task; begin
    if(IS_RUN_ALL == 1) begin
        sel_prime=prime_list[pat_prime];
        sel_num=pat_num;
        
    end
    else begin
        sel_prime = prime_list[ {$random(SEED)}%num_prime ];
        sel_num = {$random(SEED)}%(sel_prime-1) + 1;
    end
    // Randomize the prime num and inversion num
    if({$random(SEED)}%2 == 1) begin
        IN_1 = sel_prime;
        IN_2 = sel_num;
    end
    else begin
        IN_1 = sel_num;
        IN_2 = sel_prime;
    end
    ext_euclid(0, sel_prime, sel_num, gold_x, gold_y);
    // $display("[Info] (IN_1, IN_2) = (%-1d, %-1d), (%1d)", IN_1, IN_2, gold_y);
    @(posedge clk);
end endtask

//**************************************
//      Check Task
//**************************************
task check_task; begin
    @(negedge clk);
    if ( OUT_INV !== gold_y ) begin
        $display("\033[1;33m                                                                                                    ");
        $display("\033[1;33m                                                   ./+oo+/.                                         ");
        $display("\033[1;36m    Your Soft IP output is not correct\033[1;33m            /s:-----+s`                             ");
        $display("\033[1;33m                                                  y/-------:y                                       ");
        $display("\033[1;33m                                             `.-:/od+/------y`                                      ");
        $display("\033[1;33m                               `:///+++ooooooo+//::::-----:/y+:`                                    ");
        $display("\033[1;33m                              -m+:::::::---------------------::o+.                                  ");
        $display("\033[1;33m                             `hod-------------------------------:o+                                 ");
        $display("\033[1;33m                       ./++/:s/-o/--------------------------------/s///::.                          ");
        $display("\033[1;33m                      /s::-://--:--------------------------------:oo/::::o+                         ");
        $display("\033[1;33m                    -+ho++++//hh:-------------------------------:s:-------+/                        ");
        $display("\033[1;33m                  -s+shdh+::+hm+--------------------------------+/--------:s                        ");
        $display("\033[1;33m                 -s:hMMMMNy---+y/-------------------------------:---------//                        ");
        $display("\033[1;33m                 y:/NMMMMMN:---:s-/o:-------------------------------------+`                        ");
        $display("\033[1;33m                 h--sdmmdy/-------:hyssoo++:----------------------------:/`                         ");
        $display("\033[1;33m                 h---::::----------+oo+/::/+o:---------------------:+++s-`                          ");
        $display("\033[1;33m                 s:----------------/s+///------------------------------o`                           ");
        $display("\033[1;33m           ``..../s------------------::--------------------------------o                            ");
        $display("\033[1;31m       -/oyhyyyyyym:\033[1;33m----------------://////:--------------------------:/                  ");
        $display("\033[1;31m      /dyssyyyssssyh:\033[1;33m-------------/o+/::::/+o/------------------------+`                  ");
        $display("\033[1;33m    -+o/---:\033[1;31m/oyyssshd/\033[1;33m-----------+o:--------:oo---------------------:/.         ");
        $display("\033[1;33m  `++--------\033[1;31m:/sysssdd\033[1;33my+:-------/+------------s/------------------://`          ");
        $display("\033[1;33m .s:---------:\033[1;31m+ooyysyydd\033[1;33moo++os-:s-------------/y----------------:++.            ");
        $display("\033[1;33m s:------------\033[1;31m/yyhssyshy:\033[1;33m---/:o:-------------:dsoo++//:::::-::+syh`            ");
        $display("\033[1;33m`h--------------\033[1;31mshyssssyyms+oy\033[1;33mo:--------------\033[1;31m/hyyyyyyyyyyyysyhyyyy`  ");
        $display("\033[1;33m`h--------------:\033[1;31myyssssyyhhyy\033[1;33m+----------------+\033[1;31mdyyyysssssssyyyhs+/.   ");
        $display("\033[1;33m s:--------------\033[1;31m/yysssssyhy\033[1;33m:-----------------\033[1;31mshyyyyyhyyssssyyh.      ");
        $display("\033[1;33m .s---------------+\033[1;31msooosyyo\033[1;33m------------------\033[1;31m/yssssssyyyyssssyo       ");
        $display("\033[1;33m  /+-------------------:++------------------:\033[1;31mysssssssssssssssy-                           ");
        $display("\033[1;33m  `s+--------------------------------------:\033[1;31msyssssssssssssssyo                            ");
        $display("\033[1;31m`+yhdo\033[1;33m--------------------:/--------------:\033[1;31msyssssssssssssssyy.                  ");
        $display("\033[1;31m+yysyhh:\033[1;33m-------------------+o------------\033[1;31m/ysyssssssssssssssy/                   ");
        $display(" \033[1;31m/hhysyds:\033[1;33m------------------y-----------\033[1;31m/+yyssssssssssssssyh`                   ");
        $display("\033[1;33m .h-\033[1;31m+yysyds:\033[1;33m---------------:s----------:--\033[1;31m/yssssssssssssssym:         ");
        $display("\033[1;33m y/---\033[1;31moyyyyhyo:\033[1;33m-----------:o:-------------:\033[1;31mysssssssssyyyssyyd-        ");
        $display("\033[1;33m`h------\033[1;31m+syyyyhhsoo+///+osh\033[1;33m---------------:\033[1;31mysssyysyyyyysssssyd:       ");
        $display("\033[1;33m/s--------:\033[1;31m+syyyyyyyyyyyyyyhso/:\033[1;33m-------::\033[1;31m+oyyyyhyyyysssssssyy+-       ");
        $display("\033[1;33m+s-----------:\033[1;31m/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/\033[1;33m`                   ");
        $display("\033[1;33m+s---------------:\033[1;31m/osyyyysssssssssssssssyyhyyssssssyyyyso/y\033[1;33m`                    ");
        $display("\033[1;33m/s--------------------:\033[1;31m/+ossyyyyyyssssssssyyyyyyysso+\033[1;33m:----:+                    ");
        $display("\033[1;33m.h--------------------------:::\033[1;31m/++oooooooo+++/\033[1;33m:::----------o`                   ");
        $display("\033[1;36mThe IN1     is : %-1d                                                                        \033[1;0m", IN_1);
        $display("\033[1;36mThe IN2     is : %-1d                                                                        \033[1;0m", IN_2);
        $display("\033[1;34mYour output is : %-1d                                                                        \033[1;0m", OUT_INV);
        $display("\033[1;34mGold output is : %-1d                                                                        \033[1;0m", gold_y);
        repeat(5) @(negedge clk);
        $finish;
    end
end endtask

//**************************************
//      Pass Task
//**************************************
task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulation!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o                                                                                      ");
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
    repeat (5) @(negedge clk);
    $finish;
    
end endtask

endmodule