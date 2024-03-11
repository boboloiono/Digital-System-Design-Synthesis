module plant(clk,rst_n,drv_duty,heading_deviation,error);

  //////////////////////////////////////////////
  // This plant model is just a stupid average
  // of the last 128 samples of the control
  // input.  It is just a plant with some
  // lag so it would show some overshoot
  ///////////////////////////////////////
  input clk;
  input rst_n;
  input [11:0] drv_duty;
  input signed [11:0] heading_deviation;	// used to preterb error like a step in desired heading
  output signed [12:0] error;
  
  
  reg [11:0]dly_mem[0:511];		// used for circular queue to delay response
  
  reg [20:0] accum;
  reg [8:0] new_ptr,old_ptr;
  reg full;						// set once queue is full
  
  wire [11:0] dly_mem_old;		// holds oldest element of delay mem to be subtracted from accum
  
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  new_ptr <= 8'h00;
	else
	  new_ptr <= new_ptr + 1;
	  
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  old_ptr <= 9'h000;
	else if (full)
	  old_ptr <= old_ptr + 1;

 always_ff @(posedge clk, negedge rst_n)
   if (!rst_n)
     full <= 1'b0;
   else if (&new_ptr)
     full <= 1'b1;   
	 
  assign dly_mem_old = dly_mem[old_ptr];
  
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  accum <= 21'h00000;
	else
	  accum <= (full) ? accum - {{9{drv_duty[11]}},drv_duty} + {{9{heading_deviation[11]}},heading_deviation} - 
	                    {{9{dly_mem_old[11]}},dly_mem_old} : 
						accum - {{9{drv_duty[11]}},drv_duty} + {{9{heading_deviation[11]}},heading_deviation};
	 
  always_ff @(posedge clk)
    dly_mem[new_ptr] <= heading_deviation - drv_duty;
	
  assign error = {accum[20],accum[20:9]};	// running average of last 256
  
endmodule
	  