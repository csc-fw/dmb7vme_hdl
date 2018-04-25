`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:23:57 04/13/2015
// Design Name:   dmb7vme_hdl
// Module Name:   C:/Users/bylsma/Projects/DMB/Firmware/dmb7vme_hdl/source/dmb7vme_hdl_sim.v
// Project Name:  dmb7vme_hdl
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: dmb7vme_hdl
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module dmb7vme_hdl_sim;

	// Inputs
	reg FPGACLK;
	reg IGLOBALRST;
	reg ISYSRST_B;
	reg ISOFTRST;
	reg INACK_B;
	reg IBERR_B;
	reg IAS_B;
	reg IDS0_B;
	reg IDS1_B;
	reg ILWORD_B;
	reg IWRITE_B;
	reg ISYSFAIL_B;
	reg [4:1] ISW;
	reg [5:0] IGA_B;
	reg [23:1] IADR;
	reg [5:0] IAM;
	reg [5:1] IFTDO;
	reg ICTDO;
	reg CIPTDO;
	reg VIPTDO;
	reg [2:1] IADC;
	reg BBCLKIN;
	reg ADCB_B;
	reg IDACOUT;
	reg [3:0] INMODE;
	reg IDONETRG;
	reg [5:1] IDONEF;

	// Outputs
	wire OTOVME;
	wire ODTACK_B;
	wire DOE_B;
	wire REPRGEN_B;
	wire CNTLFPGA;
	wire OVMEREADY_B;
	wire [7:0] LED;
	wire [5:1] OFTCK;
	wire [5:1] OFTDI;
	wire OFTMS;
	wire OCTCK;
	wire OCTMS;
	wire OCTDI;
	wire COPTCK;
	wire COPTMS;
	wire COPTDI;
	wire VOPTCK;
	wire VOPTMS;
	wire VOPTDI;
	wire ADCDT;
	wire ADCCK;
	wire BBCONVOUT_B;
	wire [4:1] ADCEN_B;
	wire DACCK;
	wire DACDT;
	wire ODACCS_B;
	wire FFWCLK;
	wire FFBUFOE_B;
	wire FFRDNEXT;
	wire [7:1] ENFF;
	wire [7:1] DSFF;
	wire [6:1] PWON;
	wire LOADPWON;
	wire PWONEN_B;
	wire [9:0] OFMADR;
	wire OFMCE_B;
	wire OFMWE_B;
	wire OFMOE_B;

	// Bidirs
	wire [15:0] IODATA;
	wire [18:0] IOPARD;
	wire [15:0] MULTI;
	wire [7:0] IOFMD;
	
	//Test Fixture Signals
	reg dcapt;
   reg [15:0] vrd_reg;
	reg [15:0] data_bus;
	integer i;
	wire [15:0] bbadc = 16'h28A6;
	reg [7:0] flash_word[15:0];

	// Instantiate the Unit Under Test (UUT)
	dmb7vme_hdl uut (
		.FPGACLK(FPGACLK), 
		.IGLOBALRST(IGLOBALRST), 
		.ISYSRST_B(ISYSRST_B), 
		.ISOFTRST(ISOFTRST), 
		.INACK_B(INACK_B), 
		.IBERR_B(IBERR_B), 
		.IAS_B(IAS_B), 
		.IDS0_B(IDS0_B), 
		.IDS1_B(IDS1_B), 
		.ILWORD_B(ILWORD_B), 
		.IWRITE_B(IWRITE_B), 
		.ISYSFAIL_B(ISYSFAIL_B), 
		.ISW(ISW), 
		.IGA_B(IGA_B), 
		.IADR(IADR), 
		.IAM(IAM), 
		.IODATA(IODATA), 
		.OTOVME(OTOVME), 
		.ODTACK_B(ODTACK_B), 
		.DOE_B(DOE_B), 
		.REPRGEN_B(REPRGEN_B), 
		.CNTLFPGA(CNTLFPGA), 
		.OVMEREADY_B(OVMEREADY_B), 
		.LED(LED), 
		.IFTDO(IFTDO), 
		.OFTCK(OFTCK), 
		.OFTDI(OFTDI), 
		.OFTMS(OFTMS), 
		.ICTDO(ICTDO), 
		.OCTCK(OCTCK), 
		.OCTMS(OCTMS), 
		.OCTDI(OCTDI), 
		.CIPTDO(CIPTDO), 
		.COPTCK(COPTCK), 
		.COPTMS(COPTMS), 
		.COPTDI(COPTDI), 
		.VIPTDO(VIPTDO), 
		.VOPTCK(VOPTCK), 
		.VOPTMS(VOPTMS), 
		.VOPTDI(VOPTDI), 
		.IADC(IADC), 
		.BBCLKIN(BBCLKIN), 
		.ADCB_B(ADCB_B), 
		.ADCDT(ADCDT), 
		.ADCCK(ADCCK), 
		.BBCONVOUT_B(BBCONVOUT_B), 
		.ADCEN_B(ADCEN_B), 
		.IDACOUT(IDACOUT), 
		.DACCK(DACCK), 
		.DACDT(DACDT), 
		.ODACCS_B(ODACCS_B), 
		.FFWCLK(FFWCLK), 
		.FFBUFOE_B(FFBUFOE_B), 
		.FFRDNEXT(FFRDNEXT), 
		.ENFF(ENFF), 
		.DSFF(DSFF), 
		.IOPARD(IOPARD), 
		.PWON(PWON), 
		.LOADPWON(LOADPWON), 
		.INMODE(INMODE), 
		.IDONETRG(IDONETRG), 
		.IDONEF(IDONEF), 
		.MULTI(MULTI), 
		.PWONEN_B(PWONEN_B), 
		.IOFMD(IOFMD), 
		.OFMADR(OFMADR), 
		.OFMCE_B(OFMCE_B), 
		.OFMWE_B(OFMWE_B), 
		.OFMOE_B(OFMOE_B)
	);
	
   parameter PERIOD = 24;


	initial begin
		// Initialize Inputs
      FPGACLK = 1'b0;
      forever
         #(PERIOD/2) FPGACLK = ~FPGACLK;
	end


	always @(posedge FPGACLK) begin
		IFTDO <= OFTDI;
		ICTDO <= OCTDI;
		CIPTDO <= COPTDI;
		VIPTDO <= VOPTDI;
	end

	initial begin
		// Initialize Inputs
		IGLOBALRST = 1;
		ISYSRST_B = 1;
		ISOFTRST = 0;
		INACK_B = 1;
		IBERR_B = 1;
		ISYSFAIL_B = 1;
		ISW = 0;
		IGA_B = 6'h3F;
		IADC = 0;
		BBCLKIN = 0;
		ADCB_B = 1;
		IDACOUT = 0;
		INMODE = 0;
		IDONETRG = 1;
		IDONEF = 5'b11111;
		IAS_B = 1;
		IDS0_B = 1;
		IDS1_B = 1;
		ILWORD_B = 1;
		IWRITE_B = 1;
		IADR = 23'hffffff;
		IAM = 6'h3f;
		dcapt = 0;
		vrd_reg =0;
		data_bus = 16'hzzzz;
		flash_word[0] = 8'h00;
		flash_word[1] = 8'h02;
		flash_word[2] = 8'h02;
		flash_word[3] = 8'h00;
		flash_word[4] = 8'h04;
		flash_word[5] = 8'h04;
		flash_word[6] = 8'h00;
		flash_word[7] = 8'h00;
		flash_word[8] = 8'h08;
		flash_word[9] = 8'h08;
		flash_word[10] = 8'h00;
		flash_word[11] = 8'h00;
		flash_word[12] = 8'h10;
		flash_word[13] = 8'h10;
		flash_word[14] = 8'h00;
		flash_word[15] = 8'h00;

		// Wait 100 ns for global reset to finish
		#100;
		IGLOBALRST = 0;
//		#(25*PERIOD);
//		IGLOBALRST = 0;
//		#(50*PERIOD);
//		IGLOBALRST = 1;
//		#(20*PERIOD);
//		IGLOBALRST = 0;
//		#(50*PERIOD);

		#250000;
		Set_Slot(5'd3);
		VME_Read(24'h180000);  
		VME_Read (24'h180004);  
		
//		while(uut.flash49bv512_i.enddata != 1) begin
//			#3;
//		end

// CFEB JTAG 
		#(20*PERIOD);
		VME_Write (24'h181020,16'h0004);  // Write CFEB selection register 
		#(20*PERIOD);
		VME_Read  (24'h181024);           // Read CFEB selection register 
		#(20*PERIOD);
		VME_Write (24'h181018,16'h0000);  // JTAG reset
		#(20*PERIOD);
		VME_Write (24'h181C1C,16'h1FE2);  // Shift instruction (bypass in PROM and USR1 in Virtex
		VME_Read  (24'h181014);           // Read TDO reg
		#(20*PERIOD);
		VME_Write (24'h18180C,16'h01A5);  // Shift Data to USR1 command reg
		VME_Read  (24'h181014);           // Read TDO reg
		#(20*PERIOD);
		VME_Write (24'h18151C,16'h0003);  // Shift instruction for USR2 in Virtex
		VME_Read  (24'h181014);           // Read TDO reg
		#(20*PERIOD);
		VME_Write (24'h181F04,16'hC3A5);  // Shift Data for command 52 bits of data plus one for bypass reg in PROM
		VME_Write (24'h181F00,16'h9009);  // Shift Data 
		VME_Write (24'h181F00,16'h1818);  // Shift Data 
		VME_Write (24'h181408,16'h1818);  // Shift Data 
		VME_Read  (24'h181014);           // Read TDO reg
		#(60*PERIOD);
//		VME_Write (24'h181C4C,16'h1FE2);  // Shift instruction with header and special trailer
//		VME_Write (24'h181408,16'h1818);  // Shift Data 
		VME_Write (24'h181F34,16'hB3FF);  // Shift instruction with header
		VME_Write (24'h181F30,16'hFC03);  // Shift instruction no header no trailer
		VME_Write (24'h181F30,16'hFFFF);  // Shift instructionno header no trailer
		VME_Write (24'h181D48,16'h3FFF);  // Shift instruction no header with special trailer
		VME_Write (24'h181F00,16'h007E);  // Shift Data no header no trailer
		VME_Write (24'h181B08,16'h0000);  // Shift Data no header with trailer
/*
//DMB Control FPGA JTAG
		VME_Write (24'h182018,16'h0000);  // JTAG reset
		#(20*PERIOD);
		VME_Write (24'h18271C,16'h00EE);  // Shift instruction config
		VME_Read  (24'h182014);           // Read TDO reg
		#(20*PERIOD);
		VME_Write (24'h182F04,16'hC3A5);  // Shift Data for command 52 bits of data plus one for bypass reg in PROM
		VME_Write (24'h182F00,16'h9009);  // Shift Data 
		VME_Write (24'h182F00,16'h1818);  // Shift Data 
		VME_Write (24'h182408,16'h1818);  // Shift Data 
		VME_Read  (24'h182014);           // Read TDO reg
		#(20*PERIOD);
		VME_Write (24'h18280C,16'h01A5);  // Shift Data to USR1 command reg
		VME_Read  (24'h182014);           // Read TDO reg
		#(20*PERIOD);

//Controller PROM JTAG
		VME_Write (24'h183018,16'h0000);  // JTAG reset
		#(20*PERIOD);
		VME_Write (24'h18371C,16'h00EE);  // Shift instruction config
		VME_Read  (24'h183014);           // Read TDO reg
		#(20*PERIOD);
		VME_Write (24'h183F04,16'hC3A5);  // Shift Data for command 52 bits of data plus one for bypass reg in PROM
		VME_Write (24'h183F00,16'h9009);  // Shift Data 
		VME_Write (24'h183F00,16'h1818);  // Shift Data 
		VME_Write (24'h183408,16'h1818);  // Shift Data 
		VME_Read  (24'h183014);           // Read TDO reg
		#(20*PERIOD);
		VME_Write (24'h18380C,16'h01A5);  // Shift Data to USR1 command reg
		VME_Read  (24'h183014);           // Read TDO reg
		#(20*PERIOD);

//VME PROM JTAG
		VME_Write (24'h184018,16'h0000);  // JTAG reset
		#(20*PERIOD);
		VME_Write (24'h18471C,16'h00EE);  // Shift instruction config
		VME_Read  (24'h184014);           // Read TDO reg
		#(20*PERIOD);
		VME_Write (24'h184F04,16'hC3A5);  // Shift Data for command 52 bits of data plus one for bypass reg in PROM
		VME_Write (24'h184F00,16'h9009);  // Shift Data 
		VME_Write (24'h184F00,16'h1818);  // Shift Data 
		VME_Write (24'h184408,16'h1818);  // Shift Data 
		VME_Read  (24'h184014);            // Read TDO reg
		#(20*PERIOD);
		VME_Write (24'h18480C,16'h01A5);  // Shift Data to USR1 command reg
		VME_Read  (24'h184014);           // Read TDO reg
		#(20*PERIOD);

//DAC setting
		VME_Write (24'h185000,16'h6794);
		#(20*PERIOD);

//FIFO writes
		VME_Write (24'h186020,16'h0004);  // Select FIFO
		VME_Read  (24'h186024);           // Read   FIFO select register
		#(20*PERIOD);
		VME_Write (24'h186000,16'h9669);  // Write data
		VME_Write (24'h186008,16'h9669);  // Write data , overlap
		VME_Write (24'h186004,16'h9669);  // Write data , lastword
		VME_Write (24'h18600C,16'h9669);  // Write data , lastword, overlap
		#(20*PERIOD);
		VME_Write (24'h186020,16'h0000);  // Select no FIFOs (back to normal)
		VME_Read  (24'h186024);           // Read   FIFO select register
		#(20*PERIOD);

//FIFO Reads
		VME_Read  (24'h186018);           // Read data from FIFO (High order, no incr)
		VME_Read  (24'h186014);           // Read data from FIFO (Low  order, incr)
		VME_Read  (24'h18601C);           // Read data from FIFO (High order, incr)
		VME_Read  (24'h186010);           // Read data from FIFO (Low  order, no incr)
		#(20*PERIOD);
		VME_Write (24'h18602C,16'h0000);  // Just increment the read address in the FIFO (POP)
		VME_Write (24'h18602C,16'h0000);  // Just increment the read address in the FIFO (POP)
		VME_Write (24'h18602C,16'h0000);  // Just increment the read address in the FIFO (POP)
		VME_Write (24'h18602C,16'h0000);  // Just increment the read address in the FIFO (POP)
		#(20*PERIOD);

// ADCs 
		#(20*PERIOD);
		VME_Write (24'h187020,16'h000B);  // Write ADC selection register (four bits active low) 
		#(20*PERIOD);
		VME_Read  (24'h187024);           // Read ADC selection register 
		#(20*PERIOD);

		VME_Write (24'h187000,16'h0089);  // Write Control Byte to ADC
		#(20*PERIOD);
		VME_Read  (24'h187004);           // Read ADC 
		#(20*PERIOD);

		#(20*PERIOD);
		VME_Write (24'h187020,16'h0007);  // Write ADC selection register Select Burr Brown
		#(20*PERIOD);
		VME_Read  (24'h187024);           // Read ADC selection register 
		#(20*PERIOD);

		VME_Read  (24'h18700C);           // Read Burr Brown 
		#(20*PERIOD);
*/

// LVDB ADCs 
//		#(20*PERIOD);
//		VME_Write (24'h188020,16'h0003);  // Write ADC selection register (3 bits) 
//		#(20*PERIOD);
//		VME_Read  (24'h188024);           // Read ADC selection register 
//		#(20*PERIOD);
//
//		VME_Write (24'h188000,16'h00D9);  // Write Control Byte to ADC
//		#(20*PERIOD);
//		VME_Read  (24'h188004);           // Read ADC 
//		#(20*PERIOD);
//
//		VME_Write (24'h188010,16'h0033);  // Write Power register
//		#(20*PERIOD);
//		VME_Read  (24'h188014);           // Read Power register
//		#(20*PERIOD);

	end
	always @(posedge dcapt) begin
		vrd_reg <= IODATA;
	end
	
	assign IOFMD = (!OFMCE_B && !OFMOE_B) ? flash_word[OFMADR[3:0]] : 8'hzz;
	assign IODATA = data_bus;
	assign IOPARD = 19'h789AB;

always @* begin
	if(BBCONVOUT_B != 1) begin
		#65;
		ADCB_B = 0;
		#135;
		for(i=15;i>=0;i=i-1) begin
		   IADC[2] = bbadc[i];
			#20;
			BBCLKIN = 1;
			#220;
			BBCLKIN = 0;
			#200;
		end
		#465;
		ADCB_B = 1;
	end
end
	
task Set_Slot;
input [4:0] slot;
begin
	IGA_B[4:0] = ~slot;
	IGA_B[5] = ^(slot);
end
endtask

task VME_Write;
input [23:0] adr;
input [15:0] data;
begin
	IAM = 6'h39;
	IADR = adr[23:1];
	INACK_B = 1;
	ILWORD_B = 1;
	#10;
	IAS_B = 0;
	#10;
	IWRITE_B = 0;
	while(IBERR_B == 0 || ODTACK_B == 0) begin
		#3;
	end
	data_bus = data;
	#10;
	IDS0_B = 0;
	IDS1_B = 0;
	while(ODTACK_B != 0) begin
		#3;
	end
	#2;
	IAM = 6'hff;
	IADR = 23'hffffff;
	INACK_B = 1;
	ILWORD_B = 1;
	data_bus = 16'hzzzz;
	#5
	IDS0_B = 1;
	IDS1_B = 1;
	IAS_B = 1;
end
endtask

task VME_Read;
input [23:0] adr;
begin
	IAM = 6'h39;
	IADR = adr[23:1];
	INACK_B = 1;
	ILWORD_B = 1;
	#10;
	IAS_B = 0;
	#10;
	IWRITE_B = 1;
	while(IBERR_B == 0 || ODTACK_B == 0) begin
		#3;
	end
	#10;
	IDS0_B = 0;
	IDS1_B = 0;
	while(ODTACK_B != 0) begin
		#3;
	end
	#2;
	dcapt = 1;
	#10;
	dcapt = 0;
	
	IAM = 6'hff;
	IADR = 23'hffffff;
	INACK_B = 1;
	ILWORD_B = 1;
	#5
	IDS0_B = 1;
	IDS1_B = 1;
	IAS_B = 1;
end
endtask
      
endmodule

