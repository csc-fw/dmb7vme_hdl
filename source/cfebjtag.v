`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:30:52 03/27/2015 
// Design Name: 
// Module Name:    cfebjtag 
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
module cfebjtag(
	input FASTCLK,
	input SLOWCLK,
	input RST,
	input INITJTAGS,
	input STROBE,
	input STRBCLK,
	input WRITE_B,
	input DEVICE,
	input [9:0] COMMAND,
	input [15:0] INDATA,
	input [5:1] FEBTDO,
	output TDI,
	output TMS,
	output [5:1] TCK,
	output LED,
	output DTACK_B,
	output [15:0] OUTDATA,
	output [15:0] DIAGOUT
);

wire datashft;
wire instshft;
wire readtdo;
wire selcfeb;
wire readcfeb;
wire rstjtag;

wire tdo;
reg pbsy;
reg busy;
reg busyp1;
reg [5:1] selfeb;
wire [15:0] q;
wire [15:0] qc;
wire shdata;
wire shihead;
wire shdhead;
wire shtail;
reg enable;
reg load;
reg pload;
reg dt1,dt2,dt3,dt4;
wire dtena;
reg dt_rdsel;
reg dt_wrtsel;
reg dheaden;
reg iheaden;
reg tailen;
reg resetjtag;
reg okrst;
reg jr1;
wire donedata_m1;
reg donedata;
reg donedata_p1;
reg donedata_p2;
wire donedhead;
wire doneihead;
wire donetail;
wire donedhead_p1;
wire doneihead_p1;
wire donetail_p1;
wire resetdone;
wire clr_bsy;
wire clr_cnt;
reg [4:0] tms_ihead_sr;
reg [4:0] tms_dhead_sr;
reg [1:0] tms_tail_sr;
reg [5:0] tms_rst_sr;
wire [3:0] shft_cnt;
wire [3:0] head_dcnt;
wire [3:0] head_icnt;
wire [3:0] tail_cnt;
wire [3:0] rst_cnt;


//////////////////////////////////////////////////
//
// CFEB JTAG commands
// 00: Shift data, no header, no trailer
// 01: Shift data with header only
// 02: Shift data with trailer only
// 03: Shift data with header and trailer
// 04: 
// 05: Read TDO register
// 06: Reset JTAG State machine
// 07: Shift Instruction register
// 08: Write CFEB Select Register
// 09: Read CFEB Select Register
//
////////////////////////////////////////////////

assign datashft  = DEVICE & (COMMAND[9:2] == 8'd0);
assign readtdo   = DEVICE & (COMMAND == 10'd5);
assign rstjtag   = DEVICE & (COMMAND == 10'd6);
assign instshft  = DEVICE & (COMMAND == 10'd7);
assign selcfeb   = DEVICE & (COMMAND == 10'd8);
assign readcfeb  = DEVICE & (COMMAND == 10'd9);

assign rdtdodk   = readtdo & STROBE & ~busyp1 & ~busy;

assign tdo = (selfeb == 5'b00001) ? FEBTDO[1] : 1'bz;
assign tdo = (selfeb == 5'b00010) ? FEBTDO[2] : 1'bz;
assign tdo = (selfeb == 5'b00100) ? FEBTDO[3] : 1'bz;
assign tdo = (selfeb == 5'b01000) ? FEBTDO[4] : 1'bz;
assign tdo = (selfeb == 5'b10000) ? FEBTDO[5] : 1'bz;
assign TDI = q[0];
assign TMS = (shihead)   ? tms_ihead_sr[0] : 1'bz;
assign TMS = (shdhead)   ? tms_dhead_sr[0] : 1'bz;
assign TMS = (shtail)    ? tms_tail_sr[0]  : 1'bz;
assign TMS = (resetjtag) ? tms_rst_sr[0]   : 1'bz;
assign TMS = (shdata)    ? tailen & donedata_m1 : 1'bz;
assign TCK = {5{enable}} & selfeb;

assign shdata  = busy & !dheaden & !iheaden & !donedata_p1;
assign shihead = busy & iheaden;
assign shdhead = busy & dheaden;
assign shtail  = busy & tailen & donedata_p1;
assign donedata_m1 = (shft_cnt == 4'b0) & !load;
assign donedhead = (head_dcnt == 4'd5);
assign doneihead = (head_icnt == 4'd5);
assign donetail  = tail_cnt[1];
assign resetdone = (rst_cnt == 4'd12);
assign clr_cnt = RST | donedata_p1 | donedata;
assign clr_bsy = RST | donetail | (donedata_p1 & !tailen);

assign OUTDATA = rdtdodk ? qc : 16'hzzzz;
assign OUTDATA = (STROBE & readcfeb) ? {11'h000,selfeb} : 16'hzzzz;
assign dtena   = dt1 & dt2 & dt3 & dt4;
assign DTACK_B = rdtdodk ? 1'b0 : 1'bz;
assign DTACK_B = dtena   ? 1'b0 : 1'bz;
assign DTACK_B = (resetdone & !INITJTAGS) ? 1'b0 : 1'bz;
assign DTACK_B = dt_rdsel   ? 1'b0 : 1'bz;
assign DTACK_B = dt_wrtsel  ? 1'b0 : 1'bz;
assign LED     = !dtena;
assign DIAGOUT = {donedhead,shdhead,donedata_p1,iheaden,dheaden,STROBE,readtdo,SLOWCLK,shdata,tdo,RST,DTACK_B,rdtdodk,busy,enable,load};

sr16lce 
tdo_rbk_reg_i(.C(SLOWCLK),.CE(shdata & !enable),.CLR(RST),.L(1'b0),.SRI(tdo),.D(16'h0000),.Q(qc));

sr16lce 
tdi_reg_i(.C(SLOWCLK),.CE(shdata & enable),.CLR(RST),.L(load),.SRI(q0),.D(INDATA),.Q(q));

always @(posedge STRBCLK or posedge load or posedge RST)begin
	if(RST | load)
		pload <= 1'b0;
	else
		pload <= datashft | instshft;
end
always @(posedge SLOWCLK) begin
	load <= pload & !busy;
	dt3  <= dt2;
	dt4  <= dt4;
end
always @(posedge SLOWCLK or negedge STROBE)begin
	if(!STROBE) begin
		dt1 <= 1'b0;
		dt2 <= 1'b0;
	end
	else begin
		if(!busy) dt1 <= datashft | instshft;
		dt2 <= dt1;
	end
end

always @(posedge STRBCLK or posedge donedhead or posedge RST)begin
	if(RST | donedhead)
		dheaden <= 1'b0;
	else
		if(datashft & !busy) dheaden <= COMMAND[0];
end
always @(posedge STRBCLK or posedge doneihead or posedge RST)begin
	if(RST | doneihead)
		iheaden <= 1'b0;
	else
		if(instshft & !busy) iheaden <= COMMAND[0];
end
always @(posedge SLOWCLK or posedge donetail or posedge RST)begin
	if(RST | donetail)
		tailen <= 1'b0;
	else
		if((datashft | instshft) & pload & !busy) tailen <= COMMAND[1];
end
always @(posedge SLOWCLK or posedge RST)begin
	if(RST)
		enable <= 1'b0;
	else
		if(resetjtag | busy) enable <= !enable; // enable is TCLK
end

udl_cnt #(
	.Width(4),
	.TMR(TMR)
) bit_cnt_i (.CLK(SLOWCLK),.RST(clr_cnt),.CE(shdata & enable),.L(load),.UP(1'b0),.D(COMMAND[9:6]),.Q(shft_cnt));

always @(posedge SLOWCLK or posedge load)begin
	if(load) begin
		donedata    <= 1'b0;
		donedata_p1 <= 1'b0;
		donedata_p2 <= 1'b0;
	end
	else begin
		if(shdata) donedata <= donedata_m1;
		donedata_p1 <= donedata;
		donedata_p2 <= donedata_p1;
	end
end

always @(posedge SLOWCLK or posedge RST)begin
	if(RST) begin
		tms_ihead_sr <= 5'b00110;
		tms_dhead_sr <= 5'b00100;
		tms_tail_sr  <= 2'b01;
		tms_rst_sr   <= 6'b011111;
	end
	else begin
		if(shihead   & enable) tms_ihead_sr <= {tms_ihead_sr[0],tms_ihead_sr[4:0]};
		if(shdhead   & enable) tms_dhead_sr <= {tms_dhead_sr[0],tms_dhead_sr[4:0]};
		if(shtail    & enable) tms_tail_sr  <= {tms_tail_sr[0],tms_tail_sr[1]};
		if(resetjtag & enable) tms_rst_sr   <= {tms_rst_sr[0],tms_rst_sr[5:0]};
	end
end

cbncer #(
	.Width(4),
	.TMR(TMR)
) head_dcnt_i (.CLK(SLOWCLK),.SRST(RST | load | donedhead_p1),.CE(shdhead),.Q(head_dcnt));
cbncer #(
	.Width(4),
	.TMR(TMR)
) head_icnt_i (.CLK(SLOWCLK),.SRST(RST | load | doneihead_p1),.CE(shihead),.Q(head_icnt));
cbnce #(
	.Width(4),
	.TMR(TMR)
) tail_cnt_i (.CLK(SLOWCLK),.RST(RST | donetail_p1),.CE(shtail & enable),.Q(tail_cnt));

always @(posedge SLOWCLK) begin
   donedhead_p1 <= donedhead;
   done1head_p1 <= done1head;
end
always @(negedge SLOWCLK) begin
   donetail_p1 <= donetail;
end

always @(posedge SLOWCLK or posedge RST)begin
	if(RST) begin
		pbsy <= 1'b0;
		busyp1 <= 1'b0;
	end
	else begin
		pbsy <= load;
		busyp1 <= busy;
	end
end
always @(posedge SLOWCLK or posedge clr_bsy)begin
	if(clr_bsy)
		busy <= 1'b0;
	else
		busy <= pbsy | busy;
end

always @(posedge FASTCLK or posedge RST) begin
   if(RST) begin
		jr1   <= 1'b0;
		okrst <= 1'b0;
	end
	else begin
		jr1   <= INITJTAGS | (STROBE & rstjtag);
		if(resetdone)
			okrst <= 1'b0;
		else
			okrst <= jr1 | okrst;
	end
end
always @(posedge SLOWCLK or posedge RST or posedge resetdone) begin
   if(RST | resetdone)
		resetjtag <= 1'b0;
	else
		resetjtag <= okrst;
end
cbnce #(
	.Width(4),
	.TMR(TMR)
) reset_cnt_i (.CLK(SLOWCLK),.RST(!okrst),.CE(resetjtag),.Q(rst_cnt));


always @(posedge FASTCLK) begin
   dt_rdsel  <= (STROBE & readcfeb);
   dt_wrtsel <= (STROBE & selcfeb);
end

always @(posedge STRBCLK or posedge RST) begin
	if(RST)
		selfeb <= 5'd0;
	else
		if(selcfeb)
			selfeb <= INDATA[4:0];
end

endmodule
