module PID(clk,rst_n,error,drv_duty);

  input clk;					// system clock
  input rst_n;					// active low asynch reset
  input signed [12:0] error;	// error from IR array
  output [11:0] drv_duty;		// duty cycle motor is driven with
  
  localparam P_coeff = 8;		// in the range 1 to 8
  localparam I_coeff = 2;		// in the range 0 to 2
  localparam D_coeff = 48;		// in the range 0 to 64
  
  wire signed [15:0] P_term;	// intermediate for build up of P_term
  wire signed [16:0] D_term;	// intermediate for build up of D_term
  wire [13:0] I_term;			// intermediate for build up of I_term
  wire signed [16:0] PID;		// summation of P, I, and D terms
  wire [19:0] nxt_integrator;
  
  reg [19:0] integrator;		// accumulator to make an integrator
  
  ////////////////////////////////////////////////////////////////
  // Dervative can simply be done by subtracting current value //
  // of error from previous value of error.  Diff over time   //
  /////////////////////////////////////////////////////////////
  reg signed [12:0] prev_error1,prev_error2;
  reg signed [12:0] prev_error3,prev_error4;
  
  //// P_term is simply error times a constant ////
  assign P_term = $signed(P_coeff)*error;
  
  //// An integrator is simply an accumulator ////
  assign nxt_integrator = integrator + {{7{error[12]}},error};
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  integrator <= 20'h0000;
	else
	  integrator <= (nxt_integrator[19]) ? 20'h00000 : nxt_integrator;
	  
  //// I_term will be integrator/128 ////
  assign I_term = I_coeff*integrator[18:7];
  
  ///////////////////////////////////////////////
  // To get a D_term one has to keep track of //
  // previous versions of the error term.    //
  ////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
	  prev_error1 <= 13'h0000;
	  prev_error2 <= 13'h0000;
	  prev_error3 <= 13'h0000;
	  prev_error4 <= 13'h0000;
	end else begin
	  prev_error1 <= error;
	  prev_error2 <= prev_error1;
	  prev_error3 <= prev_error2;
	  prev_error4 <= prev_error3;
	end
	
  //// D_term is simply a scaled version of error diff from previous ////
  assign D_term = $signed(D_coeff)*$signed(error - prev_error4);
  
  //// Sum up P,I, & D. ////
  assign PID = {{3{P_term[15]}},P_term[15:2]} + I_term + D_term;
  
  //// drv_duty is just PID, however, it is not allowed ////
  //// negative or greater than FFF, so saturate       ////
  assign drv_duty = (PID[16]) ? 12'h000 :
                    (|PID[15:12]) ? 12'hFFF :
					PID[11:0];
					
endmodule
	  
  