`timescale 1ns/1ps
module Test_vg();
	`include "tb_task(1).sv";
	//<< optional include or import >>

	reg clk,RST_n;
	reg send_cmd;					// assert to send command to MazeRunner_tb
	reg [15:0] cmd;				// 16-bit command to send
	reg [11:0] batt;				// battery voltage 0xDA0 is nominal

	logic cmd_sent;				
	logic resp_rdy;				// MazeRunner has sent a pos acknowledge
	logic [7:0] resp;				// resp byte from MazeRunner (hopefully 0xA5)
	logic hall_n;					// magnet found?

	/////////////////////////////////////////////////////////////////////////
	// Signals interconnecting MazeRunner to RunnerPhysics and RemoteComm //
	///////////////////////////////////////////////////////////////////////
	wire TX_RX,RX_TX;
	wire INRT_SS_n,INRT_SCLK,INRT_MOSI,INRT_MISO,INRT_INT;
	wire lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
	wire A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;
	wire IR_lft_en,IR_cntr_en,IR_rght_en;  

	localparam FAST_SIM = 1'b1;

	logic iDUT_iCMD_cmd_rdy, iDUT_iCMD_strt_hdng, iDUT_iCMD_dsrd_hdng, iDUT_iCMD_mv_cmplt;
	logic iDUT_iCMD_strt_mv, iDUT_iCMD_stp_lft, iDUT_iCMD_stp_rght, iDUT_iCMD_cmd_md;
	logic [19:0] iPHYS_heading_robot;
	logic [14:0] iPHYS_xx, iPHYS_yy;
	
	//////////////////////
	// Instantiate DUT //
	////////////////////
	MazeRunner iDUT(.clk(clk),.RST_n(RST_n),.INRT_SS_n(INRT_SS_n),.INRT_SCLK(INRT_SCLK),
				  .INRT_MOSI(INRT_MOSI),.INRT_MISO(INRT_MISO),.INRT_INT(INRT_INT),
				  .A2D_SS_n(A2D_SS_n),.A2D_SCLK(A2D_SCLK),.A2D_MOSI(A2D_MOSI),
				  .A2D_MISO(A2D_MISO),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
				  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.RX(RX_TX),.TX(TX_RX),
				  .hall_n(hall_n),.piezo(),.piezo_n(),.IR_lft_en(IR_lft_en),
				  .IR_rght_en(IR_rght_en),.IR_cntr_en(IR_cntr_en),.LED());

	///////////////////////////////////////////////////////////////////////////////////////
	// Instantiate RemoteComm which models bluetooth module receiving & forwarding cmds //
	/////////////////////////////////////////////////////////////////////////////////////
	RemoteComm iCMD(.clk(clk), .rst_n(RST_n), .RX(TX_RX), .TX(RX_TX), .cmd(cmd), .send_cmd(send_cmd),
			   .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp));
			   
				  
	RunnerPhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(INRT_SS_n),.SCLK(INRT_SCLK),.MISO(INRT_MISO),
					  .MOSI(INRT_MOSI),.INT(INRT_INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
					  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),
					 .IR_lft_en(IR_lft_en),.IR_cntr_en(IR_cntr_en),.IR_rght_en(IR_rght_en),
					 .A2D_SS_n(A2D_SS_n),.A2D_SCLK(A2D_SCLK),.A2D_MOSI(A2D_MOSI),
					 .A2D_MISO(A2D_MISO),.hall_n(hall_n),.batt(batt));
	
	// local parameter for testing "com_proc"
	assign iPHYS_heading_robot = iPHYS.heading_robot;
	assign iPHYS_xx = iPHYS.xx;
	assign iPHYS_yy = iPHYS.yy;
	
	localparam RESP_REPEAT_CLK = 10000000;
	localparam MV_CMPLT_REPEAT_CLK = 100000;
	localparam HEADING_REPEAT_CLK = 15000000;
	localparam MOVE_TO_XX_YY_CLK = 15000000;
	
	localparam CALIBRATE = 3'b000, HEADING = 3'b001, MOVE = 3'b010, SOVLE_MAZE = 3'b011;
	localparam HEAD_TO_NORTH = 12'h000, HEAD_TO_WEST = 12'h3ff, HEAD_TO_SOUTH = 12'h7ff, HEAD_TO_EAST = 12'hC00;
	initial begin
		clk = 0;
		RST_n = 0;
		send_cmd = 1'b0;
		@(posedge clk);
		@(negedge clk) RST_n = 1;
		batt = 12'hDA0;  	// this is value to use with RunnerPhysics
		
		/// Set up - calibrate
		cmd = 16'h0000;
		sendcmd(clk, send_cmd);
		wait4Calibration(clk, resp_rdy, 1000000);
		
		//Heading to west
		cmd[15:13] = HEADING; cmd[11:0] = HEAD_TO_WEST;
		sendcmd(clk, send_cmd);
		check_heading_robot_West(clk, iPHYS_heading_robot, resp_rdy, resp, HEADING_REPEAT_CLK);

		batt = 12'h000;
		fork
			begin: timeoutA
				repeat(1000000) @(posedge clk);
				$display("Error: pizeo toggling failed");
				$stop();
			end
			begin
				@ (posedge iDUT.ICHRG.piezo);
				@ (negedge iDUT.ICHRG.piezo);
				@ (posedge iDUT.ICHRG.piezo);
				$display("The piezo toggles");

				if (iDUT.ICHRG.piezo === 1 && iDUT.ICHRG.piezo_n === 0) begin
					$display("The piezo toggles and the piezo_n does too");
				end else begin
					$display("Error: the piezo toggles but the piezo_n does not");
				end 
				disable timeoutA;
			end
		join

		
		$display("Yahoo! VG test passed");
		$stop();
	end
	always
		#5 clk = ~clk;

endmodule
