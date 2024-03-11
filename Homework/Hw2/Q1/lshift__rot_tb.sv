module lshift__rot_tb();
	reg [15:0] src;
	reg rot;
	reg [3:0] amt;
	reg [15:0] res;
	//logic test; 
	
	lshift_rot iDUT(.src(src), .rot(rot), .amt(amt), .res(res));
	
	initial begin
		src = 0;
		rot = 0;
		amt = 4'b0001;
		src = 16'b0000_0100_1110_1011;
		#10
		if(res==16'b0000_1001_1101_0110) begin
			$display("pass left shift #1");
		end
		else begin
			$display("fail left shift #1");
			$stop();
		end
		
		src = res;
		amt = 4'b0011;
		#10
		if(res==16'b0100_1110_1011_0000)
			$display("pass left shift #3");
		else begin
			$display("fail left shift #3");
			$stop();
		end
		
		src = res;
		amt = 4'b1001;
		#10
		if(res==16'b0110_0000_0000_0000)
			$display("pass left shift #9");
		else begin
			$display("fail left shift #9");
			$stop();
		end
		
		src = res;
		rot = 1;
		amt = 4'b0010;
		#10
		if(res==16'b1000_0000_0000_0001)
			$display("pass rotate #2");
		else begin
			$display("fail rotate #2");
			$stop();
		end
		
		src = res;
		amt = 4'b0110;
		#10
		if(res==16'b0000_0000_0110_0000)
			$display("pass rotate #6");
		else begin
			$display("fail rotate #6");
			$stop();
		end
		
		src = res;
		amt = 4'b1111;
		#10
		if(res==16'b0000_0000_0011_0000)
			$display("pass rotate #15");
		else begin
			$display("fail rotate #15");
			$stop();
		end
		
		$finish();
	end
	
endmodule