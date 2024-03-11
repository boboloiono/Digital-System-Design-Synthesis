module MtrDrv_tb();
	
	logic clk, rst_n;
	logic [11:0] lft_spd, rght_spd, vbatt;
	logic lftPWM1, lftPWM2;
	logic rghtPWM1, rghtPWM2;
	
	localparam NONOVERLAP = 12'h02C;
	localparam DUTY_100 = 4096, DUTY_50 = 2049, DUTY_75 = 3073, DUTY_76 = 3122, DUTY_28 = 1168;
	
	MtrDrv iDUT(.clk(clk), .rst_n(rst_n), .lft_spd(lft_spd), .vbatt(vbatt), .rght_spd(rght_spd), 
				.lftPWM1(lftPWM1), .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2));
	
	initial begin
		clk = 0;
		rst_n = 0;
		@(negedge clk) rst_n = 1;
		
		///////// 50%: duty cycle //////////
		lft_spd = 12'h000;
		vbatt = 12'h000;
		
		///////// 75%: duty cycle //////////
		repeat(10000) @(posedge clk);
		lft_spd = 12'h3FF;
		vbatt[11:4] = 8'hDB;

		///////// 76.5%: duty cycle //////////
		repeat(10000) @(posedge clk);
		lft_spd = 12'h3FF;
		vbatt[11:4] = 8'hD0;

		///////// 28.5%: duty cycle //////////
		repeat(10000) @(posedge clk);
		lft_spd = 12'hC00;
		vbatt[11:4] = 8'hFF;

		repeat(10000) @(posedge clk);
		$stop();
	end
	
	always
		#5 clk = ~clk;
		
endmodule