`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:24:40 03/27/2015 
// Design Name: 
// Module Name:    serdac 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module serdac #(
	parameter TMR = 0
)(
	input FASTCLK,
	input MIDCLK,
	input RST,
	input STROBE,
	input WRITE_B,
	input DEVICE,
	input [9:0] COMMAND,
	input [15:0] INDATA,
	input DACOUT,
	output DACCS_B,
	output DACDATA,
	output DACCLK,
	output DTACK_B
);



wire writedac;
reg finished;
wire [3:0] clk_cnt;
reg shiften;
reg dt_wrtdac;
reg load;
reg load_1;
reg busy;
wire [15:0] q;

initial begin
	dt_wrtdac = 0;
end

assign writedac  = DEVICE & (COMMAND == 10'd0);

cbnce #(
	.Width(4),
	.TMR(TMR)
) clk_cnt_i (.CLK(MIDCLK),.RST(finished | RST),.CE(shiften),.Q(clk_cnt));

always @(posedge MIDCLK) begin
	load_1 <= load;
	if(RST | load)
		load <= 1'b0;
	else
		load <= STROBE & writedac & !busy;
end

srnlce #(
	.Width(16),
	.Left(1), //shift left
	.TMR(TMR)
) dac_data_reg_i(.C(MIDCLK),.CE(shiften),.CLR(RST),.L(load),.SI(1'b0),.D(INDATA),.Q(q));

always @(posedge MIDCLK) begin
	if(RST | finished)
		busy <= 1'b0;
	else
		busy <= load | busy;
end

always @(posedge MIDCLK or posedge RST) begin
	if(RST) begin
		finished <= 1'b0;
		shiften  <= 1'b0;
	end
	else begin
		finished <= (clk_cnt == 4'hF);
		if(busy) shiften <= ~shiften;
	end
end

always @(posedge FASTCLK) begin
	dt_wrtdac <= writedac & (load_1 | dt_wrtdac);
end

assign DTACK_B = dt_wrtdac  ? 1'b0 : 1'bz;
assign DACCLK  = shiften;
assign DACCS_B = !busy;
assign DACDATA = q[15] & busy;
endmodule
