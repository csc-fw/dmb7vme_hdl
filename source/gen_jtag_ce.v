`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:30:52 03/27/2015 
// Design Name: 
// Module Name:    gen_jtag 
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
module gen_jtag_ce #(
	parameter TMR = 0
)(
	input FASTCLK,
	input SLOWCLK_EN,
	input NEG_SLOWCLK_EN,
	input RST,
	input INITJTAGS,
	input STROBE,
	input STRBCE,
	input WRITE_B,
	input DEVICE,
	input [9:0] COMMAND,
	input [15:0] INDATA,
	input TDO,
	output TDI,
	output TMS,
	output TCK,
	output LEDA,
	output LEDB,
	output DTACK_B,
	output [15:0] OUTDATA,
	output [15:0] DIAGOUT
);

wire datashft;
wire instshft;
wire readtdo;
wire rstjtag;

reg pbsy;
reg busy;
reg busyp1;
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
reg dheaden;
reg iheaden;
reg tailen;
reg resetjtag;
reg okrst;
reg jr1;
reg jr2;
wire le_jr1;
wire donedata_m1;
reg donedata;
reg donedata_p1;
wire donedhead;
wire doneihead;
wire donetail;
reg  donedhead_p1;
reg  doneihead_p1;
reg  donetail_p1;
wire resetdone;
wire clr_bsy;
wire clr_cnt;
wire clr_pload;
wire clr_dheaden;
wire clr_iheaden;
wire clr_tailen;
wire clr_resetjtag;

reg [4:0] tms_ihead_sr;
reg [4:0] tms_dhead_sr;
reg [1:0] tms_tail_sr;
reg [5:0] tms_rst_sr;
wire [3:0] shft_cnt;
wire [3:0] head_dcnt;
wire [3:0] head_icnt;
wire [3:0] tail_cnt;
wire [3:0] rst_cnt;


initial begin
	dt1    = 0;
	dt2    = 0;
	dt3    = 0;
	dt4    = 0;
	busy   = 0;
	busyp1 = 0;
end


//////////////////////////////////////////////////
//
// JTAG commands
// 00: Shift data, no header, no trailer
// 01: Shift data with header only
// 02: Shift data with trailer only
// 03: Shift data with header and trailer
// 04: 
// 05: Read TDO register
// 06: Reset JTAG State machine
// 07: Shift Instruction register
//
////////////////////////////////////////////////

assign datashft  = DEVICE & (COMMAND[5:2] == 4'd0);
assign readtdo   = DEVICE & (COMMAND[5:0] == 6'd5);
assign rstjtag   = DEVICE & (COMMAND[5:0] == 6'd6);
assign instshft  = DEVICE & (COMMAND[5:0] == 6'd7);

assign rdtdodk   = readtdo & STROBE & ~busyp1 & ~busy;

assign TDI = q[0];
assign TMS = (shihead)   ? tms_ihead_sr[0] : 1'bz;
assign TMS = (shdhead)   ? tms_dhead_sr[0] : 1'bz;
assign TMS = (shtail)    ? tms_tail_sr[0]  : 1'bz;
assign TMS = (resetjtag) ? tms_rst_sr[0]   : 1'bz;
assign TMS = (shdata)    ? tailen & donedata_m1 : 1'bz;
assign TCK = enable;

assign shdata  = busy & !dheaden & !iheaden & !donedata_p1;
assign shihead = busy & iheaden;
assign shdhead = busy & dheaden;
assign shtail  = busy & tailen & donedata_p1;
assign donedata_m1 = (shft_cnt == 4'b0) & !load;
assign donedhead = (head_dcnt == 4'd10);
assign doneihead = (head_icnt == 4'd10);
assign donetail  = tail_cnt[1];
assign le_jr1    = jr1 & !jr2;
assign resetdone = (rst_cnt == 4'd12);
assign clr_cnt = RST | donedata_p1 | donedata;
assign clr_bsy = RST | donetail | (donedata_p1 & !tailen);
assign clr_pload      = (load | RST);
assign clr_dheaden    = (donedhead | RST);
assign clr_iheaden    = (doneihead | RST);
assign clr_tailen     = (donetail | RST);
assign clr_resetjtag  = (resetdone | RST);

assign OUTDATA = rdtdodk ? qc : 16'hzzzz;
assign dtena   = dt1 & dt2 & dt3 & dt4;
assign DTACK_B = rdtdodk ? 1'b0 : 1'bz;
assign DTACK_B = dtena   ? 1'b0 : 1'bz;
assign DTACK_B = (resetdone & !INITJTAGS) ? 1'b0 : 1'bz;
assign LEDA    = !dtena;
assign LEDB    = !busy;
assign DIAGOUT = {donedhead,shdhead,donedata_p1,iheaden,dheaden,STROBE,readtdo,SLOWCLK_EN,shdata,TDO,RST,DTACK_B,rdtdodk,busy,enable,load};

srnlce #(
	.Width(16),
	.Left(0), //shift right
	.TMR(TMR)
) tdo_rbk_reg_i(.C(FASTCLK),.CE(SLOWCLK_EN & shdata & !enable),.CLR(RST),.L(1'b0),.SI(TDO),.D(16'h0000),.Q(qc));

srnlce #(
	.Width(16),
	.Left(0), //shift right
	.TMR(TMR)
) tdi_reg_i(.C(FASTCLK),.CE(SLOWCLK_EN & shdata & enable),.CLR(RST),.L(load),.SI(q[0]),.D(INDATA),.Q(q));

always @(posedge FASTCLK or posedge clr_pload)begin
	if(clr_pload)
		pload <= 1'b0;
	else
		if(STRBCE) pload <= datashft | instshft;
end
always @(posedge FASTCLK) begin
	if(SLOWCLK_EN) begin
		load <= pload & !busy;
		dt3  <= dt2;
		dt4  <= dt3;
	end
end

always @(posedge FASTCLK or negedge STROBE)begin
	if(!STROBE) begin
		dt1 <= 1'b0;
		dt2 <= 1'b0;
	end
	else
		if(SLOWCLK_EN) begin
			if(!busy) dt1 <= datashft | instshft;
			dt2 <= dt1;
		end
end

always @(posedge FASTCLK or posedge clr_dheaden)begin
	if(clr_dheaden)
		dheaden <= 1'b0;
	else
		if(datashft & !busy & STROBE) dheaden <= COMMAND[0];
end

always @(posedge FASTCLK or posedge clr_iheaden)begin
	if(clr_iheaden)
		iheaden <= 1'b0;
	else
		if(instshft & !busy & STROBE) iheaden <= COMMAND[0];
end

always @(posedge FASTCLK or posedge clr_tailen)begin
	if(clr_tailen)
		tailen <= 1'b0;
	else
		if(SLOWCLK_EN) begin
			if((datashft | instshft) & pload & !busy) tailen <= COMMAND[1];
		end
end
always @(posedge FASTCLK or posedge RST)begin
	if(RST)
		enable <= 1'b0;
	else
		if(SLOWCLK_EN) begin
			if(resetjtag | busy) enable <= !enable; // enable is TCK
		end
end

udl_cnt #(
	.Width(4),
	.TMR(TMR)
) shft_cnt_i (.CLK(FASTCLK),.RST(clr_cnt),.CE(SLOWCLK_EN & shdata & enable),.L(load),.UP(1'b0),.D(COMMAND[9:6]),.Q(shft_cnt));

always @(posedge FASTCLK or posedge load)begin
	if(load) begin
		donedata    <= 1'b0;
		donedata_p1 <= 1'b0;
	end
	else
		if(SLOWCLK_EN) begin
			if(shdata) donedata <= donedata_m1;
			donedata_p1 <= donedata;
		end
end

always @(posedge FASTCLK or posedge RST)begin
	if(RST) begin
		tms_ihead_sr <= 5'b00110;
		tms_dhead_sr <= 5'b00100;
		tms_tail_sr  <= 2'b01;
		tms_rst_sr   <= 6'b011111;
	end
	else
		if(SLOWCLK_EN) begin
			if(shihead   & enable) tms_ihead_sr <= {tms_ihead_sr[0],tms_ihead_sr[4:1]};
			if(shdhead   & enable) tms_dhead_sr <= {tms_dhead_sr[0],tms_dhead_sr[4:1]};
			if(shtail    & enable) tms_tail_sr  <= {tms_tail_sr[0],tms_tail_sr[1]};
			if(resetjtag & enable) tms_rst_sr   <= {tms_rst_sr[0],tms_rst_sr[5:1]};
		end
end

cbncer #(
	.Width(4),
	.TMR(TMR)
) head_dcnt_i (.CLK(FASTCLK),.SRST(RST | load | donedhead_p1),.CE(SLOWCLK_EN & shdhead),.Q(head_dcnt));
cbncer #(
	.Width(4),
	.TMR(TMR)
) head_icnt_i (.CLK(FASTCLK),.SRST(RST | load | doneihead_p1),.CE(SLOWCLK_EN & shihead),.Q(head_icnt));
cbnce #(
	.Width(4),
	.TMR(TMR)
) tail_cnt_i (.CLK(FASTCLK),.RST(RST | donetail_p1),.CE(SLOWCLK_EN & shtail & enable),.Q(tail_cnt));

always @(posedge FASTCLK) begin
	if(SLOWCLK_EN) begin
		donedhead_p1 <= donedhead;
		doneihead_p1 <= doneihead;
	end
end
always @(posedge FASTCLK) begin
	if(NEG_SLOWCLK_EN) begin
		donetail_p1 <= donetail;
	end
end

always @(posedge FASTCLK or posedge RST)begin
	if(RST) begin
		pbsy <= 1'b0;
		busyp1 <= 1'b0;
	end
	else
		if(SLOWCLK_EN) begin
			pbsy <= load;
			busyp1 <= busy;
		end
end
always @(posedge FASTCLK or posedge clr_bsy)begin
	if(clr_bsy)
		busy <= 1'b0;
	else
		if(SLOWCLK_EN) begin
			busy <= pbsy | busy;
		end
end

always @(posedge FASTCLK or posedge RST) begin
   if(RST) begin
		jr1   <= 1'b0;
		jr2   <= 1'b0;
		okrst <= 1'b0;
	end
	else begin
		jr1   <= INITJTAGS | (STROBE & rstjtag & !busy & !busyp1);
		jr2   <= jr1;
		if(resetdone)
			okrst <= 1'b0;
		else
			okrst <= le_jr1 | okrst;
	end
end

always @(posedge FASTCLK or posedge clr_resetjtag) begin
   if(clr_resetjtag)
		resetjtag <= 1'b0;
	else
		if(SLOWCLK_EN) begin
			resetjtag <= okrst;
		end
end
cbnce #(
	.Width(4),
	.TMR(TMR)
) reset_cnt_i (.CLK(FASTCLK),.RST(!okrst),.CE(SLOWCLK_EN & resetjtag),.Q(rst_cnt));

endmodule
