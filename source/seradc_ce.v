`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:24:40 03/27/2015 
// Design Name: 
// Module Name:    seradc 
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
module seradc_ce #(
	parameter TMR = 0
)(
	input BBCLK,
	input FASTCLK,
	input SLOWCLK_EN,
	input RST,
	input STROBE,
	input STRBCE,
   input WRITE_B,
	input ADCBUSY_B,
	input DEVICE,
	input [9:0] COMMAND,
	input [15:0] INDATA,
	input [2:1] ADCIN,
	output ADCCLK,
	output ADCDATA,
	output [4:1] ADCENA_B,
	output LED,
	output DTACK_B,
	output BBCONV,
	output [15:0] OUTDATA,
	output [15:0] DIAGADC
);

wire dataready;
wire writemax;
wire readmax;
wire readbb;
wire seladc;
wire readadc;
wire clr_qtime;
wire clr_cmax;
reg  clr_load;
reg  clkmax;
reg  load;
reg  busy;
reg  rst_busy;
reg  rst_busy_1;
wire donemax;

reg dt_rdsel;
reg dt_wrtsel;
reg dt_wrtmax;
reg [4:1] seladcreg_b;
wire [7:0]  q;
wire [15:0] qmax;
wire [15:0] qburrb;
reg  [4:0] qtime;

initial begin
   dt_rdsel   = 0;
   dt_wrtsel  = 0;
	dt_wrtmax  = 0;
	busy       = 0;
end


//////////////////////////////////////////////////
//
// Serial ADC commands
// 00: Write Control Byte to MAX1271s
// 01: Read data back from 1271 register
// 02:
// 03: Read data back from Burr-Brown register
// 04: 
// 05: 
// 06: 
// 07: 
// 08: Write Serial ADC Chip Select register
// 09: Read  Serial ADC Chip Select register
//
////////////////////////////////////////////////

assign writemax  = DEVICE & (COMMAND == 10'd0);
assign readmax   = DEVICE & (COMMAND == 10'd1);
assign readbb    = DEVICE & (COMMAND == 10'd3);
assign seladc    = DEVICE & (COMMAND == 10'd8);
assign readadc   = DEVICE & (COMMAND == 10'd9);

assign clr_cmax  = RST | !busy;
assign clr_qtime = RST | rst_busy_1;

srnlce #(
	.Width(16),
	.Left(1), //shift left
	.TMR(TMR)
) maxadc_rbk_reg_i(.C(FASTCLK),.CE(SLOWCLK_EN && busy && !rst_busy && !clkmax),.CLR(RST),.L(1'b0),.SI(ADCIN[1]),.D(16'h0000),.Q(qmax));

srnlce #(
	.Width(8),
	.Left(1), //shift left
	.TMR(TMR)
) adc_inp_reg_i(.C(FASTCLK),.CE(SLOWCLK_EN && busy && !clkmax),.CLR(RST),.L(load && !clkmax),.SI(1'b0),.D(INDATA[7:0]),.Q(q));

srnlce #(
	.Width(16),
	.Left(1), //shift left
	.TMR(TMR)
) bbadc_rbk_reg_i(.C(BBCLK),.CE(1'b1),.CLR(RST),.L(1'b0),.SI(ADCIN[2]),.D(16'h0000),.Q(qburrb));

BB_adc_ce_FSM 
BB_adc_FSM_i (
	.CLK(FASTCLK),
	.CE(SLOWCLK_EN),
	.RST(RST),
	.STROBE(STROBE),
	.READBB(readbb),
	.ADCBUSY(!ADCBUSY_B),
	.BBCONV(BBCONV),
	.DATAREADY(dataready)
);

always @(posedge FASTCLK or posedge RST) begin
	if(RST)
		seladcreg_b <= 4'hF;
	else
		if(seladc & STRBCE)
			seladcreg_b <= INDATA[3:0];
end

always @(posedge FASTCLK or posedge clr_cmax) begin
	if (clr_cmax)
		clkmax <= 1'b0;
	else
		if(SLOWCLK_EN) begin
			if(!rst_busy) clkmax <= ~clkmax;
		end
end

always @(posedge FASTCLK) begin
	if(RST | clr_load)
		load <= 1'b0;
	else
		if(SLOWCLK_EN) begin
			load <= load | (STROBE & writemax & !busy);
		end
end
always @(posedge FASTCLK or posedge RST) begin
	if(RST)
		clr_load <= 1'b0;
	else
		if(SLOWCLK_EN) begin
			if(busy & !clkmax)
				clr_load <= load;
		end
end
always @(posedge FASTCLK) begin
	if(SLOWCLK_EN) begin
		rst_busy_1 <= rst_busy;
		if(RST | rst_busy)
			busy <= 1'b0;
		else
			busy <= load | busy;
	end
end
always @(posedge FASTCLK or posedge clr_qtime) begin
	if(clr_qtime) begin
		qtime    <= 5'h00;
		rst_busy <= 1'b0;
	end
	else
		if(SLOWCLK_EN) begin
			if(busy & !clkmax) qtime    <= qtime + 1;
			if(busy & clkmax)  rst_busy <= (qtime == 5'd26) | (qtime == 5'd27);
		end
end

always @(posedge FASTCLK) begin
   dt_rdsel  <= (STROBE & readadc);
   dt_wrtsel <= (STROBE & seladc);
	dt_wrtmax <= writemax & (clr_load | dt_wrtmax);
end

assign DTACK_B = (STROBE && readmax && !busy) ? 1'b0 : 1'bz;
assign DTACK_B = (STROBE && readbb && dataready) ? 1'b0 : 1'bz;
assign DTACK_B = dt_rdsel   ? 1'b0 : 1'bz;
assign DTACK_B = dt_wrtsel  ? 1'b0 : 1'bz;
assign DTACK_B = dt_wrtmax  ? 1'b0 : 1'bz;

assign OUTDATA = (WRITE_B & readbb ) ? qburrb : 16'hzzzz;
assign OUTDATA = (WRITE_B & readmax & !busy) ? qmax : 16'hzzzz;
assign OUTDATA = (WRITE_B & readadc) ? {12'h000,seladcreg_b} : 16'hzzzz;
assign ADCENA_B = {seladcreg_b[4],!(seladcreg_b[3:1]==3'b011),!(seladcreg_b[3:1]==3'b101),!(seladcreg_b[3:1]==3'b110)};
assign ADCDATA = q[7];
assign ADCCLK  = ~clkmax;
assign LED     = ~busy;
assign DIAGADC = {busy,ADCCLK,ADCDATA,OUTDATA[9:6],ADCENA_B[2],DTACK_B,qmax[9:6],ADCENA_B[1],ADCIN[1],clkmax};

endmodule
