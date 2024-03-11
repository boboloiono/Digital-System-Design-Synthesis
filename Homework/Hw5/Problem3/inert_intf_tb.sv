module inert_intf_tb();

	reg clk, rst_n;
	reg strt_cal, cal_done;
	wire signed [11:0] heading;
	reg rdy;
	reg SS_n, SCLK, MISO, MOSI;
	reg INT;
	
	inert_intf iINTF(.clk(clk),.rst_n(rst_n),.strt_cal(strt_cal),.cal_done(cal_done),.heading(heading),.rdy(rdy),.IR_Dtrm(9'h0),
                  .SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),.INT(INT),.moving(1'b1),.en_fusion(1'b0));
	SPI_iNEMO2 iNEMO(.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.INT(INT));
	
	initial begin
		clk = 0;
		rst_n = 0;
		strt_cal = 0;
		INT = 0;
		@(negedge clk) rst_n = 1;		
		fork
			begin: timeout1
				repeat(500000) @(posedge clk);
				$display("Waiting for NEMO_setup time out.");
				$stop();
			end
			begin
				@(posedge iNEMO.NEMO_setup);
				$display("Waiting for NEMO_setup passed.");
				disable timeout1;
			end
		join
		
		strt_cal = 1;
		@(posedge clk) strt_cal = 0;
		
		fork
			begin: timeout2
				repeat(1000000) @(posedge clk);
				$display("Failed. Waiting for NEMO_setup time out.");
				$stop();
			end
			begin
				@(posedge cal_done);
				$display("Pass. Waiting for cal_done asserted.");
				disable timeout2;
			end
		join
		repeat(8000000) @(posedge clk);
		$finish();
	end
	
	always
		#5 clk = ~clk;
endmodule