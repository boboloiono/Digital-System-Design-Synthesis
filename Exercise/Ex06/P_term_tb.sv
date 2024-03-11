module P_term_tb();

  reg clk;  
  logic signed [11:0] error;
  logic [13:0] P_term;
  localparam P_coeff = 4'h3;
  
  /////////////////////////////////
  // Instantiate PID controller //
  ///////////////////////////////
  P_term iDUT(.clk(clk),.error(error), .P_term(P_term));

  always begin
    clk = 0;
	error = 12'h000;
	repeat(1) @(posedge clk);
	
	//test1
	error = 12'h4CC;
	repeat(1) @(posedge clk);
	if(P_term == 10'h1FF*P_coeff) $display("You pass");
	else begin
		$display("You failed");
		$stop();
	end
	
	//test2
	error = 12'hAFF;
	repeat(1) @(posedge clk);
	if(P_term == 10'h200*P_coeff)
		$display("You pass");
	else begin
		$display("You failed");
		$stop();
	end
	
	// test3
	error = 12'h0FF;
	repeat(1) @(posedge clk);
	if(P_term == 12'h0FF*P_coeff)
		$display("You pass");
	else begin
		$display("You failed");
		$stop();
	end
	//// just wait a bunch of time for response of PID loop ////
	//repeat(300) @(posedge clk) error = error + 12h'0100;
	$finish();
  end
  
  always
    #10 clk = ~clk;
  
endmodule