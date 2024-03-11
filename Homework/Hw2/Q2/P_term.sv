module P_term(clk, error, P_term);

	input clk;					// system clock
	//input rst_n;					// active low asynch reset
	input signed [11:0] error;	// error from IR array
	output signed [13:0] P_term;
	
	wire [9:0] err_sat;
	localparam P_coeff = 4'h3;

	assign err_sat = (error[11] && ~&error[11:9]) ? 10'h200 : 
					 (!error[11] && |error[11:9]) ? 10'h1FF :
					 error[9:0];
					 
	assign P_term = $signed(P_coeff)*err_sat;

endmodule