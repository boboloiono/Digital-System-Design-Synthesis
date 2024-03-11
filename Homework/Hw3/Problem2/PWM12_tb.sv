module PWM12_tb();
	reg clk;
	reg rst_n;
	reg unsigned [11:0] duty;
	reg PWM1, PWM2;
	
	PWM12 iDUT(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM1(PWM1), .PWM2(PWM2));
	
	initial begin
		clk = 0;
		rst_n = 1;
		duty = 12'b0;
		@(negedge clk);
		rst_n = 0;
		@(posedge clk);
		rst_n = 1;
		
		///////// low duty cycle //////////
		duty = 12'h3FF; // 25%: 1023
		repeat(1025) @(posedge clk);

		if(PWM1==0 && PWM2==0)
			$display("pass #1");
		else begin
			$display("fail #1");
			$stop();
		end
		repeat(4096-1025) @(posedge clk);
		
		///////// mid duty cycle //////////
		duty = 12'h7FF; // 50%: 2047
		repeat(2049) @(posedge clk);

		if(PWM1==0 && PWM2==0)
			$display("pass #2");
		else begin
			$display("fail #2");
			$stop();
		end
		repeat(4096-2049) @(posedge clk);
		
		///////// high duty cycle //////////
		duty = 12'hF12; // 90%: 3858
		repeat(3860) @(posedge clk);

		if(PWM1==0 && PWM2==0)
			$display("pass #3");
		else begin
			$display("fail #3");
			$stop();
		end
		repeat(4096-3860) @(posedge clk);
		
		$finish();
	end
	
	always
		#5 clk = ~clk;
endmodule