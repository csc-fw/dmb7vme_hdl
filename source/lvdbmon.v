`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:24:40 03/27/2015 
// Design Name: 
// Module Name:    lvdbmon 
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
module lvdbmon #(
	parameter TMR = 0
)(
	input FASTCLK,
	input SLOWCLK,
	input RST,
	input STROBE,
	input STRBCE,
	input WRITE_B,
	input DEVICE,
	input [9:0] COMMAND,
	input [15:0] INDATA,
	input ADCIN,
	output ADCDATA,
	output ADCCLK,
	output reg LOADON,
	output [6:0] LVADCEN_B,
	output reg [6:1] LVTURNON,
	output DTACK_B,
	output [15:0] OUTDATA,
	output [15:0] DIAGLVDB
);

wire writemax;
wire readmax;
wire writepower;
wire readpower;
wire seladc;
wire readadc;
reg  pre_load;

wire clr_qtime;
wire clr_cmax;
reg  clr_load;
reg  clr_load_1;
reg  clkmax;
reg  load;
reg  busy;
reg  rst_busy;
reg  rst_busy_1;
wire donemax;

reg dt_wrtmax;
wire [7:0]  q;
wire [15:0] qmax;
reg [4:0]  qtime;


reg dt_writepower;
reg dt_readpower;
reg dt_seladc;
reg dt_readadc;
reg [2:0] sel_adc;


initial begin
	dt_wrtmax     = 0;
	dt_writepower = 0;
	dt_readpower  = 0;
	dt_seladc     = 0;
	dt_readadc    = 0;
   busy          = 0;
end

//////////////////////////////////////////////////
//
// Serial ADC commands
// 00: Write control byte to MAX1271's
// 01: Read Data Back from 1271 Register
// 02: 
// 03: 
// 04: Write Low Voltage Power Register
// 05: Read  Low Voltage Power Register
// 06: 
// 07: 
// 08: Write Low Voltage Monitoring Serial ADC Chip Select Register
// 09: Read  Low Voltage Monitoring Serial ADC Chip Select Register
//
////////////////////////////////////////////////

assign writemax   = DEVICE & (COMMAND == 10'd0);
assign readmax    = DEVICE & (COMMAND == 10'd1);
assign writepower = DEVICE & (COMMAND == 10'd4);
assign readpower  = DEVICE & (COMMAND == 10'd5);
assign seladc     = DEVICE & (COMMAND == 10'd8);
assign readadc    = DEVICE & (COMMAND == 10'd9);

assign clr_cmax  = RST | !busy;
assign clr_qtime = RST | rst_busy_1;

srnlce #(
	.Width(16),
	.Left(1), //shift left
	.TMR(TMR)
) lvdb_rbk_reg_i(.C(SLOWCLK),.CE(busy && !rst_busy && !clkmax),.CLR(RST),.L(1'b0),.SI(ADCIN),.D(16'h0000),.Q(qmax));

srnlce #(
	.Width(8),
	.Left(1), //shift left
	.TMR(TMR)
) lvdb_inp_reg_i(.C(SLOWCLK),.CE(busy && !clkmax),.CLR(RST),.L(load && !clkmax),.SI(1'b0),.D(INDATA[7:0]),.Q(q));

always @(posedge SLOWCLK or posedge clr_cmax) begin
	if (clr_cmax)
		clkmax <= 1'b0;
	else
		if(!rst_busy) clkmax <= ~clkmax;
end

always @(posedge SLOWCLK) begin
	if(RST | clr_load)
		load <= 1'b0;
	else
		load <= load | (STROBE & writemax & !busy);
end
always @(posedge SLOWCLK or posedge RST) begin
	if(RST)
		clr_load <= 1'b0;
	else
		if(busy & !clkmax)
			clr_load <= load;
end
always @(posedge SLOWCLK) begin
	clr_load_1 <= clr_load;
end
always @(posedge SLOWCLK) begin
	rst_busy_1 <= rst_busy;
	if(RST | rst_busy)
		busy <= 1'b0;
	else
		busy <= load | busy;
end
always @(posedge SLOWCLK or posedge clr_qtime) begin
	if(clr_qtime) begin
		qtime    <= 5'h00;
		rst_busy <= 1'b0;
	end
	else begin
		if(busy & !clkmax) qtime    <= qtime + 1;
		if(busy & clkmax)  rst_busy <= (qtime == 5'd26) | (qtime == 5'd27);
	end
end

always @(posedge FASTCLK or posedge LOADON) begin
	if(LOADON)
		pre_load <= 1'b0;
	else
		pre_load <= pre_load | (STROBE & writepower);
end
always @(posedge SLOWCLK) begin
	LOADON <= pre_load;
end

always @(posedge FASTCLK or posedge RST) begin
	if(RST)
		LVTURNON <= 6'd0;
	else
		if(writepower & STRBCE)
			LVTURNON <= INDATA[5:0];
end

always @(posedge FASTCLK or posedge RST) begin
	if(RST)
		sel_adc <= 3'd0;
	else
		if(seladc & STRBCE)
			sel_adc <= INDATA[2:0];
end

always @(posedge FASTCLK) begin
	dt_wrtmax     <= writemax & (clr_load_1 | dt_wrtmax);
	dt_writepower <= STROBE & writepower;
	dt_readpower  <= STROBE & readpower;
	dt_seladc     <= STROBE & seladc;
	dt_readadc    <= STROBE & readadc;
end

assign DTACK_B = dt_wrtmax      ? 1'b0 : 1'bz;
assign DTACK_B = dt_writepower  ? 1'b0 : 1'bz;
assign DTACK_B = dt_readpower   ? 1'b0 : 1'bz;
assign DTACK_B = dt_seladc      ? 1'b0 : 1'bz;
assign DTACK_B = dt_readadc     ? 1'b0 : 1'bz;
assign DTACK_B = (STROBE && readmax && !busy) ? 1'b0 : 1'bz;

assign OUTDATA = (WRITE_B & readmax & !busy) ? qmax : 16'hzzzz;
assign OUTDATA = (WRITE_B & readpower) ? {10'd0,LVTURNON} : 16'hzzzz;
assign OUTDATA = (WRITE_B & readadc)   ? {13'd0,sel_adc} : 16'hzzzz;

assign LVADCEN_B = {~(sel_adc == 3'd6),~(sel_adc == 3'd5),~(sel_adc == 3'd4),~(sel_adc == 3'd3),~(sel_adc == 3'd2),~(sel_adc == 3'd1),~(sel_adc == 3'd0)};

assign ADCDATA = q[7];
assign ADCCLK  = ~clkmax;

assign DIAGLVDB = {busy,ADCIN,ADCCLK,ADCDATA,LVADCEN_B[0],sel_adc[1],LOADON,STROBE,writepower,DTACK_B,LVTURNON[3],INDATA[2],LVTURNON[2],INDATA[1],LVTURNON[1],INDATA[0]};

endmodule
