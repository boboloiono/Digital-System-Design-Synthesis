module navigate_tb();

  //// Declare stimulus as type reg ////
  reg clk,rst_n;			// 50MHz clock and asynch active low reset
  reg strt_hdng;			// indicates to start a new heading sequence
  reg strt_mv;				// indicates a new forward movement occurring
  reg stp_lft;				// indicates move should stop at a left opening
  reg stp_rght;				// indicates move should stop at a right opening
  reg hdng_rdy;				// used to pace frwrd_spd increments
  reg at_hdng;				// asserted by PID when new heading is close enough
  reg lft_opn;				// from IR sensor....indicates opening in maze to left
  reg rght_opn;				// from IR sensor....indicates opening in maze to right
  reg frwrd_opn;			// from IR sensor....indicates opening in front
  
  //// declare outputs monitored of type wire ////
  wire mv_cmplt;			// should be asserted at end of move
  wire moving;				// should be asserted at all times not in IDLE
  wire en_fusion;			// should be asserted whenever frwrd_spd>MAX_FRWRD
  wire [10:0] frwrd_spd;	// the primary output...forward motor speed

  localparam FAST_SIM = 1;	// we always simulate with FAST_SIM on
  localparam MIN_FRWRD = 11'h0D0;		// minimum duty at which wheels will turn
  localparam MAX_FRWRD = 11'h2A0;		// max forward speed
  
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  navigate #(FAST_SIM) iDUT(.clk(clk),.rst_n(rst_n),.strt_hdng(strt_hdng),.strt_mv(strt_mv),
                .stp_lft(stp_lft),.stp_rght(stp_rght),.mv_cmplt(mv_cmplt),.hdng_rdy(hdng_rdy),
				.moving(moving),.en_fusion(en_fusion),.at_hdng(at_hdng),.lft_opn(lft_opn),
				.rght_opn(rght_opn),.frwrd_opn(frwrd_opn),.frwrd_spd(frwrd_spd));
  
  initial begin
    clk = 0;
	rst_n = 0;
	strt_hdng = 0;
	strt_mv = 0;
	stp_lft = 0;
	stp_rght = 0;
	hdng_rdy = 1;		// allow increments of frwrd_spd initially
	at_hdng = 0;
	lft_opn = 0;
	rght_opn = 0;
	frwrd_opn = 1;		// no wall in front of us
	
	@(negedge clk);		// after negedge clk
	rst_n = 1;			// deassert reset
	
	assert (!moving) $display("GOOD0: moving should not be asserted when IDLE");
	else $error("ERR0: why is moving asserted now?");	
	//////////////////////////////////////////////
	// First testcase will be a heading change //
	////////////////////////////////////////////
	strt_hdng = 1;
	@(negedge clk);
	strt_hdng = 0;
	assert (moving) $display("GOOD1: moving asserted during heading change");
	else $error("ERR1: expecting moving asserted during heading change");
	repeat(5) @(negedge clk);
	at_hdng = 1;				// end the heading
	#1;							// give DUT time to respond
	assert (mv_cmplt) $display("GOOD2: mv_cmplt should be asserted when at_hdng");
	else $error("ERR2: expecting mv_cmplt to be asserted at time %t",$time);
	@(negedge clk);
	at_hdng = 0;
	
	///////////////////////////////////////////////////////////////////////////////////
	// Second testcase will be move forward looking for lft_opn, but hit wall first //
	/////////////////////////////////////////////////////////////////////////////////
	strt_mv = 1;
	@(negedge clk);
	strt_mv = 0;
	assert (moving) $display("GOOD3: moving asserted during forward move");
	else $error("ERR3: expecting moving asserted during forward move");
	assert (frwrd_spd===MIN_FRWRD) $display("GOOD4: frwrd spd should have changed to MIN_FRWRD");
	else $error("ERR4: expecting frwrd_spd to have loaded MIN_FRWRD at time %t",$time);

	@(negedge clk);
	assert (frwrd_spd===MIN_FRWRD+11'h018) $display("GOOD5: frwrd spd should have incrementd to MIN_FRWRD+0x018");
	else $error("ERR5: expecting frwrd_spd to have incremented by 0x018 at time %t",$time);	
	
	/// Now lower hdng_rdy to ensure frwrd_spd does not increment ////
	hdng_rdy = 0;
	@(negedge clk);
	assert (frwrd_spd===MIN_FRWRD+11'h018) $display("GOOD6: frwrd spd should still be MIN_FRWRD+0x018");
	else $error("ERR6: expecting frwrd_spd to have maintained at MIN_FRWRD+0x018");	
	
	/// Now raise hdng_rdy back up
	hdng_rdy = 1;
	@(negedge clk);
	assert (moving) $display("GOOD7: moving should still be asserted");
	else $error("ERR7: why is moving not still asserted?");
	assert (frwrd_spd===MIN_FRWRD+11'h030) $display("GOOD8: frwrd spd should have incremented to MIN_FRWRD+0x030");
	else $error("ERR8: expecting frwrd_spd to have incremented to MIN_FRWRD+0x030 at time %t",$time);
	
	/// Now let it increment 6 more times (so 9 in total) ////
	repeat(6) @(negedge clk);
	
	/// Now let it know it has an obstacle in front ////
	frwrd_opn = 0;
	repeat(2) @(negedge clk);
	assert (frwrd_spd===MIN_FRWRD+11'h018) $display("GOOD9: frwrd spd should have decremented fast to MIN_FRWRD+0x018");
	else $error("ERR9: expecting a fast decrement of frwrd_spd at time %t",$time);	
	
	/// Now check that it properly decrements to zero ////
	repeat(2) @(negedge clk);
	assert (frwrd_spd===11'h000) $display("GOOD10: frwrd spd should be zero now");
	else $error("ERR10: expecting frwrd_spd to have decremented to zero by time %t",$time);	
	assert (mv_cmplt) $display("GOOD11: mv_cmplt should be asserted when speed hits zero");
	else $error("ERR11: expecting mv_cmplt to be asserted at time %t",$time);	
	
	///////////////////////////////////////////////////////////////////////////
	// Now you add more tests to test moves where opening (lft/rght) occurs //
	/////////////////////////////////////////////////////////////////////////
	
	////////////////////////////// lft occurs ///////////////////////////////
	@(negedge clk);
	strt_mv = 1;
	frwrd_opn = 1;
	@(negedge clk);
	strt_mv = 0;
	
	/// Now let it increment 4 more times (so 5 in total) ////
	repeat(4) @(negedge clk);
	
	/// Now let it know it has an left open  ////
	lft_opn = 1;
	stp_lft = 1;
	repeat(3) @(negedge clk); // start decrement at 2X speed
	assert (frwrd_spd===MIN_FRWRD+11'h018) $display("GOOD12: frwrd spd should have decremented fast to MIN_FRWRD-0x004");
	else $error("ERR12: expecting a decrement of frwrd_spd at time %t",$time);	
	
	/// Now check that it properly decrements to zero ////
	repeat(5) @(negedge clk);
	assert (frwrd_spd===11'h000) $display("GOOD13: frwrd spd should be zero now");
	else $error("ERR13: expecting frwrd_spd to have decremented to zero by time %t",$time);
	assert (mv_cmplt) $display("GOOD14: mv_cmplt should be asserted when speed hits zero");
	else $error("ERR14: expecting mv_cmplt to be asserted at time %t",$time);	
	lft_opn = 0;
	frwrd_opn = 0;
	
	
	////////////////////////////// rght occurs ///////////////////////////////
	
	@(negedge clk);
	strt_mv = 1;
	frwrd_opn = 1;
	@(negedge clk);
	strt_mv = 0;
	
	/// Now let it increment 7 more times (so 8 in total) ////
	repeat(2) @(negedge clk);
	
	//////////////////////////////////////////////////////////////////////////
	// Also...I never checked en_fusion in my testing above...do that too  //
	////////////////////////////////////////////////////////////////////////
	assert ((en_fusion && (frwrd_spd > MAX_FRWRD >> 1)) || (!en_fusion && !(frwrd_spd > MAX_FRWRD >> 1)))
		$display("GOOD15: en_fusion is only asserted when frwrd_spd > 1/2 MAX_FRWRD to allow the IR sensors to only affect navigation.");
	else $error("ERR15: expecting en_fusion should be asserted when frwrd_spd > 1/2 MAX_FRWRD at time %t",$time);	
	
	repeat(3) @(negedge clk);
	assert ((en_fusion && (frwrd_spd > MAX_FRWRD >> 1)) || (!en_fusion && !(frwrd_spd > MAX_FRWRD >> 1)))
		$display("GOOD16: en_fusion is only asserted when frwrd_spd > 1/2 MAX_FRWRD to allow the IR sensors to only affect navigation.");
	else $error("ERR16: expecting en_fusion should be asserted when frwrd_spd > 1/2 MAX_FRWRD at time %t",$time);	
	
	/// Now let it know it has an right open  ////
	repeat(2) @(negedge clk);
	rght_opn = 1;
	stp_rght = 1;
	repeat(5) @(negedge clk);	// start to decrement at 2X speed
	assert (frwrd_spd===MIN_FRWRD) $display("GOOD17: frwrd spd should have decremented fast to MIN_FRWRD-0x004");
	else $error("ERR17: expecting a decrement of frwrd_spd at time %t",$time);	
	
	/// Now check that it properly decrements to zero ////
	repeat(5) @(negedge clk);
	assert (frwrd_spd===11'h000) $display("GOOD18: frwrd spd should be zero now");
	else $error("ERR18: expecting frwrd_spd to have decremented to zero by time %t",$time);
	assert (mv_cmplt) $display("GOOD19: mv_cmplt should be asserted when speed hits zero");
	else $error("ERR19: expecting mv_cmplt to be asserted at time %t",$time);	
	rght_opn = 0;
	
	
	$display("All tests completed...did all pass?");
	$stop();
	
  end
  
  always
    #5 clk = ~clk;
	
endmodule