module UART_tx_tb();
	reg clk, rst_n;
	reg trmt, tx_done;
	reg [7:0] tx_data;
	reg TX;
	
	UART_tx iDUT(.clk(clk), .rst_n(rst_n), .TX(TX), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));
	
	initial begin
		clk = 0;
		rst_n = 1;
		trmt = 0;
		@(negedge clk) rst_n = 0;
		
		@(posedge clk);
		tx_data = 8'hD3;
		trmt = 1;
		
		@(negedge clk) rst_n = 1;
		@(posedge clk) trmt = 0;
		
		repeat(2605*10+2) @(posedge clk); // 2024 clk for a baud + 1 clk for shift + 2 set_done ff
		if(TX == tx_data[0] && tx_done == 1) begin // ?? 0/1
			$display("Pass! TX is 1.");
		end else begin
			$display("Fail. TX should be 1.");
			$stop();
		end
		if(tx_done == 1) begin // ?? 0/1
			$display("Pass! tx_done is 1. Succeed to transmit data");
		end else begin
			$display("Fail. tx_done should be 1.");
			$stop();
		end
		$display("Yahoo!! all tests passed");
		$stop();
	end
	
	always
		#5 clk = ~clk;
endmodule