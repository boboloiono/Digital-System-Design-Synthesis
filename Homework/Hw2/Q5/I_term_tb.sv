module I_term_tb();
	
	reg clk, rst_n, hdng_vld, moving;
	reg [9:0] err_sat;
	reg [11:0] I_term;
	
	reg [15:0] accum, err_ext, moving_in;
	reg ov_out;
	
	I_term iDUT(.clk(clk), .rst_n(rst_n), .hdng_vld(hdng_vld), .moving(moving), .err_sat(err_sat), .I_term(I_term));
	
	initial begin
		clk = 0;
		rst_n = 0;
		moving = 1;
		hdng_vld = 1;
		err_sat = 10'h1FF;
		@(negedge clk);
		rst_n = 1; // deassert reset
		
		//////// test moving //////////
		@(posedge clk);
		moving = 0;
		repeat(2) @(posedge clk);
		if(I_term == 12'h000)
			$display("Pass #1: moving");
		else begin
			$display("Fail #1: moving");
			$stop();
		end
		
		//////// postive overflow //////////
		moving = 1;
		repeat(65) @(posedge clk);
		err_sat = 10'h1FF;
		if(I_term == 12'h7FC)
			$display("Pass #2: postive overflow");
		else begin
			$display("Fail #2: postive overflow");
			$stop();
		end
		
		/////////////// reset ///////////////
		rst_n = 0;
		err_sat = 10'h200;
		@(negedge clk);
		rst_n = 1;
		
		////////// test heading ////////////
		@(posedge clk);
		hdng_vld = 0;
		repeat(2) @(posedge clk);
		if(I_term == 12'hfe0)
			$display("Pass #3: heading valid");
		else begin
			$display("Fail #3: heading valid");
			$stop();
		end
		
		//////// negtive overflow //////////
		hdng_vld = 1;
		repeat(65) @(posedge clk);
		err_sat = 10'h200;
		if(I_term == 12'h800)
			$display("Pass #4: negtive overflow");
		else begin
			$display("Fail #4: negtive overflow");
			$stop();
		end

		$finish();
	end
	
	always
		#5 clk = ~clk;
endmodule

/*

0000 0001 1111 1111 -> add 1FF
0000 0001 1111 1111 -> add 1FF -> not overflow => 3FE
-------------------
0000 0011 1111 1110 -> result: 3FE -> not overflow
0000 0001 1111 1111 -> add 1FF
-------------------
0000 0101 1111 1101 -> result: 5FD
0000 0001 1111 1111 -> add 1FF
-------------------
0000 0111 1111 1100 -> result: 7FC
0000 0001 1111 1111 -> add: 1FF
-------------------
0000 1001 1111 1011 -> result: 9FB
0000 0001 1111 1111 -> add: 1FF
-------------------
0000 1011 1111 1010 -> result: BFA
0000 0001 1111 1111 -> add: 1FF
-------------------
0000 1101 1111 1001 -> result: DF9
0000 0001 1111 1111 -> add: 1FF
-------------------
0000 1111 1111 1000 -> result: FF8
0000 0001 1111 1111 -> add: 1FF
-------------------
0001 0001 1111 0111 -> result: 11F7
0000 0001 1111 1111 -> add: 1FF
-------------------
0001 0010 1111 0110 -> result: 12F6
0000 0001 1111 1111 -> add: 1FFF
-------------------
0001 0100 1111 0101 -> result: 14F5
0000 0001 1111 1111 -> add: 1FFF
-------------------


1111 1110 0000 0000 -> A00 -> not overflow => result is 16'hFFFF
1111 1110 0000 0000 -> A00 -> overflow => result is 16'hFFFF

+  05 1111 1111

[ positive overflow ]
0111 1111 1100 0000 -> integrator: 16'd7FC
0000 0001 1111 1111 -> err_ext
-------------------
1000 0001 1011 1111 -> become negtive :(

*/