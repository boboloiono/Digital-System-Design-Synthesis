module PID_cntrl_tb();

  reg clk, rst_n;
  reg [11:0] heading_deviation;	// represents a deviaiton in desired heading (step function to PID)
  
  wire signed [12:0] error;				// error from plant
  wire [11:0] drv_duty;					// from PID controller to plant
  
  /////////////////////////////////
  // Instantiate PID controller //
  ///////////////////////////////
  PID iCNTRL(.clk(clk),.rst_n(rst_n),.error(error),
             .drv_duty(drv_duty));

  /////////////////////////////////
  // Instantiate model of plant //
  ///////////////////////////////			 
  plant iPLNT(.clk(clk),.rst_n(rst_n),.drv_duty(drv_duty),
              .error(error),.heading_deviation(heading_deviation));
			  
  initial begin
    clk = 0;
	rst_n = 0;
	heading_deviation = 12'h000;
	//// wait 1.5 clocks for reset ////
	@(posedge clk);
	@(negedge clk) rst_n = 1;
	
	//// step function increase in target (desired) current ////
	repeat(100) @(negedge clk);
	heading_deviation = 12'h200;
	
	//// just wait a bunch of time for response of PID loop ////
	repeat(5000) @(posedge clk);
	
	$stop();
  end
  
  always
    #5 clk = ~clk;
  
endmodule