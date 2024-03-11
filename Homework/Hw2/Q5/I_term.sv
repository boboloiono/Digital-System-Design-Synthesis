module I_term(clk, rst_n, hdng_vld, moving, err_sat, I_term);
	input clk, rst_n;
	input hdng_vld;
	input moving;
	input [9:0] err_sat;
	output [11:0] I_term;
	
	wire [15:0] accum, err_ext, moving_in;
	wire ov_out;
	reg [15:0] integrator, nxt_integrator;
	
	// signed extened 16-bits
	assign err_ext = {{6{err_sat[9]}}, err_sat};
	// add 16-bits output and extended error
	assign accum = integrator + err_ext;
	
	// design overflow
	assign ov_out = (!err_ext[15] & !integrator[15] & accum[15]) || (err_ext[15] & integrator[15] & !accum[15]);
	
	// select integrator after the result of anding ov_out and hdng_vld
	assign moving_in = (!ov_out & hdng_vld) ? accum : integrator;
	
	// select next integrator
	assign nxt_integrator = moving ? moving_in : 16'h0000;
	
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			integrator <= 16'h0000;
		else
			integrator <= nxt_integrator;
	
	assign I_term = integrator[15:4];
		
endmodule