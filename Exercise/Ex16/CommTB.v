module CommTB();

	reg clk, rst_n; 
	reg [15:0] cmd1;
	wire [15:0] cmd2;
	wire cmd_snt;
	wire resp_rdy;
	reg snd_cmd;
	wire [7:0] resp;
	reg clr_cmd_rdy;
	reg trmt;
	wire cmd_rdy;
	wire RX_TX;
	wire TX_RX;
	
	// why resp, resp_rdy, and tx_done no data? 
	RemoteComm iDUT(.clk(clk), .rst_n(rst_n), .cmd(cmd1), .snd_cmd(snd_cmd), .RX(RX_TX), .cmd_snt(cmd_snt), .resp(resp), .resp_rdy(resp_rdy), .TX(TX_RX));
	UART_wrapper iCLK(.clk(clk), .rst_n(rst_n), .RX(TX_RX), .cmd_rdy(cmd_rdy), .cmd(cmd2), .clr_cmd_rdy(clr_cmd_rdy), .trmt(trmt), .resp(8'hA5), .tx_done(), .TX(RX_TX));
	
	localparam COMMAND = 16'h4F53;
	
	initial begin
		clk = 0;
		rst_n = 0;
		snd_cmd = 0;
		trmt = 1'b0;
		@(negedge clk) rst_n = 1;
		@(posedge clk) cmd1 = COMMAND;
		snd_cmd = 1;	// start to send cmd
		@(posedge cmd_rdy) snd_cmd = 0;
		// check whether cmd is equal to origin cmd or not
		if (cmd2 === COMMAND) $display("pass");
		else begin
			$error("Failed. cmd is not equal to the origin cmd sended from RomoteComm.");
			$stop();
		end
		// after cmd transmit to UART, we should clear cmd_rdy to avoid send inadvently
		clr_cmd_rdy = 1'b1;
		snd_cmd = 0;
		cmd1 = 0;
		
		// make sure cmd_rdy is clear.
		repeat(2) @(posedge clk);
		if(cmd_rdy === 1'b0) $display("pass");
		else begin
			$display("Failed. cmd_rdy should be cleared to 0");
			$stop();
		end
		
		trmt = 1'b1;
		@(posedge clk)
		trmt = 0;
		
		///////// .resp(resp), .resp_rdy(resp_rdy) ////////////////
		$display("All pass! cmd processed by RemoteComm and Wrapper is still the smame cmd.");
		$stop();
	end
	
	always 
		#5 clk = ~clk;
endmodule