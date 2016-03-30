`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:24:40 03/27/2015 
// Design Name: 
// Module Name:    portcntl 
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
module portcntl(
    input FASTCLK,
    input MIDCLK,
    input RST,
    input STROBE,
    input STRBCE,
    input WRITE_B,
    input DEVICE,
    input [9:0] COMMAND,
    input [15:0] INDATA,
    input [18:0] FF_RD_DATA,
    output RDFFNXT,
    output LDFFCLK,
    output FFWEN_B,
    output TOFF_B,
    output reg [7:1] ENAFF,
    output DTACK_B,
	 output [15:0] OUTDATA,
	 output [9:0] DIAGOUT
    );

wire writefifo;
wire readfifo;
wire selfifo;
wire selback;
wire incrfifo;
wire readhigh;
wire readlow;
reg dt_incrdff;
reg dt_wrtff;
reg dt_wrtff_m0;
reg dt_wrtff_m1;
reg dt_wrtff_m2;
reg dt_selbk;
reg dt_selff;
wire clr_wrt;
wire no_re;
reg  no_re_1;
reg  no_re_2;
wire req_re;
reg  req_re_1;
reg  req_re_2;
wire tr_req_re;
reg release_dtack;

initial begin
	dt_incrdff  = 0;
	dt_wrtff    = 0;
	dt_wrtff_m0 = 0;
	dt_wrtff_m1 = 0;
	dt_wrtff_m2 = 0;
	dt_selbk    = 0;
	dt_selff    = 0;
end



//////////////////////////////////////////////////
//
// External FIFO read and write commands
// 00: Write to FIF, 00 for LastWord/Overlap (no last, no overlap)
// 01: Write to FIF, 01 for LastWord/Overlap (last, no overlap)
// 02: Write to FIF, 10 for LastWord/Overlap (no last, overlap)
// 03: Write to FIF, 11 for LastWord/Overlap (last and overlap)
// 04: Read low order 16 bits, no FIFO read counter Increment
// 05: Read low order 16 bits, and FIFO read counter Increment
// 06: Read high order 3 bits, no FIFO read counter Increment
// 07: Read high order 3 bits, and FIFO read counter Increment
// 08: Write FIFO Select Register, (more than 1 FIFO can be enabled)
// 09: Read  FIFO Select Register, just to check 08 function
// 10:
// 11: Just Increment FIFO Read Counter
//
////////////////////////////////////////////////

assign writefifo  = DEVICE & (COMMAND[9:2] == 8'd0);
assign readfifo   = DEVICE & (COMMAND[9:2] == 8'd1);
assign selfifo    = DEVICE & (COMMAND == 10'd8);
assign selback    = DEVICE & (COMMAND == 10'd9);
assign incrfifo   = DEVICE & (COMMAND == 10'd11);
assign readlow    = (WRITE_B && readfifo && !COMMAND[1]);
assign readhigh   = (WRITE_B && readfifo &&  COMMAND[1]);
assign no_re      = (STROBE &             (readfifo & !COMMAND[0]));
assign req_re     = (STROBE & (incrfifo | (readfifo &  COMMAND[0])));
assign tr_req_re  = ~req_re_1 & req_re_2;
assign clr_wrt    = RST | !(STROBE & writefifo);

always @(posedge FASTCLK or posedge RST) begin
	if(RST) begin
		dt_incrdff  <= 1'b0;
		no_re_1     <= 1'b0;
		no_re_2     <= 1'b0;
		req_re_1    <= 1'b0;
		req_re_2    <= 1'b0;
		release_dtack <= 1'b0;
	end
	else begin
		if(release_dtack)
			dt_incrdff <= 1'b0;
		else
			dt_incrdff <= (STROBE & (incrfifo | readfifo)) | dt_incrdff;
		no_re_1     <= no_re;
		no_re_2     <= no_re_1;
		req_re_1    <= req_re;
		req_re_2    <= req_re_1;
		release_dtack <= (tr_req_re | no_re_2) & !STROBE;
	end
end
always @(posedge MIDCLK or posedge clr_wrt) begin
	if(clr_wrt) begin
		dt_wrtff_m0 <= 1'b0;
		dt_wrtff_m1 <= 1'b0;
		dt_wrtff_m2 <= 1'b0;
	end
	else begin
		dt_wrtff_m2 <= STROBE & writefifo;
		dt_wrtff_m1 <= dt_wrtff_m2;
		dt_wrtff_m0 <= dt_wrtff_m1;
	end
end
always @(posedge MIDCLK or posedge RST) begin
	if(RST) begin
		dt_wrtff    <= 1'b0;
	end
	else begin
		dt_wrtff    <= dt_wrtff_m0;
	end
end

always @(posedge FASTCLK) begin
	dt_selbk <= STROBE & selback;
	dt_selff <= STROBE & selfifo;
end

always @(posedge FASTCLK or posedge RST) begin
	if(RST)
		ENAFF <= 7'd0;
	else
		if(selfifo & STRBCE)
			ENAFF <= INDATA[6:0];
end

assign OUTDATA = (readlow)  ? FF_RD_DATA[15:0]  : 16'hzzzz;
assign OUTDATA = (readhigh) ? {13'd0,FF_RD_DATA[18:16]} : 16'hzzzz;
assign OUTDATA = (WRITE_B & selback) ? {2'd0,~ENAFF,ENAFF} : 16'hzzzz;
assign LDFFCLK = dt_wrtff_m1 & ~dt_wrtff_m0;
assign FFWEN_B = !(dt_wrtff_m2 & ~dt_wrtff_m0);

assign TOFF_B  = !(STROBE && writefifo && !WRITE_B);
assign DTACK_B = dt_incrdff ? 1'b0 : 1'bz;
assign DTACK_B = dt_wrtff   ? 1'b0 : 1'bz;
assign DTACK_B = dt_selbk   ? 1'b0 : 1'bz;
assign DTACK_B = dt_selff   ? 1'b0 : 1'bz;
assign RDFFNXT = tr_req_re;

assign DIAGOUT = {COMMAND[0],readfifo,STROBE,incrfifo,RDFFNXT,release_dtack,MIDCLK,RST,1'b0,1'b0};

endmodule
