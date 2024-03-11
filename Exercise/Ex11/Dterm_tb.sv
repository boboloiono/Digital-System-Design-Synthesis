module Dterm_tb();
	reg clk, rst_n, hdng_vld;
	reg [9:0] err_sat;
	reg [12:0] D_term;
	localparam D_COEFF = 5'h0E;
	
	Dterm iDUT(.clk(clk), .rst_n(rst_n), .err_sat(err_sat), .hdng_vld(hdng_vld), .D_term(D_term));
	
	initial begin
		clk = 0;
		rst_n = 0;
		hdng_vld = 1;			// let it integrate and differentiate
		@(negedge clk);
		rst_n = 1;				// deassert reset
		err_sat = 10'h3FF;		// initial err_sat, starting with negedge.
		@(posedge clk);
		if (D_term!=8'hFF*D_COEFF) begin
		  $display("ERR: failed test1");
		  $stop();
		end else
			$display("GOOD: passed test1");
		
		// assign negedge err_sat
		err_sat = 10'h0FF;
		@(posedge clk);
		if(D_term!=8'h7F*D_COEFF) begin
			$display("ERR: failed test2");
			$stop();
		end else
			$display("GOOD: passed test2");
		
		// if desire heading is 0, Dterm don't change.
		hdng_vld = 0;
		@(posedge clk);
		if(D_term!=8'h7F*D_COEFF) begin
			$display("ERR: failed test3");
			$stop();
		end else
			$display("GOOD: passed test3");
		
		// if desire heading is 1, PID works again.
		// Let's assign new err_sat.
		hdng_vld = 1;
		err_sat = 10'h280;
		@(posedge clk);
		if(D_term!=8'h80*D_COEFF) begin
			$display("ERR: failed test4");
			$stop();
		end else
			$display("GOOD: passed test4");
		
		// assign negedge err_sat
		err_sat = 10'h200;
		@(negedge clk);
		if(D_term!=8'h7f*D_COEFF) begin
			$display("ERR: failed test5");
			$stop();
		end else
			$display("GOOD: passed test5");
		
		
		$display("Yahoo!! all tests passed");
		$stop();
	end
	
	always 
		#5 clk = ~clk;
endmodule