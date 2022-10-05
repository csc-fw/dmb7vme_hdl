`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:30:52 03/27/2015 
// Design Name: 
// Module Name:    vmestat 
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
module vmestat(
	input FASTCLK,
	input RST,
	input STROBE,
	input WRITE_B,
	input DEVICE,
	input [9:0] COMMAND,
	input [15:0] INDATA,
	output DTACK_B,
	output [15:0] OUTDATA
);

wire readvers;
wire readdate;
wire readstat1;
wire readstat2;
reg  dtena;
wire [15:0] ver_code;
wire [15:0] date_code;
wire [3:0] board_version;
wire [3:0] firmware_version;
wire [7:0] firmware_revision;
wire [3:0] month;
wire [5:0] day;
wire [5:0] year;


//////////////////////////////////////////////////
//
// VME Status monitor
// 00: Read firmware version
// 01: Firmware date
// 02: Status of FPGA
// 03: More status
//
////////////////////////////////////////////////

initial begin
	dtena = 0;
end

// set firmware version
assign board_version     = 4'd7;
assign firmware_version  = 4'hE;
assign firmware_revision = 8'h1C;

// set date
assign month             = 4'd10;
assign day               = 6'd05;
assign year              = 6'd22;

assign ver_code  = {board_version,firmware_version,firmware_revision}; //Format: VvRR V= board version (6), v = firmware version, RR = revision
assign date_code = {month,day,year};                                   //Format: mmmmm,0ddd,ddyy,yyyy

assign readvers  = WRITE_B & DEVICE & (COMMAND[2:0] == 3'd0);
assign readdate  = WRITE_B & DEVICE & (COMMAND[2:0] == 3'd1);
//assign readstat1 = WRITE_B & DEVICE & (COMMAND[2:0] == 3'd2);
//assign readstat2 = WRITE_B & DEVICE & (COMMAND[2:0] == 3'd3);

assign OUTDATA = (STROBE & readvers) ? ver_code  : 16'hzzzz; //Format: VvRR V= board version (6), v = firmware version, RR = revision
assign OUTDATA = (STROBE & readdate) ? date_code : 16'hzzzz; //Format: mmmmm,0ddd,ddyy,yyyy
//assign OUTDATA = (STROBE & readstat1) ? status[15:0] : 16'hzzzz;
//assign OUTDATA = (STROBE & readstat2) ? status[31:16] : 16'hzzzz;

always @(posedge FASTCLK) begin
	dtena <= (STROBE & readvers) | (STROBE & readdate);
end

assign DTACK_B = dtena ? 1'b0 : 1'bz;

endmodule
