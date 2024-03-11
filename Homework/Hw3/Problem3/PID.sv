module PID(clk, rst_n, moving, dsrd_hdng, actl_hdng, hdng_vld, at_hdng, frwrd_spd, lft_spd, rght_spd);
			 
	input clk, rst_n, moving, hdng_vld;
	input [11:0] dsrd_hdng, actl_hdng;
	input [10:0] frwrd_spd;
	output at_hdng;
	output [11:0] lft_spd, rght_spd;
	
	wire signed [11:0] error;
	wire signed [9:0] err_sat;
	wire signed [14:0] P_term_ext, I_term_ext, D_term_ext;

	// P-term 
	wire signed [13:0] P_term;
	
	// I-term
	wire signed [15:0] accum, err_ext, moving_in;
	wire signed ov_out;
	reg signed [15:0] integrator, nxt_integrator;
	wire signed [11:0] I_term;
	
	// D-term
	reg signed [9:0] ff_out1, prev_err;
	wire signed [12:0] D_term;
	wire signed [10:0] D_diff;
	wire signed [7:0] D_diff_sat;
	
	wire signed [11:0] frwrd_spd_ext, div8;
	
	///////////////////////////////////
	//////// P, D Coefficient /////////
	///////////////////////////////////
	localparam P_COEFF = 4'h3;
	localparam D_COEFF = 5'h0E;
	
	//////////////////////////////////
	///////// saturate error /////////
	//////////////////////////////////
	assign error = actl_hdng - dsrd_hdng;	// 12 bits
	assign err_sat = (error[11] && ~&error[10:9]) ? 10'h200 : 
					 (!error[11] && |error[10:9]) ? 10'h1FF :
					 error[9:0];			// sat to 10 bits
	
	// absolute err_sat and assert at_hdng if error is smaller than 10'd30
	assign at_hdng = ($signed(err_sat)<0 ? -$signed(err_sat) : err_sat) < 10'd30; // at_hdng < -255
	
	///////////////////////////////////
	/////////////  P_term /////////////
	///////////////////////////////////
	assign P_term = {{4{err_sat[9]}},err_sat}*{{10{P_COEFF[3]}},P_COEFF};
	
	///////////////////////////////////
	/////////////  I_term /////////////
	///////////////////////////////////
	assign err_ext = {{6{err_sat[9]}}, err_sat};	// 15 bits
	assign accum = integrator + err_ext;
	assign ov_out = (!err_ext[15] & !integrator[15] & accum[15]) || (err_ext[15] & integrator[15] & !accum[15]);
	assign moving_in = (!ov_out & hdng_vld) ? accum : integrator;
	assign nxt_integrator = moving ? moving_in : 16'h0000;
	always_ff @(posedge clk or negedge rst_n)
		if(!rst_n)
			integrator <= 16'h0000;
		else
			integrator <= nxt_integrator;
	assign I_term = integrator[15:4]; 				// 12 bits
	assign I_term_ext = {{3{I_term[11]}}, I_term}; 	// SE to 15 bits
	
	///////////////////////////////////
	/////////////  D_term /////////////
	///////////////////////////////////
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
	assign D_term_ext = {{2{D_term[11]}}, D_term};		// SE to 15 bits
	
	///////////////////////////////////
	/////////  Fiinal Block  //////////
	///////////////////////////////////
	assign div8 = (P_term_ext + I_term_ext + D_term_ext) >> 3;	// 15 -> 12 bits
	assign frwrd_spd_ext = {frwrd_spd[10], frwrd_spd};			// SE to 12 bits
	assign lft_spd = moving ? (frwrd_spd_ext+div8) : 12'h000;
	assign rght_spd = moving ? (frwrd_spd_ext-div8) : 12'h000;
	
endmodule