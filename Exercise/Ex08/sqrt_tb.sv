module sqrt_tb();

	reg clk, rst_n;
	reg go;
	reg signed [15:0] op;
	reg [7:0] sqrt;
	reg done, err;

	sqrt iDUT(.clk(clk),.rst_n(rst_n),.go(go),.op(op),.sqrt(sqrt),.done(done),.err(err));
	
	initial begin
		clk = 0;
		rst_n = 0;
		@(posedge clk);
		@(negedge clk) rst_n = 1;
		
		@(posedge clk) go = 1;
		@(posedge clk) op = 16'h0040; // op:+64 -> sqrt: +8
		// repeat(9) @(posedge clk);
		@(posedge done);
		if (sqrt === 8'h08 && err === 0) 
			$display("Pass #1");
		else begin
			go = 0;
			$display("Fail #1");
			$stop();
		end
		
		op = 16'h1000; // op: +4096 -> sqrt: +64
		// repeat(9) @(posedge clk);
		@(posedge done);
		if (sqrt === 8'h40 && err === 0) 
			$display("Pass #2");
		else begin
			go = 0;
			$display("Fail #2");
			$stop();
		end
		
		op = 16'hFFC0; //-64
		// repeat(11) @(posedge clk);
		@(posedge done);
		if (err === 1) begin
			$display("Pass #3");
			$finish();
		end
		else begin
			go = 0;
			$display("Fail #3");
			$stop();
		end
	end
	
	always
		#5 clk = ~clk;
endmodule