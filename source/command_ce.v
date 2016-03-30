`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:02:14 03/27/2015 
// Design Name: 
// Module Name:    command 
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
module command_ce #(
	parameter TMR = 0
)(
    input CMSCLK,
    input RST,
    input [5:0] GA_B,
    input [5:0] AM,
    input [23:1] ADR,
    input AS_B,
    input DS0_B,
    input DS1_B,
    input LWORD_B,
    input WRITE_B,
    input BERR_B,
    input IACK_B,
    input SYSFAIL_B,
    output FASTCLK,
    output MIDCLK,
	 output [4:0] CLKCNT,
    output [9:0] DEVICE,
    output [9:0] COMMAND,
    output [15:0] ADDMON,
    output [2:0] LED,
    output [15:0] DIAGOUT,
    output TOVME_B,
    output reg STROBE,
    output STRBCE,
    output reg VMEREADY
    );

wire fclk;
wire mclk;
wire locked;

reg  [23:1] adrs;
reg [5:0] ams;
wire [6:0] devcode;
wire [4:0] cga;
wire cgap;
wire validga;
wire validam;
wire oldcrate;
wire board_sel_new;
wire boardenb;
wire broadcast;
wire sysok;
wire asynstrb;
reg s1;
reg s2;
wire drst;


assign ADDMON          = adrs[17:2];
assign COMMAND         = adrs[11:2];
//assign DIAGOUT         = {DS0_B,board_sel_new,validam,sysok,validga,cgap,cga[0],adrs[19],cga[1],adrs[20],cga[2],adrs[21],cga[3],adrs[22],cga[4],adrs[23]};
assign DIAGOUT         = {STROBE,board_sel_new,DEVICE,devcode[3:0]};

assign devcode = adrs[18:12];
assign {cgap,cga} = ~GA_B;
assign validga   = ^{cgap,cga};
assign oldcrate  = ~|{cgap,cga};
assign board_sel_new = ~|(adrs[23:19]^cga);
assign validam = LWORD_B & ams[5] & ams[4] & ams[3] & (ams[1]^ams[0]);
assign sysok   = IACK_B & SYSFAIL_B;
assign broadcast = (adrs[23:19]==5'd25) || (adrs[23:19]==5'd27);
assign boardenb = oldcrate | (validga & board_sel_new) | broadcast;
assign asynstrb = sysok & validam & boardenb & ~DS0_B & ~DS1_B;
assign TOVME_B  = ~(sysok & validam & boardenb & WRITE_B);
assign LED      = {~STROBE,~asynstrb,~TOVME_B};
assign drst = 1'b0;
assign DEVICE[0] = (devcode == 7'h00);
assign DEVICE[1] = (devcode == 7'h01);
assign DEVICE[2] = (devcode == 7'h02);
assign DEVICE[3] = (devcode == 7'h03);
assign DEVICE[4] = (devcode == 7'h04);
assign DEVICE[5] = (devcode == 7'h05);
assign DEVICE[6] = (devcode == 7'h06);
assign DEVICE[7] = (devcode == 7'h07);
assign DEVICE[8] = (devcode == 7'h08);
assign DEVICE[9] = (devcode == 7'h09);

//////////////////////////////////////////////////
//
// Device code
// 00: VME Interface FPGA
// 01: CFEB JTAG
// 02: DAQMB Controller FPGA JTAG
// 03: DAQMB Controller PROM JTAG
// 04: VME Interface PROM JTAG
// 05: Dual DAC for Calibration
// 06: FIFO Read/Write
// 07: DAQMB ADC Interface
// 08: Low Voltage Monitoring Interface
// 09: Flash Memory for buckeye shift
// 0F: Emergency PROM Programming, Reserved for Emergency CPLD
//
////////////////////////////////////////////////

(* iob = "TRUE" *)
always @(AS_B or ADR or AM) begin //Latch on address strobe
	if(AS_B) begin
		adrs = ADR;
		ams  = AM;
	end
end

always @(posedge FASTCLK or negedge asynstrb) begin
	if(~asynstrb) begin
		s1 <= 1'b0;
		s2 <= 1'b0;
		STROBE <= 1'b0;
	end
	else begin
		s1 <= asynstrb;
		s2 <= s1;
		STROBE <= s2;
	end
end

assign STRBCE = s2 & !STROBE;

BUFG bufg_fastclk   (.O(FASTCLK),.I(fclk)); 
BUFG bufg_midclk    (.O(MIDCLK),.I(mclk));

CLKDLL #(
	.CLKDV_DIVIDE(4.0),     // Divide by: 1.5,2.0,2.5,3.0,4.0,5.0,8.0 or 16.0
	.DUTY_CYCLE_CORRECTION("TRUE"),  // Duty cycle correction, TRUE or FALSE
	.FACTORY_JF(16'hC080),  // FACTORY JF Values
	.STARTUP_WAIT("FALSE") // Delay config DONE until DLL LOCK, TRUE/FALSE
) CLKDLL_fast_mid (
	.CLK0(fclk),     // 0 degree DLL CLK output
	.CLK180(), // 180 degree DLL CLK output
	.CLK270(), // 270 degree DLL CLK output
	.CLK2X(),   // 2X DLL CLK output
	.CLK90(),   // 90 degree DLL CLK output
	.CLKDV(mclk),    // Divided DLL CLK out (CLKDV_DIVIDE)
	.LOCKED(locked), // DLL LOCK status output
	.CLKFB(FASTCLK),   // DLL clock feedback
	.CLKIN(CMSCLK),   // Clock input (from IBUFG, BUFG or DLL)
	.RST(drst)        // DLL asynchronous reset input
);

always @(posedge MIDCLK) begin
	VMEREADY <= locked;
end

cbncer #(
	.Width(5),
	.TMR(TMR)
) clk_cnt_i (.CLK(FASTCLK),.SRST(RST),.CE(1'b1),.Q(CLKCNT));



endmodule
