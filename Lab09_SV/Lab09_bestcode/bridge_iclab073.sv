//5/1 00:15 final
module bridge(input clk, INF.bridge_inf inf);


///////////////////////////////////////////////////////////////////////
////////////////////////////declare////////////////////////////////////
///////////////////////////////////////////////////////////////////////
typedef enum logic [1:0]  {
	S_idle,
	S_read,
	S_write,
	S_output
} State;

State current_state,next_state;

logic [63:0] write_data;
logic handshake_read,handshake_write;

///////////////////////////////////////////////////////////////////////
////////////////////////////design/////////////////////////////////////
///////////////////////////////////////////////////////////////////////
//  FSM
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) 	current_state <= S_idle;
	else 				current_state <= next_state ;
end

//next_state
always_comb begin
	case(current_state)
		S_idle: begin
			if(inf.C_in_valid) begin
				if(inf.C_r_wb) next_state = S_read;
				else next_state = S_write;
			end
			else next_state = current_state;
		end 
		S_read: begin
			if(inf.R_VALID && inf.R_READY) next_state = S_output;
			else next_state = current_state;
		end
		S_write: begin
			if(inf.W_VALID && inf.B_VALID) next_state = S_output;
			else next_state = current_state;
		end
		S_output: begin
			next_state = S_idle;
		end
		default : next_state = current_state;	
	endcase 
end

//write_data 
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n) write_data <= 64'b0;
	else if(current_state == S_idle) begin
		if(inf.C_in_valid && (!inf.C_r_wb)) write_data <= inf.C_data_w; //write
	end 
end

//C_out_valid
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n) inf.C_out_valid <= 0;
	else begin
		if(next_state == S_output) inf.C_out_valid <= 1;
		else inf.C_out_valid <= 0;
	end
end

//C_data_r
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n) inf.C_data_r <= 64'b0;
	else begin
		if(inf.R_VALID) inf.C_data_r <= inf.R_DATA;
		else inf.C_data_r <= 64'b0;
	end
end

////////////////////////////////////////////////////////////////////
//AXI Lite Signals
////////////////////////////////////////////////////////////////////

//Read//////////////////////////////////////////////////////////////
//AR_ADDR
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n) inf.AR_ADDR <= 17'b0;
	else if(inf.C_in_valid && inf.C_r_wb) inf.AR_ADDR <= {6'b100000,inf.C_addr,3'b0}; //65536 + addr*8
end
//AR_valid
always_comb begin 
	if((current_state == S_read)&&(!handshake_read)) begin
		inf.AR_VALID = 1'b1;
	end 
	else inf.AR_VALID = 1'b0;
end
//R_ready
always_comb begin 
	if((current_state == S_read)&&(handshake_read)) begin
		inf.R_READY = 1'b1;
	end 
	else inf.R_READY = 1'b0;
end
//handshake_read
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n) handshake_read <= 1'b0;
	else if(current_state == S_idle) begin
		handshake_read <= 1'b0;
	end
	else if(current_state == S_read) begin
		if(inf.AR_VALID && inf.AR_READY) handshake_read <= 1'b1;
		else if(inf.R_VALID && inf.R_READY) handshake_read <= 1'b0; //read end
	end
end


//write/////////////////////////////////////////////////////////////
//AW_ADDR
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n) inf.AW_ADDR <= 17'b0;
	else if(inf.C_in_valid && !inf.C_r_wb) inf.AW_ADDR <= {6'b100000,inf.C_addr,3'b0}; //65536 + addr*8
end
//AW_valid
always_comb begin 
	if((current_state == S_write)&&(!handshake_write)) begin
		inf.AW_VALID = 1'b1;
	end 
	else inf.AW_VALID = 1'b0;
end
//W_VALID
always_comb begin 
	if((current_state == S_write)&&(handshake_write)) begin
		inf.W_VALID = 1'b1;
	end 
	else inf.W_VALID = 1'b0;
end
//W_DATA
always_comb begin 
	if((current_state == S_write)&&(handshake_write)) begin
		inf.W_DATA = write_data;
	end 
	else inf.W_DATA = 1'b0;
end
//handshake_write
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n) handshake_write <= 1'b0;
	else if(current_state == S_idle) begin
		handshake_write <= 1'b0;
	end
	else if(current_state == S_write) begin
		if(inf.AW_VALID && inf.AW_READY) handshake_write <= 1'b1;
		else if(inf.W_VALID && inf.B_VALID) handshake_write <= 1'b0; //write end
	end
end

//BREADY
always_comb begin 
	if(current_state == S_write) begin
		inf.B_READY = 1'b1;
	end 
	else inf.B_READY = 1'b0;
end

endmodule
