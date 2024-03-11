module PID(clk, rst_n, moving, dsrd_hdng, actl_hdng, hdng_vld, at_hdng, frwrd_spd, lft_spd, rght_spd);
			 
	input clk, rst_n, moving, hdng_vld;
	input signed [11:0] dsrd_hdng, actl_hdng;
	input [10:0] frwrd_spd;
	output logic at_hdng;
	output signed [11:0] lft_spd, rght_spd;
	
	///////////////////////////////////
	/////////////  P_term /////////////
	///////////////////////////////////
	logic signed [11:0] error;
	logic signed [9:0] err_sat;
	
	assign error = actl_hdng - dsrd_hdng;	// 12 bits
	
	logic signed [13:0] P_term;
	
	//saturation
	localparam greatest_positive = 10'h1FF; //0111111111
	localparam greatest_negative = 10'h200; // 10 bit greatest negative
	
	localparam P_COEFF = 4'h3;
	
	assign err_sat = (!error[11] & |error[10:9])? greatest_positive:
					(error[11] & ~&error[10:9])? greatest_negative:
					error[9:0];
					
	assign P_term = {{4{err_sat[9]}},err_sat}*{{10{P_COEFF[3]}},P_COEFF};
	
	///////////////////////////////////
	/////////////  I_term /////////////
	///////////////////////////////////
	
	logic signed [15:0] accum, err_ext, moving_in;
	logic signed [15:0] integrator, nxt_integrator;
	logic signed [11:0] I_term;
	logic ov_out;

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
	
	assign I_term = integrator[15:4]; 
	
	
	///////////////////////////////////
	/////////////  D_term /////////////
	///////////////////////////////////
	
	logic signed [12:0] D_term;
	logic signed [10:0] D_diff;
	logic signed [7:0] D_diff_sat;
	logic signed [9:0] ff_out1, prev_err;
	
	localparam greatest_positive_8 = 8'h7F; // 01111111
	localparam greatest_negative_8 = 8'h80; // 10000000
	
	localparam signed D_COEFF = 5'h0E;	// should be signed
	
	logic signed [11:0] div8;
	
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n)
			ff_out1 <= 10'h000;
		else if (hdng_vld)
			ff_out1 <= err_sat;
	end
	
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n)
			prev_err <= 10'h000;
		else if (hdng_vld)
			prev_err <= ff_out1;
	end
	
	assign D_diff = err_sat - prev_err;		// 11 bits (10 bits-10 bits may overflow, so SE to 11 bits)
	
	assign D_diff_sat = (!D_diff[10] && |D_diff[9:7])? greatest_positive_8:
						(D_diff[10] & ~&D_diff[9:7])? greatest_negative_8:
						D_diff[7:0];
	
	assign D_term = D_diff_sat * D_COEFF;		// 13 bits
	
	///////////////////////////////////
	/////////  Fiinal Block  //////////
	///////////////////////////////////
	
	// Assembling the PID
	logic signed [14:0] sum_of_all;

	assign sum_of_all = {{P_term[13]},P_term}+{{3{I_term[11]}},I_term}+{{2{D_term[12]}},D_term};
	assign div8 = sum_of_all[14:3];								// 15 -> 12 bits
	assign lft_spd = moving ? (frwrd_spd + div8) : 12'h000;
	assign rght_spd = moving ? (frwrd_spd - div8) : 12'h000;
	
	// Calculate the absolute value of err_sat
	logic signed [9:0] abs_err_sat; // N is the width of err_sat

	assign abs_err_sat = (err_sat < 0) ? -err_sat : err_sat;

	// Compare the absolute value to 10'd30 and assign hdng
	assign at_hdng = (abs_err_sat < 10'd30) ? 1'b1 : 1'b0;

endmodule