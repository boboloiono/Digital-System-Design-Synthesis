module D_term (clk, rst_n, err_sat, hdng_vld, D_term);

	input clk, rst_n, hdng_vld;
	input [9:0] err_sat;
	output [12:0] D_term;
	
	localparam D_COEFF = 5'h0E;
	
	reg signed [9:0] ff_out1, prev_err;
	wire signed [10:0] D_diff;
	wire signed [7:0] D_diff_sat;
	
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) ff_out1 <= 0;
		else ff_out1 <= (hdng_vld) ? err_sat : ff_out1;
	end
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) prev_err <= 0;
		else prev_err <= (hdng_vld) ? ff_out1 : prev_err;
	end
	
	assign D_diff = err_sat - prev_err;					// 11 bits (10 bits-10 bits may overflow, so SE to 11 bits)
	assign D_diff_sat = (D_diff[10] & ~&D_diff[9:7]) ? 8'b10000000 : 
						(!D_diff[10] & |D_diff[9:7]) ? 8'b01111111 :
						D_diff[7:0];
	assign D_term = $signed(D_COEFF) * D_diff_sat;		// 13 bits
	
endmodule