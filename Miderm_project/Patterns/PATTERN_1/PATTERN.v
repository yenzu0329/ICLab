`ifdef RTL
`define CYCLE_TIME 20.0
`endif
`ifdef GATE
`define CYCLE_TIME 20.0
`endif


`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM.v"

module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=32, ADDR_WIDTH=32)(
        
				clk,	
			  rst_n,	
	
			in_addr_M,
			in_addr_G,
			in_dir,
			in_dis,
			in_valid,
			out_valid, 
	

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



//Connection wires
output reg			  clk,rst_n;
        
// -----------------------------
// IO port
output reg [ADDR_WIDTH-1:0]      in_addr_M;
output reg [ADDR_WIDTH-1:0]      in_addr_G;
output reg [1:0]  	  		in_dir;
output reg [3:0]	    	in_dis;
output reg 			    	in_valid;
input	              out_valid;
// -----------------------------

reg [ADDR_WIDTH-1:0]      gold_addr_G;


// axi write address channel 
input wire [ID_WIDTH-1:0]        awid_s_inf;
input wire [ADDR_WIDTH-1:0]    awaddr_s_inf;
input wire [2:0]            awsize_s_inf;
input wire [1:0]           awburst_s_inf;
input wire [3:0]             awlen_s_inf;
input wire                 awvalid_s_inf;
output wire                awready_s_inf;
// axi write data channel 
input wire [DATA_WIDTH-1:0]     wdata_s_inf;
input wire                   wlast_s_inf;
input wire                  wvalid_s_inf;
output wire                 wready_s_inf;
// axi write response channel
output wire [ID_WIDTH-1:0]         bid_s_inf;
output wire [1:0]             bresp_s_inf;
output wire              	  bvalid_s_inf;
input wire                    bready_s_inf;
// -----------------------------
// axi read address channel 
input wire [ID_WIDTH-1:0]       arid_s_inf;
input wire [ADDR_WIDTH-1:0]   araddr_s_inf;
input wire [3:0]            arlen_s_inf;
input wire [2:0]           arsize_s_inf;
input wire [1:0]          arburst_s_inf;
input wire                arvalid_s_inf;
output wire               arready_s_inf;
// -----------------------------
// axi read data channel 
output wire [ID_WIDTH-1:0]         rid_s_inf;
output wire [DATA_WIDTH-1:0]     rdata_s_inf;
output wire [1:0]             rresp_s_inf;
output wire                   rlast_s_inf;
output wire                  rvalid_s_inf;
input wire                   rready_s_inf;
// -----------------------------


//================================================================
//   DRAM
//================================================================
pseudo_DRAM DRAM (
// Glbal Signal
  	  .clk(clk),
  	  .rst_n(rst_n),
// slave interface 
      // axi write address channel 
      // src master
      .awid_s_inf(awid_s_inf),
      .awaddr_s_inf(awaddr_s_inf),
      .awsize_s_inf(awsize_s_inf),
      .awburst_s_inf(awburst_s_inf),
      .awlen_s_inf(awlen_s_inf),
      .awvalid_s_inf(awvalid_s_inf),
      // src slave
      .awready_s_inf(awready_s_inf),
      // -----------------------------
   
      // axi write data channel 
      // src master
      .wdata_s_inf(wdata_s_inf),
      .wlast_s_inf(wlast_s_inf),
      .wvalid_s_inf(wvalid_s_inf),
      // src slave
      .wready_s_inf(wready_s_inf),
   
      // axi write response channel 
      // src slave
      .bid_s_inf(bid_s_inf),
      .bresp_s_inf(bresp_s_inf),
      .bvalid_s_inf(bvalid_s_inf),
      // src master 
      .bready_s_inf(bready_s_inf),
      // -----------------------------
   
      // axi read address channel 
      // src master
      .arid_s_inf(arid_s_inf),
      .araddr_s_inf(araddr_s_inf),
      .arlen_s_inf(arlen_s_inf),
      .arsize_s_inf(arsize_s_inf),
      .arburst_s_inf(arburst_s_inf),
      .arvalid_s_inf(arvalid_s_inf),
      // src slave
      .arready_s_inf(arready_s_inf),
      // -----------------------------
   
      // axi read data channel 
      // slave
      .rid_s_inf(rid_s_inf),
      .rdata_s_inf(rdata_s_inf),
      .rresp_s_inf(rresp_s_inf),
      .rlast_s_inf(rlast_s_inf),
      .rvalid_s_inf(rvalid_s_inf),
      // master
      .rready_s_inf(rready_s_inf)
      // -----------------------------
);

//================================================================
//   parameters & integers
//================================================================
integer PATNUM; // PATNUM would be set due to first line in input.txt
integer patcount;
integer input_file;
integer output_file;
integer f;
integer i;
integer lat;
integer valid_time;

//================================================================
//    clock
//================================================================
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
//    wires % registers
//================================================================
reg [ADDR_WIDTH-1:0] addr_start;
reg [7:0] golden_ans;
reg [7:0] dram_value;

//================================================================
//    initial
//================================================================
initial begin
	input_file = $fopen("../00_TESTBED/input.txt", "r");
	output_file = $fopen("../00_TESTBED/output.txt", "r");
	
	reset_task;
	
	f = $fscanf(input_file, "%d", PATNUM);
	for (patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
		input_task;
		wait_out_valid_task;
		check_ans_task;
		$display("No. %3d Pattern Pass", patcount);
	end
	
	YOU_PASS_task;
	$finish;

end


//================================================================
//    task
//================================================================
task reset_task; begin
	rst_n = 1'b1;
	
	in_valid = 1'b0;
	in_addr_M = 32'bx;
	in_addr_G = 32'bx;
	in_dir = 2'bx;
	in_dis = 4'bx;

	force clk = 0;
	#CYCLE; rst_n = 1'b0;
	#CYCLE; rst_n = 1'b1;
	
	if (out_valid !== 0) begin
		$display("**************************************************************");
		$display("*       Output signal should be 0 after initial RESET        *");
		$display("**************************************************************");
		$finish;
	end
	
	#CYCLE; release clk;

end
endtask

task input_task; begin
	@(negedge clk);
	in_valid = 1'b1;
	f = $fscanf(input_file, "%h", in_addr_M);
	f = $fscanf(input_file, "%h", in_addr_G);
	f = $fscanf(input_file, "%d", in_dir);
	f = $fscanf(input_file, "%d", in_dis);
	addr_start = in_addr_G;

	if (out_valid === 1) begin
		$display("**************************************************************");
		$display("*    out_valid should not be raised when in_valid is high    *");
		$display("**************************************************************");
		$finish;
	end
	
	@(negedge clk);
	
	in_valid = 1'b0;
	in_addr_M = 32'bx;
	in_addr_G = 32'bx;
	in_dir = 2'bx;
	in_dis = 4'bx;
	
end
endtask

task wait_out_valid_task; begin
	lat = 0;
	while (out_valid === 0) begin
		lat = lat + 1;
		if (lat === 100000) begin
			$display("**************************************************************");
			$display("*          Execution latency is over 100000 cycles            *");
			$display("**************************************************************");
			$finish;
		end
		
		@(negedge clk);
	end
end
endtask

task check_ans_task; begin
	valid_time = 0;
	while (out_valid === 1) begin
		if (valid_time > 0) begin
			$display("**************************************************************");
			$display("*           out_valid should be high only 1 cycle            *");
			$display("**************************************************************");
			repeat(2) @(negedge clk);
			$finish;
		end
		
		for (i = 0; i < 1024; i = i + 1) begin
			f = $fscanf(output_file, "%d", golden_ans);
			dram_value = DRAM.DRAM_r[addr_start + i];
			if (golden_ans !== dram_value) begin
				$display("**************************************************************");
				$display("*                         YOU FAIL                           *");
				$display("**************************************************************");
				$display("patcount               = %d", patcount);
				$display("address of wrong value = %4h (in hex format)", addr_start + i);
				$display("Golden answer          = %d (in decimal format)", golden_ans);
				$display("Your answer            = %d (in decimal foramt)", dram_value);
				repeat(2) @(negedge clk);
				$finish;
			end
			
		end
		
		valid_time = valid_time + 1;
		
		@(negedge clk);
	end

end
endtask

task YOU_PASS_task; begin
$display("\033[37m                                                                                                                                          ");        
$display("\033[37m                                                                                \033[32m      :BBQvi.                                              ");        
$display("\033[37m                                                              .i7ssrvs7         \033[32m     BBBBBBBBQi                                           ");        
$display("\033[37m                        .:r7rrrr:::.        .::::::...   .i7vr:.      .B:       \033[32m    :BBBP :7BBBB.                                         ");        
$display("\033[37m                      .Kv.........:rrvYr7v7rr:.....:rrirJr.   .rgBBBBg  Bi      \033[32m    BBBB     BBBB                                         ");        
$display("\033[37m                     7Q  :rubEPUri:.       ..:irrii:..    :bBBBBBBBBBBB  B      \033[32m   iBBBv     BBBB       vBr                               ");        
$display("\033[37m                    7B  BBBBBBBBBBBBBBB::BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB :R     \033[32m   BBBBBKrirBBBB.     :BBBBBB:                            ");        
$display("\033[37m                   Jd .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: Bi    \033[32m  rBBBBBBBBBBBR.    .BBBM:BBB                             ");        
$display("\033[37m                  uZ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B    \033[32m  BBBB   .::.      EBBBi :BBU                             ");        
$display("\033[37m                 7B .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  B    \033[32m MBBBr           vBBBu   BBB.                             ");        
$display("\033[37m                .B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: JJ   \033[32m i7PB          iBBBBB.  iBBB                              ");        
$display("\033[37m                B. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  Lu             \033[32m  vBBBBPBBBBPBBB7       .7QBB5i                ");        
$display("\033[37m               Y1 KBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi XBBBBBBBi :B            \033[32m :RBBB.  .rBBBBB.      rBBBBBBBB7              ");        
$display("\033[37m              :B .BBBBBBBBBBBBBsRBBBBBBBBBBBrQBBBBB. UBBBRrBBBBBBr 1BBBBBBBBB  B.          \033[32m    .       BBBB       BBBB  :BBBB             ");        
$display("\033[37m              Bi BBBBBBBBBBBBBi :BBBBBBBBBBE .BBK.  .  .   QBBBBBBBBBBBBBBBBBB  Bi         \033[32m           rBBBr       BBBB    BBBU            ");        
$display("\033[37m             .B .BBBBBBBBBBBBBBQBBBBBBBBBBBB       \033[38;2;242;172;172mBBv \033[37m.LBBBBBBBBBBBBBBBBBBBBBB. B7.:ii:   \033[32m           vBBB        .BBBB   :7i.            ");        
$display("\033[37m            .B  PBBBBBBBBBBBBBBBBBBBBBBBBBBBBbYQB. \033[38;2;242;172;172mBB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBB  Jr:::rK7 \033[32m             .7  BBB7   iBBBg                  ");        
$display("\033[37m           7M  PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBB..i   .   v1                  \033[32mdBBB.   5BBBr                 ");        
$display("\033[37m          sZ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBB iD2BBQL.                 \033[32m ZBBBr  EBBBv     YBBBBQi     ");        
$display("\033[37m  .7YYUSIX5 .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBBBY.:.      :B                 \033[32m  iBBBBBBBBD     BBBBBBBBB.   ");        
$display("\033[37m LB.        ..BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB. \033[38;2;242;172;172mBB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBMBBB. BP17si                 \033[32m    :LBBBr      vBBBi  5BBB   ");        
$display("\033[37m  KvJPBBB :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: \033[38;2;242;172;172mZB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBsiJr .i7ssr:                \033[32m          ...   :BBB:   BBBu  ");        
$display("\033[37m i7ii:.   ::BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBj \033[38;2;242;172;172muBi \033[37mQBBBBBBBBBBBBBBBBBBBBBBBBi.ir      iB                \033[32m         .BBBi   BBBB   iMBu  ");        
$display("\033[37mDB    .  vBdBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBg \033[38;2;242;172;172m7Bi \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBB rBrXPv.                \033[32m          BBBX   :BBBr        ");        
$display("\033[37m :vQBBB. BQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQ \033[38;2;242;172;172miB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .L:ii::irrrrrrrr7jIr   \033[32m          .BBBv  :BBBQ        ");        
$display("\033[37m :7:.   .. 5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBr \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBB:            ..... ..YB. \033[32m           .BBBBBBBBB:        ");        
$display("\033[37mBU  .:. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mB7 \033[37mgBBBBBBBBBBBBBBBBBBBBBBBBBB. gBBBBBBBBBBBBBBBBBB. BL \033[32m             rBBBBB1.         ");        
$display("\033[37m rY7iB: BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: \033[38;2;242;172;172mB7 \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBB. QBBBBBBBBBBBBBBBBBi  v5                                ");        
$display("\033[37m     us EBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB \033[38;2;242;172;172mIr \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBgu7i.:BBBBBBBr Bu                                 ");        
$display("\033[37m      B  7BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB.\033[38;2;242;172;172m:i \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBv:.  .. :::  .rr    rB                                  ");        
$display("\033[37m      us  .BBBBBBBBBBBBBQLXBBBBBBBBBBBBBBBBBBBBBBBBq  .BBBBBBBBBBBBBBBBBBBBBBBBBv  :iJ7vri:::1Jr..isJYr                                   ");        
$display("\033[37m      B  BBBBBBB  MBBBM      qBBBBBBBBBBBBBBBBBBBBBB: BBBBBBBBBBBBBBBBBBBBBBBBBB  B:           iir:                                       ");        
$display("\033[37m     iB iBBBBBBBL       BBBP. :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  B.                                                       ");        
$display("\033[37m     P: BBBBBBBBBBB5v7gBBBBBB  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: Br                                                        ");        
$display("\033[37m     B  BBBs 7BBBBBBBBBBBBBB7 :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B                                                         ");        
$display("\033[37m    .B :BBBB.  EBBBBBQBBBBBJ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB. B.                                                         ");        
$display("\033[37m    ij qBBBBBg          ..  .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B                                                          ");        
$display("\033[37m    UY QBBBBBBBBSUSPDQL...iBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBK EL                                                          ");        
$display("\033[37m    B7 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: B:                                                          ");        
$display("\033[37m    B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBYrBB vBBBBBBBBBBBBBBBBBBBBBBBB. Ls                                                          ");        
$display("\033[37m    B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi_  /UBBBBBBBBBBBBBBBBBBBBBBBBB. :B:                                                        ");        
$display("\033[37m   rM .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  ..IBBBBBBBBBBBBBBBBQBBBBBBBBBB  B                                                        ");        
$display("\033[37m   B  BBBBBBBBBdZBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBPBBBBBBBBBBBBEji:..     sBBBBBBBr Br                                                       ");        
$display("\033[37m  7B 7BBBBBBBr     .:vXQBBBBBBBBBBBBBBBBBBBBBBBBBQqui::..  ...i:i7777vi  BBBBBBr Bi                                                       ");        
$display("\033[37m  Ki BBBBBBB  rY7vr:i....  .............:.....  ...:rii7vrr7r:..      7B  BBBBB  Bi                                                       ");        
$display("\033[37m  B. BBBBBB  B:    .::ir77rrYLvvriiiiiiirvvY7rr77ri:..                 bU  iQBB:..rI                                                      ");        
$display("\033[37m.S: 7BBBBP  B.                                                          vI7.  .:.  B.                                                     ");        
$display("\033[37mB: ir:.   :B.                                                             :rvsUjUgU.                                                      ");        
$display("\033[37mrMvrrirJKur                                                                                                                               \033[m");
end
endtask

endmodule

