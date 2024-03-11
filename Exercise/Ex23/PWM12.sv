module PWM12(clk, rst_n, duty, PWM1, PWM2);
	
	input clk;
	input rst_n;
	input unsigned [11:0] duty;
	output reg PWM1, PWM2;	// PWM1 & PWM2 are complementary signals but also have a non-overlap time
	localparam NONOVERLAP = 12'h02C;
	
	reg [11:0] cnt;
	// wire a, b, c, d;	// create 4 combinational statement
	
	localparam NONVERLAP = 12'h02C;
	
	assign s1 = ( cnt>= (duty + NONVERLAP)) ? 1 : 0; // 
	assign r1 = ( &cnt) ? 1 : 0;
	assign s2 = (cnt >= NONVERLAP) ? 1 : 0;
	assign r2 = ( cnt>=duty) ? 1 : 0;
	
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) PWM2 <= 1'b0;
		else if (r1) PWM2 <= 1'b0;
		else if (s1) PWM2 <= 1'b1; //
		else PWM2 <= PWM2;
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) PWM1 <= 1'b0;
		else if (r2) PWM1 <= 1'b0;
		else if (s2) PWM1 <= 1'b1;
		else PWM1 <= PWM1;
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
