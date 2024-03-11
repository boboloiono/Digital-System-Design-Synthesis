module inert_inft_test_tb();
	logic clk, RST_n;
	logic MISO;
	logic INT;
	logic SS_n, SCLK, MOSI;
	logic [7:0] LED;
	inert_intf_test iTEST(.clk(clk), .RST_n(RST_n), .MISO(MISO), .INT(INT), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .LED(LED));
	initial begin
		clk = 0;
		RST_n = 0;
		MISO = 0;
		INT = 0;
		@(negedge clk) RST_n = 1;
		@(posedge clk) INT = 1;
		@(posedge iTEST.cal_done);
		if(LED===8'hA5) $display("PASS!");
		else begin
			$display("FAIL!");
			$stop();
		end
		repeat(10) @(posedge clk);
		$finish;
	end
	
	always
		#5 clk = ~clk;
endmodule