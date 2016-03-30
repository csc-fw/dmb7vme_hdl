`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:53:51 03/30/2015 
// Design Name: 
// Module Name:    flash49bv512 
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
module flash49bv512_ce #(
	parameter Flash_Disabled = 0,
	parameter TMR = 0
)(
	input FASTCLK,
	input [4:0] CLKCNT,
	input RST,
	input STROBE,
	input WRITE_B,
	input DEVICE,
	input [9:0] COMMAND,
	input [15:0] INDATA,
	input [7:0] FMDIN,
	output FMOE_B,
	output FMCE_B,
	output FMWE_B,
	output FMOUTEN_B,
	output [7:0] FMDOUT,
	output [9:0] FMADR,
	output JTAGEN,
	output TMS,
	output [5:1] TCK,
	output [5:1] TDI,
	output DTACK_B,
	output [15:0] OUTDATA,
	output [15:0] DIAGOUT
);

//////////////////////////////////////////////////
//
// Atmel AT49BV512 Flash Memory chips
// 512K bits (64K X 8)
// There are 16 address lines (A15 ... A0)
// But on the PCB: A15 is pulled low
//                 A9, A11, and A13 are tied together
//                 A8, A10, A12 and A14 are tied together
// So the firmware only drives 10 address bits (A9...A0)
//
// Command sequences are:
//       |  Erase     |  BootBlock |  Byte      |
//       |  Chip      |  Lockout   |  Program   |
//-----------------------------------------------
// Cycle | Addr  Data | Addr  Data | Addr  Data |
//-----------------------------------------------
//   1st | 5555   AA  | 5555   AA  | 5555   AA  |
//   2nd | 2AAA   55  | 2AAA   55  | 2AAA   55  |
//   3rd | 5555   80  | 5555   80  | 5555   A0  |
//   4th | 5555   AA  | 5555   AA  | Addr   Din |
//   5th | 2AAA   55  | 2AAA   55  |            |
//   6th | 5555   10  | 5555   40  |            |
//
//////////////////////////////////////////////////

wire initialize;
wire loadbuf;
wire program;
wire read_ram;
wire read_flash;
wire buckeye;
wire erase;

reg slowclk_en;
reg neg_slowclk_en;
reg wen;
wire le_rst;
reg rst_d1;
reg rst_d2;

wire jtagena;
wire jtagsetup;
wire tdi_a;
wire tdi_b;
wire tdi_c;
wire tdi_d;
reg  ctdi;
wire tms_a;
wire tms_b;
wire tms_c;
wire tms_d;
reg  ctms;
reg  febtck;
wire [6:0] romadr;

reg stdata;
reg enddata;
reg endhead;

wire erases;
wire initc;
reg  start_erase;
reg  sterase;
reg  [6:1] ersh;
reg  rsterase;
wire eheads;
wire eh1346;
wire eh25;
wire pheads;
reg  prgrstce;
wire bgnprg;

wire ampinit;
wire clr_jtagsetup;
wire clr_stdata;
wire clr_er_prg;
wire clr_ster;
wire clr_prgtime;
wire clr_st_read_inc;
wire clr_start_erase;

wire read_inc;
wire asynread;
reg  asr_1;
reg  asr_1_1f;
reg  asr_2;
reg  st_read_inc;
wire rd_busy;
reg  rd_busy_1;
wire load;
wire asynload;
reg  asl_1;
reg  asl_2;
reg  asl_3;

wire [8:0] wadr;
wire [7:0] dataout;
wire [8:0] pcount;
wire [7:0] prg_time;
reg  prgstop;
reg  fmoutena;
reg  pgmx_1;
reg  phead1;
reg  phead2;
reg  phead3;
reg  prgdata;
reg  prg_time_ce;

reg dt_initc;
reg dt_erases;
reg dt_ampinit;
reg dt_programx;
reg dt_read;
reg dt_read_1;
wire dt_read_tr;

wire [7:0] dmy1;
wire dmy_rst;
assign dmy_rst = 0;

initial begin
	dt_initc    = 0;
	dt_erases   = 0;
	dt_ampinit  = 0;
	dt_programx = 0;
	dt_read     = 0;
	dt_read_1   = 0;
	st_read_inc = 0;
	asr_1       = 0;
	asr_1_1f    = 0;
	asr_2       = 0;
	asl_1       = 0;
	asl_2       = 0;
	asl_3       = 0;
end

//////////////////////////////////////////////////
//
// Flash Memory commands
// 00: Initialize PROGRAM process
// 01: Load in BUCKEYE pattern
// 02: Program data to Flash Memory 
// 03: Read back Flash Memory
// 04: Initialize Buckeye
// 05: Erase Flash Memory
//
////////////////////////////////////////////////

assign initialize = DEVICE & (COMMAND == 10'd0);
assign loadbuf    = DEVICE & (COMMAND == 10'd1);
assign program    = DEVICE & (COMMAND == 10'd2);
assign read_ram   = DEVICE & (COMMAND == 10'd3);
assign buckeye    = DEVICE & (COMMAND == 10'd4);
assign erase      = DEVICE & (COMMAND == 10'd5);
assign read_flash = DEVICE & (COMMAND == 10'd6);

assign initc       = STROBE & initialize;
assign erases      = STROBE & erase;
assign ampinit     = STROBE & buckeye;
assign asynread    = STROBE & (read_ram | read_flash);
assign asynload    = STROBE & loadbuf;
assign programx    = STROBE & program;
//assign read        = !asynread & asr_1;   //trailing edge
assign read_inc      = asr_1 & !asr_2;     //slowclock falling edge to rising edge
assign dt_read_tr  = !dt_read & dt_read_1; //trailing edge
assign clr_st_read_inc = asr_1 & !asr_1_1f;   //leading edge with fast clock
assign rd_busy     = (st_read_inc | asr_1 | asr_2);
assign load        = asynload & !asl_1;   //leading edge
assign eh1346      = ersh[1] | ersh[3] | ersh[4] | ersh[6];
assign eh25        = ersh[2] | ersh[5];
assign eheads      = eh1346 | eh25;
assign pheads      = (phead1 | phead2 | phead3);
assign le_rst      = RST & !rst_d1;
assign clr_jtagsetup = (le_rst | initc | endhead);
assign clr_stdata    = (le_rst | initc | enddata);
assign clr_er_prg    = (le_rst | initc);
assign clr_ster      = (le_rst | initc | prgrstce | rsterase);
assign clr_prgtime   = (le_rst | initc | phead1);
assign clr_start_erase = (le_rst | initc | ersh[1]);
assign bgnprg        = (pgmx_1 | prg_time[7]);


always @(posedge FASTCLK) begin
	slowclk_en      <= (CLKCNT == 5'd0) || (CLKCNT == 5'd16);
	neg_slowclk_en  <= (CLKCNT == 5'd8) || (CLKCNT == 5'd24);
	wen             <= ((CLKCNT >= 5'd2) && (CLKCNT < 5'd10)) || ((CLKCNT >= 5'd18) && (CLKCNT < 5'd26));
	febtck          <= ((CLKCNT >= 5'd0) && (CLKCNT < 5'd8)) || ((CLKCNT >= 5'd16) && (CLKCNT < 5'd24));
end

always @(posedge FASTCLK) begin
	rst_d1     <= RST;
	rst_d2     <= le_rst;
	dt_initc    <= initc;
	dt_erases   <= erases;
	dt_ampinit  <= ampinit;
	dt_programx <= programx;
	dt_read     <= asynread & !rd_busy_1;
	dt_read_1   <= dt_read;
	asr_1_1f    <= asr_1;
	rd_busy_1   <= rd_busy;
end
always @(posedge FASTCLK) begin
	if(clr_st_read_inc)
		st_read_inc <= 1'b0;
	else
		st_read_inc <= (st_read_inc | dt_read_tr);
end
always @(posedge FASTCLK) begin
	if(neg_slowclk_en) begin
		asr_1 <= st_read_inc;
	end
end
always @(posedge FASTCLK) begin
	if(slowclk_en) begin
		asr_2 <= asr_1;
	end
end

always @(posedge FASTCLK or negedge asynload) begin
	if(!asynload) begin
		asl_1 <= 1'b0;
		asl_2 <= 1'b0;
		asl_3 <= 1'b0;
	end
	else
	if(slowclk_en) begin
		asl_1 <= asynload;
		asl_2 <= asl_1;
		asl_3 <= asl_2;
	end
end

cbnce #(
	.Width(9),
	.TMR(TMR)
) wadr_i (.CLK(FASTCLK),.RST(RST | initc),.CE(slowclk_en & load),.Q(wadr));

RAMB4_S8_S8 #(
	.SIM_COLLISION_CHECK("ALL"), // "NONE", "WARNING_ONLY", "GENERATE_X_ONLY", "ALL" 
	// The following INIT_xx declarations specify the initial contents of the RAM
	.INIT_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
	.INIT_0F(256'h0000000000000000000000000000000000000000000000000000000000000000)
) RAMB4_S8_S8_inst (
	.DOA(dmy1),     // Port A 8-bit data output
	.DOB(dataout),     // Port B 8-bit data output
	.ADDRA(wadr), // Port A 9-bit address input
	.ADDRB(pcount), // Port B 9-bit address input
	.CLKA(FASTCLK),   // Port A clock input
	.CLKB(FASTCLK),   // Port B clock input
	.DIA(INDATA[7:0]),     // Port A 8-bit data input
	.DIB(INDATA[7:0]),     // Port B 8-bit data input
	.ENA(1'b1),     // Port A RAM enable input
	.ENB(slowclk_en),     // Port B RAM enable input
	.RSTA(dmy_rst),   // Port A Synchronous reset input
	.RSTB(dmy_rst),   // Port B Synchronous reset input
	.WEA(slowclk_en & load),     // Port A RAM write enable input
	.WEB(1'b0)      // Port B RAM write enable input
);



generate
if(Flash_Disabled==1) 
// Disabling Flash prevents JTAG constants being sent to (D)CFEBs on power up and reset
begin : no_flash_loading
	assign jtagena   = 0; 
	assign jtagsetup = 0; 
end
else
begin : with_flash_loading
	reg jtagena_r;
	reg pjs;
	reg jtagsetup_r;

	always @(posedge FASTCLK) begin
		if(enddata)
			jtagena_r <= 1'b0;
		else
			jtagena_r <= (jtagena_r | rst_d2 | ampinit);
	end
	
	always @(posedge FASTCLK or posedge clr_jtagsetup) begin
		if(clr_jtagsetup)
			pjs <= 1'b0;
		else
			pjs <= (pjs | rst_d2 | ampinit);
	end
	
	always @(posedge FASTCLK or posedge clr_jtagsetup) begin
		if(clr_jtagsetup)
			jtagsetup_r <= 1'b0;
		else
			if(slowclk_en) begin
				jtagsetup_r <= pjs;
			end
	end
	assign jtagena = jtagena_r;
	assign jtagsetup = jtagsetup_r;
end
endgenerate

cbnce #(
	.Width(7),
	.TMR(TMR)
) rom_addr_i (.CLK(FASTCLK),.RST(clr_jtagsetup),.CE(slowclk_en & jtagsetup),.Q(romadr));

always @(posedge FASTCLK or posedge le_rst) begin
	if(le_rst)
		endhead <= 1'b0;
	else
		if(slowclk_en) begin
			endhead <= ((romadr & 7'h75) == 7'h75);
		end
end
always @(posedge FASTCLK or posedge clr_stdata) begin
	if(clr_stdata)
		stdata <= 1'b0;
	else
		if(slowclk_en) begin
			stdata <= stdata | ((romadr & 7'h75) == 7'h75);
		end
end

always @(posedge FASTCLK or posedge clr_start_erase) begin
	if(clr_start_erase)
		start_erase <= 0;
	else
		start_erase <= start_erase | erases;
end
always @(posedge FASTCLK or posedge clr_er_prg) begin
	if(clr_er_prg) begin
		ersh     <= 6'b000000;
		rsterase <= 1'b0;
	end
	else
		if(slowclk_en) begin
			ersh     <= {ersh[5:1],start_erase};
			rsterase <= ersh[6];
		end
end
always @(posedge FASTCLK or posedge clr_ster) begin
	if(clr_ster)
		sterase <= 1'b0;
	else
		if(slowclk_en) begin
			sterase <= (sterase | bgnprg | start_erase);
		end
end
always @(posedge FASTCLK or posedge le_rst) begin
	if(le_rst)
		enddata <= 1'b0;
	else
		if(slowclk_en) begin
			enddata <= stdata & ((pcount & 9'd432) == 432);
		end
end


// ROMs for TDI and TMS for putting XC18V01 in Bypass and selecting proper registers in CFEB firmware.
ROM32X1 #(.INIT(32'h507F8800)) tdiroma_i (.O(tdi_a),.A0(romadr[0]),.A1(romadr[1]),.A2(romadr[2]),.A3(romadr[3]),.A4(romadr[4]));
ROM32X1 #(.INIT(32'hFFFFC7F0)) tdiromb_i (.O(tdi_b),.A0(romadr[0]),.A1(romadr[1]),.A2(romadr[2]),.A3(romadr[3]),.A4(romadr[4]));
ROM32X1 #(.INIT(32'h05E7F880)) tdiromc_i (.O(tdi_c),.A0(romadr[0]),.A1(romadr[1]),.A2(romadr[2]),.A3(romadr[3]),.A4(romadr[4]));
ROM32X1 #(.INIT(32'h00FBFC7E)) tdiromd_i (.O(tdi_d),.A0(romadr[0]),.A1(romadr[1]),.A2(romadr[2]),.A3(romadr[3]),.A4(romadr[4]));

ROM32X1 #(.INIT(32'h01C000DF)) tmsroma_i (.O(tms_a),.A0(romadr[0]),.A1(romadr[1]),.A2(romadr[2]),.A3(romadr[3]),.A4(romadr[4]));
ROM32X1 #(.INIT(32'h00E00078)) tmsromb_i (.O(tms_b),.A0(romadr[0]),.A1(romadr[1]),.A2(romadr[2]),.A3(romadr[3]),.A4(romadr[4]));
ROM32X1 #(.INIT(32'h801C000F)) tmsromc_i (.O(tms_c),.A0(romadr[0]),.A1(romadr[1]),.A2(romadr[2]),.A3(romadr[3]),.A4(romadr[4]));
ROM32X1 #(.INIT(32'h000E0007)) tmsromd_i (.O(tms_d),.A0(romadr[0]),.A1(romadr[1]),.A2(romadr[2]),.A3(romadr[3]),.A4(romadr[4]));

cbnce #(
	.Width(9),
	.TMR(TMR)
) pcount_i (.CLK(FASTCLK),.RST(le_rst | initc | enddata | programx),.CE(slowclk_en & (stdata | read_inc | prgdata)),.Q(pcount));

always @(posedge FASTCLK or posedge clr_er_prg) begin
	if(clr_er_prg)
		prgstop <= 1'b0;
	else
		if(neg_slowclk_en) begin
			prgstop <= ((pcount & 9'h1C0) == 9'h1C0);
		end
end

always @(posedge FASTCLK) begin
	if(le_rst | rsterase | prgstop)
		fmoutena <= 1'b0;
	else
		fmoutena <= (fmoutena | erases | programx);
end
always @(posedge FASTCLK) begin
	if(le_rst | phead1)
		pgmx_1 <= 1'b0;
	else
		pgmx_1 <= (pgmx_1 | programx);
end

always @(posedge FASTCLK or posedge le_rst) begin
	if(le_rst) begin
		phead1  <= 1'b0;
		phead2  <= 1'b0;
		phead3  <= 1'b0;
		prgdata <= 1'b0;
	end
	else
		if(slowclk_en) begin
			phead1  <= bgnprg;
			phead2  <= phead1;
			phead3  <= phead2;
			prgdata <= phead3;
		end
end

always @(posedge FASTCLK or posedge clr_prgtime) begin
	if(clr_prgtime)
		prg_time_ce <= 1'b0;
	else
		prg_time_ce <= (prg_time_ce | prgdata);
end

cbnce #(
	.Width(8),
	.TMR(TMR)
) prg_time_i (.CLK(FASTCLK),.RST(le_rst | initc | prgstop | phead1),.CE(slowclk_en & prg_time_ce),.Q(prg_time));

always @(posedge FASTCLK) begin
	if(slowclk_en) begin
		prgrstce <= prg_time[4] & !prg_time[6];
	end
end

always @* begin
	case(romadr[6:5])
		2'b00: ctdi = tdi_a;
		2'b01: ctdi = tdi_b;
		2'b10: ctdi = tdi_c;
		2'b11: ctdi = tdi_d;
	endcase
	case(romadr[6:5])
		2'b00: ctms = tms_a;
		2'b01: ctms = tms_b;
		2'b10: ctms = tms_c;
		2'b11: ctms = tms_d;
	endcase
end

assign TDI = (jtagsetup) ? {5{ctdi}}       : 5'bzzzzz;
assign TMS = (jtagsetup) ? ctms            : 1'bz;
assign TDI = (stdata)    ? FMDIN[5:1]      : 5'bzzzzz;
assign TMS = (stdata | endhead) ? FMDIN[0] : 1'bz;
assign TCK = (jtagena)   ? {5{~febtck}}    : 5'bzzzzz;
assign JTAGEN = jtagena;


assign FMCE_B = !(sterase |  stdata | (WRITE_B & read_flash));
assign FMOE_B =  (sterase | ~(stdata | (WRITE_B & read_flash)));
assign FMWE_B = !(wen & (prgdata | pheads | eh1346 | eh25));

assign FMDOUT = (eheads)  ? {(ersh[1] | ersh[3] | ersh[4]),eh25,(ersh[1] | ersh[4]),(ersh[2] | ersh[5] | ersh[6]),(ersh[1] | ersh[4]),eh25,(ersh[1] | ersh[4]),eh25} : 8'hzz;
assign FMDOUT = (pheads)  ? {(phead1 | phead3),phead2,(phead1 | phead3),phead2,phead1,phead2,phead1,phead2} : 8'hzz;
assign FMDOUT = (prgdata) ? dataout : 8'hzz;
assign FMADR  = (eheads)  ? {eh25,eh1346,eh25,eh1346,eh25,eh1346,eh25,eh1346,eh25,eh1346} : 10'hzzz;
assign FMADR  = (pheads)  ? {phead2,(phead1 | phead3),phead2,(phead1 | phead3),phead2,(phead1 | phead3),phead2,(phead1 | phead3),phead2,(phead1 | phead3)} : 10'hzzz;
assign FMADR  = (prgdata | stdata | (WRITE_B & read_flash))  ? {1'b1,pcount} : 10'hzzz;
assign FMOUTEN_B = !fmoutena;

assign DTACK_B = (asynload & asl_3) ? 1'b0 : 1'bz;
assign DTACK_B = (dt_read_1) ? 1'b0 : 1'bz;
assign DTACK_B = (dt_ampinit | dt_erases | dt_initc | dt_programx)   ? 1'b0 : 1'bz;

assign OUTDATA = (WRITE_B & read_ram) ? {8'h00,dataout} : 16'hzzzz;
assign OUTDATA = (WRITE_B & read_flash) ? {8'h00,FMDIN} : 16'hzzzz;

assign DIAGOUT = {ampinit,initc,stdata,TDI[1],TCK[1],TMS,prgstop,FMDIN[1],FMDOUT[1],FMOE_B,FMWE_B,FMCE_B,FMDIN[0],FMDOUT[0],FMOUTEN_B,programx};

endmodule
