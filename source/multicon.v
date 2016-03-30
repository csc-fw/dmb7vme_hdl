`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:05:50 03/30/2015 
// Design Name: 
// Module Name:    multicon 
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
module multicon(
	input LVADCCLK,
	input LVADCDATA,
	input [6:0] LVADCEN_B,
	input [7:0] SPLITIN,
	input [15:0] INDATA,
	input [15:0] MDATAIN,
	input [3:0] MODE,
	input [17:2] VMEADD,
	input [15:0] DIAGIN,
	output LVADCBACK,
	output POWEREN_B,
	output [7:0] FROMCON,
	output [15:0] MDATAOUT,
	output [4:1] MOUTEN_B
);

wire flvmon;
wire fvmediag;
wire fsplit;
wire fvmedata;
wire fvmeadd;

assign flvmon   = (MODE == 4'h0);
assign fvmediag = (MODE == 4'h8);
assign fsplit   = (MODE == 4'hA);
assign fvmedata = (MODE == 4'hC);
assign fvmeadd  = (MODE == 4'hD);

assign LVADCBACK = MDATAIN[15];
assign POWEREN_B = !flvmon;
assign MOUTEN_B[1] = ~(flvmon | fvmediag | fsplit | fvmedata | fvmeadd);
assign MOUTEN_B[2] = ~(flvmon | fvmediag          | fvmedata | fvmeadd);
assign MOUTEN_B[3] = ~(         fvmediag          | fvmedata | fvmeadd);
assign MOUTEN_B[4] = ~(         fvmediag | fsplit | fvmedata | fvmeadd);

assign MDATAOUT[14:6] = (flvmon)   ? {LVADCDATA,LVADCCLK,LVADCEN_B} : 15'hzzzz;
assign MDATAOUT       = (fvmediag) ? DIAGIN : 16'hzzzz;
assign MDATAOUT       = (fvmedata) ? INDATA : 16'hzzzz;
assign MDATAOUT       = (fvmeadd)  ? VMEADD : 16'hzzzz;
assign MDATAOUT[7:0]  = (fsplit)   ? SPLITIN : 8'hzz;
assign FROMCON        = (fsplit)   ? MDATAIN[15:8] : 8'hzz;

endmodule
