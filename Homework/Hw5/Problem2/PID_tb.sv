`timescale 1ns/1ps
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
			

	////////////////////////////////////////////
	////// Loading Memory Data From Files //////
	////////////////////////////////////////////
	reg [37:0] stim[0:1999]; // 38 bit wide 2000 entry stimulation
	reg [24:0] resp[0:1999]; // 25 bit wide 2000 entry response
	reg [10:0] addr;

	initial begin
		$readmemh ("PID_stim.hex", stim);
		$readmemh ("PID_resp.hex", resp);
	end
	
  initial begin
  
	clk = 0;
	addr = 0;
	
	while(addr < 2000) begin
		rst_n = stim[addr][37];
		moving = stim[addr][36];
		hdng_vld = stim[addr][35];
		dsrd_hdng = stim[addr][34:23];
		actl_hdng = stim[addr][22:11];
		frwrd_spd = stim[addr][10:0];
		@(posedge clk);
		#1
		if (at_hdng === resp[addr][24]);
		else begin $error("Fail at_hdng"); $stop(); end
		if (lft_spd === resp[addr][23:12]);
		else begin $error("Fail lft_spd"); $stop(); end
		if (rght_spd === resp[addr][11:0]);
		else begin $error("Fail rght_spd"); $stop(); end
		
		addr = addr + 1;
	end
	
	$display("Congrats PEI-YU LIN!! All 2000 vectors match.");
	$finish;
	
  end
  
  always
    #5 clk = ~clk;
			 
endmodule
