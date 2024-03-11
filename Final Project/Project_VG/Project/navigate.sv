module navigate(clk,rst_n,strt_hdng,strt_mv,stp_lft,stp_rght,mv_cmplt,hdng_rdy,moving,
                en_fusion,at_hdng,lft_opn,rght_opn,frwrd_opn,frwrd_spd);
				
  parameter FAST_SIM = 1;		// speeds up incrementing of frwrd register for faster simulation
				
  input clk,rst_n;					// 50MHz clock and asynch active low reset
  input strt_hdng;					// indicates should start a new heading
  input strt_mv;					// indicates should start a new forward move
  input stp_lft;					// indicates should stop at first left opening
  input stp_rght;					// indicates should stop at first right opening
  input hdng_rdy;					// new heading reading ready....used to pace frwrd_spd increments
  output logic mv_cmplt;			// asserted when heading or forward move complete
  output logic moving;				// enables integration in PID and in inertial_integrator
  output en_fusion;					// Only enable fusion (IR reading affect on nav) when moving forward at decent speed.
  input at_hdng;					// from PID, indicates heading close enough to consider heading complete.
  input lft_opn,rght_opn,frwrd_opn;	// from IR sensors, indicates available direction.  Might stop at rise of lft/rght
  output reg [10:0] frwrd_spd;		// unsigned forward speed setting to PID
  
  //<< Your declarations of states, regs, wires, ...>>
  logic lft_opn_rise, rght_opn_rise;
  logic temp1, temp2;
  logic [5:0]frwrd_inc;
  logic init_frwrd, inc_frwrd, dec_frwrd, dec_frwrd_fast;
  
  localparam MAX_FRWRD = 11'h2A0;		// max forward speed
  localparam MIN_FRWRD = 11'h0D0;		// minimum duty at which wheels will turn
  
  ////////////////////////////////
  // Now form forward register //
  //////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  frwrd_spd <= 11'h000;
	else if (init_frwrd)		// assert this signal when leaving IDLE due to strt_mv
	  frwrd_spd <= MIN_FRWRD;									// min speed to get motors moving
	else if (hdng_rdy && inc_frwrd && (frwrd_spd<MAX_FRWRD))	// max out at 2A0
	  frwrd_spd <= frwrd_spd + {5'h00,frwrd_inc};				// always accel at 1x frwrd_inc
	else if (hdng_rdy && (frwrd_spd>11'h000) && (dec_frwrd | dec_frwrd_fast))
	  frwrd_spd <= ((dec_frwrd_fast) && (frwrd_spd>{2'h0,frwrd_inc,3'b000})) ? frwrd_spd - {2'h0,frwrd_inc,3'b000} : // 8x accel rate
                    (dec_frwrd_fast) ? 11'h000 :	  // if non zero but smaller than dec amnt set to zero.
	                (frwrd_spd>{4'h0,frwrd_inc,1'b0}) ? frwrd_spd - {4'h0,frwrd_inc,1'b0} : // slow down at 2x accel rate
					11'h000;

  //<< Your implementation of ancillary circuits and SM >>

  //assign frwrd_inc = (FAST_SIM)? 6'h18:6'h02;

  
logic at_hdng_prev1, at_hdng_prev2, at_hdng_prev3, at_hdng_rise;

//rising edge of at_hdng

always_ff @(posedge clk)begin
	at_hdng_prev1 <= at_hdng;
	//at_hdng_prev2 <= at_hdng_prev1;
	//at_hdng_prev3 <= at_hdng_prev2;
end

assign at_hdng_rise = at_hdng & ~at_hdng_prev1;
  
  generate if(FAST_SIM) begin
	assign frwrd_inc = 6'h18;
  end else 
	assign frwrd_inc = 6'h02;
  endgenerate
  
  assign en_fusion = (frwrd_spd > (MAX_FRWRD >> 1));
  
  //rising  edge detector
  always @(posedge clk) begin
	temp1 <= lft_opn;
	temp2 <= rght_opn;
  end
  
  assign lft_opn_rise = lft_opn & ~temp1;
  assign rght_opn_rise = rght_opn & ~temp2;
  
  typedef enum logic [2:0] {IDLE, HEADING, ACCLERATE, DECELERATE, DECELERATE_FAST, TO_TURN} state_t;
	state_t state, nxt_state;
	
   //SM
  always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
		
   //SM control
   
  always_comb begin 
	// defaulting the outputs to prevent latches
	nxt_state = state;
	moving = 0;
	init_frwrd = 0;
	inc_frwrd = 0;
	dec_frwrd = 0;
	dec_frwrd_fast = 0;
	mv_cmplt = 0;
	
    case(state)
	
	default: begin // is idle
		if(strt_hdng) begin
			nxt_state = HEADING;
		end
		
		else if(strt_mv) begin
			init_frwrd = 1;
			nxt_state = ACCLERATE;
		end
		
	end
	
	HEADING: begin
		moving = 1;
		if(at_hdng_rise) begin
			mv_cmplt = 1;
			nxt_state = IDLE;
		end
	end
	
	ACCLERATE: begin
		moving = 1;
		inc_frwrd = 1;
		if(!frwrd_opn) begin
			nxt_state = DECELERATE_FAST;
		end
		
		else if(lft_opn_rise && stp_lft) begin
			nxt_state = DECELERATE;
		end
		else if(rght_opn_rise && stp_rght) begin
			nxt_state = DECELERATE;
		end
	end
	
	DECELERATE: begin
		moving = 1;
		dec_frwrd = 1;
		if(!frwrd_spd) begin
			mv_cmplt = 1;
			nxt_state = IDLE;
		end
	end
	
	DECELERATE_FAST: begin
		moving = 1;
		dec_frwrd_fast = 1;
		if(!frwrd_spd) begin
			mv_cmplt = 1;
			nxt_state = IDLE;
		end
	end

	TO_TURN: begin
		if(at_hdng_rise == 1'b0)
			nxt_state = HEADING;
	end

	endcase
end

   
endmodule
  
