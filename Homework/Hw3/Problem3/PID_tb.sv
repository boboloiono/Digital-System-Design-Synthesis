module PID_tb();

  reg clk,rst_n;	// clock and active low asynch reset
  reg moving;		// lft/rght spd are zero when !moving
  reg [11:0] dsrd_hdng;		// 0x000 = North 0x3FF = West, 0x7FF = South, 0xBFF = East
  reg [11:0] actl_hdng;		// actual heading from inertial sensor
  reg hdng_vld;				// indicates a new actl_hdng is ready
  reg [10:0] frwrd_spd;		// forward speed
  
  wire at_hdng;				// monitors at_hdng output
  wire signed [11:0] lft_spd;
  wire signed [11:0] rght_spd;
  
  
  /////////////////////////////////
  // Instantiate PID controller //
  ///////////////////////////////			 
  PID iCNTRL(.clk(clk),.rst_n(rst_n),.moving(moving),.dsrd_hdng(dsrd_hdng),.actl_hdng(actl_hdng),
             .hdng_vld(hdng_vld),.at_hdng(at_hdng),.frwrd_spd(frwrd_spd),.lft_spd(lft_spd),
			 .rght_spd(rght_spd));
			 
  initial begin
    clk = 0;
	rst_n = 0;
	moving = 0;				// expect zero output at first
	dsrd_hdng = 12'h000;	// after setting moving to 1
	actl_hdng = 12'h000;	// expect outputs to be same as frwrd_spd (200)
	hdng_vld = 1;			// let it integrate and differentiate
	frwrd_spd = 11'h200;
	@(negedge clk);
	rst_n = 1;				// deassert reset
	
	@(negedge clk);
	if ((lft_spd!==12'h000) || (rght_spd!==12'h000)) begin
	  $display("ERR: with moving=0 expect lft/rght spd to be zero");
	  $stop();
	end else
	  $display("GOOD: passed test1");
	  
	moving = 1;				// let PID influece motor speeds
	
	repeat(2) @(negedge clk);
	if ((lft_spd!==frwrd_spd) || (rght_spd!==frwrd_spd)) begin
	  $display("ERR: with actl_hdng=dsrd_hdng expect no PID influence");
	  $stop();
	end else
	  $display("GOOD: passed test2");
	  
	if (at_hdng!==1'b1) begin
	  $display("ERR: with actl_hdng=dsrd_hdng expect at_hdng to be 1");
	  $stop();
	end else
	  $display("GOOD: passed test2.2");	
	  
	  
	dsrd_hdng = 12'h3FF;	// turn to west
	
	@(negedge clk);
	
	if (((lft_spd>12'h05E) || (lft_spd<12'h05A)) ||
  	    ((rght_spd>12'h3A6) || (rght_spd<12'h3A2))) begin
	  $display("ERR: Expect lft_spd in 0x05C range and rght_spd in 0x3A4 range");
	  $stop();
	end else
	  $display("GOOD: passed test3");
	  
	 
	@(negedge clk);			// give a clock for Dterm to dissipate and Iterm to increase
	
	if (((lft_spd>12'h13A) || (lft_spd<12'h136)) ||
  	    ((rght_spd>12'h2CA) || (rght_spd<12'h2C6))) begin
	  $display("ERR: Expect D_term to zero and Iterm to become more negative");
	  $stop();
	end else
	  $display("GOOD: passed test4");
	  
	dsrd_hdng = 12'hBFF;	// turn to east (change sign of terms) to positive
	
	@(negedge clk);			// give a clock for Dterm to increase

	if (((lft_spd>12'h39B) || (lft_spd<12'h396)) ||
  	    ((rght_spd>12'h06A) || (rght_spd<12'h064))) begin
	  $display("ERR: Expect D_term sat pos (7F) and P_term to be positive and Iterm small negative");
	  $stop();
	end else
	  $display("GOOD: passed test5");	
	
	hdng_vld = 1'b0;		// now freeze PID
	
	repeat(4) @(negedge clk);
	if (((lft_spd>12'h39B) || (lft_spd<12'h396)) ||
  	    ((rght_spd>12'h06A) || (rght_spd<12'h064))) begin
	  $display("ERR: Once hdng_vld lowered expect results to freeze");
	  $stop();
	end else
	  $display("GOOD: passed test6");	
	  
	  
	$display("Yahoo!! all tests passed");
	$display("This was not a comprehensive test of PID, more testing to follow in full chip context");
	$stop();
	
  end
  
  always
    #5 clk = ~clk;
			 
endmodule
