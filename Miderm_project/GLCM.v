//============================================================================
//----------------------------------------------------------------------------
//   (C) Copyright Si2 LAB @NCTU ED415
//   All Right Reserved
//----------------------------------------------------------------------------
//
//   ICLAB 2023 spring
//   Midterm Proejct            : GLCM 
//   Author                     : Hsi-Hao Huang
//
//----------------------------------------------------------------------------
//
//   File Name   : GLCM.v
//   Module Name : GLCM
//   Release version : V1.0 (Release Date: 2023-04)
//
//----------------------------------------------------------------------------
//============================================================================

module GLCM(
      	clk,	
        rst_n,	
      
      in_addr_M,
      in_addr_G,
      in_dir,
      in_dis,
      in_valid,
      out_valid,
      

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
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32;
input			  clk,rst_n;


// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
     therefore I declared output of AXI as wire in Poly_Ring
*/
   
// -----------------------------
// IO port
input [ADDR_WIDTH-1:0]              in_addr_M;
input [ADDR_WIDTH-1:0]              in_addr_G;
input [1:0]                            in_dir;
input [3:0]                            in_dis;
input                                in_valid;
output                              out_valid;
// -----------------------------


// axi write address channel 
output  wire [ID_WIDTH-1:0]        awid_m_inf;
output  wire [ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [2:0]               awsize_m_inf;
output  wire [1:0]              awburst_m_inf;
output  wire [3:0]                awlen_m_inf;
output  wire                    awvalid_m_inf;
input   wire                    awready_m_inf;
// axi write data channel 
output  reg  [DATA_WIDTH-1:0]     wdata_m_inf;
output  wire                      wlast_m_inf;
output  wire                     wvalid_m_inf;
input   wire                     wready_m_inf;
// axi write response channel   
input   wire [ID_WIDTH-1:0]         bid_m_inf;
input   wire [1:0]                bresp_m_inf;
input   wire              	     bvalid_m_inf;
output  wire                     bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]        arid_m_inf;
output  wire [ADDR_WIDTH-1:0]    araddr_m_inf;
output  wire [3:0]                arlen_m_inf;
output  wire [2:0]               arsize_m_inf;
output  wire [1:0]              arburst_m_inf;
output  wire                    arvalid_m_inf;
input   wire                    arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [ID_WIDTH-1:0]         rid_m_inf;
input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [1:0]                rresp_m_inf;
input   wire                      rlast_m_inf;
input   wire                     rvalid_m_inf;
output  wire                     rready_m_inf;
// -----------------------------

// ===============
//   Parameters
// ===============
// for in_mat
parameter M_IDLE    = 3'b000;
parameter M_READ_H1 = 3'b001;
parameter M_READ_1  = 3'b010;
parameter M_READ_H2 = 3'b011;
parameter M_READ_2  = 3'b100;
parameter M_WAIT    = 3'b101;
parameter M_WRITE   = 3'b110; // write back to DRAM
parameter M_OUT     = 3'b111;

// for SRAM (cache)
parameter S_READ    = 1'b0;
parameter S_WRITE   = 1'b1;

// for DRAM read
parameter DR_PREF   = 2'b00;
parameter DR_IDLE   = 2'b01;
parameter DR_REQ    = 2'b10;
parameter DR_READ   = 2'b11;

// for DRAM write
parameter DW_IDLE   = 2'b00;
parameter DW_REQ    = 2'b01;
parameter DW_WRITE  = 2'b10;
parameter DW_RESP   = 2'b11;

// for GLCM
parameter G_IDLE    = 2'b00;
parameter G_WAIT    = 2'b01;
parameter G_WRITE   = 2'b10;
parameter G_READ    = 2'b11;

// ================
//   Regs & Wires
// ================
// -------
//   FSM 
// -------
reg [2:0] m_state,  next_m_state, m_state_d1;
reg [1:0] dr_state, next_dr_state;
reg [1:0] dw_state, next_dw_state;
reg [1:0] g_state,  next_g_state, g_state_d1;
reg       s_state;
reg       start_flg;

// --------------------
//   Input infomation
// --------------------
reg  [1:0]  lst_col_filter;
reg  [7:0]  tot_offset;
wire [1:0]  lst_2bit;
wire [11:0] in_addr_M2;
reg         in_valid_d1;

// ----------
//   Matrix
// ----------
reg  [19:0] m_vec1_head;
reg  [19:0] m_vec1;
reg  [19:0] m_vec2_head;
reg  [19:0] m_vec2;
reg  [1:0]  m_cnt;

reg  [9:0]  m_vec1_addr;
reg  [9:0]  m_vec2_addr;
reg  [1:0]  m_vec1_offset;
reg  [1:0]  m_vec2_offset;
reg  [1:0]  m_jump_col;

reg  [9:0]  m_mat_end;
wire        m_row_end_flg;
reg         m_row_end_flg_d1;
wire        m_mat_end_flg;
wire        m_jump_col_flg;
reg         m_init_flg;

// -----------------
//   GLCM controls
// -----------------
reg  [31:0]  g_data_in;
reg  [7:0]   g_addr_in;
wire [31:0]  g_data_out;
wire         g_wen;
 
reg  [9:0]   g_buffer [3:0];
reg  [3:0]   g_has_data;
reg  [255:0] g_dirty;

wire         g_valid_flg;
wire         g_start_cal_flg;
wire         g_dirty_flg;
reg          g_valid_flg_d1;

// for generate g_data_in and g_addr_in
reg  [1:0]   g_sel;
reg  [31:0]  g_base;
wire [7:0]   g_buffer_0;
reg  [7:0]   g_buffer_0_d1;

// for big data
reg  [7:0]   g_big_addr [6:0];
reg  [11:0]  g_big_data [6:0];

// --------
//   DRAM 
// --------
reg  [11:0] dw_addr;
reg  [5:0]  dr_addr, next_dr_addr;
wire [3:0]  dw_req_cnt;
reg  [7:0]  dw_cnt, next_dw_cnt, temp_dw_cnt;
reg  [3:0]  dr_cnt;

// -----------------
//   SRAM controls
// -----------------
reg  [9:0]  s_addr_in;
wire [19:0] s_data_in;
wire [19:0] s_data_out;
wire        s_wen;

reg  [5:0]  s_block_addr;
reg  [3:0]  s_block_offset;

reg  [63:0] s_valid;
wire        s_valid_flg;
reg         s_valid_flg_d1;

// ==========
//   Design
// ==========
// --------------------
//   Input infomation
// --------------------
assign lst_2bit = in_addr_M[1:0];
assign in_addr_M2 = in_addr_M + tot_offset;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  in_valid_d1 <= 0;
    else        in_valid_d1 <= in_valid;
end

always @(posedge clk) begin
    if(in_valid) begin
        lst_col_filter <= 4 - tot_offset[1:0];

        m_vec1_offset  <= in_addr_M;
        m_vec2_offset  <= in_addr_M2;
 
        m_mat_end      <= lst_2bit ? (in_addr_M[11:2] + 64) : (in_addr_M[11:2] + 63);
        m_jump_col     <= tot_offset[3:2];
    end 
    else begin 
        lst_col_filter <= lst_col_filter;
 
        m_vec1_offset  <= m_vec1_offset;
        m_vec2_offset  <= m_vec2_offset;
 
        m_mat_end      <= m_mat_end;
        m_jump_col     <= m_jump_col;
    end
end

always @(*) begin
    case(in_dir)
        2'b01:   tot_offset = {in_dis, 4'b0};     // offset = (in_dis, 0)
        2'b10:   tot_offset = {4'b0,   in_dis};   // offset = (0, in_dis)
        default: tot_offset = {in_dis, in_dis};   // offset = (in_dis, in_dis)
    endcase
end

// ----------
//   Matrix
// ----------
assign out_valid = (m_state == M_OUT);
assign m_mat_end_flg = (m_vec2_addr >= m_mat_end);
assign m_row_end_flg = (m_cnt == 3);
assign m_jump_col_flg = (m_jump_col > 0) && m_row_end_flg;

// FSM
always @(*) begin
    next_m_state = m_state;
    case(m_state)
        M_IDLE:
            if(in_valid_d1) begin
                if(m_vec1_offset != 0)
                    next_m_state = M_READ_H1;
                else
                    next_m_state = M_READ_1;
            end
        M_READ_H1:
            if(s_valid_flg) begin
                next_m_state = M_READ_1;
            end
        M_READ_1:
            if(s_valid_flg) begin
                if((m_init_flg || ((m_jump_col > 0) && (m_cnt == m_jump_col))) && m_vec2_offset != 0)
                    next_m_state = M_READ_H2;
                else
                    next_m_state = M_READ_2;
            end
        M_READ_H2:
            if(s_valid_flg) begin
                next_m_state = M_READ_2;
            end
        M_READ_2:
            if(s_valid_flg && g_valid_flg) begin
                if(m_mat_end_flg && m_row_end_flg)
                    next_m_state = M_WAIT;
                else begin
                    if(m_jump_col_flg && m_vec1_offset != 0)
                        next_m_state = M_READ_H1;
                    else
                        next_m_state = M_READ_1;
                end
            end
        M_WAIT:
            if(g_valid_flg && m_state_d1 == M_WAIT) begin
                next_m_state = M_WRITE;
            end
        M_WRITE:
            if(dw_req_cnt == 15 && wlast_m_inf) begin
                next_m_state = M_OUT;
            end
        M_OUT:
            next_m_state = M_IDLE;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  m_state <= M_IDLE;
    else        m_state <= next_m_state;
end

always @(posedge clk) begin
    if(in_valid) begin
        m_cnt <= tot_offset[3:2];
    end
    else if(m_state == M_READ_2 && s_valid_flg && g_valid_flg) begin
        if(m_cnt == 3)
            m_cnt <= m_jump_col;
        else
            m_cnt <= m_cnt + 1;
    end
    else begin
        m_cnt <= m_cnt;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)   m_state_d1 <= 0;    
    else         m_state_d1 <= m_state;    
end

// m_init_flg
always @(posedge clk) begin
    if(m_state == M_IDLE)
        m_init_flg <= 1;
    else if(m_state == M_READ_2)
        m_init_flg <= 0;
    else
        m_init_flg <= m_init_flg;
end

// m_vec1_head
always @(posedge clk) begin
    if((m_state_d1 == M_READ_H1 || m_state_d1 == M_READ_1) && s_valid_flg_d1)
        m_vec1_head <= s_data_out;
    else
        m_vec1_head <= m_vec1_head;
end

// m_vec1
always @(posedge clk) begin
    if(m_state_d1 == M_READ_1) begin
        case(m_vec1_offset)
            0:  m_vec1 <= s_data_out;
            1:  m_vec1 <= {s_data_out[4:0],  m_vec1_head[19:5]};
            2:  m_vec1 <= {s_data_out[9:0],  m_vec1_head[19:10]};
            3:  m_vec1 <= {s_data_out[14:0], m_vec1_head[19:15]};
        endcase
    end
    else begin
        m_vec1 <= m_vec1;
    end
end

// m_vec2_head
always @(posedge clk) begin
    if((m_state_d1 == M_READ_H2 || m_state_d1 == M_READ_2 && g_valid_flg_d1) && s_valid_flg_d1)
        m_vec2_head <= s_data_out;
    else
        m_vec2_head <= m_vec2_head;
end

// m_vec2
always @(*) begin
    m_vec2 = s_data_out;
    case(m_vec2_offset)
        0:  m_vec2 = s_data_out;
        1:  m_vec2 = {s_data_out[4:0],  m_vec2_head[19:5]};
        2:  m_vec2 = {s_data_out[9:0],  m_vec2_head[19:10]};
        3:  m_vec2 = {s_data_out[14:0], m_vec2_head[19:15]};
    endcase
end

// m_vec1_addr
always @(posedge clk) begin
    if(in_valid)
        m_vec1_addr <= in_addr_M >> 2;
    else begin
        if(m_state == M_READ_H1 && s_valid_flg) begin
            m_vec1_addr <= m_vec1_addr + 1;
        end
        else if(m_state == M_READ_1 && s_valid_flg) begin
            if(m_jump_col_flg)
                m_vec1_addr <= m_vec1_addr + m_jump_col + (m_vec1_offset == 0);
            else
                m_vec1_addr <= m_vec1_addr + 1;
        end
        else begin
            m_vec1_addr <= m_vec1_addr;
        end
    end
end

// m_vec2_addr
always @(posedge clk) begin
    if(in_valid) begin
        m_vec2_addr <= in_addr_M2 >> 2;
    end
    else if(m_state == M_READ_H2 && s_valid_flg) begin
        m_vec2_addr <= m_vec2_addr + 1;
    end
    else if(m_state == M_READ_2 && g_valid_flg && s_valid_flg) begin
        if(m_jump_col_flg)
            m_vec2_addr <= m_vec2_addr + m_jump_col + (m_vec2_offset == 0);
        else
            m_vec2_addr <= m_vec2_addr + 1;
    end
    else begin
        m_vec2_addr <= m_vec2_addr;
    end
end


// --------
//   GLCM
// --------
assign g_valid_flg = (g_state == G_IDLE) || (g_has_data == 1 && next_g_state == G_WRITE);
assign g_start_cal_flg = (m_state_d1 == M_READ_2) && (m_state != M_READ_2);
assign g_dirty_flg = g_dirty[g_buffer_0];
assign g_buffer_0 = g_buffer[0][9:2];

always @(posedge clk) begin
    g_valid_flg_d1 <= g_valid_flg;
end

always @(posedge clk) begin
    m_row_end_flg_d1 <= m_row_end_flg;
end

always @(posedge clk) begin
    g_buffer_0_d1 <= g_buffer_0;
end

// GLCM memory control
assign g_wen = ~(g_state == G_WRITE);

always @(*) begin
    if(m_state_d1 == M_WRITE)
        g_addr_in = next_dw_cnt;
    else
        g_addr_in = g_buffer_0_d1;
end

always @(posedge clk) begin
    g_sel <= g_buffer[0][1:0];
end

always @(*) begin
    if(g_state_d1 == G_READ)  g_base = g_data_out;
    else                      g_base = 0;
end

always @(*) begin
    g_data_in = 0;
    case(g_sel)
        0:  g_data_in = g_base + 32'h00000001;
        1:  g_data_in = g_base + 32'h00000100;
        2:  g_data_in = g_base + 32'h00010000;
        3:  g_data_in = g_base + 32'h01000000;
    endcase
end

// FSM
always @(*) begin
    next_g_state = g_state;
    case(g_state)
        G_IDLE:
            if(g_start_cal_flg)
                next_g_state = G_WAIT;
        G_WAIT:
            if(g_dirty_flg)
                next_g_state = G_READ;
            else
                next_g_state = G_WRITE;
        G_WRITE:
            if(g_valid_flg_d1) begin
                if(g_start_cal_flg)
                    next_g_state = G_WAIT;
                else
                    next_g_state = G_IDLE;
            end
            else begin
                if(g_dirty_flg)
                    next_g_state = G_READ;
                else
                    next_g_state = G_WRITE;
            end
        G_READ:
            next_g_state = G_WRITE;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  g_state <= G_IDLE;
    else        g_state <= next_g_state;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  g_state_d1 <= 0;
    else        g_state_d1 <= g_state;    
end

// g_buffer
always @(posedge clk) begin
    if(g_start_cal_flg) begin
        g_buffer[0] <= {m_vec1[4:0],   m_vec2[4:0]};
        g_buffer[1] <= {m_vec1[9:5],   m_vec2[9:5]}; 
        g_buffer[2] <= {m_vec1[14:10], m_vec2[14:10]}; 
        g_buffer[3] <= {m_vec1[19:15], m_vec2[19:15]}; 
    end
    else begin
        if(next_g_state == G_WRITE) begin
            g_buffer[0] <= g_buffer[1];
            g_buffer[1] <= g_buffer[2];
            g_buffer[2] <= g_buffer[3];
            g_buffer[3] <= g_buffer[3];
        end
        else begin
            g_buffer[0] <= g_buffer[0];
            g_buffer[1] <= g_buffer[1];
            g_buffer[2] <= g_buffer[2];
            g_buffer[3] <= g_buffer[3];
        end
    end
end

// g_has_data
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        g_has_data <= 0;
    end
    else if(g_start_cal_flg) begin
        if(m_row_end_flg_d1) begin
            case(lst_col_filter)
                2'd1:    g_has_data <= 4'b0001;
                2'd2:    g_has_data <= 4'b0011;
                2'd3:    g_has_data <= 4'b0111;
                default: g_has_data <= 4'b1111;
            endcase
        end
        else begin
            g_has_data <= 4'b1111;
        end
    end
    else begin
        if(next_g_state == G_WRITE) 
            g_has_data <= g_has_data >> 1;
        else
            g_has_data <= g_has_data;
    end
end

// g_dirty
always @(posedge clk) begin
    if(m_state == M_IDLE) begin
        g_dirty <= 0;
    end
    else begin
        if(next_g_state == G_WRITE)
            g_dirty <= g_dirty | (1 << g_buffer_0);
        else
            g_dirty <= g_dirty;
    end
end

// ----------------------
//   DRAM read controls
// ----------------------
// FSM
always @(*) begin
    next_dr_state = dr_state;
    case(dr_state)
        DR_PREF:
            next_dr_state = DR_REQ;
        DR_IDLE:
            if(s_valid[next_dr_addr] == 0)
                next_dr_state = DR_REQ;
        DR_REQ:
            if(arready_m_inf)
                next_dr_state = DR_READ;
        DR_READ:
            if(rlast_m_inf)
                next_dr_state = DR_IDLE;
    endcase 
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)        dr_state <= DR_PREF;
    else              dr_state <= next_dr_state;
end

// dr_cnt
always @(posedge clk) begin
    if(rvalid_m_inf & rready_m_inf)
        dr_cnt <= dr_cnt + 1;
    else
        dr_cnt <= 0;
end

// dr_addr
always @(posedge clk) begin
    if(dr_state == DR_PREF)
        next_dr_addr <= 0;
    if(s_valid[s_block_addr] == 0)
        next_dr_addr <= s_block_addr;
    else if(s_valid[next_dr_addr] == 0)
        next_dr_addr <= next_dr_addr;
    else
        next_dr_addr <= next_dr_addr + 1;
end

always @(posedge clk) begin
    if(dr_state == DR_PREF)
        dr_addr <= 0;
    else if(dr_state == DR_IDLE)
        dr_addr <= next_dr_addr;
    else
        dr_addr <= dr_addr;
end

// axi read address channel 
assign arid_m_inf    = 0;
assign araddr_m_inf  = {16'b0, 4'b0001, dr_addr, 6'b000000};
assign arlen_m_inf   = 4'b1111;
assign arsize_m_inf  = 3'b010;
assign arburst_m_inf = 2'b01;
assign arvalid_m_inf = (dr_state == DR_REQ);

// axi read data channel
assign rready_m_inf = (dr_state == DR_READ);

// -----------------------
//   DRAM write controls
// -----------------------
// FSM
assign dw_req_cnt = dw_cnt[7:4];
always @(*) begin
    next_dw_state = dw_state;
    case(dw_state)
        DW_IDLE: 
            if(next_m_state == M_WRITE)
                next_dw_state = DW_REQ;
        DW_REQ:
            if(awready_m_inf)
                next_dw_state = DW_WRITE;
        DW_WRITE:
            if(wlast_m_inf)
                next_dw_state = DW_RESP;
        DW_RESP:
            if(bvalid_m_inf) begin
                if(dw_cnt == 0)
                    next_dw_state = DW_IDLE;
                else begin
                    next_dw_state = DW_REQ;
                end
            end
    endcase
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)        dw_state <= DW_IDLE;
    else              dw_state <= next_dw_state;
end

// dw_cnt
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        next_dw_cnt <= 0;
    else if(dw_state == DW_IDLE)  
        next_dw_cnt <= 0;
    else if(wlast_m_inf)
        next_dw_cnt <= dw_cnt + 1;
    else if(dw_state == DW_WRITE)
        next_dw_cnt <= next_dw_cnt + 1;
    else
        next_dw_cnt <= next_dw_cnt;
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)    temp_dw_cnt <= 0;
    else          temp_dw_cnt <= next_dw_cnt;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)    
        dw_cnt <= 0;
    else if(wvalid_m_inf & wready_m_inf) 
        dw_cnt <= dw_cnt + 1;
    else
        dw_cnt <= dw_cnt;
end

// dw_addr
always @(posedge clk) begin
    if(in_valid) begin
        dw_addr <= in_addr_G;
    end
    else if(wvalid_m_inf & wready_m_inf) begin
        dw_addr <= dw_addr + 4;
    end
    else
        dw_addr <= dw_addr; 
end

// axi write address channel 
assign awid_m_inf    = 0;
assign awaddr_m_inf  = {16'b0, 4'b0010, dw_addr};
assign awlen_m_inf   = 4'b1111;
assign awsize_m_inf  = 3'b010;
assign awburst_m_inf = 2'b01;
assign awvalid_m_inf = (dw_state == DW_REQ);

// axi write data channel 
assign wvalid_m_inf = (dw_state == DW_WRITE);
assign wlast_m_inf = (dw_cnt[3:0] == 15);
always @(posedge clk) begin
    wdata_m_inf <= (g_dirty[temp_dw_cnt]) ? g_data_out : 0;
end

// axi write response channel 
assign bready_m_inf = (dw_state == DW_RESP);

// --------
//   SRAM 
// --------
// SRAM memory control
assign s_wen = ~(s_state == S_WRITE);
assign s_data_in = {rdata_m_inf[28:24], rdata_m_inf[20:16], rdata_m_inf[12:8], rdata_m_inf[4:0]};

always @(*) begin
    if(m_state == M_READ_H2 || m_state == M_READ_2) begin
        s_block_addr   = m_vec2_addr[9:4];
        s_block_offset = m_vec2_addr[3:0];
    end
    else begin
        s_block_addr   = m_vec1_addr[9:4];
        s_block_offset = m_vec1_addr[3:0];
    end
    if(s_state == S_WRITE)
        s_addr_in = {dr_addr, dr_cnt};
    else
        s_addr_in = {s_block_addr, s_block_offset};
end

// FSM
always @(*) begin
    if(rvalid_m_inf)   s_state = S_WRITE;
    else               s_state = S_READ;
end

// s_valid
assign s_valid_flg = s_valid[s_block_addr] && (s_state == S_READ);
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        s_valid <= 0;
    end
    else begin
        if(rlast_m_inf)
            s_valid <= s_valid | (1 << dr_addr);
        else 
            s_valid <= s_valid;
    end
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)  s_valid_flg_d1 <= 0;
    else        s_valid_flg_d1 <= s_valid_flg;
end


// ---------------
//   SRAM blocks
// ---------------
sram_20x1024 sram_C(.Q(s_data_out), .CLK(clk), .CEN(1'b0), .WEN(s_wen), .A(s_addr_in), .D(s_data_in), .OEN(1'b0));
sram_32x256  sram_G(.Q(g_data_out), .CLK(clk), .CEN(1'b0), .WEN(g_wen), .A(g_addr_in), .D(g_data_in), .OEN(1'b0));

endmodule





