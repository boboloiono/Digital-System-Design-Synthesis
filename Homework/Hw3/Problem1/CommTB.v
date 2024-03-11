module CommTB();

	reg clk,rst_n; 
	reg [15:0] cmd;
	reg snd_cmd, cmd_snt, resp_rdy;
	reg [7:0] resp;
	reg trmt, RX;
	reg cmd_rdy, clr_cmd_rdy, tx_done, TX;
	
	RemoteComm iDUT(.clk(clk), .rst_n(rst_n), .cmd(cmd), .snd_cmd(snd_cmd), .cmd_snt(cmd_snt), .resp(resp), .resp_rdy(resp_rdy));
	UART_wrapper iCLK(.clk(clk), .rst_n(rst_n), .RX(RX), .cmd_rdy(cmd_rdy), .cmd(cmd), .clr_cmd_rdy(clr_cmd_rdy), .trmt(trmt), .resp(resp), .tx_done(tx_done), .TX(TX));
	
	localparam COMMAND = 16'h4F53;
	
	initial begin
		clk = 0;
		rst_n = 0;
		snd_cmd = 0;
		@(negedge clk) rst_n = 1;
		@(posedge clk);
		cmd = COMMAND;
		snd_cmd = 1;
		// go to state HIGH and LOW
		repeat(3) @(posedge clk);
		
		if(cmd_snt === 1'b1) $display("pass #1");
		else begin
			$display("Failed. cmd_snt should be 1")
			$stop();
		end
		
		// tx_data got cmd
		if(tx_data === COMMAND) $display("pass #2");
		else begin
			$display("Failed. tx_data should be equal to cmd after pass RemoteComm.")
			$stop();
		end
		
		// after send {high,low}, we should close snd_cmd
		snd_cmd = 0;
		
		// clear cmd_snt
		@(posedge clk);
		if(cmd_snt === 1'b0 $display("pass #3");
		else begin
			$display("Failed. cmd_snt should be 0 after clear cmd_snt")
			$stop();
		end
		
		// send cmd to UART_wrapper
		repeat(3) @(posedge clk);
		if(cmd_rdy === 1'b1) $display("pass #4");
		else begin
			$display("Failed. cmd_rdy should be 1 after sending cmd to UART")
			$stop();
		end
		
		// check whether cmd is equal to origin cmd or not
		if(cmd === COMMAND) $display("pass #5");
		else begin
			$display("Failed. cmd is not equal to the origin cmd sended from RomoteComm.")
			$stop();
		end
		
		// after cmd transmit to UART, we should clear cmd_rdy to avoid send inadvently
		clr_cmd_rdy = 1'b1;
		
		// make sure cmd_rdy is clear.
		@(posedge clk);
		if(cmd_rdy === 1'b0) $display("pass #6");
		else begin
			$display("Failed. cmd_rdy should be cleared to 0")
			$stop();
		end
		
		///////// .resp(resp), .resp_rdy(resp_rdy) ////////////////
		$display("Yahoo! All pass");
		$stop();
	end
	
	always 
		#5 clk = ~clk;
endmodule