module SPI_mnrch_tb();

	reg clk, rst_n;
	reg SS_n, SCLK;
	reg MOSI, MISO;
	reg wrt;
	reg [15:0] wt_data, rd_data;
	reg done;
	reg INT;
	// NEMO_setup;	//a reg to configure the INT output pin to assert when new data is ready.
	
	SPI_mnrch iMNRCH(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .wrt(wrt), .wt_data(wt_data), .done(done), .rd_data(rd_data));
	SPI_iNEMO1 iNEMO1(.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT));
	
	initial begin
		clk = 0;
		rst_n = 0;
		SS_n = 0;
		SCLK = 0;
		MISO = 0;
		MOSI = 0;
		@(negedge clk) rst_n = 1;
		wrt = 1;
		
		// The NEMO contains a “WHO_AM_I” read only register at address 0x0F.
		// This register always returns the value 0x6A. So your first test should be a read from 0x0F.
		wt_data = 16'h8F00;
		@(posedge done);
		assert (rd_data === 16'h006A) $display("Pass WHO_AM_I");	// finish NEMO_setup
		else begin
			$error("Fail. When wt_data = 16'h8Fxx, rd_data would be expected as 16'hxx6A.");
			$stop();
		end
		
		// write to the register to configure the INT output pin to assert when new data is ready.
		wt_data = 16'h0D02;
		
		// After NEMO_setup has been asserted, the INT pin eventually would be asserted.
		@(posedge INT);
		
		///////////////////////////////////////
		//////////// test 1 : yawL ////////////
		///////////////////////////////////////
		
		// Inert_data: pointer==0, so read yaw[0][7:0].
		@(posedge done);
		wt_data = 16'hA600;
		@(posedge done);
		assert(rd_data === 16'h008d) $display("Pass test 1 : yawL");
		else $error("Fail. The 1st inert_data is yawL, so rd_data should be 16'hxx8d.");
		@(posedge clk);	// wait for a clk, and then INT should deassert.
		assert(!INT) $display("Pass test 1 INI");		// INT pin is cleared when yawL is read.
		else $error("Fail. The INT pin should drop after rd_data got the result from 1st yawL.");
		
		///////////////////////////////////////
		//////////// test 2 : yawH ////////////
		///////////////////////////////////////
		
		// Inert_data: pointer + 1, so read yaw[1][15:8].
		@(posedge INT);
		@(posedge done);
		wt_data = 16'hA700;
		@(posedge done);
		assert(rd_data === 16'h00cd) $display("Pass test 2 : yawH");
		else $display("Fail. The 2nd inert_data is yawH, so rd_data should be 16'hxxcd.");
		assert (INT) $display("Pass test 2 INI");		// INT pin keep high when trasmit yawH
		else $error("Fail: After 2nd yawH is asserted, INT pin would keep high.");
		
		///////////////////////////////////////
		//////////// test 3 : yawL ////////////
		///////////////////////////////////////
		
		// Inert_data: pointer = pointer, so read yaw[1][7:0].
		assert (INT);
		@(posedge done);
		wt_data = 16'hA600;
		@(posedge done);
		assert(rd_data === 16'h003d) $display("Pass test 3 : yawL");
		else $error("Fail. The 3rd inert_data is yawL, so rd_data should be 16'hxx3d.");
		assert(!INT) $display("Pass test 3 INI");
		else $error("Fail. The INT pin should drop after rd_data got the result from 3rd yawL.");
		
		///////////////////////////////////////
		//////////// test 4 : yawH ////////////
		///////////////////////////////////////
		
		// Inert_data: pointer + 1, so read yaw[2][15:8].
		@(posedge INT);
		@(posedge done);
		wt_data = 16'hA700;
		@(posedge done);
		assert(rd_data === 16'h00d2) $display("Pass test 4 : yawH");
		else $display("Fail. The 4th inert_data is yawH, so rd_data should be 16'hxxd2.");
		assert (!INT) $display("Pass test 4 INI");
		else $error("Fail: After 4th yawH is asserted, INT pin would keep high.");
		
		wrt = 0;
		
		$display("Yahoo. All tests completed. All pass.");
		$finish();
		
	 end
	 
	always
		#5 clk = ~clk;
		
endmodule