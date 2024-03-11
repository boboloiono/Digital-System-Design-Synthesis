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
  
  // << Your declarations of states, regs, wires, ...>>
  
  localparam MAX_FRWRD = 11'h2A0;		// max forward speed
  localparam MIN_FRWRD = 11'h0D0;		// minimum duty at which wheels will turn
  
  logic lft_opn_delay, rght_opn_delay, lft_opn_rise, rght_opn_rise;
  logic init_frwrd, inc_frwrd, dec_frwrd, dec_frwrd_fast;
  logic [5:0] frwrd_inc;
	
  typedef enum reg [2:0] {IDLE, HEADING, RAMP_UP, RAMP_DWON, RAMP_DWON_FAST} state_t;
  state_t state, nxt_state;
  
  ////////////////////////////////
  // Now form forward register //
  //////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  frwrd_spd <= 11'h000;
	else if (init_frwrd)
	  frwrd_spd <= MIN_FRWRD;									// min speed to get motors moving
	else if (hdng_rdy && inc_frwrd && (frwrd_spd<MAX_FRWRD))	// max out at 400 of 7FF for control head room
	  frwrd_spd <= frwrd_spd + {5'h00,frwrd_inc};
	else if (hdng_rdy && (frwrd_spd>11'h000) && (dec_frwrd | dec_frwrd_fast))
	  frwrd_spd <= ((dec_frwrd_fast) && (frwrd_spd>{2'h0,frwrd_inc,3'b000})) ? frwrd_spd - {2'h0,frwrd_inc,3'b000} : // 8x accel rate
                    (dec_frwrd_fast) ? 11'h000 :	  // if non zero but smaller than dec amnt set to zero.
	                (frwrd_spd>{4'h0,frwrd_inc,1'b0}) ? frwrd_spd - {4'h0,frwrd_inc,1'b0} : // slow down at 2x accel rate
					11'h000;

	// << Your implementation of ancillary circuits and SM 	>>
	
	// en_fusion should be asserted if frwrd_spd is greater than ½ MAX_FRWRD
	assign en_fusion = (frwrd_spd > MAX_FRWRD >> 1) ? 1'b1 : 1'b0;
	
	assign lft_opn_rise = (lft_opn & !lft_opn_delay) ? 1'b1 : 1'b0;
	assign rght_opn_rise = (rght_opn & !rght_opn_delay) ? 1'b1 : 1'b0;

	always_comb begin
		moving = 1'b0;
		mv_cmplt = 1'b0;
		init_frwrd = 1'b0; inc_frwrd = 1'b0; dec_frwrd = 1'b0; dec_frwrd_fast = 1'b0;
		case(state) 
			IDLE: begin
				if(strt_hdng) begin
					nxt_state = HEADING;
				end else if (strt_mv) begin
					nxt_state = RAMP_UP;
					init_frwrd = 1'b1;
				end
			end
			HEADING: begin
				if(at_hdng) begin
					nxt_state = IDLE;
					mv_cmplt = 1'b1;
				end
				moving = 1'b1;
			end
			RAMP_UP: begin
				if(~frwrd_opn) nxt_state = RAMP_DWON_FAST;
				else if ((lft_opn_rise & stp_lft) || (rght_opn_rise & stp_rght)) nxt_state = RAMP_DWON;
				moving = 1'b1;
				inc_frwrd = 1'b1;
			end
			RAMP_DWON: begin
				if(~|frwrd_spd) begin
					nxt_state = IDLE;
					mv_cmplt = 1'b1;
				end
				dec_frwrd = 1'b1; 
				moving = 1'b1;
			end
			RAMP_DWON_FAST: begin
				if(~|frwrd_spd) begin
					nxt_state = IDLE;
					mv_cmplt = 1'b1;
				end
				dec_frwrd_fast = 1'b1;
				moving = 1'b1;
			end
		endcase
	end
	
	always_ff @(posedge clk) begin
		lft_opn_delay <= lft_opn;
	end
	
	always_ff @(posedge clk) begin
		rght_opn_delay <= rght_opn;
	end
	
	
	////////////////////////////////////////////////////////////////////////////
	/// Rate of inc/dec of frwrd_spd is controlled by magnitude of frwrd_inc. //
	//  frwrd_inc should be controlled by a parameter FAST_SIM and should be //
	//  6’h18 if FAST_SIM and 6’h02 otherwise.								//
	/////////////////////////////////////////////////////////////////////////
	
	generate if(FAST_SIM) begin
		assign frwrd_inc = 6'h18;
	end else begin
		assign frwrd_inc = 6'h02;
	end	endgenerate
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= IDLE;
		else state <= nxt_state;
	end
endmodule
  