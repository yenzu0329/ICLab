module SNN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	img,
	ker,
	weight,
	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
genvar x, y;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [6:0] count_in;
wire [2:0] count_in_x;
wire [1:0] count_in_y;
wire [2:0] count_row;
reg [7:0] image[2:0][5:0];
reg [7:0] kernel[8:0];
reg [7:0] fc_weight[3:0];
// conv
reg conv_in_valid;
wire conv_out_valid;
reg [63:0] next_conv_in;
reg [71:0] conv_in;
wire [19:0] conv_out;

// conv quatization
wire [7:0] conv_quantize_out;
wire conv_quantize_out_valid;

// maxpool
wire [7:0] max_pool_out;
wire max_pool_out_valid;

// fully connect
wire [16:0] fc_out_1;
wire [16:0] fc_out_2;
wire fc_out_valid;

// fc quantization
wire [7:0] fc_quantization_out_1;
wire [7:0] fc_quantization_out_2;
wire fc_quantization_out_valid;

// l1 distance
wire [9:0] l1_out;
wire l1_out_valid;

//==============================================//
//                   input                      //
//==============================================//
assign count_in_x = count_in % 'd6;
assign count_in_y = (count_in / 'd6) % 'd3;
assign count_row = (count_in / 'd6) % 'd6;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		count_in <= 0;
	else if(in_valid)
		count_in <= count_in + 1;
	else
		count_in <= 0;
end

generate
for(x=0;x<6;x=x+1) begin
	for(y=0;y<3;y=y+1) begin
		always@(posedge clk) begin
			if(x == count_in_x && count_in_y == y)
				image[y][x] <= img;
			else
				image[y][x] <= image[y][x];
		end
	end
end

for(x=0;x<9;x=x+1) begin
	always@(posedge clk) begin
		if(x == count_in)
			kernel[x] <= ker;
		else
			kernel[x] <= kernel[x];
	end
end


for(x=0;x<4;x=x+1) begin
	always@(posedge clk) begin
		if(in_valid && x == count_in)
			fc_weight[x] <= weight;
		else
			fc_weight[x] <= fc_weight[x];
	end
end
endgenerate

// conv
wire [23:0] row1;
wire [23:0] row2;
wire [23:0] row3;
assign row1 = {image[0][count_in_x],image[0][count_in_x-1],image[0][count_in_x-2]};
assign row2 = {image[1][count_in_x],image[1][count_in_x-1],image[1][count_in_x-2]};
assign row3 = {image[2][count_in_x],image[2][count_in_x-1],image[2][count_in_x-2]};
always@(*) begin
	case(count_in_y)
	'd2: next_conv_in = {row3[15:0],row2,row1};
	'd0: next_conv_in = {row1[15:0],row3,row2};
	'd1: next_conv_in = {row2[15:0],row1,row3};
	default: next_conv_in = 0;
	endcase
end

always@(*) begin
	if(count_row > 1 && count_in_x > 1)
		conv_in = {img,next_conv_in};
	else
		conv_in = 0;
end

always@(*) begin
	conv_in_valid = count_row > 1 && count_in_x > 1;
end


conv c1(
	.rst_n(rst_n),
	.clk(clk),
	.clk_valid(clk),
	.in_valid(conv_in_valid),
	.kernel({kernel[8],kernel[7],kernel[6],kernel[5],kernel[4],kernel[3],kernel[2],kernel[1],kernel[0]}),
	.image(conv_in),
	.out_valid(conv_out_valid),
	.out(conv_out)
);

// quantization
quatization_1 q1(
	.rst_n(rst_n),
	.clk(clk),
	.in_valid(conv_out_valid),
	.in(conv_out),
	.out(conv_quantize_out),
	.out_valid(conv_quantize_out_valid)
);

// max pool
max_pool m1(
	.rst_n(rst_n),
	.clk(clk),
	.in_valid(conv_quantize_out_valid),
	.in(conv_quantize_out),
	.out(max_pool_out),
	.out_valid(max_pool_out_valid)
);

// fully connect
fully_connect fc1(
	.rst_n(rst_n),
	.clk(clk),
	.in_valid(max_pool_out_valid),
	.in(max_pool_out),
	.weight({fc_weight[3],fc_weight[2],fc_weight[1],fc_weight[0]}),
	.out_1(fc_out_1),
	.out_2(fc_out_2),
	.out_valid(fc_out_valid)
);

// quantization 2
quatization_2 q2(
	.rst_n(rst_n),
	.clk(clk),
	.in_valid(fc_out_valid),
	.in_1(fc_out_1),
	.in_2(fc_out_2),
	.out_1(fc_quantization_out_1),
	.out_2(fc_quantization_out_2),
	.out_valid(fc_quantization_out_valid)
);

// l1 distance
L1_distance l1(
	.rst_n(rst_n),
	.clk(clk),
	.in_valid(fc_quantization_out_valid),
	.in_1(fc_quantization_out_1),
	.in_2(fc_quantization_out_2),
	.out(l1_out),
	.out_valid(l1_out_valid)
);

//output
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_data <= 0;
	end
	else if(l1_out_valid)
		out_data <= l1_out;
	else
		out_data <= 0;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else
		out_valid <= l1_out_valid;
end


endmodule



//==============================================//
//                  sub module                  //
//==============================================//




//==============================================//
//                convolution                   //
//==============================================//

module conv(
	input rst_n,
	input clk,
	input clk_valid,
	input in_valid,
	input [71:0] kernel,
	input [71:0] image,
	output reg out_valid,
	output reg [19:0] out
);
wire [15:0] mult_out[8:0];
genvar gen_conv;
generate
for(gen_conv=0;gen_conv<9;gen_conv=gen_conv+1)
	assign mult_out[gen_conv] = kernel[(gen_conv*8)+7:(gen_conv*8)] * image[(gen_conv*8)+7:(gen_conv*8)];
endgenerate
wire [19:0] next_out;
assign next_out = ( (mult_out[0] + mult_out[1]) + (mult_out[2] + mult_out[3]) ) + ( (mult_out[4] + mult_out[5]) + (mult_out[6] + mult_out[7]) + mult_out[8]);

always@(posedge clk) begin
	if(in_valid)
		out <= next_out;
	else
		out <= out;
end

always@(posedge clk_valid or negedge rst_n) begin
	if(!rst_n)
		out_valid <= 0;
	else
		out_valid <= in_valid;
end
endmodule

//==============================================//
//              quantization 2295               //
//==============================================//

module quatization_1(
	input rst_n,
	input clk,
	input in_valid,
	input [19:0] in,
	output reg [7:0] out,
	output reg out_valid
);
wire [7:0] next_out;
assign next_out = in / 'd2295;

always@(*) begin
	out = next_out;
end

always@(*) begin
	out_valid = in_valid;
end
endmodule

//==============================================//
//                 max pooling                  //
//==============================================//

module max_pool(
	input rst_n,
	input clk,
	input in_valid,
	input [7:0] in,
	output reg [7:0] out,
	output reg out_valid
);
reg [2:0] count_in;
reg [7:0] temp1;
reg [7:0] temp2;
wire [7:0] next_temp;
reg [7:0] cmp_in;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		count_in <= 0;
	else if(in_valid)
		count_in <= count_in + 1;
	else
		count_in <= count_in;
end

always@(posedge clk) begin
	if(in_valid && count_in == 0)
		temp1 <= in;
	else if(in_valid && (count_in == 'd1 || count_in == 'd4))
		temp1 <= next_temp;
	else
		temp1 <= temp1;
end

always@(posedge clk) begin
	if(in_valid && count_in == 'd2)
		temp2 <= in;
	else if(in_valid && (count_in == 'd3 || count_in == 'd6))
		temp2 <= next_temp;
	else
		temp2 <= temp2;
end

always@(*) begin
	case(count_in)
	'd1,'d4,'d5: cmp_in = temp1;
	'd3,'d6,'d7: cmp_in = temp2;
	default: cmp_in = temp1;
	endcase
end

assign next_temp = (cmp_in > in) ? cmp_in : in;

always@(posedge clk) begin
	if(count_in == 'd5 || count_in == 'd7)
		out <= next_temp;
	else
		out <= out;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		out_valid <= 0;
	else
		out_valid <= (count_in == 'd5 || count_in == 'd7) && in_valid;
end
endmodule

//==============================================//
//                fully connect                 //
//==============================================//

module fully_connect(
	input rst_n,
	input clk,
	input in_valid,
	input [7:0] in,
	input [31:0] weight,
	output reg [16:0] out_1,
	output reg [16:0] out_2,
	output reg out_valid
);
reg count_in;
wire [15:0] mul_out_1;
wire [15:0] mul_out_2;
reg [7:0] mul_in_1;
reg [7:0] mul_in_2;
reg [15:0] temp1;
reg [15:0] temp2;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		count_in <= 0;
	else if(in_valid)
		count_in <= ~count_in;
	else
		count_in <= count_in;
end

always@(*) begin
	case(count_in)
	'd0: mul_in_1 = weight[7:0];
	'd1: mul_in_1 = weight[23:16];
	endcase
end

always@(*) begin
	case(count_in)
	'd0: mul_in_2 = weight[15:8];
	'd1: mul_in_2 = weight[31:24];
	endcase
end

assign mul_out_1 = mul_in_1 * in;
assign mul_out_2 = mul_in_2 * in;

always@(posedge clk) begin
	if(in_valid)
		temp1 <= mul_out_1;
	else
		temp1 <= temp1;
end

always@(posedge clk) begin
	if(in_valid)
		temp2 <= mul_out_2;
	else
		temp2 <= temp2;
end

always@(*) begin
	if(in_valid && count_in)
		out_1 = mul_out_1 + temp1;
	else
		out_1 = 0;
end

always@(*) begin
	if(in_valid && count_in)
		out_2 = mul_out_2 + temp2;
	else
		out_2 = 0;
end

always@(*) begin
	out_valid = in_valid && count_in;
end
endmodule

//==============================================//
//               quatization 510                //
//==============================================//

module quatization_2(
	input rst_n,
	input clk,
	input in_valid,
	input [16:0] in_1,
	input [16:0] in_2,
	output reg [7:0] out_1,
	output reg [7:0] out_2,
	output reg out_valid
);
always@(*) begin
	out_1 = in_1 / 'd510;
end

always@(*) begin
	out_2 = in_2 / 'd510;
end

always@(*) begin
	out_valid = in_valid;
end
endmodule

//==============================================//
//                      L1                      //
//==============================================//


module L1_distance(
	input rst_n,
	input clk,
	input in_valid,
	input [7:0] in_1,
	input [7:0] in_2,
	output reg [9:0] out,
	output reg out_valid
);
reg [1:0] count_in;
reg [7:0] temp [3:0];
wire [7:0] next_temp[3:0];
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		count_in <= 0;
	else if(in_valid)
		count_in <= count_in + 1;
	else
		count_in <= count_in;
end

always@(posedge clk) begin
	if(in_valid && count_in == 0) begin
		temp[0] <= in_1;
		temp[1] <= in_2;
	end
	else if(in_valid && count_in == 'd1) begin
		temp[2] <= in_1;
		temp[3] <= in_2;
	end
	else begin
		temp[0] <= temp[0];
		temp[1] <= temp[1];
		temp[2] <= temp[2];
		temp[3] <= temp[3];
	end
end

reg [7:0] adder_in_1;
reg [7:0] adder_in_2;
reg [7:0] adder_in_3;
reg [7:0] adder_in_4;
always@(*) begin
	if(count_in == 'd2) begin
		adder_in_1 = (temp[0] > in_1) ? temp[0] - in_1 : in_1 - temp[0];
		adder_in_2 = (temp[1] > in_2) ? temp[1] - in_2 : in_2 - temp[1];
	end
	else begin
		adder_in_1 = 0;
		adder_in_2 = 0;
	end
end
always@(*) begin
	if(count_in == 'd3) begin
		adder_in_3 = (temp[2] > in_1) ? temp[2] - in_1 : in_1 - temp[2];
		adder_in_4 = (temp[3] > in_2) ? temp[3] - in_2 : in_2 - temp[3];
	end
	else begin
		adder_in_3 = 0;
		adder_in_4 = 0;
	end
end
wire [7:0] real_adder_in_1;
wire [7:0] real_adder_in_2;
assign real_adder_in_1 = (count_in == 'd3) ? adder_in_3 : adder_in_1;
assign real_adder_in_2 = (count_in == 'd3) ? adder_in_4 : adder_in_2;
wire [8:0] adder_out;
assign adder_out = real_adder_in_1 + real_adder_in_2;

reg [8:0] temp_out;
always@(posedge clk) begin
	if(count_in == 'd2)
		temp_out <= adder_out;
	else
		temp_out <= temp_out;
end

wire [9:0] sum;
wire [9:0] next_out;
assign sum = adder_out + temp_out;
assign next_out = (sum > 'd15) ? sum : 0;

always@(*) begin
	out = next_out;
end

always@(*) begin
	out_valid = count_in == 'd3 && in_valid;
end

endmodule