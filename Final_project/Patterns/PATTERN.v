`ifdef RTL
`define CYCLE_TIME 4.1
`elsif GATE
`define CYCLE_TIME 4.2
`elsif CHIP
`define CYCLE_TIME 4.2
`elsif POST
`define CYCLE_TIME 4.2
`endif

`define CYCLE_TIME_DATA 5

`ifdef FUNC
`define PAT_NUM 1
`define MAX_LAT 2000
`endif
`ifdef PERF
`define PAT_NUM 1
`define MAX_LAT 100000
`endif


`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM_data.v"
`include "../00_TESTBED/pseudo_DRAM_inst.v"

module PATTERN(
    			clk,
			  rst_n,
		   IO_stall,


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

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
parameter ID_WIDTH=4, DATA_WIDTH=16, ADDR_WIDTH=32, DRAM_NUMBER=2, WRIT_NUMBER=1;

output reg			clk,rst_n;
input				IO_stall;

// axi write address channel 
input wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_s_inf;
input wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_s_inf;
input wire [WRIT_NUMBER * 3 -1:0]            awsize_s_inf;
input wire [WRIT_NUMBER * 2 -1:0]           awburst_s_inf;
input wire [WRIT_NUMBER * 7 -1:0]             awlen_s_inf;
input wire [WRIT_NUMBER-1:0]                awvalid_s_inf;
output wire [WRIT_NUMBER-1:0]               awready_s_inf;
// axi write data channel 
input wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_s_inf;
input wire [WRIT_NUMBER-1:0]                  wlast_s_inf;
input wire [WRIT_NUMBER-1:0]                 wvalid_s_inf;
output wire [WRIT_NUMBER-1:0]                wready_s_inf;
// axi write response channel
output wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_s_inf;
output wire [WRIT_NUMBER * 2 -1:0]             bresp_s_inf;
output wire [WRIT_NUMBER-1:0]             	  bvalid_s_inf;
input wire [WRIT_NUMBER-1:0]                  bready_s_inf;
// -----------------------------
// axi read address channel 
input wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_s_inf;
input wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_s_inf;
input wire [DRAM_NUMBER * 7 -1:0]            arlen_s_inf;
input wire [DRAM_NUMBER * 3 -1:0]           arsize_s_inf;
input wire [DRAM_NUMBER * 2 -1:0]          arburst_s_inf;
input wire [DRAM_NUMBER-1:0]               arvalid_s_inf;
output wire [DRAM_NUMBER-1:0]              arready_s_inf;
// -----------------------------
// axi read data channel 
output wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_s_inf;
output wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_s_inf;
output wire [DRAM_NUMBER * 2 -1:0]             rresp_s_inf;
output wire [DRAM_NUMBER-1:0]                  rlast_s_inf;
output wire [DRAM_NUMBER-1:0]                 rvalid_s_inf;
input wire [DRAM_NUMBER-1:0]                  rready_s_inf;
// -----------------------------

// ============
//     DRAM
// ============
pseudo_DRAM_data #(4, 32, 16, 7) DRAM_data (
    .clk(clk), 
    .rst_n(rst_n),

    // axi write address channel 
    .awid_s_inf    (awid_s_inf),
    .awaddr_s_inf  (awaddr_s_inf),
    .awsize_s_inf  (awsize_s_inf),
    .awburst_s_inf (awburst_s_inf),
    .awlen_s_inf   (awlen_s_inf),
    .awvalid_s_inf (awvalid_s_inf),
    .awready_s_inf (awready_s_inf),
    // axi write data channel 
    .wdata_s_inf   (wdata_s_inf),
    .wlast_s_inf   (wlast_s_inf),
    .wvalid_s_inf  (wvalid_s_inf),
    .wready_s_inf  (wready_s_inf),
    // axi write response channel
    .bid_s_inf     (bid_s_inf),
    .bresp_s_inf   (bresp_s_inf),
    .bvalid_s_inf  (bvalid_s_inf),
    .bready_s_inf  (bready_s_inf),
    
    // axi read address channel 
    .arid_s_inf    (arid_s_inf[ID_WIDTH-1:0]),
    .araddr_s_inf  (araddr_s_inf[ADDR_WIDTH-1:0]),
    .arlen_s_inf   (arlen_s_inf[6:0]),
    .arsize_s_inf  (arsize_s_inf[2:0]),
    .arburst_s_inf (arburst_s_inf[1:0]),
    .arvalid_s_inf (arvalid_s_inf[0]),
    .arready_s_inf (arready_s_inf[0]),
    // axi read data channel 
    .rid_s_inf     (rid_s_inf[ID_WIDTH-1:0]),
    .rdata_s_inf   (rdata_s_inf[DATA_WIDTH-1:0]),
    .rresp_s_inf   (rresp_s_inf[1:0]),
    .rlast_s_inf   (rlast_s_inf[0]),
    .rvalid_s_inf  (rvalid_s_inf[0]),
    .rready_s_inf  (rready_s_inf[0])
);

wire inst_awready, inst_wready, inst_bvalid;
wire [1:0] inst_bresp;
wire [ID_WIDTH-1:0] inst_bid;
pseudo_DRAM_inst #(4, 32, 16, 7) DRAM_inst (
    .clk(clk), 
    .rst_n(rst_n),
    // axi write address channel 
    .awid_s_inf    (0),
    .awaddr_s_inf  (0),
    .awsize_s_inf  (0),
    .awburst_s_inf (0),
    .awlen_s_inf   (0),
    .awvalid_s_inf (0),
    .awready_s_inf (inst_awready),
    // axi write data channel 
    .wdata_s_inf   (0),
    .wlast_s_inf   (0),
    .wvalid_s_inf  (0),
    .wready_s_inf  (inst_wready),
    // axi write response channel
    .bid_s_inf     (inst_bid),
    .bresp_s_inf   (inst_bresp),
    .bvalid_s_inf  (inst_bvalid),
    .bready_s_inf  (0),
    
    // axi read address channel 
    .arid_s_inf    (arid_s_inf[ID_WIDTH*2-1:ID_WIDTH]),
    .araddr_s_inf  (araddr_s_inf[ADDR_WIDTH*2-1:ADDR_WIDTH]),
    .arlen_s_inf   (arlen_s_inf[13:7]),
    .arsize_s_inf  (arsize_s_inf[5:3]),
    .arburst_s_inf (arburst_s_inf[3:2]),
    .arvalid_s_inf (arvalid_s_inf[1]),
    .arready_s_inf (arready_s_inf[1]),
    // axi read data channel 
    .rid_s_inf     (rid_s_inf[ID_WIDTH*2-1:ID_WIDTH]),
    .rdata_s_inf   (rdata_s_inf[DATA_WIDTH*2-1:DATA_WIDTH]),
    .rresp_s_inf   (rresp_s_inf[3:2]),
    .rlast_s_inf   (rlast_s_inf[1]),
    .rvalid_s_inf  (rvalid_s_inf[1]),
    .rready_s_inf  (rready_s_inf[1])
);

// ==============================
//     Parameters & Variables
// ==============================
integer cycle;
integer latency;
integer total_latency;
integer curr_inst_addr, next_inst_addr;
integer i, j, k;

integer i_pat;
integer inst_type;
integer rs, rt, rd;
integer target_inst_addr, target_data_addr;
reg signed [4:0] imm;

reg [15:0] inst_code;
reg signed [15:0] golden_reg[0:15];
reg signed [15:0] golden_mem[0:2047];

parameter ADD = 0;
parameter SUB = 1;
parameter SLT = 2;
parameter MUL = 3;
parameter LH  = 4;
parameter SH  = 5;
parameter BEQ = 6;
parameter J   = 7;
parameter WAIT_MAX_LAT = `MAX_LAT;

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
parameter CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;
always #(CYCLE) cycle = cycle+1;

// ============
//     Main
// ============
initial begin
    reset_task;
    setup_env_task;
    @(negedge clk);
    while(curr_inst_addr < 'h2000) begin
        wait_out_valid_task;
        check_ans_task;
        $display("%0sPASS PATTERN NO. %4d | %0sPC: %4d | Func: %3s | Latency: %4d%0s",txt_blue_prefix, i_pat, txt_green_prefix, (curr_inst_addr-'h1000) / 2, func_name(inst_type), latency, reset_color);
        i_pat = i_pat + 1;
        curr_inst_addr = next_inst_addr;
        @(negedge clk);
    end
    YOU_PASS_task;
    $finish;
end

// =============
//     Tasks
// =============
task check_ans_task; begin
    read_inst_task;
    check_reg_task;
    if(i_pat % 10 == 0)
        check_mem_task;
end endtask

task reset_task; begin
    rst_n          = 'b1;
    //  
    cycle          = 0; 
    total_latency  = 0;
    i_pat          = 0;
    curr_inst_addr = 'h1000;
    //
    force clk = 0;
    #CYCLE; rst_n = 0; 
    #(CYCLE);
    
    if(awvalid_s_inf !== 0 || wdata_s_inf !== 0 || wlast_s_inf !== 0 || wvalid_s_inf !== 0 || bready_s_inf != 0 ||
       arvalid_s_inf !== 0 || rready_s_inf !== 0) begin //out!==0
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("                AXI4 signals should be 0 after initial RESET          ");
        $display ("====================================================================");  
        $finish;
    end
    if(IO_stall !== 1'b1) begin //out!==0
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("                 IO_stall should be 1 after initial RESET          ");
        $display ("====================================================================");  
        $finish;
    end
    #(CYCLE/2.0); rst_n = 1;
	#CYCLE; release clk;
    //
end endtask

task setup_env_task; begin
    // init reg
    for(i=0; i<16; i=i+1) begin
        golden_reg[i] = 0;
    end
    // init mem
    k = 0;
    for(i='h1000; i<'h2000; i=i+2) begin
        golden_mem[k] = {DRAM_data.DRAM_r[i+1], DRAM_data.DRAM_r[i]};
        k = k + 1;
    end
end endtask

task wait_out_valid_task; begin
    latency = 1;
    while(IO_stall === 1'b1) begin
        if(latency == WAIT_MAX_LAT) begin
            $display ("====================================================================");
            $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
            $display ("            the execution latency is over %6d cycles                ", WAIT_MAX_LAT);
            $display ("====================================================================");  
            $finish;
        end
        latency = latency + 1;
        @(negedge clk);
    end
    if(IO_stall !== 1'b0) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("              IO_stall is DON'T CARE at %5d th cycle                ", cycle);
        $display ("====================================================================");  
        $finish;
    end
    total_latency = total_latency + latency;
end endtask

task read_inst_task; begin
    i = curr_inst_addr;
    next_inst_addr = curr_inst_addr + 2;
    inst_code = {DRAM_inst.DRAM_r[i+1], DRAM_inst.DRAM_r[i]};
    case (inst_code[15:13])
        'b000:  inst_type = (inst_code[0]) ? ADD : SUB;
        'b001:  inst_type = (inst_code[0]) ? SLT : MUL;
        'b011:  inst_type = LH;
        'b010:  inst_type = SH;
        'b101:  inst_type = BEQ;
        'b100:  inst_type = J;
    endcase
    rs = inst_code[12:9];
    rt = inst_code[8:5];
    rd = inst_code[4:1];
    imm = inst_code[4:0];
    target_inst_addr = inst_code[12:0];
    target_data_addr = golden_reg[rs] + imm;
    case (inst_type)
        ADD: golden_reg[rd] = golden_reg[rs] + golden_reg[rt];
        SUB: golden_reg[rd] = golden_reg[rs] - golden_reg[rt];
        SLT: golden_reg[rd] = (golden_reg[rs] < golden_reg[rt]) ? 1 : 0;
        MUL: golden_reg[rd] = golden_reg[rs] * golden_reg[rt];
        LH:  golden_reg[rt] = golden_mem[target_data_addr];
        SH:  golden_mem[target_data_addr] = golden_reg[rt];
        BEQ: next_inst_addr = (golden_reg[rs] == golden_reg[rt]) ? (next_inst_addr + imm*2) : next_inst_addr;
        J:   next_inst_addr = target_inst_addr;
    endcase
end endtask
`ifdef POST
    task check_reg_task; begin
        if( My_CHIP.core_r0 !== golden_reg[0] || My_CHIP.core_r8  !== golden_reg[8]  || 
            My_CHIP.core_r1 !== golden_reg[1] || My_CHIP.core_r9  !== golden_reg[9]  || 
            My_CHIP.core_r2 !== golden_reg[2] || My_CHIP.core_r10 !== golden_reg[10] || 
            My_CHIP.core_r3 !== golden_reg[3] || My_CHIP.core_r11 !== golden_reg[11] || 
            My_CHIP.core_r4 !== golden_reg[4] || My_CHIP.core_r12 !== golden_reg[12] ||
            My_CHIP.core_r5 !== golden_reg[5] || My_CHIP.core_r13 !== golden_reg[13] ||
            My_CHIP.core_r6 !== golden_reg[6] || My_CHIP.core_r14 !== golden_reg[14] ||
            My_CHIP.core_r7 !== golden_reg[7] || My_CHIP.core_r15 !== golden_reg[15]) begin
                $display ("==========================================================================");
                $display ("                                     %0sFAIL!%0s                          ", txt_red_prefix, reset_color);
                $display ("                               PATTERN NO. %04d                           ", i_pat);
                $display ("                            PC: %4d | Func:  %3s                          ", (curr_inst_addr-'h1000) / 2, func_name(inst_type));
                $display ("    --------------------------------------------------------------------  ");
                $display ("              your_ans   golden_ans  |             your_ans   golden_ans  ");
                $display ("    --------------------------------------------------------------------  ");
                $display ("    core_r0     %6d       %6d  |  core_r8      %6d       %6d  ", My_CHIP.core_r0, golden_reg[0], My_CHIP.core_r8 , golden_reg[8] );
                $display ("    core_r1     %6d       %6d  |  core_r9      %6d       %6d  ", My_CHIP.core_r1, golden_reg[1], My_CHIP.core_r9 , golden_reg[9] );
                $display ("    core_r2     %6d       %6d  |  core_r10     %6d       %6d  ", My_CHIP.core_r2, golden_reg[2], My_CHIP.core_r10, golden_reg[10]);
                $display ("    core_r3     %6d       %6d  |  core_r11     %6d       %6d  ", My_CHIP.core_r3, golden_reg[3], My_CHIP.core_r11, golden_reg[11]);
                $display ("    core_r4     %6d       %6d  |  core_r12     %6d       %6d  ", My_CHIP.core_r4, golden_reg[4], My_CHIP.core_r12, golden_reg[12]);
                $display ("    core_r5     %6d       %6d  |  core_r13     %6d       %6d  ", My_CHIP.core_r5, golden_reg[5], My_CHIP.core_r13, golden_reg[13]);
                $display ("    core_r6     %6d       %6d  |  core_r14     %6d       %6d  ", My_CHIP.core_r6, golden_reg[6], My_CHIP.core_r14, golden_reg[14]);
                $display ("    core_r7     %6d       %6d  |  core_r15     %6d       %6d  ", My_CHIP.core_r7, golden_reg[7], My_CHIP.core_r15, golden_reg[15]);
                $display ("    --------------------------------------------------------------------  ");
                $display ("==========================================================================");  
                $finish;
        end
    end endtask
`else
    task check_reg_task; begin
        if( My_CPU.core_r0 !== golden_reg[0] || My_CPU.core_r8  !== golden_reg[8]  || 
            My_CPU.core_r1 !== golden_reg[1] || My_CPU.core_r9  !== golden_reg[9]  || 
            My_CPU.core_r2 !== golden_reg[2] || My_CPU.core_r10 !== golden_reg[10] || 
            My_CPU.core_r3 !== golden_reg[3] || My_CPU.core_r11 !== golden_reg[11] || 
            My_CPU.core_r4 !== golden_reg[4] || My_CPU.core_r12 !== golden_reg[12] ||
            My_CPU.core_r5 !== golden_reg[5] || My_CPU.core_r13 !== golden_reg[13] ||
            My_CPU.core_r6 !== golden_reg[6] || My_CPU.core_r14 !== golden_reg[14] ||
            My_CPU.core_r7 !== golden_reg[7] || My_CPU.core_r15 !== golden_reg[15]) begin
                $display ("==========================================================================");
                $display ("                                     %0sFAIL!%0s                          ", txt_red_prefix, reset_color);
                $display ("                               PATTERN NO. %04d                           ", i_pat);
                $display ("                            PC: %4d | Func:  %3s                          ", (curr_inst_addr-'h1000) / 2, func_name(inst_type));
                $display ("    --------------------------------------------------------------------  ");
                $display ("              your_ans   golden_ans  |             your_ans   golden_ans  ");
                $display ("    --------------------------------------------------------------------  ");
                $display ("    core_r0     %6d       %6d  |  core_r8      %6d       %6d  ", My_CPU.core_r0, golden_reg[0], My_CPU.core_r8 , golden_reg[8] );
                $display ("    core_r1     %6d       %6d  |  core_r9      %6d       %6d  ", My_CPU.core_r1, golden_reg[1], My_CPU.core_r9 , golden_reg[9] );
                $display ("    core_r2     %6d       %6d  |  core_r10     %6d       %6d  ", My_CPU.core_r2, golden_reg[2], My_CPU.core_r10, golden_reg[10]);
                $display ("    core_r3     %6d       %6d  |  core_r11     %6d       %6d  ", My_CPU.core_r3, golden_reg[3], My_CPU.core_r11, golden_reg[11]);
                $display ("    core_r4     %6d       %6d  |  core_r12     %6d       %6d  ", My_CPU.core_r4, golden_reg[4], My_CPU.core_r12, golden_reg[12]);
                $display ("    core_r5     %6d       %6d  |  core_r13     %6d       %6d  ", My_CPU.core_r5, golden_reg[5], My_CPU.core_r13, golden_reg[13]);
                $display ("    core_r6     %6d       %6d  |  core_r14     %6d       %6d  ", My_CPU.core_r6, golden_reg[6], My_CPU.core_r14, golden_reg[14]);
                $display ("    core_r7     %6d       %6d  |  core_r15     %6d       %6d  ", My_CPU.core_r7, golden_reg[7], My_CPU.core_r15, golden_reg[15]);
                $display ("    --------------------------------------------------------------------  ");
                $display ("==========================================================================");  
                $finish;
        end
    end endtask
`endif

task check_mem_task; begin
    k = 0;
    j = 1; // print fail flag
    for(i='h1000; i<'h2000; i=i+2) begin
        if(golden_mem[k] !== {DRAM_data.DRAM_r[i+1], DRAM_data.DRAM_r[i]}) begin
            if(j) begin
                $display ("=========================================================================");
                $display ("                                 %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
                $display ("                           PATTERN NO. %04d                            ", i_pat);
                $display ("                            PC: %4d | Func:  %3s                       ", (curr_inst_addr-'h1000) / 2, func_name(inst_type));
                $display ("    ---------------------------------------------------------------    ");
                $display ("           addr       |   idx  |    your_ans     golden_ans            ");
                $display ("    ---------------------------------------------------------------    ");
                j = 0;
            end
            $display ("          0x%04H      |  %4d  |      %6d         %6d        ", i, k, $signed({DRAM_data.DRAM_r[i+1], DRAM_data.DRAM_r[i]}), golden_mem[k]);
        end
        k = k + 1;
    end
    if(j == 0) begin
        $display ("    ---------------------------------------------------------------    ");
        $display ("=========================================================================");
        $finish;
    end
end endtask

task YOU_PASS_task; begin
    $display ("====================================================================");
    $display ("                           %0sCongratulation!!%0s                   ", txt_green_prefix, reset_color);
    $display ("                    You have passed all patterns!                   ");
    $display ("               execution cycles   = %5d cycles                      ", total_latency);
    $display ("               clock period       = %.1f ns                         ", `CYCLE_TIME);
    $display ("               total latency      = %.1f ns                         ", total_latency*`CYCLE_TIME );
    $display ("====================================================================");  
    $finish;
end endtask

// ================
//     Function
// ================
function [8*3:1] func_name;
    input [2:0] type;
    begin
        case (type)
            ADD: func_name = "ADD";
            SUB: func_name = "SUB";
            SLT: func_name = "SLT";
            MUL: func_name = "MUL";
            LH:  func_name = " LH";
            SH:  func_name = " SH";
            BEQ: func_name = "BEQ";
            J:   func_name = "  J";
        endcase
    end
endfunction
endmodule

