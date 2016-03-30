`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:35:22 03/25/2015 
// Design Name: 
// Module Name:    dmb7vme_hdl 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision E.14 - Files copied from dmb6vme_hdl version E.14
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module dmb7vme_hdl #(
	parameter Flash_Disabled = 0,
	parameter TMR = 0
)
(
    input FPGACLK,
    input IGLOBALRST,
    input ISYSRST_B,
    input ISOFTRST,
    input INACK_B,
    input IBERR_B,
    input IAS_B,
    input IDS0_B,
    input IDS1_B,
    input ILWORD_B,
    input IWRITE_B,
    input ISYSFAIL_B,
    input [4:1] ISW,
    input [5:0] IGA_B,
    input [23:1] IADR,
    input [5:0] IAM,
    inout [15:0] IODATA,
    output OTOVME,
    output ODTACK_B,
    output DOE_B,
    output REPRGEN_B,
    output CNTLFPGA,
    output OVMEREADY_B,
    output [7:0] LED,
    input [5:1] IFTDO,
    output [5:1] OFTCK,
    output [5:1] OFTDI,
    output OFTMS,
    input ICTDO,
    output OCTCK,
    output OCTMS,
    output OCTDI,
    input CIPTDO,
    output COPTCK,
    output COPTMS,
    output COPTDI,
    input VIPTDO,
    output VOPTCK,
    output VOPTMS,
    output VOPTDI,
    input [2:1] IADC,
    input BBCLKIN,
    input ADCB_B,
    output ADCDT,
    output ADCCK,
    output BBCONVOUT_B,
    output [4:1] ADCEN_B,
    input IDACOUT,
    output DACCK,
    output DACDT,
    output ODACCS_B,
    output FFWCLK,
    output FFBUFOE_B,
    output FFRDNEXT,
    output [7:1] ENFF,
    output [7:1] DSFF,
    inout [18:0] IOPARD,
    output [6:1] PWON,
    output LOADPWON,
    input [3:0] INMODE,
    input IDONETRG,
    input [5:1] IDONEF,
    inout [15:0] MULTI,
    output PWONEN_B,
    inout [7:0] IOFMD,
    output [9:0] OFMADR,
    output OFMCE_B,
    output OFMWE_B,
    output OFMOE_B
);

wire cmsclk;
wire [15:0] indata;
wire [15:0] outdata;
wire [5:0]  am;
wire [5:0]  ga_b;
wire [23:1] adr;
reg  [7:0] timer;
wire [7:0] sled;
wire [4:1] sw;

reg dt_rdsel;
reg dt_wrtsel;
reg [5:1] selfeb;
wire [5:1] cfebtdo;
wire [5:1] cfebtck;
wire cfjtck;
wire [5:1] cfebtdi;
wire cfjtdo;
wire cfjtdi;
wire cfjtms;
wire cfebtms;
wire initamp;
wire dmy1;
wire dmy2;
wire dmy3;
wire dmy4;

wire mbctdo;
wire mbctck;
wire mbctms;
wire mbctdi;
wire cpromtdo;
wire cpromtck;
wire cpromtms;
wire cpromtdi;
wire vpromtdo;
wire vpromtck;
wire vpromtms;
wire vpromtdi;
wire dvcenb;

wire tovme_b;
wire dtack_b;
wire iack_b;
wire berr_b;
wire as_b;
wire ds0_b;
wire ds1_b;
wire lword_b;
wire write_b;
wire sysfail_b;
wire glbrst;
wire sysrst_b;
wire softrstin;
wire grst;
wire softrst;
wire rst;
wire fpgarst;
wire donetrg;
wire vmeready;
reg  vmeready_1;
reg  dvmeready;
wire fastclk;
wire [4:0] clkcnt;
reg  slowclk_en;
reg  slowclk2_en;
reg  neg_slowclk_en;
reg  neg_slowclk2_en;
wire midclk;
reg  midclk_en;
reg  neg_midclk_en;

wire [2:1] adcin;
wire adcbusy_b;
wire adcdata;
wire adcclk;
wire [4:1] adcena_b;
(* USELOWSKEWLINES = "TRUE" *) wire bbclk;
wire bbconv;

wire dacout;
wire dacdata;
wire dacclk;
wire daccs_b;

wire [18:0] ff_rd_data;
wire [18:0] ff_wr_data;
wire toff_b;
wire [7:1] enaff;
wire [6:1] poweron;
wire poweronen_b;
wire loadpower;

wire [5:1] donef;
wire [3:0] monmode;

wire [15:0] mdatain;
wire [15:0] mdataout;
wire [4:1] mouten_b;

wire [7:0] fmdin;
wire [7:0] fmdout;
wire fmouten_b;
wire [9:0] fmadr;
wire fmce_b;
wire fmwe_b;
wire fmoe_b;


wire strobe;
wire strbce;
wire [15:0] addmon;
wire [9:0] command;
wire [9:0] device;

wire initjtags;
wire [15:0] diagtop;
wire [15:0] diagcmd;
wire [15:0] diagcfeb;
wire [15:0] diagmbc;
wire [15:0] diagcprom;
wire [15:0] diagvprom;
wire [15:0] diagadc;
wire [15:0] diagport;
wire [15:0] diaglvdb;
wire [15:0] diagfm;

wire ldffclk;
wire ffwen_b;
wire rdnextff;

wire lvadcback;
wire lvadcdata;
wire lvadcclk;
wire [6:0] lvadcen_b;

wire [7:0] splitin;
wire [7:0] fromcon;

reg  jinitdone;
wire jtimer_clr;
wire tr_rst;
reg [15:0] vrd_timer;
reg [5:0] jini_timer;
reg rst_1;
reg strt_jinit;

reg dvcenb_hld;
reg dvc_enb_cnt_7;
wire clr_enb;
wire [7:0] dvc_enb_cnt;

reg dvcenb_2;
reg dvc_enb_cnt_2_7;
wire clr_enb_2;
wire [7:0] dvc_enb_cnt_2;


IBUFG IBUFG_cmsclk   (.O(cmsclk),   .I(FPGACLK));
IBUF  IBUF_iack      (.O(iack_b),   .I(INACK_B));
IBUF  IBUF_berr      (.O(berr_b),   .I(IBERR_B));
IBUF  IBUF_as        (.O(as_b),     .I(IAS_B));
IBUF  IBUF_ds0       (.O(ds0_b),    .I(IDS0_B));
IBUF  IBUF_ds1       (.O(ds1_b),    .I(IDS1_B));
IBUF  IBUF_lword     (.O(lword_b),  .I(ILWORD_B));
IBUF  IBUF_write     (.O(write_b),  .I(IWRITE_B));
IBUF  IBUF_sysfail   (.O(sysfail_b),.I(ISYSFAIL_B));
IBUF  IBUF_glbrst    (.O(glbrst),   .I(IGLOBALRST));
IBUF  IBUF_sysrst_b  (.O(sysrst_b), .I(ISYSRST_B));
IBUF  IBUF_softrstin (.O(softrstin),.I(ISOFTRST));

genvar i;
generate
begin
	for(i=0;i<16;i=i+1) begin: idx1
		IOBUF  IOBUF_data (.O(indata[i]),.IO(IODATA[i]),.I(outdata[i]),.T(tovme_b));
	end
	for(i=0;i<19;i=i+1) begin: idx2
		IOBUF  IOBUF_ffdata (.O(ff_rd_data[i]),.IO(IOPARD[i]),.I(ff_wr_data[i]),.T(toff_b));
	end
	for(i=0;i<6;i=i+1) begin: idx3
		IBUF  IBUF_am (.O(am[i]),  .I(IAM[i]));
		IBUF  IBUF_ga (.O(ga_b[i]),.I(IGA_B[i]));
	end
	for(i=1;i<7;i=i+1) begin: idx4
		OBUF  OBUF_pow (.O(PWON[i]),.I(poweron[i]));
	end
	for(i=1;i<24;i=i+1) begin: idx5
		IBUF  IBUF_adr (.O(adr[i]),.I(IADR[i]));
	end
	for(i=0;i<4;i=i+1) begin: idx6
		IBUF  IBUF_monmode (.O(monmode[i]),.I(INMODE[i]));
	end
	for(i=1;i<5;i=i+1) begin: idx7
		IBUF  IBUF_sw (.O(sw[i]),.I(ISW[i]));
		OBUF  OBUF_adcena_b (.O(ADCEN_B[i]),.I(adcena_b[i]));
	end
	for(i=0;i<8;i=i+1) begin: idx8
		OBUF  OBUF_led (.O(LED[i]),.I(sled[i]));
		IOBUF  IOBUF_fmd (.O(fmdin[i]),.IO(IOFMD[i]),.I(fmdout[i]),.T(fmouten_b));
	end
	for(i=0;i<10;i=i+1) begin: idx9
		OBUF  OBUF_fmadr (.O(OFMADR[i]),.I(fmadr[i]));
	end
	for(i=1;i<6;i=i+1) begin: idx10
		IBUF  IBUF_donef (.O(donef[i]),.I(IDONEF[i]));
		IBUF  IBUF_cfebtdo (.O(cfebtdo[i]),.I(IFTDO[i]));
		OBUF  OBUF_cfebtck (.O(OFTCK[i]),.I(cfebtck[i]));
		OBUF  OBUF_cfebtdi (.O(OFTDI[i]),.I(cfebtdi[i]));
		if(Flash_Disabled==0) begin
			PULLUP PU_cfebtck  (.O(cfebtck[i]));
			PULLUP PU_cfebtdi  (.O(cfebtdi[i]));
		end
	end
	for(i=1;i<8;i=i+1) begin: idx11
		OBUF  OBUF_enaff (.O(ENFF[i]),.I(enaff[i]));
		OBUF  OBUF_disff (.O(DSFF[i]),.I(~enaff[i]));
	end
	for(i=0;i<6;i=i+1) begin: idx12
		IOBUF  IOBUF_multi_a (.O(mdatain[i]),.IO(MULTI[i]),.I(mdataout[i]),.T(mouten_b[4]));
	end
	for(i=6;i<8;i=i+1) begin: idx13
		IOBUF  IOBUF_multi_b (.O(mdatain[i]),.IO(MULTI[i]),.I(mdataout[i]),.T(mouten_b[1]));
	end
	for(i=8;i<15;i=i+1) begin: idx14
		IOBUF  IOBUF_multi_c (.O(mdatain[i]),.IO(MULTI[i]),.I(mdataout[i]),.T(mouten_b[2]));
	end
	for(i=15;i<16;i=i+1) begin: idx15
		IOBUF  IOBUF_multi_d (.O(mdatain[i]),.IO(MULTI[i]),.I(mdataout[i]),.T(mouten_b[3]));
	end

	OBUF OBUF_cfebTMS (.O(OFTMS),.I(cfebtms));
	if(Flash_Disabled==0) begin
		PULLUP PU_cfebTMS  (.O(cfebtms));
	end

end
endgenerate



IBUF  IBUF_mbctdo   (.O(mbctdo),.I(ICTDO));
OBUF  OBUF_mbctck   (.O(OCTCK),.I(mbctck));
OBUF  OBUF_mbctms   (.O(OCTMS),.I(mbctms));
OBUF  OBUF_mbctdi   (.O(OCTDI),.I(mbctdi));
IBUF  IBUF_cpromtdo (.O(cpromtdo),.I(CIPTDO));
OBUF  OBUF_cpromtck (.O(COPTCK),.I(cpromtck));
OBUF  OBUF_cpromtms (.O(COPTMS),.I(cpromtms));
OBUF  OBUF_cpromtdi (.O(COPTDI),.I(cpromtdi));
IBUF  IBUF_vpromtdo (.O(vpromtdo),.I(VIPTDO));
OBUFT OBUF_vpromtck (.O(VOPTCK),.I(vpromtck),.T(~dvcenb));
OBUFT OBUF_vpromtms (.O(VOPTMS),.I(vpromtms),.T(~dvcenb));
OBUFT OBUF_vpromtdi (.O(VOPTDI),.I(vpromtdi),.T(~dvcenb));

PULLUP PU_dtack_b (.O(dtack_b));
OBUF OBUF_dtack (.O(ODTACK_B),.I(dtack_b));
OBUF OBUF_tovme (.O(OTOVME),.I(tovme_b));
OBUF OBUF_oe    (.O(DOE_B),.I(timer[7]));
OBUF OBUF_grst  (.O(CNTLFPGA),.I(grst));
OBUF OBUF_vmeready (.O(OVMEREADY_B),.I(~dvmeready));
OBUF OBUF_reprgen  (.O(REPRGEN_B),.I(1'b0));

IBUF  IBUF_adcin1    (.O(adcin[1]),.I(IADC[1]));
IBUF  IBUF_adcin2    (.O(adcin[2]),.I(IADC[2]));
IBUF  IBUF_adcbusy_b (.O(adcbusy_b),.I(ADCB_B));
OBUF OBUF_adcdata    (.O(ADCDT),.I(adcdata));
OBUF OBUF_adcclk     (.O(ADCCK),.I(adcclk));

IBUF  IBUF_bbclk   (.O(bbclk),.I(BBCLKIN));
OBUF  OBUF_bbconv  (.O(BBCONVOUT_B),.I(~bbconv));

IBUF  IBUF_dacout   (.O(dacout),.I(IDACOUT));
OBUF  OBUF_dacdata  (.O(DACDT),.I(dacdata));
OBUF  OBUF_dacclk   (.O(DACCK),.I(dacclk));
OBUF  OBUF_daccs_b  (.O(ODACCS_B),.I(daccs_b));

OBUF  OBUF_ldffclk  (.O(FFWCLK),.I(ldffclk));
OBUF  OBUF_rdwrfifo (.O(FFBUFOE_B),.I(~write_b));
OBUF  OBUF_rdnextff (.O(FFRDNEXT),.I(rdnextff));

OBUF  OBUF_poweronen_b  (.O(PWONEN_B),.I(poweronen_b));
OBUF  OBUF_loadpower    (.O(LOADPWON),.I(loadpower));

IBUF  IBUF_donetrg   (.O(donetrg),.I(IDONETRG));

OBUF  OBUF_fmce_b    (.O(OFMCE_B),.I(fmce_b));
OBUF  OBUF_fmwe_b    (.O(OFMWE_B),.I(fmwe_b));
OBUF  OBUF_fmoe_b    (.O(OFMOE_B),.I(fmoe_b));

//assign sled[5] = 1'b1;
//assign sled[6] = 1'b0;

assign grst    = glbrst | !sysrst_b;
assign softrst = softrstin & donetrg;
assign fpgarst = vmeready & !vmeready_1;
assign rst     = grst | softrst | fpgarst;
assign tr_rst  = ~rst & rst_1;
assign initjtags = jini_timer[4];
assign jtimer_clr = rst | jinitdone;

always @(posedge fastclk) begin
	midclk_en       <= (clkcnt == 5'd0) || (clkcnt == 5'd4) || (clkcnt == 5'd8) || (clkcnt == 5'd12) || (clkcnt == 5'd16) || (clkcnt == 5'd20) || (clkcnt == 5'd24) || (clkcnt == 5'd28);
	neg_midclk_en   <= (clkcnt == 5'd2) || (clkcnt == 5'd6) || (clkcnt == 5'd10) || (clkcnt == 5'd14) || (clkcnt == 5'd18) || (clkcnt == 5'd22) || (clkcnt == 5'd26) || (clkcnt == 5'd30);
	slowclk_en      <= (clkcnt == 5'd0) || (clkcnt == 5'd16);
	neg_slowclk_en  <= (clkcnt == 5'd8) || (clkcnt == 5'd24);
	slowclk2_en     <= (clkcnt == 5'd0);
	neg_slowclk2_en <= (clkcnt == 5'd16);
end

always @(posedge fastclk or posedge tovme_b) begin
	if(tovme_b)
		timer <= 8'h00;
	else
		if(slowclk_en) begin
			if(!tovme_b && !timer[7])
				timer <= timer +1;
		end
end

always @(posedge midclk) begin
	vmeready_1 <= vmeready;
end

always @(posedge midclk or negedge vmeready) begin
	if(~vmeready) begin
		vrd_timer <= 16'h0000;
		dvmeready  <= 1'b0;
	end
	else begin
		dvmeready  <= (vrd_timer == 16'hFFFF) | dvmeready;
		if(vmeready)
			vrd_timer <= vrd_timer + 1;
	end
end

always @(posedge fastclk) begin
	rst_1 <= rst;
end
always @(posedge fastclk or posedge jtimer_clr) begin
	if(jtimer_clr)
		strt_jinit <= 1'b0;
	else
		strt_jinit <= tr_rst | strt_jinit;
end
always @(posedge fastclk or posedge jtimer_clr) begin
	if(jtimer_clr)
		jini_timer <= 6'h00;
	else
		if(slowclk2_en) begin
			if(strt_jinit)
				jini_timer <= jini_timer + 1;
		end
end
always @(posedge fastclk) begin
	if(slowclk2_en) begin
		jinitdone <= jini_timer[5];
	end
end

//command command_i(
//	.CMSCLK(cmsclk),
//	.GA_B(ga_b),
//	.AM(am),
//	.ADR(adr),
//	.AS_B(as_b),
//	.DS0_B(ds0_b),
//	.DS1_B(ds1_b),
//	.LWORD_B(lword_b),
//	.WRITE_B(write_b),
//	.BERR_B(berr_b),
//	.IACK_B(iack_b),
//	.SYSFAIL_B(sysfail_b),
//	.FASTCLK(fastclk),
//	.SLOWCLK(slowclk),
//	.SLOWCLK2(slowclk2),
//	.MIDCLK(midclk),
//	.DEVICE(device),
//	.COMMAND(command),
//	.ADDMON(addmon),
//	.LED(sled[2:0]),
//	.DIAGOUT(diagcmd),
//	.TOVME_B(tovme_b),
//	.STROBE(strobe),
//	.STRBCE(strbce),
//	.VMEREADY(vmeready)
//);
command_ce #(
	.TMR(TMR)
) command_i(
	.CMSCLK(cmsclk),
	.RST(rst),
	.GA_B(ga_b),
	.AM(am),
	.ADR(adr),
	.AS_B(as_b),
	.DS0_B(ds0_b),
	.DS1_B(ds1_b),
	.LWORD_B(lword_b),
	.WRITE_B(write_b),
	.BERR_B(berr_b),
	.IACK_B(iack_b),
	.SYSFAIL_B(sysfail_b),
	.FASTCLK(fastclk),
	.MIDCLK(midclk),
	.CLKCNT(clkcnt),
	.DEVICE(device),
	.COMMAND(command),
	.ADDMON(addmon),
	.LED(sled[2:0]),
	.DIAGOUT(diagcmd),
	.TOVME_B(tovme_b),
	.STROBE(strobe),
	.STRBCE(strbce),
	.VMEREADY(vmeready)
);

/////////////////////////////////////
//
// Device 0: VMESTAT
//
/////////////////////////////////////
vmestat vmestat_i(
	.FASTCLK(fastclk),
	.RST(rst),
	.STROBE(strobe),
	.WRITE_B(write_b),
	.DEVICE(device[0]),
	.COMMAND(command),
	.INDATA(indata),
	.DTACK_B(dtack_b),
	.OUTDATA(outdata)
);

/////////////////////////////////////
//
// Device 1: CFEBJTAG
//
/////////////////////////////////////
assign selcfeb  = device[1] & (command == 10'd8);
assign readcfeb = device[1] & (command == 10'd9);
assign cfjtdo  = (selfeb == 5'b00001) ? cfebtdo[1] : 1'bz;
assign cfjtdo  = (selfeb == 5'b00010) ? cfebtdo[2] : 1'bz;
assign cfjtdo  = (selfeb == 5'b00100) ? cfebtdo[3] : 1'bz;
assign cfjtdo  = (selfeb == 5'b01000) ? cfebtdo[4] : 1'bz;
assign cfjtdo  = (selfeb == 5'b10000) ? cfebtdo[5] : 1'bz;


assign cfebtck = initamp ? 5'bzzzzz : {5{cfjtck}} & selfeb;
assign cfebtdi = initamp ? 5'bzzzzz : {6{cfjtdi}};
assign cfebtms = initamp ? 1'bz : cfjtms;

initial begin
   dt_rdsel  = 0;
   dt_wrtsel = 0;
end

always @(posedge fastclk) begin
   dt_rdsel  <= (strobe & readcfeb);
   dt_wrtsel <= (strobe & selcfeb);
end

always @(posedge fastclk or posedge rst) begin
	if(rst)
		selfeb <= 5'd0;
	else
		if(selcfeb & strbce)
			selfeb <= indata[4:0];
end
assign dtack_b = dt_rdsel   ? 1'b0 : 1'bz;
assign dtack_b = dt_wrtsel  ? 1'b0 : 1'bz;

assign outdata = (write_b & readcfeb) ? {11'h000,selfeb} : 16'hzzzz;

//gen_jtag cfebjtag_i(
//	.FASTCLK(fastclk),
//	.SLOWCLK(slowclk),
//	.RST(rst),
//	.INITJTAGS(initjtags),
//	.STROBE(strobe),
//	.STRBCE(strbce),
//	.WRITE_B(write_b),
//	.DEVICE(device[1]),
//	.COMMAND(command),
//	.INDATA(indata),
//	.TDO(cfjtdo),
//	.TDI(cfjtdi),
//	.TMS(cfjtms),
//	.TCK(cfjtck),
//	.LEDA(sled[3]),
//	.LEDB(dmy1),
//	.DTACK_B(dtack_b),
//	.OUTDATA(outdata),
//	.DIAGOUT(diagcfeb)
//);
gen_jtag_ce #(
	.TMR(TMR)
) cfebjtag_i(
	.FASTCLK(fastclk),
	.SLOWCLK_EN(slowclk_en),
	.NEG_SLOWCLK_EN(neg_slowclk_en),
	.RST(rst),
	.INITJTAGS(initjtags),
	.STROBE(strobe),
	.STRBCE(strbce),
	.WRITE_B(write_b),
	.DEVICE(device[1]),
	.COMMAND(command),
	.INDATA(indata),
	.TDO(cfjtdo),
	.TDI(cfjtdi),
	.TMS(cfjtms),
	.TCK(cfjtck),
	.LEDA(sled[3]),
	.LEDB(dmy1),
	.DTACK_B(dtack_b),
	.OUTDATA(outdata),
	.DIAGOUT(diagcfeb)
);


/////////////////////////////////////
//
// Device 2: MBCJTAG (Mother Board Controller JTAG)
//
/////////////////////////////////////
//gen_jtag mbcjtag_i (
//	.FASTCLK(fastclk),
//	.SLOWCLK(midclk),
//	.RST(rst),
//	.INITJTAGS(initjtags),
//	.STROBE(strobe),
//	.STRBCE(strbce),
//	.WRITE_B(write_b),
//	.DEVICE(device[2]),
//	.COMMAND(command),
//	.INDATA(indata),
//	.TDO(mbctdo),
//	.TDI(mbctdi),
//	.TMS(mbctms),
//	.TCK(mbctck),
//	.LEDA(sled[4]),
//	.LEDB(dmy2),
//	.DTACK_B(dtack_b),
//	.OUTDATA(outdata),
//	.DIAGOUT(diagmbc)
//);
gen_jtag_ce #(
	.TMR(TMR)
) mbcjtag_i (
	.FASTCLK(fastclk),
	.SLOWCLK_EN(midclk_en),
	.NEG_SLOWCLK_EN(neg_midclk_en),
	.RST(rst),
	.INITJTAGS(initjtags),
	.STROBE(strobe),
	.STRBCE(strbce),
	.WRITE_B(write_b),
	.DEVICE(device[2]),
	.COMMAND(command),
	.INDATA(indata),
	.TDO(mbctdo),
	.TDI(mbctdi),
	.TMS(mbctms),
	.TCK(mbctck),
	.LEDA(sled[4]),
	.LEDB(dmy2),
	.DTACK_B(dtack_b),
	.OUTDATA(outdata),
	.DIAGOUT(diagmbc)
);

/////////////////////////////////////
//
// Device 3: CPROMJTAG (Controller PROM JTAG)
//
/////////////////////////////////////
//gen_jtag cpromjtag_i (
//	.FASTCLK(fastclk),
//	.SLOWCLK(slowclk2),
//	.RST(rst),
//	.INITJTAGS(initjtags),
//	.STROBE(strobe),
//	.STRBCE(strbce),
//	.WRITE_B(write_b),
//	.DEVICE(device[3]),
//	.COMMAND(command),
//	.INDATA(indata),
//	.TDO(cpromtdo),
//	.TDI(cpromtdi),
//	.TMS(cpromtms),
//	.TCK(cpromtck),
//	.LEDA(dmy3),
//	.LEDB(sled[5]),
//	.DTACK_B(dtack_b),
//	.OUTDATA(outdata),
//	.DIAGOUT(diagcprom)
//);
gen_jtag_ce #(
	.TMR(TMR)
) cpromjtag_i (
	.FASTCLK(fastclk),
	.SLOWCLK_EN(slowclk2_en),
	.NEG_SLOWCLK_EN(neg_slowclk2_en),
	.RST(rst),
	.INITJTAGS(initjtags),
	.STROBE(strobe),
	.STRBCE(strbce),
	.WRITE_B(write_b),
	.DEVICE(device[3]),
	.COMMAND(command),
	.INDATA(indata),
	.TDO(cpromtdo),
	.TDI(cpromtdi),
	.TMS(cpromtms),
	.TCK(cpromtck),
	.LEDA(dmy3),
	.LEDB(sled[5]),
	.DTACK_B(dtack_b),
	.OUTDATA(outdata),
	.DIAGOUT(diagcprom)
);

/////////////////////////////////////
//
// Device 4: VPROMJTAG (VME PROM JTAG)
//
/////////////////////////////////////
//gen_jtag vpromjtag_i (
//	.FASTCLK(fastclk),
//	.SLOWCLK(slowclk2),
//	.RST(rst),
//	.INITJTAGS(initjtags),
//	.STROBE(strobe),
//	.STRBCE(strbce),
//	.WRITE_B(write_b),
//	.DEVICE(device[4]),
//	.COMMAND(command),
//	.INDATA(indata),
//	.TDO(vpromtdo),
//	.TDI(vpromtdi),
//	.TMS(vpromtms),
//	.TCK(vpromtck),
//	.LEDA(dmy4),
//	.LEDB(sled[6]),
//	.DTACK_B(dtack_b),
//	.OUTDATA(outdata),
//	.DIAGOUT(diagvprom)
//);
gen_jtag_ce #(
	.TMR(TMR)
) vpromjtag_i (
	.FASTCLK(fastclk),
	.SLOWCLK_EN(slowclk2_en),
	.NEG_SLOWCLK_EN(neg_slowclk2_en),
	.RST(rst),
	.INITJTAGS(initjtags),
	.STROBE(strobe),
	.STRBCE(strbce),
	.WRITE_B(write_b),
	.DEVICE(device[4]),
	.COMMAND(command),
	.INDATA(indata),
	.TDO(vpromtdo),
	.TDI(vpromtdi),
	.TMS(vpromtms),
	.TCK(vpromtck),
	.LEDA(dmy4),
	.LEDB(sled[6]),
	.DTACK_B(dtack_b),
	.OUTDATA(outdata),
	.DIAGOUT(diagvprom)
);

assign dvcenb  = device[4] | initjtags | dvcenb_hld;
assign clr_enb = rst | (dvc_enb_cnt_7 & !device[4]);

always @(posedge fastclk or posedge clr_enb) begin
	if(clr_enb)
		dvcenb_hld <= 1'b0;
	else
		dvcenb_hld <= device[4] | dvcenb_hld;
end

cbnce #(
	.Width(8),
	.TMR(TMR)
) dvc_enb_cnt_i (.CLK(fastclk),.RST(device[4] | dvc_enb_cnt_7),.CE(slowclk2_en & dvcenb),.Q(dvc_enb_cnt));

always @(posedge fastclk) begin
	if(slowclk2_en) begin
		dvc_enb_cnt_7 <= dvc_enb_cnt[7];
	end
end


/////////////////////////////////////
//
// Device 5: SERDAC (Serial DAC)
//
/////////////////////////////////////
serdac serdac_i (
	.FASTCLK(fastclk),
	.MIDCLK(midclk),
	.RST(rst),
	.STROBE(strobe),
	.WRITE_B(write_b),
	.DEVICE(device[5]),
	.COMMAND(command),
	.INDATA(indata),
	.DACOUT(dacout),
	.DACCS_B(daccs_b),
	.DACDATA(dacdata),
	.DACCLK(dacclk),
	.DTACK_B(dtack_b)
);

/////////////////////////////////////
//
// Device 6: PORTCNTL (FIFO read/write control)
//
/////////////////////////////////////

assign ff_wr_data = {ffwen_b,command[1:0],indata};

portcntl portcntl_i (
	.FASTCLK(fastclk),
	.MIDCLK(midclk),
	.RST(rst),
	.STROBE(strobe),
	.STRBCE(strbce),
	.WRITE_B(write_b),
	.DEVICE(device[6]),
	.COMMAND(command),
	.INDATA(indata),
	.FF_RD_DATA(ff_rd_data),
	.RDFFNXT(rdnextff),
	.LDFFCLK(ldffclk),
	.FFWEN_B(ffwen_b),
	.TOFF_B(toff_b),
	.ENAFF(enaff),
	.DTACK_B(dtack_b),
	.OUTDATA(outdata),
	.DIAGOUT(diagport[9:0])
);

/////////////////////////////////////
//
// Device 7: SERADC (Serial ADC Max1270/1271)
//
/////////////////////////////////////
seradc_ce seradc_i (
	.BBCLK(bbclk),
	.FASTCLK(fastclk),
	.SLOWCLK_EN(slowclk_en),
	.RST(rst),
	.STROBE(strobe),
	.STRBCE(strbce),
	.WRITE_B(write_b),
	.ADCBUSY_B(adcbusy_b),
	.DEVICE(device[7]),
	.COMMAND(command),
	.INDATA(indata),
	.ADCIN(adcin),
	.ADCCLK(adcclk),
	.ADCDATA(adcdata),
	.ADCENA_B(adcena_b),
	.LED(sled[7]),
	.DTACK_B(dtack_b),
	.BBCONV(bbconv),
	.OUTDATA(outdata),
	.DIAGADC(diagadc)
);

/////////////////////////////////////
//
// Device 8: LVDBMON (Low Voltage Distribution Board Monitoring)
//
/////////////////////////////////////
lvdbmon_ce lvdbmon_i (
	.FASTCLK(fastclk),
	.SLOWCLK_EN(slowclk_en),
	.RST(rst),
	.STROBE(strobe),
	.STRBCE(strbce),
	.WRITE_B(write_b),
	.DEVICE(device[8]),
	.COMMAND(command),
	.INDATA(indata),
	.ADCIN(lvadcback),
	.ADCDATA(lvadcdata),
	.ADCCLK(lvadcclk),
	.LOADON(loadpower),
	.LVADCEN_B(lvadcen_b),
	.LVTURNON(poweron),
	.DTACK_B(dtack_b),
	.OUTDATA(outdata),
	.DIAGLVDB(diaglvdb)
);

/////////////////////////////////////
//
// Device 9: FLASH49BV512 (Flash memory controller)
//
/////////////////////////////////////
flash49bv512_ce #(
	.Flash_Disabled(Flash_Disabled),
	.TMR(TMR)
)
flash49bv512_i (
	.FASTCLK(fastclk),
	.CLKCNT(clkcnt),
	.RST(fpgarst),
	.STROBE(strobe),
	.WRITE_B(write_b),
	.DEVICE(device[9]),
	.COMMAND(command),
	.INDATA(indata),
	.FMDIN(fmdin),
	.FMOE_B(fmoe_b),
	.FMCE_B(fmce_b),
	.FMWE_B(fmwe_b),
	.FMOUTEN_B(fmouten_b),
	.FMDOUT(fmdout),
	.FMADR(fmadr),
	.JTAGEN(initamp),
	.TMS(cfebtms),
	.TCK(cfebtck),
	.TDI(cfebtdi),
	.DTACK_B(dtack_b),
	.OUTDATA(outdata),
	.DIAGOUT(diagfm)
);

assign splitin = {bbconv,adcclk,adcdata,mbctms,mbctck,mbctdo,mbctdi,dtack_b};
assign diagport[15:10] = {adcena_b[1],adcena_b[4],bbconv,adcbusy_b,bbclk,adcin[2]};
assign diagtop = {diagmbc[15:8],fastclk,midclk,neg_midclk_en,midclk_en,neg_slowclk_en,slowclk_en,neg_slowclk2_en,slowclk2_en};

/////////////////////////////////////
//
// MULTICON (Multipurpos front panel connector interface)
//
/////////////////////////////////////
multicon multicon_i (
	.LVADCCLK(lvadcclk),
	.LVADCDATA(lvadcdata),
	.LVADCEN_B(lvadcen_b),
	.SPLITIN(splitin),
	.INDATA(indata),
	.MDATAIN(mdatain),
	.MODE(monmode),
	.VMEADD(addmon),
	.DIAGIN(diagcmd),
	.LVADCBACK(lvadcback),
	.POWEREN_B(poweronen_b),
	.FROMCON(fromcon),
	.MDATAOUT(mdataout),
	.MOUTEN_B(mouten_b)
);


endmodule
