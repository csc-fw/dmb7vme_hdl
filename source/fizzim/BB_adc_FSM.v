
// Created by fizzim_tmr.pl version $Revision: 4.44 on 2016:02:04 at 16:02:37 (www.fizzim.com)

module BB_adc_FSM (
  output reg BBCONV,
  output reg DATAREADY,
  input ADCBUSY,
  input CLK,
  input READBB,
  input RST,
  input STROBE 
);

  // state bits
  parameter 
  Idle      = 3'b000, 
  Conv      = 3'b001, 
  Data      = 3'b010, 
  Pause     = 3'b011, 
  Wait_Busy = 3'b100; 

  reg [2:0] state;


  reg [2:0] nextstate;


  reg [2:0] hold;
  reg scnd;
  reg next_scnd;

  // comb always block
  always @* begin
    nextstate = 3'bxxx; // default to x because default_state_is_x is set
    next_scnd = scnd;
    case (state)
      Idle     : begin
                                             next_scnd = 0;
        if               (STROBE && READBB)  nextstate = Conv;
        else                                 nextstate = Idle;
      end
      Conv     : if      (ADCBUSY)           nextstate = Wait_Busy;
                 else                        nextstate = Conv;
      Data     : if      (!STROBE)           nextstate = Idle;
                 else                        nextstate = Data;
      Pause    : begin
                                             next_scnd = 1;
        if               (hold == 3'd6)      nextstate = Conv;
        else                                 nextstate = Pause;
      end
      Wait_Busy: if      (!ADCBUSY && scnd)  nextstate = Data;
                 else if (!ADCBUSY)          nextstate = Pause;
                 else                        nextstate = Wait_Busy;
    endcase
  end

  // Assign reg'd outputs to state bits

  // sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      state <= Idle;
      scnd <= 0;
    end
    else begin
      state <= nextstate;
      scnd <= next_scnd;
    end
  end

  // datapath sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      BBCONV <= 0;
      DATAREADY <= 0;
      hold <= 0;
    end
    else begin
      BBCONV <= 0; // default
      DATAREADY <= 0; // default
      hold <= 0; // default
      case (nextstate)
        Conv     : BBCONV <= 1;
        Data     : DATAREADY <= 1;
        Pause    : hold <= hold + 1;
      endcase
    end
  end

  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [71:0] statename;
  always @* begin
    case (state)
      Idle     : statename = "Idle";
      Conv     : statename = "Conv";
      Data     : statename = "Data";
      Pause    : statename = "Pause";
      Wait_Busy: statename = "Wait_Busy";
      default  : statename = "XXXXXXXXX";
    endcase
  end
  `endif

endmodule

