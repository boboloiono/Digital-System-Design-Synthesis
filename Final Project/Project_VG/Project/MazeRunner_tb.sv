
module MazeRunner_tb();
	`include "tb_task(1).sv";
	`include "tasks_tb4.sv";
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

	logic iDUT_iCMD_cal_done, iDUT_iCMD_cmd_rdy, iDUT_iCMD_strt_hdng, iDUT_iCMD_dsrd_hdng, iDUT_iCMD_mv_cmplt;
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
	assign iDUT_iCMD_cmd_rdy = iDUT.iCMD.cmd_rdy;
	assign iDUT_iCMD_cal_done = iDUT.iCMD.cal_done;
	assign iDUT_iCMD_strt_hdng = iDUT.iCMD.strt_hdng;
	assign iDUT_iCMD_dsrd_hdng = iDUT.iCMD.dsrd_hdng;
	assign iDUT_iCMD_mv_cmplt = iDUT.iCMD.mv_cmplt;
	assign iDUT_iCMD_strt_mv = iDUT.iCMD.strt_mv;
	assign iDUT_iCMD_stp_lft = iDUT.iCMD.stp_lft;
	assign iDUT_iCMD_stp_rght = iDUT.iCMD.stp_rght;
	assign iDUT_iCMD_cmd_md = iDUT.iCMD.cmd_md;
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
		
		@(negedge clk) RST_n = 1;
		batt = 12'hDA0;  	// this is value to use with RunnerPhysics
		
		
    //////////////////////////////////////////////////////////
    // cmd_proc testing: this manually checks various       //
	// (x, y) movements and heading changes. It is 			//
	// essentially a prelude to the kind of changes that    //
	// should be happening automaticall yin maze_solve.     //
    //////////////////////////////////////////////////////////

		/// Set up - calibrate
		cmd = 16'h0000;
		sendcmd(clk, send_cmd);
		wait4Calibration(clk, iDUT_iCMD_cal_done, 1000000);
		check_heading_robot_North(clk, iPHYS_heading_robot, resp_rdy, resp, HEADING_REPEAT_CLK);

	//////////////////////////////////////////////////////////
	// The meat of the test                                 //
	//////////////////////////////////////////////////////////
		
		// move to (2,1)
		cmd[15:13] = MOVE;
		sendcmd(clk, send_cmd);
		//check_stp_lft_or_rght(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_mv, iDUT_iCMD_stp_lft, iDUT_iCMD_stp_rght);
		check_move_to_xx_yy(clk, 2, 1, iPHYS_xx, iPHYS_yy, resp_rdy, resp, MOVE_TO_XX_YY_CLK);
		
		cmd[15:13] = HEADING; cmd[11:0] = HEAD_TO_WEST;
		sendcmd(clk, send_cmd);
		//check_dsrd_hdng(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_hdng, iDUT_iCMD_dsrd_hdng, iDUT_iCMD_mv_cmplt, HEADING_REPEAT_CLK);
		check_heading_robot_West(clk, iPHYS_heading_robot, resp_rdy, resp, HEADING_REPEAT_CLK);
		
		// move to (1,1)
		cmd[15:13] = MOVE;
		cmd[1] = 1'b1; cmd[0] = 1'b0; // stop at left opening
		sendcmd(clk, send_cmd);
		//check_stp_lft_or_rght(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_mv, iDUT_iCMD_stp_lft, iDUT_iCMD_stp_rght);
		check_move_to_xx_yy(clk, 1, 1, iPHYS_xx, iPHYS_yy, resp_rdy, resp, MOVE_TO_XX_YY_CLK);
		
		cmd[15:13] = HEADING; cmd[11:0] = HEAD_TO_SOUTH;
		sendcmd(clk, send_cmd);
		//check_dsrd_hdng(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_hdng, iDUT_iCMD_dsrd_hdng, iDUT_iCMD_mv_cmplt, HEADING_REPEAT_CLK);
		check_heading_robot_South(clk, iPHYS_heading_robot, resp_rdy, resp, HEADING_REPEAT_CLK);
		
		// move to (1,0)
		cmd[15:13] = MOVE;
		cmd[1] = 1'b0; cmd[0] = 1'b1; // stop at right opening
		sendcmd(clk, send_cmd);
		//check_stp_lft_or_rght(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_mv, iDUT_iCMD_stp_lft, iDUT_iCMD_stp_rght);
		check_move_to_xx_yy(clk, 1, 0, iPHYS_xx, iPHYS_yy, resp_rdy, resp, MOVE_TO_XX_YY_CLK);
		
		cmd[15:13] = HEADING; cmd[11:0] = HEAD_TO_WEST;
		sendcmd(clk, send_cmd);
		//check_dsrd_hdng(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_hdng, iDUT_iCMD_dsrd_hdng, iDUT_iCMD_mv_cmplt, HEADING_REPEAT_CLK);
		check_heading_robot_West(clk, iPHYS_heading_robot, resp_rdy, resp, HEADING_REPEAT_CLK);
		
		// move to (0,0)
		cmd[15:13] = MOVE;
		cmd[1] = 1'b0; cmd[0] = 1'b1; // stop at right opening
		sendcmd(clk, send_cmd);
		//check_stp_lft_or_rght(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_mv, iDUT_iCMD_stp_lft, iDUT_iCMD_stp_rght);
		check_move_to_xx_yy(clk, 0, 0, iPHYS_xx, iPHYS_yy, resp_rdy, resp, MOVE_TO_XX_YY_CLK);
		
		cmd[15:13] = HEADING; cmd[11:0] = HEAD_TO_NORTH;
		sendcmd(clk, send_cmd);
		//check_dsrd_hdng(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_hdng, iDUT_iCMD_dsrd_hdng, iDUT_iCMD_mv_cmplt, HEADING_REPEAT_CLK);
		check_heading_robot_North(clk, iPHYS_heading_robot, resp_rdy, resp, HEADING_REPEAT_CLK);
		
		// move to (0,3)
		cmd[15:13] = MOVE;
		cmd[1] = 1'b0; cmd[0] = 1'b1; // stop at right opening
		sendcmd(clk, send_cmd);
		//check_stp_lft_or_rght(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_mv, iDUT_iCMD_stp_lft, iDUT_iCMD_stp_rght);
		check_move_to_xx_yy(clk, 0, 3, iPHYS_xx, iPHYS_yy, resp_rdy, resp, MOVE_TO_XX_YY_CLK);
		
		cmd[15:13] = HEADING; cmd[11:0] = HEAD_TO_EAST;
		sendcmd(clk, send_cmd);
		//check_dsrd_hdng(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_hdng, iDUT_iCMD_dsrd_hdng, iDUT_iCMD_mv_cmplt, HEADING_REPEAT_CLK);
		check_heading_robot_East(clk, iPHYS_heading_robot, resp_rdy, resp, HEADING_REPEAT_CLK);
		
		// move to (3,3)
		cmd[15:13] = MOVE;
		cmd[1] = 1'b0; cmd[0] = 1'b1; // stop at right opening
		sendcmd(clk, send_cmd);
		//check_stp_lft_or_rght(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_strt_mv, iDUT_iCMD_stp_lft, iDUT_iCMD_stp_rght);
		check_move_to_xx_yy(clk, 3, 3, iPHYS_xx, iPHYS_yy, resp_rdy, resp, MOVE_TO_XX_YY_CLK);
		
		cmd[15:13] = SOVLE_MAZE;
		check_solve_maze(clk, send_cmd, iDUT_iCMD_cmd_rdy, cmd, iDUT_iCMD_cmd_md);
		
		$display("Yahoo! The cmd_proc testing passes the route of (2,0)->(2,1)->(1,1)->(1,0)->(0,0)->(0,3)->(3,3).");
		// $stop();

	//////////////////////////////////////////////////////////
    // maze_solve testing: this tests whether the robot can //
	// solve the provided path using left and right 		//
	// affinity and also tests another path.				//
    //////////////////////////////////////////////////////////


	//////////////////////////////////////////////////////////
    // Test 1: Checking for left affinity for the magnet    //
    // at (x,y) = (3,3), with start (2, 0) This has many    //
    // mini tests that check xx, yy, heading_robot values   //
    //////////////////////////////////////////////////////////


	//////////////////////////////////////////////////////////
	// Basic logic to run a new test - involves resetting   //
	// the original variables.								//
	//////////////////////////////////////////////////////////

			clk = 0;
			RST_n = 0;

			iPHYS.alpha_lft = 13'h0000;
			iPHYS.alpha_rght = 13'h0000;
			iPHYS.omega_lft = 16'h0000;
			iPHYS.omega_rght = 16'h0000;
			iPHYS.heading_robot = 20'h00000;		// start North
			iPHYS.xx = 15'h2800;			// start 2.5 squares from left
			iPHYS.yy = 15'h800;             // start 0.5 squares from left

			send_cmd = 1'b0;	
			@(negedge clk) RST_n = 1;

			// task 1: set up - calibrate
			cmd = 16'h0000;
			send_cmd = 1'b1;
			@(posedge clk) send_cmd = 1'b0;
			wait4caldone(clk, resp, RESP_REPEAT_CLK);
			// asserting we received a5 before sending another command
			@(posedge resp_rdy) assert(resp === 8'hA5); 
			
			cmd[15:13] = 3'b011; //011
			cmd[0] = 1'b1; //left affinity
			send_cmd = 1'b1;
			@(posedge clk) send_cmd = 1'b0;

	//////////////////////////////////////////////////////////
	// The meat of the test                                 //
	//////////////////////////////////////////////////////////
		
			wait4mv_cmplt(clk, 100000000);
			check_robot_position(clk, 15'h2800 ,  15'h1800);

			wait4mv_cmplt(clk, 100000000);
			check_heading_direction(clk, 12'h3ff);

			wait4mv_cmplt(clk, 100000000);
			check_robot_position(clk, 15'h1800 ,  15'h1800);

			wait4mv_cmplt(clk, 100000000);
			check_heading_direction(clk, 12'h7ff);
		
			wait4mv_cmplt(clk, 100000000);
			check_robot_positionF(clk, 15'h1800 ,  15'h0800);

			wait4mv_cmplt(clk, 100000000);
			check_heading_direction(clk, 12'h3ff);

			wait4mv_cmplt(clk, 100000000);
			check_robot_position(clk, 15'h0800 ,  15'h0800);

			wait4mv_cmplt(clk, 100000000);
			check_heading_direction(clk, 12'h000);

			wait4mv_cmplt(clk, 100000000);
			check_robot_positionF(clk, 15'h0800 ,  15'h3800);

			wait4mv_cmplt(clk, 100000000);
			check_heading_direction(clk, 12'hc00);

			wait4mv_cmplt(clk, 100000000);
			check_robot_positionF(clk, 15'h3800 ,  15'h3800);

			// maze_solve(clk, 1000000);
			if (iDUT.iSLV.sol_cmplt !== 1) begin
				$display("Error: you didn't find the magnet when you should");
				$stop();
			end else begin
				$display("LEFT AFFINITY: found the magnet!!!");
			end

			$display("Test 1 passes.");


	//////////////////////////////////////////////////////////
	// Test 2: Checking for right affinity for the magnet   //
	// at (x,y) = (3,3), strt (2, 0). This has many mini    //
	// tests that check xx, yy, heading_robot values.       //
	//////////////////////////////////////////////////////////

	//////////////////////////////////////////////////////////
	// Basic logic to run a new test - involves resetting   //
	// the original variables.								//
	//////////////////////////////////////////////////////////

		// clk = 0;
		RST_n = 0;

		iPHYS.alpha_lft = 13'h0000;
		iPHYS.alpha_rght = 13'h0000;
		iPHYS.omega_lft = 16'h0000;
		iPHYS.omega_rght = 16'h0000;
		iPHYS.heading_robot = 20'h00000;		// start North
		iPHYS.xx = 15'h2800;			// start 2.5 squares from left
		iPHYS.yy = 15'h800;             // start 0.5 squares from left

		@ (negedge clk) RST_n = 1; 
		send_cmd = 0;

	//////////////////////////////////////////////////////////
	// Calibrating the robot, waiting for response          // 
	// A5 at resp_rdy                                       //
	//////////////////////////////////////////////////////////

		cmd = 16'h0000;
		send_cmd = 1;
		@ (negedge clk) send_cmd = 0;

		// asserting we received a5 before sending another command
		// todo add timeout 
		waitForResponse(clk, resp, resp_rdy);

	//////////////////////////////////////////////////////////
	// The meat of the test                                 //
	//////////////////////////////////////////////////////////
			
		cmd[15:13] = 3'b011;                    // 011 implies being run by maze_solve 
		cmd[0] = 0;                             // right affinity
		send_cmd = 1;
		@ (posedge clk) send_cmd = 0;

		// at first move complete check if at xx 2800 yy 1800
		wait4mv_cmplt(clk, 10000000);
		check_robot_position(clk, 15'h2800, 15'h1800);

		// at second move complete check if heading_robot at 3ff
		wait4mv_cmplt(clk, 2000000);
		check_heading_direction(clk, 13'h3FF);

		// at third move complete check if at xx 1800 yy 1800
		wait4mv_cmplt(clk, 10000000);
		check_robot_position(clk, 15'h1800, 15'h1800);

		// at tenth mv_complt check if heading_robot moved to 000 since 
		// both right and left are open
		// mv_cmplt 4, 5, 6, 7, 8, 9
		wait4mv_cmplt(clk, 10000000); 
		wait4mv_cmplt(clk, 10000000);
		wait4mv_cmplt(clk, 10000000);
		wait4mv_cmplt(clk, 10000000);
		wait4mv_cmplt(clk, 10000000);
		wait4mv_cmplt(clk, 10000000);

		wait4mv_cmplt(clk, 2000000);
		check_heading_direction(clk, 13'h000);

		// once the maze is solved, check if the xx yy values are correct 
		maze_solve(clk, 10000000);
		wait4mv_cmplt(clk, 10000000);
		check_robot_position(clk, 15'h3800, 15'h3800);

		$display("Test 2 passes.");

	//////////////////////////////////////////////////////////
	// Test 3: Checking for left affinity for the magnet    //
	// at (x,y) = (3,3), start (2, 2). This has many mini   //
	// tests that check xx, yy, heading_robot values.       //
	//////////////////////////////////////////////////////////
		
		RST_n = 0;

		iPHYS.alpha_lft = 13'h0000;
		iPHYS.alpha_rght = 13'h0000;
		iPHYS.omega_lft = 16'h0000;
		iPHYS.omega_rght = 16'h0000;
		iPHYS.heading_robot = 20'h00000;		// start North
		iPHYS.xx = 15'h2800;			// start 2.5 squares from left
		iPHYS.yy = 15'h800;             // start 2.5 squares from bottom

		iPHYS.magnet_pos_xx = 7'h08;	// magnet pos is middle of (3,3)
		iPHYS.magnet_pos_yy = 7'h38;

		@ (negedge clk) RST_n = 1; 
		send_cmd = 0;
		
	//////////////////////////////////////////////////////////
	// Calibrating the robot, waiting for response          // 
	// A5 at resp_rdy                                       //
	//////////////////////////////////////////////////////////
		
		cmd = 16'h0000;
		send_cmd = 1;
		@ (negedge clk) send_cmd = 0;

		// asserting we received a5 before sending another command
		// todo add timeout 
		waitForResponse(clk, resp, resp_rdy);
		
	//////////////////////////////////////////////////////////
	// The meat of the test.                                //
	//////////////////////////////////////////////////////////
		
		cmd[15:13] = 3'b011;                    // 011 implies being run by maze_solve 
		cmd[0] = 1;                             // left affinity
		send_cmd = 1;
		@ (posedge clk) send_cmd = 0;

		// once the maze is solved, check if the xx yy values are correct 
		maze_solve(clk, 90000000);
		wait4mv_cmplt(clk, 10000000);
		check_robot_position(clk, 15'h0800, 15'h3800);

		$display("Tst 3 passes.");
		

	//////////////////////////////////////////////////////////
	// Test 4: Checking Piezo (visual test) for the correct //
	// states upon sol_cmplt, and when batt_low is asserted //
	//////////////////////////////////////////////////////////
		
		// check for victory notes 
		repeat (1000000) @ (posedge clk);

		batt = 12'h000;
		// check for battery low notes

	//////////////////////////////////////////////////////////
	// At the very end...                                   //
	//////////////////////////////////////////////////////////

		repeat (1000000) @ (posedge clk);
		$display("At the end. Does everything pass?");
		$stop();

	end

	always
		#5 clk = ~clk;

endmodule