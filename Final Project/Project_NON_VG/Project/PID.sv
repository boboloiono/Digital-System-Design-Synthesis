module PID(
	input clk,
	input rst_n,
	input moving,
	input signed [11:0]dsrd_hdng,
	input signed [11:0]actl_hdng,
	input hdng_vld,
	input [10:0]frwrd_spd,
	output logic at_hdng,
	output logic signed [11:0]lft_spd,
	output logic signed [11:0] rght_spd

);

//P-term
logic signed [11:0]error;
logic signed [11:0]error_ff;
logic signed [9:0] err_sat;

assign error = actl_hdng - dsrd_hdng;

always_ff @(posedge clk, negedge rst_n)
	if(!rst_n) 
		error_ff <= 12'h000;
	else 
		error_ff <= error;


	logic signed [13:0]P_term;

	//saturation
	localparam greatest_positive = 10'h1FF; //0111111111
	localparam greatest_negative = 10'h200; // 10 bit greatest negative
	
	localparam signed P_COEFF = 4'h3;

	assign err_sat = (!error_ff[11] && |error_ff[10:9])? greatest_positive:
			 (error_ff[11] && !(&error_ff[10:9]))? greatest_negative:
			  error_ff[9:0];

	
	assign P_term = {{4{err_sat[9]}},err_sat}*{{10{P_COEFF[3]}},P_COEFF};

//I_term

	logic [11:0]I_term;

	logic signed [15:0] nxt_integrator;
	logic signed [15:0] addition;
	logic signed [15:0] sign_ext_err;
	logic signed [15:0] integrator;
	logic signed [15:0] intermediate;
	logic ov;
	
	//Implementation
	assign sign_ext_err = {{6{err_sat[9]}},err_sat}; // sign extending to 16 bits
	
	
	assign addition = sign_ext_err + integrator;
			
	// checking for overflow
	assign ov = (err_sat[9] !== integrator[15]) ? 1'b0:
				(integrator[15] === addition[15])? 1'b0:
				1'b1;
		
	assign intermediate = (!ov && hdng_vld)? addition:
							integrator;
	assign nxt_integrator = (moving)? intermediate: 16'h0000;
	
	// flop implementation
	always_ff @(posedge clk, negedge rst_n)
	 if (!rst_n)
	   integrator <= 16'h0000;
	 else
	   integrator <= nxt_integrator;
	
	assign I_term = integrator[15:4];
	
//D_term

logic signed [12:0]D_term;


localparam signed D_COEFF = 5'h0E;
logic signed [9:0]flop1out;
logic signed [9:0] prev_D_diff;
logic signed [10:0]D_diff, D_diff_ff;
logic signed [7:0] saturated;

localparam greatest_positive_8 = 8'h7F; //01111111
localparam greatest_negative_8 = 8'h80; // 10000000

// Logic for the previous err
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		flop1out <= 10'h000;
	else if(hdng_vld)
		flop1out <= err_sat;
end

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		prev_D_diff <= 10'h000;
	else if(hdng_vld)
		prev_D_diff <= flop1out;
end

assign D_diff = err_sat - prev_D_diff;

	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			D_diff_ff <= 0;
		else
			D_diff_ff <= D_diff;


//Saturation logic
assign saturated = (!D_diff_ff[10] && |D_diff_ff[9:7])? greatest_positive_8:
			 (D_diff_ff[10] && !(&D_diff_ff[9:7]))? greatest_negative_8:
			  D_diff_ff[7:0];


assign D_term = saturated * D_COEFF;

// Assembling the PID
logic signed [14:0] sum_of_all;
logic signed [14:0] sum_of_all_ff;

assign sum_of_all = {{P_term[13]},P_term}+{{3{I_term[11]}},I_term}+{{2{D_term[12]}},D_term};

logic signed [11:0]div8;
logic frwrd_spd_ext;

assign div8 = sum_of_all[14:3];

assign lft_spd = (moving)? (div8 + frwrd_spd):
					12'h000;
assign rght_spd = (moving)? (frwrd_spd - div8):
					12'h000;
					
// Calculate the absolute value of err_sat
logic signed [9:0] abs_err_sat; // N is the width of err_sat

always @* begin
  abs_err_sat = (err_sat < 0) ? -err_sat : err_sat;
end

// Compare the absolute value to 10'd30 and assign hdng
always @* begin
   at_hdng = (abs_err_sat < 10'd30) ? 1'b1 : 1'b0;
end


endmodule