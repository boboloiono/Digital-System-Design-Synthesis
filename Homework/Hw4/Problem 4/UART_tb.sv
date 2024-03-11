module UART_tb();
	reg clk, rst_n;
	reg trmt, tx_done, rdy, clr_rdy;
	reg [7:0] tx_data, rx_data;
	reg TX, RX;
	
	UART_tx iDUT_TX(.clk(clk), .rst_n(rst_n), .TX(TX), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));
	UART_rx iDUT_RX(.clk(clk), .rst_n(rst_n), .RX(RX), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));

	initial begin
		clk = 0;
		rst_n = 1;
		trmt = 0;
		clr_rdy = 1;
		@(negedge clk) rst_n = 0;
		
		@(posedge clk)
		tx_data = 8'h3A;
		trmt = 1;
		
		@(negedge clk) rst_n = 1;
		@(posedge clk) trmt = 0;	// trmt only runs for 1 clock after rst_n
		
		// each bit need 2605 clk for 2604 clk per bit and 2 clk per shift flop flop
		repeat(2605) @(posedge clk) RX = TX; // 1 bit
		repeat(2605) @(posedge clk) RX = TX; // 2 bit
		repeat(2605) @(posedge clk) RX = TX; // 3 bit
		repeat(2605) @(posedge clk) RX = TX; // 4 bit
		repeat(2605) @(posedge clk) RX = TX; // 5 bit
		repeat(2605) @(posedge clk) RX = TX; // 6 bit
		repeat(2605) @(posedge clk) RX = TX; // 7 bit
		repeat(2605) @(posedge clk) RX = TX; // 8 bit
		repeat(2605) @(posedge clk) RX = TX; // 9 bit
		repeat(2605) @(posedge clk) RX = TX; // 10 bit
		repeat(2) @(posedge clk);			 // transmitter needs two clk for set_done flop flop
		
		if(TX == tx_data[0] && tx_done == 1) begin
			$display("succeed to transmit data");
		end else begin
			$display("fail to transmit data");
			$stop();
		end
		
		// reciever needs more half clk than transmitter to completely transmit the last bit
		repeat(1304) @(posedge clk);
		clr_rdy = 0;
			
		// reciever needs two clk for set_rdy flip flop
		repeat(2) @(posedge clk);
		if(rdy == 1) begin
			$display("pass rdy");
		end else begin
			$display("fail rdy");
			$stop();
		end
		
		// UART is sure that transmit and recieve data corretly and completely.
		if(tx_data == rx_data) begin
			$display("succeed to recieve data");
		end else begin
			$display("fail to recieve data");
			$stop();
		end
		$display("Yahoo!! all tests passed");
		$stop();
	end
	
	always
		#5 clk = ~clk;
		
endmodule