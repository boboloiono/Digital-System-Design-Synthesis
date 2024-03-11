module PWM12(clk, rst_n, duty, PWM1, PWM2);
	
	input clk;
	input rst_n;
	input unsigned [11:0] duty;
	output reg PWM1, PWM2;	// PWM1 & PWM2 are complementary signals but also have a non-overlap time
	localparam NONOVERLAP = 12'h02C;
	
	reg [11:0] cnt;
	wire a, b, c, d;	// create 4 combinational statement
	
	// don't put in if/else statement because of too much workload
	assign a = ((duty+NONOVERLAP)==cnt) || ((duty+NONOVERLAP)<cnt);
	assign b = &cnt;
	assign c = (NONOVERLAP==cnt) || (NONOVERLAP<cnt);
	assign d = (duty==cnt) || (duty<cnt);
	
	// use S/R flip flop for PWM to ensure no glitching
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			PWM1 <= 0; PWM2 <= 0;
		end
		else begin
			PWM2 <= b ? 1'b0 : a ?  1'b1 : PWM2;
			PWM1 <= d ? 1'b0 : c ?  1'b1 : PWM1;
		end
	end
	
	// flip flop for counter
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) cnt <= 12'b0;
		else cnt <= cnt + 1;
	end
	
	///////////////////////////////////////////////////////////////////////
	//  Duty cycles less than NONOVERLAP will result in zero duty cycle. //
	///////////////////////////////////////////////////////////////////////
	
endmodule