module synch_detect_tb();	

reg clk;				// system clock
reg asynch_sig_in;		// models the asynchronous signal coming in
reg rst_n;				// Asynch active low system reset 

wire fall_edge;			// signal output from DUT

/////// Instantiate DUT /////////
synch_detect iDUT(.asynch_sig_in(asynch_sig_in), .clk(clk), .rst_n(rst_n), .fall_edge(fall_edge));

always begin
  clk = 0;
  asynch_sig_in = 0;
  rst_n = 1;
  repeat(2) @(negedge clk);
  rst_n = 0;
  repeat(1) @(negedge clk);		// wait till 3rd falling clock edge
  asynch_sig_in = 1;
  repeat(2) @(posedge clk);
  if (fall_edge) begin
    $display("ERROR: triggered on rising edge instead of falling\n");
	$stop();
  end
  @(posedge clk);				// wait a clock
  @(posedge clk);
  asynch_sig_in = 0;
  @(posedge clk);
  if (fall_edge) begin
    $display("ERROR: triggering too early...did you double flop?\n");
	$stop();
  end
  @(posedge clk);
  #1;							// wait one time unit
  if (!fall_edge) begin
    $display("You should have detected falling edge here\n");
	$stop();
  end
  @(posedge clk);
  #1;							// wait one time unit
  if (fall_edge) begin
    $display("ERROR: Hmmm...should have dropped fall_edge by now\n");
    $stop();
  end
  $display("YAHOO!! test passed!\n");
  $stop();  
end

always
  #10 clk <= ~clk;		// toggle clock every 10 time units
  
endmodule