//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2023-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(
				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 
);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;
// parameters
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// ------------------------------------------
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// ------------------------------------------
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// ------------------------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// ------------------------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// ------------------------------------------


/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;

reg signed [15:0] regs[15:0];

// ========================
//       parameter   
// ========================
parameter REG_WRITE  = 3'b000;
parameter MEM_READ   = 3'b001;
parameter MEM_WRITE  = 3'b010;
parameter BRANCH     = 3'b011;
parameter ALU_SRC    = 3'b100;
parameter ALU_OP0    = 3'b101;
parameter ALU_OP1    = 3'b110;

// ========================
//       reg & wire   
// ========================
// stall
reg  ID_stall;
reg  EXE_stall;
reg  MEM_stall;
reg  WB_stall;

wire gen_ID_nop;
wire gen_EXE_nop;

wire is_inst_valid;
wire is_data_valid;

// ------------
//   IF stage
// ------------
wire is_branch;
wire is_jump;
wire is_pc_update;
reg  [10:0] next_pc;
reg  [10:0] pc;
wire [10:0] IF_pc;
wire [15:0] IF_inst;

// ------------
//   ID stage
// ------------
reg  is_load_use;
reg  [15:0] ID_inst;
reg  [10:0] ID_pc;
//
wire [3:0]  ID_rs;
wire [3:0]  ID_rt;
wire [12:0] ID_addr;
wire [2:0]  ID_opcode;
wire [4:0]  ID_4_0;
reg  signed [15:0] ID_rs_data;
reg  signed [15:0] ID_rt_data;

// -------------
//   EXE stage
// -------------
wire is_zero;
reg  [6:0]  EXE_ctrl;
reg  [15:0] EXE_inst;
reg  [10:0] EXE_pc;
//
wire [3:0]  EXE_rs;
wire [3:0]  EXE_rt;
wire [3:0]  EXE_rd;
wire [2:0]  EXE_opcode;
wire        EXE_func;
wire signed [15:0] EXE_imm;
reg  signed [15:0] EXE_rs_data;
reg  signed [15:0] EXE_rt_data;
//
wire [1:0]  alu_op;
wire signed [15:0] EXE_alu_in1;
wire signed [15:0] EXE_alu_in2;
reg  signed [15:0] EXE_alu_out;
// 
reg [1:0] EXE_forward1;
reg [1:0] EXE_forward2;

// -------------
//   MEM stage
// -------------
wire is_load;
wire is_store;
reg  MEM_is_nop;
reg  [2:0]  MEM_ctrl;
reg  [3:0]  MEM_rd;
reg  signed [15:0] MEM_alu_out;
reg  signed [15:0] MEM_rt_data;
wire signed [15:0] MEM_addr_in;
wire signed [15:0] MEM_data_in;
wire signed [15:0] MEM_data_out;
wire signed [15:0] MEM_result;

// ------------
//   WB stage
// ------------
reg  WB_ctrl;
reg  WB_is_nop;
reg  [3:0]  WB_rd;
reg  signed [15:0] WB_result;

// ========================
//         design   
// ========================
// ------------
//   IF stage
// ------------
assign is_branch    = EXE_ctrl[BRANCH] & is_zero;
assign is_jump      = ID_opcode == 3'b100;
assign is_pc_update = is_inst_valid & is_data_valid & ~is_load_use;
assign IF_pc        = is_pc_update ? next_pc : pc;

always @(*) begin
    if(is_branch)               next_pc = EXE_pc + EXE_imm;
    else if(is_jump)            next_pc = ID_addr[11:1];
    else                        next_pc = pc + 1;
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)                  pc <= 0;
    else begin
        if(is_branch)           pc <= EXE_pc + EXE_imm;
        else if(is_jump)        pc <= ID_addr[11:1];
        else if(is_pc_update)   pc <= pc + 1;
        else                    pc <= pc;
    end
end

// ------------
//   ID stage
// ------------
assign ID_opcode = ID_inst[15:13];
assign ID_addr   = ID_inst[12:0];
assign ID_rs     = ID_inst[12:9];
assign ID_rt     = ID_inst[8:5];
assign ID_4_0    = ID_inst[4:0];

// IF => ID
assign gen_ID_nop = is_jump | is_branch | ~is_inst_valid;
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)                  ID_stall <= 1;
    else if (is_data_valid)     ID_stall <= is_jump | is_branch;
    else                        ID_stall <= ID_stall;
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)                  ID_pc <= 0;
    else if(is_data_valid)      ID_pc <= IF_pc;
    else                        ID_pc <= ID_pc;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)               
        ID_inst <= 'hFFFF;
    else begin
        if(is_data_valid) begin
            if(is_load_use)      ID_inst <= ID_inst;
            else if(gen_ID_nop)  ID_inst <= 'hFFFF;
            else                 ID_inst <= IF_inst;
        end
        else ID_inst <= ID_inst;
    end
end

// data hazard detection
always @(*) begin
    is_load_use = 0;
    if(EXE_ctrl[MEM_READ]) begin
        if(ID_opcode == 3'b000 || ID_opcode == 3'b001 || ID_opcode == 3'b101 || ID_opcode == 3'b010) begin
            if((EXE_rt == ID_rt) || (EXE_rt == ID_rs))
                is_load_use = 1;
        end
        else if(ID_opcode == 3'b011) begin
            if(EXE_rt == ID_rs)
                is_load_use = 1;
        end
    end
end

// read data from register
always @(*) begin
    ID_rs_data = regs[ID_rs];
    ID_rt_data = regs[ID_rt];
end

// -------------
//   EXE stage
// -------------
assign EXE_opcode = EXE_inst[15:13];
assign EXE_rs     = EXE_inst[12:9];
assign EXE_rt     = EXE_inst[8:5];
assign EXE_rd     = (EXE_ctrl[MEM_READ]) ? EXE_inst[8:5] : EXE_inst[4:1];
assign EXE_func   = EXE_inst[0];
assign EXE_imm    = {{12{EXE_inst[4]}}, EXE_inst[3:0]};
assign is_zero    = ~|EXE_alu_out;

// ID => EXE
assign gen_EXE_nop = is_load_use | is_branch;
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)               EXE_stall <= 1;
    else if (is_data_valid)  EXE_stall <= ID_stall | gen_EXE_nop;
    else                     EXE_stall <= EXE_stall;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)               EXE_inst <= 'hFFFF;
    else if (is_data_valid) begin
        if (gen_EXE_nop)     EXE_inst <= 'hFFFF;
        else                 EXE_inst <= ID_inst;
    end
    else                     EXE_inst <= EXE_inst;
end

always @(posedge clk) begin
    if(is_data_valid)        EXE_pc <= ID_pc;
    else                     EXE_pc <= EXE_pc;
end

// decoder
always @(*) begin
    // {ALU_OP1, ALU_OP0, ALU_SRC, BRANCH, MEM_WRITE, MEM_READ, REG_WRITE};
    EXE_ctrl = 0;
    casex(EXE_opcode)
        3'b00x: EXE_ctrl = {EXE_opcode[0], EXE_func, 5'b00001};  // R-type
        3'b011: EXE_ctrl = 'b0110011;  // load
        3'b010: EXE_ctrl = 'b0110100;  // store
        3'b101: EXE_ctrl = 'b0001000;  // branch
    endcase
end 

// forwarding unit
always @(*) begin
    EXE_forward1 = 2'b00;
    EXE_forward2 = 2'b00;
    if (EXE_ctrl[REG_WRITE] & (EXE_rd == ID_rs))      EXE_forward1 = 2'b10;
    else if(MEM_ctrl[REG_WRITE] & (MEM_rd == ID_rs))  EXE_forward1 = 2'b01;
    
    if (EXE_ctrl[REG_WRITE] & (EXE_rd == ID_rt))      EXE_forward2 = 2'b10;
    else if(MEM_ctrl[REG_WRITE] & (MEM_rd == ID_rt))  EXE_forward2 = 2'b01;
end
always @(posedge clk) begin
    if(is_data_valid) begin
        case(EXE_forward1)
            2'b10:   EXE_rs_data <= EXE_alu_out;
            2'b01:   EXE_rs_data <= MEM_result;
            default: EXE_rs_data <= ID_rs_data;
        endcase
        case(EXE_forward2)
            2'b10:   EXE_rt_data <= EXE_alu_out;
            2'b01:   EXE_rt_data <= MEM_result;
            default: EXE_rt_data <= ID_rt_data;
        endcase
    end
    else begin
        EXE_rs_data  <= EXE_rs_data;
        EXE_rt_data  <= EXE_rt_data;
    end
end

// ALU
assign EXE_alu_in1 = EXE_rs_data;
assign EXE_alu_in2 = (EXE_ctrl[ALU_SRC]) ? EXE_imm : EXE_rt_data;
assign alu_op      = {EXE_ctrl[ALU_OP1], EXE_ctrl[ALU_OP0]};
always @(*) begin
    case(alu_op)
        2'b01: EXE_alu_out = EXE_alu_in1 + EXE_alu_in2;            // ADD
        2'b00: EXE_alu_out = EXE_alu_in1 - EXE_alu_in2;            // SUB
        2'b11: EXE_alu_out = (EXE_alu_in1 < EXE_alu_in2) ? 1 : 0;  // SLT
        2'b10: EXE_alu_out = EXE_alu_in1 * EXE_alu_in2;            // MUL
    endcase
end


// -------------
//   MEM stage
// -------------
assign MEM_addr_in = is_data_valid ? EXE_alu_out : MEM_alu_out;
assign MEM_data_in = is_data_valid ? EXE_rt_data : MEM_rt_data;
assign is_load     = is_data_valid ? EXE_ctrl[MEM_READ] : MEM_ctrl[MEM_READ];
assign is_store    = is_data_valid ? EXE_ctrl[MEM_WRITE] : MEM_ctrl[MEM_WRITE];
assign MEM_result  = MEM_ctrl[MEM_READ] ? MEM_data_out : MEM_alu_out;

// EXE => MEM
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)               MEM_stall <= 1;
    else if (is_data_valid)  MEM_stall <= EXE_stall;
    else                     MEM_stall <= MEM_stall;
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        MEM_alu_out <= 0;
        MEM_rt_data <= 0;
        MEM_ctrl    <= 0;
        MEM_rd      <= 0;
        MEM_is_nop  <= 0;
    end
    else if(is_data_valid) begin
        MEM_alu_out <= EXE_alu_out;
        MEM_rt_data <= EXE_rt_data;
        MEM_ctrl    <= EXE_ctrl;
        MEM_rd      <= EXE_rd;
        MEM_is_nop  <= EXE_opcode == 'b111;
    end
    else begin
        MEM_alu_out <= MEM_alu_out;
        MEM_rt_data <= MEM_rt_data;
        MEM_ctrl    <= MEM_ctrl;
        MEM_rd      <= MEM_rd;
        MEM_is_nop  <= MEM_is_nop;
    end
end

// ------------
//   WB stage
// ------------
// MEM => WB
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)         WB_stall <= 1;
    else               WB_stall <= MEM_stall | ~is_data_valid;

end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        WB_result   <= 0;
        WB_ctrl     <= 0;
        WB_rd       <= 0;
        WB_is_nop   <= 0;
    end
    else if(is_data_valid) begin
        WB_result   <= MEM_result;
        WB_ctrl     <= MEM_ctrl;
        WB_rd       <= MEM_rd;
        WB_is_nop   <= MEM_is_nop;
    end
    else begin
        WB_result   <= WB_result;
        WB_ctrl     <= WB_ctrl;
        WB_rd       <= WB_rd;
        WB_is_nop   <= WB_is_nop;
    end
end
// write data to register
always @(*) begin
    if(WB_ctrl && WB_rd == 0)  regs[0] = WB_result;
    else                       regs[0] = core_r0;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 1)  regs[1] = WB_result;
    else                       regs[1] = core_r1;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 2)  regs[2] = WB_result;
    else                       regs[2] = core_r2;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 3)  regs[3] = WB_result;
    else                       regs[3] = core_r3;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 4)  regs[4] = WB_result;
    else                       regs[4] = core_r4;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 5)  regs[5] = WB_result;
    else                       regs[5] = core_r5;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 6)  regs[6] = WB_result;
    else                       regs[6] = core_r6;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 7)  regs[7] = WB_result;
    else                       regs[7] = core_r7;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 8)  regs[8] = WB_result;
    else                       regs[8] = core_r8;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 9)  regs[9] = WB_result;
    else                       regs[9] = core_r9;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 10) regs[10] = WB_result;
    else                       regs[10] = core_r10;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 11) regs[11] = WB_result;
    else                       regs[11] = core_r11;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 12) regs[12] = WB_result;
    else                       regs[12] = core_r12;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 13) regs[13] = WB_result;
    else                       regs[13] = core_r13;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 14) regs[14] = WB_result;
    else                       regs[14] = core_r14;
end
always @(*) begin
    if(WB_ctrl && WB_rd == 15) regs[15] = WB_result;
    else                       regs[15] = core_r15;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        core_r0  <= 0;
        core_r1  <= 0;
        core_r2  <= 0;
        core_r3  <= 0;
        core_r4  <= 0;
        core_r5  <= 0;
        core_r6  <= 0;
        core_r7  <= 0;
        core_r8  <= 0;
        core_r9  <= 0;
        core_r10 <= 0;
        core_r11 <= 0;
        core_r12 <= 0;
        core_r13 <= 0;
        core_r14 <= 0;
        core_r15 <= 0;
    end
    else begin
        core_r0  <= regs[0];
        core_r1  <= regs[1];
        core_r2  <= regs[2];
        core_r3  <= regs[3];
        core_r4  <= regs[4];
        core_r5  <= regs[5];
        core_r6  <= regs[6];
        core_r7  <= regs[7];
        core_r8  <= regs[8];
        core_r9  <= regs[9];
        core_r10 <= regs[10];
        core_r11 <= regs[11];
        core_r12 <= regs[12];
        core_r13 <= regs[13];
        core_r14 <= regs[14];
        core_r15 <= regs[15];
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  IO_stall <= 1;
    else        IO_stall <= WB_stall | WB_is_nop;
end
// --------------------------
//   submodules declaration 
// --------------------------
Inst_Mem inst_mem (
    .clk(clk),
    .rst_n(rst_n), 
    // DRAM  
    .arid_m_inf(arid_m_inf[2*ID_WIDTH-1:ID_WIDTH]),
    .araddr_m_inf(araddr_m_inf[2*ADDR_WIDTH-1:ADDR_WIDTH]),
    .arlen_m_inf(arlen_m_inf[13:7]),
    .arsize_m_inf(arsize_m_inf[5:3]),
    .arburst_m_inf(arburst_m_inf[3:2]),
    .arvalid_m_inf(arvalid_m_inf[1]),
    .arready_m_inf(arready_m_inf[1]),
    //
    .rid_m_inf(rid_m_inf[2*ID_WIDTH-1:ID_WIDTH]),
    .rdata_m_inf(rdata_m_inf[2*DATA_WIDTH-1:DATA_WIDTH]),
    .rresp_m_inf(rresp_m_inf[3:2]),
    .rlast_m_inf(rlast_m_inf[1]),
    .rvalid_m_inf(rvalid_m_inf[1]),
    .rready_m_inf(rready_m_inf[1]),
    // SRAM
    .in_addr(IF_pc),
    .out_data(IF_inst),
    .out_valid(is_inst_valid)
);

Data_Mem data_mem (
    .clk(clk),
    .rst_n(rst_n),
    // DRAM     
    .awid_m_inf(awid_m_inf),
    .awaddr_m_inf(awaddr_m_inf),
    .awsize_m_inf(awsize_m_inf),
    .awburst_m_inf(awburst_m_inf),
    .awlen_m_inf(awlen_m_inf),
    .awvalid_m_inf(awvalid_m_inf),
    .awready_m_inf(awready_m_inf),
    //
    .wdata_m_inf(wdata_m_inf),
    .wlast_m_inf(wlast_m_inf),
    .wvalid_m_inf(wvalid_m_inf),
    .wready_m_inf(wready_m_inf),
    //
    .bid_m_inf(bid_m_inf),
    .bresp_m_inf(bresp_m_inf),
    .bvalid_m_inf(bvalid_m_inf),
    .bready_m_inf(bready_m_inf),
    //
    .arid_m_inf(arid_m_inf[ID_WIDTH-1:0]),
    .araddr_m_inf(araddr_m_inf[ADDR_WIDTH-1:0]),
    .arlen_m_inf(arlen_m_inf[6:0]),
    .arsize_m_inf(arsize_m_inf[2:0]),
    .arburst_m_inf(arburst_m_inf[1:0]),
    .arvalid_m_inf(arvalid_m_inf[0]),
    .arready_m_inf(arready_m_inf[0]),
    //
    .rid_m_inf(rid_m_inf[ID_WIDTH-1:0]),
    .rdata_m_inf(rdata_m_inf[DATA_WIDTH-1:0]),
    .rresp_m_inf(rresp_m_inf[1:0]),
    .rlast_m_inf(rlast_m_inf[0]),
    .rvalid_m_inf(rvalid_m_inf[0]),
    .rready_m_inf(rready_m_inf[0]),
    // SRAM
    .in_addr(MEM_addr_in[10:0]),
    .in_data(MEM_data_in),
    .in_r_valid(is_load),
    .in_w_valid(is_store),
    .out_data(MEM_data_out),
    .out_valid(is_data_valid)
);
endmodule

module Inst_Mem(
    			clk,
			  rst_n, 
// DRAM                 
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
      arready_m_inf,
       
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf,
// SRAM
            in_addr,
           out_data,
          out_valid
);
// parameters
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16;

// ========================
//     port declaration
// ========================
// global
input   wire clk, rst_n;
// ------------------------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]     arid_m_inf;
output  wire [ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [7-1:0]            arlen_m_inf;
output  wire [3-1:0]            arsize_m_inf;
output  wire [2-1:0]            arburst_m_inf;
output  wire                    arvalid_m_inf;
input   wire                    arready_m_inf;
// ------------------------------------------
// axi read data channel 
input   wire [ID_WIDTH-1:0]     rid_m_inf;
input   wire [DATA_WIDTH-1:0]   rdata_m_inf;
input   wire [2-1:0]            rresp_m_inf;
input   wire                    rlast_m_inf;
input   wire                    rvalid_m_inf;
output  wire                    rready_m_inf;
// ------------------------------------------
// SRAM signals
input   wire [11-1:0]           in_addr;
output  wire [DATA_WIDTH-1:0]   out_data;
output  reg                     out_valid;

// ========================
//       parameter   
// ========================
parameter I_IDLE   = 2'b00;
parameter I_REQ    = 2'b01;
parameter I_READ   = 2'b10;
parameter I_VALID  = 2'b11;

// ========================
//       reg & wire   
// ========================
// FSM
reg  [1:0]      state, next_state;
wire            invalid_flag;
// SRAM  
reg  [4-1:0]    sram_tag;
reg  [7-1:0]    sram_addr;
reg  [7-1:0]    sram_addr_reg;

// ========================
//         design   
// ========================
// --------
//   FSM
// --------
assign invalid_flag = (in_addr[10:7] != sram_tag);
always @(*) begin
    next_state = state;
    case(state)
        I_IDLE:  next_state = I_REQ;
        I_REQ:   if(arready_m_inf) next_state = I_READ;
        I_READ:  if(rlast_m_inf)   next_state = I_VALID;
        I_VALID: if(invalid_flag)  next_state = I_REQ;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) state <= I_IDLE;
    else       state <= next_state;
end

// --------
//   DRAM
// --------
assign arid_m_inf    = 0;
assign arlen_m_inf   = 7'b111_1111;
assign arsize_m_inf  = 3'b001;
assign arburst_m_inf = 2'b01;
assign araddr_m_inf  = (state == I_REQ) ? {16'b0, 4'b0001, sram_tag, 8'b0} : 0;
assign arvalid_m_inf = (state == I_REQ);
assign rready_m_inf  = (state == I_READ);

// --------
//  output
// --------
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        out_valid <= 0;
    else begin
        if(rvalid_m_inf && (sram_addr == in_addr[6:0]) && !invalid_flag)
            out_valid <= 1;
        else if(next_state == I_VALID && state == I_VALID)
            out_valid <= 1;
        else
            out_valid <= 0;
    end
end

// --------
//   SRAM
// --------
always @(posedge clk) begin
    if(next_state == I_REQ)   sram_tag <= in_addr[10:7];
    else                      sram_tag <= sram_tag;
end
always @(*) begin
    if(state == I_VALID)      sram_addr = in_addr[6:0];
    else                      sram_addr = sram_addr_reg;
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)                sram_addr_reg <= 0;
    else if(rvalid_m_inf)     sram_addr_reg <= sram_addr_reg + 1;
    else                      sram_addr_reg <= sram_addr_reg;
end
SRAM inst_sram(.Q(out_data), .CLK(clk), .CEN(1'b0), .WEN(!rvalid_m_inf), .A(sram_addr), .D(rdata_m_inf), .OEN(1'b0));

endmodule

module Data_Mem(
                clk,
			  rst_n,
// DRAM             
         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,     
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,               
      arready_m_inf,

          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf,
// SRAM
            in_addr,
            in_data,
         in_r_valid,
         in_w_valid,
           out_data,
          out_valid
);
// parameters
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16;

// ========================
//     port declaration
// ========================
// global
input   wire clk, rst_n;
// ------------------------------------------
// axi write address channel 
output  wire [ID_WIDTH-1:0]     awid_m_inf;
output  wire [ADDR_WIDTH-1:0]   awaddr_m_inf;
output  wire [3-1:0]            awsize_m_inf;
output  wire [2-1:0]            awburst_m_inf;
output  wire [7-1:0]            awlen_m_inf;
output  wire                    awvalid_m_inf;
input   wire                    awready_m_inf;
// ------------------------------------------
// axi write data channel 
output  wire [DATA_WIDTH-1:0]   wdata_m_inf;
output  wire                    wlast_m_inf;
output  reg                     wvalid_m_inf;
input   wire                    wready_m_inf;
// ------------------------------------------
// axi write response channel
input   wire [ID_WIDTH-1:0]     bid_m_inf;
input   wire [2-1:0]            bresp_m_inf;
input   wire                    bvalid_m_inf;
output  reg                     bready_m_inf;
// ------------------------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]     arid_m_inf;
output  wire [ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [7-1:0]            arlen_m_inf;
output  wire [3-1:0]            arsize_m_inf;
output  wire [2-1:0]            arburst_m_inf;
output  wire                    arvalid_m_inf;
input   wire                    arready_m_inf;
// ------------------------------------------
// axi read data channel 
input   wire [ID_WIDTH-1:0]     rid_m_inf;
input   wire [DATA_WIDTH-1:0]   rdata_m_inf;
input   wire [2-1:0]            rresp_m_inf;
input   wire                    rlast_m_inf;
input   wire                    rvalid_m_inf;
output  wire                    rready_m_inf;
// ------------------------------------------
// SRAM signals
input   wire [11-1:0]           in_addr;
input   wire [DATA_WIDTH-1:0]   in_data;
input   wire                    in_r_valid;
input   wire                    in_w_valid;
output  wire [DATA_WIDTH-1:0]   out_data;
output  reg                     out_valid;

// ========================
//       parameter   
// ========================
parameter D_IDLE   = 2'b00;
parameter D_REQ    = 2'b01;
parameter D_READ   = 2'b10;
parameter D_VALID  = 2'b11;

// ========================
//       reg & wire   
// ========================
// FSM
reg  [1:0]      state, next_state;
reg             is_aw_stage;
wire            invalid_flag;
// SRAM  
reg  [4-1:0]    sram_tag;
reg  [7-1:0]    sram_addr;
reg  [7-1:0]    sram_addr_reg;
wire [16-1:0]   sram_in_data;
wire            sram_wen;

// ========================
//         design   
// ========================
// --------
//   FSM
// --------
assign invalid_flag = (in_r_valid) && (in_addr[10:7] != sram_tag);
always @(*) begin
    next_state = state;
    case(state)
        D_IDLE:  if(in_r_valid)    next_state = D_REQ;
        D_REQ:   if(arready_m_inf) next_state = D_READ;
        D_READ:  if(rlast_m_inf)   next_state = D_VALID;
        D_VALID: if(invalid_flag)  next_state = D_REQ;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) state <= D_IDLE;
    else       state <= next_state;
end

// -------------
//   DRAM read
// -------------
assign arid_m_inf    = 0;
assign arlen_m_inf   = 7'b111_1111;
assign arsize_m_inf  = 3'b001;
assign arburst_m_inf = 2'b01;
assign araddr_m_inf  = (state == D_REQ) ? {16'b0, 4'b0001, sram_tag, 8'b0} : 0;
assign arvalid_m_inf = (state == D_REQ);
assign rready_m_inf  = (state == D_READ);

// --------------
//   DRAM write
// --------------
assign awid_m_inf    = 0;
assign awlen_m_inf   = 7'b0;
assign awsize_m_inf  = 3'b001;
assign awburst_m_inf = 2'b01;
assign awaddr_m_inf  = (in_w_valid) ? {16'b0, 4'b0001, in_addr, 1'b0} : 0;
assign awvalid_m_inf = (in_w_valid) & (is_aw_stage);
assign wdata_m_inf   = (wvalid_m_inf) ? in_data : 0;
assign wlast_m_inf   = (wvalid_m_inf);

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)                is_aw_stage <= 1;
    else begin
        if(awready_m_inf)     is_aw_stage <= 0;
        else if(bvalid_m_inf) is_aw_stage <= 1;
        else                  is_aw_stage <= is_aw_stage;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)                wvalid_m_inf <= 0;
    else begin 
        if(awready_m_inf)     wvalid_m_inf <= 1;
        else if(wready_m_inf) wvalid_m_inf <= 0;
        else                  wvalid_m_inf <= wvalid_m_inf;
    end
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)                bready_m_inf <= 0;
    else begin
        if(wready_m_inf)      bready_m_inf <= 1;
        else if(bvalid_m_inf) bready_m_inf <= 0;
        else                  bready_m_inf <= bready_m_inf;
    end
end

// --------
//  output
// --------
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)                     
        out_valid <= 1;
    else begin
        if(bvalid_m_inf)
            out_valid <= 1;
        else if(in_w_valid)            
            out_valid <= 0;
        else if((next_state == D_VALID && state == D_VALID) || next_state == D_IDLE)
            out_valid <= 1;
        else
            out_valid <= 0;
    end
end

// --------
//   SRAM
// --------
assign sram_wen = !(rvalid_m_inf || (in_w_valid && sram_tag == in_addr[10:7]));
assign sram_in_data = (in_w_valid) ? in_data : rdata_m_inf;
always @(posedge clk) begin
    if(next_state == D_REQ)    sram_tag <= in_addr[10:7];
    else                       sram_tag <= sram_tag;
end
always @(*) begin
    if(state == D_VALID)       sram_addr = in_addr[6:0];
    else                       sram_addr = sram_addr_reg;
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)                 sram_addr_reg <= 0;
    else if(rvalid_m_inf)      sram_addr_reg <= sram_addr_reg + 1;
    else                       sram_addr_reg <= sram_addr_reg;
end
SRAM data_sram(.Q(out_data), .CLK(clk), .CEN(1'b0), .WEN(sram_wen), .A(sram_addr), .D(sram_in_data), .OEN(1'b0));

endmodule