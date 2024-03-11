module cmd_proc_tb();

	////////////////////////////////////////////////
	/////// reg of RemoteComm & UART_wrapper ///////
	////////////////////////////////////////////////
	logic clk, rst_n; 
	logic [15:0] cmd, cmd2;
	logic snd_cmd;
	logic cmd_snt;
	logic resp_rdy;
	logic [7:0] resp;
	logic clr_cmd_rdy;
	logic cmd_rdy;
	logic RX_TX, TX_RX;
	logic send_resp;
	logic tx_done;
	
	
	///////////////////////////////////////////
	////////	reg of cmd_proc			//////
	//////////////////////////////////////////
	logic strt_cal, in_cal;
	logic sol_cmplt;
	logic cmd_md;
	logic cal_done;
	logic strt_hdng;			// indicates to start a new heading sequence
	logic strt_mv;				// indicates a new forward movement occurring
	logic stp_lft;				// indicates move should stop at a left opening
	logic stp_rght;				// indicates move should stop at a right opening
	logic mv_cmplt;				// should be asserted at end of move
	logic moving;				// should be asserted at all times not in IDLE
	
	////////////////////////////////////////////
	////	Flip flop for creating input	////
	///////////////////////////////////////////
	logic strt_cal_ff, strt_hdng_mv_ff, strt_hdng_mv_reg, cmd_md_ff;
	
	RemoteComm iROM(.clk(clk), .rst_n(rst_n), .cmd(cmd), .snd_cmd(snd_cmd), .RX(RX_TX), .cmd_snt(cmd_snt), .resp(resp), .resp_rdy(resp_rdy), .TX(TX_RX));
	UART_wrapper iWRAP(.clk(clk), .rst_n(rst_n), .RX(TX_RX), .cmd_rdy(cmd_rdy), .cmd(cmd2), .clr_cmd_rdy(clr_cmd_rdy), .trmt(send_resp), .resp(8'hA5), .tx_done(tx_done), .TX(RX_TX));
	cmd_proc iPROC(.clk(clk), .rst_n(rst_n), .cmd(cmd2), .cmd_rdy(cmd_rdy), .clr_cmd_rdy(clr_cmd_rdy), .send_resp(send_resp), .strt_cal(strt_cal), .cal_done(cal_done), .in_cal(in_cal), .sol_cmplt(sol_cmplt),
				.strt_hdng(strt_hdng), .strt_mv(strt_mv), .stp_lft(stp_lft), .stp_rght(stp_rght), .dsrd_hdng(dsrd_hdng), .mv_cmplt(mv_cmplt), .cmd_md(cmd_md));
		
	initial begin
		
		//////////////////////////////////////////////////////////////
		/////////////////////////// STEP 1 ///////////////////////////
		//////////////////////////////////////////////////////////////
		
		clk = 1'b0;
		rst_n = 1'b0;
		snd_cmd = 1'b0;
		cmd_rdy = 1'b0;
		
		@(negedge clk) rst_n = 1;
		
		
		//////////////////////////////////////////////////////////////
		//////////////////////// STEP 2: CAL /////////////////////////
		//////////////////////////////////////////////////////////////
		
		// Send Calibrate command (0x0000)
		cmd = 16'h0000;
		// snd_cmd for one clock. This will send the command and check for its proper operation.
		snd_cmd = 1'b1;
		@(posedge clk) snd_cmd = 1'b0;
		
		fork
			begin: timeout1
				repeat(100000) @(posedge clk);
				$display("Failed. Waiting for NEMO_setup time out.");
				$stop();
			end
			begin
				@(posedge cal_done);
				$display("Pass. Waiting for cal_done asserted.");
				disable timeout1;
			end
		join
		
		/// Wait for resp_rdy or timeout if it does not occur.
		fork
			begin: timeout2
				repeat(100000) @(posedge clk);
				$display("fail resp_rdy");
				$stop();
			end
			begin
				@(posedge resp_rdy);
				$display("pass resp_rdy");
				disable timeout2;
			end
		join
		
		@(posedge tx_done);
		
		//////////////////////////////////////////////////////////////
		////////////////////// STEP 3: HEADING ///////////////////////
		//////////////////////////////////////////////////////////////
		
		/// Send heading command and look for strt_hdng at time of cmd_rdy.
		cmd = 16'h2000;	// heading to north
		snd_cmd = 1'b1;
		@(posedge clk) snd_cmd = 1'b0;
		@(posedge cmd_rdy);
		
		#1 if(strt_hdng) $display("Pass strt_hdng");
		else begin $error("Fail to strt_hdng"); $stop(); end
		
		/// One clock later check that dsrd_hdng is heading direction you sent.
		@(posedge clk);
		if(dsrd_hdng === cmd[11:0]) $display("Pass! dsrd_hdng is heading direction I sent");
		else begin $error("Fail. dsrd_hdng is not heading direction I sent"); $stop(); end
				
		/// Check that it sends a 0xA5 response when cal_done occurs.
		
		fork
			begin: timeout3
				repeat(100000) @(posedge clk);
				$display("fail mv_cmplt");
				$stop();
			end
			begin
				@(posedge mv_cmplt);
				$display("pass mv_cmplt");
				disable timeout3;
			end
		join
		if(resp === 8'hA5) $display("Pass! RemoteComm got the OxA5 response");
		else begin $error("Fail. RemoteComm didn't got the OxA5 response"); $stop(); end
		
		@(posedge tx_done);
		
		//////////////////////////////////////////////////////////////
		//////////////////////// STEP 4: MOVE ////////////////////////
		//////////////////////////////////////////////////////////////

		/// Send move command and look for strt_mv at time of cmd_rdy.
		cmd = {3'b010, 13'h1CB6};	// cmd[1]==1, cmd[0]==0 --> movement should stop at a left opening.
		snd_cmd = 1'b1;
		@(posedge clk) snd_cmd = 1'b0;
		@(posedge cmd_rdy);
		
		#1 if(strt_mv) $display("Pass! MazeRunner starts to move.");
		else begin $error("Fail. MazeRunner didn't move."); $stop(); end
		
		/// clock later check that either stp_lft or stp_rght is asserted.
		@(posedge clk);
		#1 if(stp_lft===cmd[1] || stp_rght===cmd[0]) $display("Pass! Movement stopped at a left opening");
		else begin $error("Fail. Movement should stop at a left opening"); $stop(); end
		
		@(posedge tx_done);
		
		//////////////////////////////////////////////////////////////
		/////////////////////// STEP 5: SOVLE ////////////////////////
		//////////////////////////////////////////////////////////////
		
		/// Send solve command and look for cmd_md to be low one clock after cmd_rdy.
		cmd = {3'b011, 13'h0AC37};
		snd_cmd = 1'b1;
		@(posedge clk) snd_cmd = 1'b0;
		@(posedge cmd_rdy);
		
		#1 if(!cmd_md) $display("Pass! cmd_md deasserted when start to solve maze puzzle.");
		else begin $error("Fail. cmd_md should deassert when start to solve maze puzzle."); $stop(); end
		
		snd_cmd = 1'b0;
		$display("Yahoo! All Pass!");
		$finish;
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			strt_cal_ff <= 1'b0;
			cal_done <= 1'b0;
		end else begin
			strt_cal_ff <= strt_cal;
			cal_done <= strt_cal_ff;
		end
	end
	
	assign strt_hdng_mv_reg = strt_hdng | strt_mv;
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			strt_hdng_mv_ff <= 1'b0;
			mv_cmplt <= 1'b0;
		end else begin
			strt_hdng_mv_ff <= strt_hdng_mv_reg;
			mv_cmplt <= strt_hdng_mv_ff;
		end
	end
	
	// the use of flops to provide cmplt /done signals a few clks after their respective strt signals.
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			cmd_md_ff <= 1'b0;
			sol_cmplt <= 1'b0;
		end else begin
			cmd_md_ff <= ~cmd_md;
			sol_cmplt <= cmd_md_ff;
		end
	end
	
	always
		#5 clk = ~clk;
		
endmodule