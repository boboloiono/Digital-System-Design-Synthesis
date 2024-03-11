//////////////////////////////////////////////////
// tesks used for testing command proc          //
//////////////////////////////////////////////////

task automatic sendcmd(ref clk, reg send_cmd);
	send_cmd = 1'b1;
	@(posedge clk) send_cmd = 1'b0;
endtask

task automatic wait4Calibrationvg(ref clk, ref resp_rdy, input int clks2wait);
	fork
		begin: timeout
			repeat(clks2wait) @(posedge clk);
			$display("fail calibration");
			$stop();
		end
		begin
			@(posedge resp_rdy);
			$display("pass calibration");
			disable timeout;
		end
	join
endtask


//waiting for cal_done
task automatic wait4Calibration(ref clk, reg cal_done, input int clks2wait);
	fork
		begin: timeout
			repeat(clks2wait) @(posedge clk);
			$display("fail calibration");
			$stop();
		end
		begin
			@(posedge cal_done);
			$display("pass calibration");
			disable timeout;
		end
	join
endtask

// waiting for response ready
task automatic wait4resp(ref clk, reg resp_rdy, ref[7:0]resp, input int clks2wait);
	fork
		begin: timeout
			repeat(clks2wait) @(posedge clk);
			$display("fail resp_rdy");
			$stop();
		end
		begin
			@(posedge resp_rdy);
			$display("pass! resp_rdy === 8'A5");
			disable timeout;
		end
	join
	assert(resp === 8'hA5);
endtask

//waiting for move complete 
task automatic check_dsrd_hdng(ref clk, ref send_cmd, ref cmd_rdy, ref [15:0] cmd, reg strt_hdng, ref dsrd_hdng, ref mv_cmplt, input int clks2wait);
	send_cmd = 1'b1;
	@(posedge clk) send_cmd = 1'b0;
	@(posedge cmd_rdy);
	
	#1 if(strt_hdng) $display("Pass strt_hdng");
	else begin $error("Fail to strt_hdng"); $stop(); end
	
	// One clock later check that dsrd_hdng is heading direction you sent.
	@(posedge clk);
	if(dsrd_hdng === cmd[11:0]) $display("Pass! dsrd_hdng is heading direction I sent");
	else begin $error("Fail. dsrd_hdng is not heading direction I sent"); $stop(); end
	
	fork
		begin: timeout2
			repeat(clks2wait) @(posedge clk);
			$display("fail mv_cmplt");
			$stop();
		end
		begin
			@(posedge mv_cmplt);
			$display("pass mv_cmplt");
			disable timeout2;
		end
	join
endtask

// check stop left and stop right
task automatic check_stp_lft_or_rght(ref clk, ref send_cmd, ref cmd_rdy, ref [15:0] cmd, reg strt_mv, ref stp_lft, ref stp_rght);
	send_cmd = 1'b1;
	@(posedge clk) send_cmd = 1'b0;
	@(posedge cmd_rdy);
	
	#1 if(strt_mv) $display("Pass! MazeRunner starts to move.");
	else begin $error("Fail. MazeRunner didn't move."); $stop(); end
	
	/// clock later check that either stp_lft or stp_rght is asserted.
	@(posedge clk);
	#1 if(stp_lft===cmd[1] || stp_rght===cmd[0]) $display("Pass! Movement matches stp_lft or stp_rght");
	else begin $error("Fail. Movement should stop at a left opening"); $stop(); end
endtask

//check maze solve 
task automatic check_solve_maze(ref clk, ref send_cmd, ref cmd_rdy, ref [15:0] cmd, reg cmd_md);
	send_cmd = 1'b1;
	@(posedge clk) send_cmd = 1'b0;
	@(posedge cmd_rdy);
	
	#1 if(!cmd_md) $display("Pass! cmd_md deasserted when start to solve maze puzzle.");
	else begin $error("Fail. cmd_md should deassert when start to solve maze puzzle."); $stop(); end
endtask

// check that the robot is facing north
task automatic check_heading_robot_North(ref clk, ref [19:0] heading_robot, reg resp_rdy, reg [7:0] resp, input int clks2wait);
	fork 
		begin: timeout1
			repeat (clks2wait) @ (posedge clk); 
			$display("fail heading_robot to north");
			$stop();
		end 
		begin
			@(posedge resp_rdy);
			assert(((heading_robot[19:8]) > $signed(12'hFe2)) || ($signed(heading_robot[19:8]) < $signed(12'h020)))
				$display("pass heading_robot to north");
			disable timeout1;
		end
	join
	assert(resp === 8'ha5);
endtask

// check that the robot is facing south
task automatic check_heading_robot_South(ref clk, ref [19:0] heading_robot, reg resp_rdy, reg [7:0] resp, input int clks2wait);
	fork 
		begin: timeout2
			repeat (clks2wait) @ (posedge clk); 
			$display("fail heading_robot to north");
			$stop();
		end 
		begin
			@(posedge resp_rdy);
			assert((heading_robot[19:8] > 12'h7df) && (heading_robot[19:8] < 12'h81f))
				$display("pass heading_robot to south");
			disable timeout2;
		end
	join
	assert(resp === 8'ha5);
endtask

// check that the robot is facing east
task automatic check_heading_robot_East(ref clk, ref [19:0] heading_robot, reg resp_rdy, reg [7:0] resp, input int clks2wait);
	fork 
		begin: timeout3
			repeat (clks2wait) @ (posedge clk); 
			$display("fail heading_robot to north");
			$stop();
		end 
		begin
			@(posedge resp_rdy);
			assert(($signed(heading_robot[19:8]) < $signed(12'hC21)) && ($signed(heading_robot[19:8]) > $signed(12'hBE0)))
				$display("pass heading_robot to east");
			disable timeout3;
		end
	join
	assert(resp === 8'ha5);
endtask

// check that the robot is facing west
task automatic check_heading_robot_West(ref clk, ref [19:0] heading_robot, reg resp_rdy, reg [7:0] resp, input int clks2wait);
	fork 
		begin: timeout4
			repeat (clks2wait) @ (posedge clk); 
			$display("fail heading_robot to north");
			$stop();
		end 
		begin
			@(posedge resp_rdy);
			assert(($signed(heading_robot[19:8]) < $signed(12'h41F)) && ($signed(heading_robot[19:8]) > $signed(12'h3DF)))
				$display("pass heading_robot to west");
			disable timeout4;
		end
	join
	assert(resp === 8'ha5);
endtask

// check that the position of the robot(xx, yy)
task automatic check_move_to_xx_yy(ref clk, input int pos_x, input int pos_y, ref [14:0] xx, ref [14:0] yy, reg resp_rdy, reg [7:0] resp, input int clks2wait);
	if(pos_x===0 && pos_y===0) begin
		fork
			begin: timeout0
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (0,0)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h0680 && xx < 15'h0920 && yy > 15'h0680 && yy < 15'h0920)
					$display("pass move to (0,0)");
				disable timeout0;
			end
		join
	end
	else if(pos_x===0 && pos_y===1) begin
		fork
			begin: timeout1
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (0,1)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h0680 && xx < 15'h0920 && yy > 15'h1680 && yy < 15'h1920)
					$display("pass move to (0,1)");
				disable timeout1;
			end
		join
	end
	else if(pos_x===0 && pos_y===2) begin
		fork
			begin: timeout2
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (0,2)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h0680 && xx < 15'h0920 && yy > 15'h2680 && yy < 15'h2920)
					$display("pass move to (0,2)");
				disable timeout2;
			end
		join
	end
	else if(pos_x===0 && pos_y===3) begin
		fork
			begin: timeout3
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (0,3)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h0680 && xx < 15'h0920 && yy > 15'h3680 && yy < 15'h3920)
					$display("pass move to (0,3)");
				disable timeout3;
			end
		join
	end
	else if(pos_x===1 && pos_y===0) begin
		fork
			begin: timeout4
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (1,0)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h1680 && xx < 15'h1920 && yy > 15'h0680 && yy < 15'h0920)
					$display("pass move to (1,0)");
				disable timeout4;
			end
		join
	end
	else if(pos_x===1 && pos_y===1) begin
		fork
			begin: timeout5
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (1,1)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h1680 && xx < 15'h1920 && yy > 15'h1680 && yy < 15'h1920)
					$display("pass move to (1,1)");
				disable timeout5;
			end
		join
	end
	else if(pos_x===1 && pos_y===2) begin
		fork
			begin: timeout6
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (1,2)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h1680 && xx < 15'h1920 && yy > 15'h2680 && yy < 15'h2920)
					$display("pass move to (1,2)");
				disable timeout6;
			end
		join
	end
	else if(pos_x===1 && pos_y===3) begin
		fork
			begin: timeout7
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (1,3)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h1680 && xx < 15'h1920 && yy > 15'h3680 && yy < 15'h3920)
					$display("pass move to (1,3)");
				disable timeout7;
			end
		join
	end
	else if(pos_x===2 && pos_y===0) begin
		fork
			begin: timeout8
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (2,0)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h2680 && xx < 15'h2920 && yy > 15'h0680 && yy < 15'h0920)
					$display("pass move to (2,0)");
				disable timeout8;
			end
		join
	end
	else if(pos_x===2 && pos_y===1) begin
		fork
			begin: timeout9
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (2,1)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h2680 && xx < 15'h2920 && yy > 15'h1680 && yy < 15'h1920)
					$display("pass move to (2,1)");
				disable timeout9;
			end
		join
	end
	else if(pos_x===2 && pos_y===2) begin
		fork
			begin: timeout10
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (2,2)"); $stop();
			end
			begin
				assert(xx > 15'h2680 && xx < 15'h2920 && yy > 15'h2680 && yy < 15'h2920)
					$display("pass move to (2,2)");
				disable timeout10;
			end
		join
	end
	else if(pos_x===2 && pos_y===3) begin
		fork
			begin: timeout11
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (2,3)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h2680 && xx < 15'h2920 && yy > 15'h3680 && yy < 15'h3920)
					$display("pass move to (2,3)");
				disable timeout11;
			end
		join
	end
	else if(pos_x===3 && pos_y===0) begin
		fork
			begin: timeout12
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (2,3)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h3680 && xx < 15'h3920 && yy > 15'h0680 && yy < 15'h0920)
					$display("pass move to (2,3)");
				disable timeout12;
			end
		join
	end
	else if(pos_x===3 && pos_y===1) begin
		fork
			begin: timeout13
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (3,1)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h3680 && xx < 15'h3920 && yy > 15'h1680 && yy < 15'h1920)
					$display("pass move to (3,1)");
				disable timeout13;
			end
		join
	end
	else if(pos_x===3 && pos_y===2) begin
		fork
			begin: timeout14
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (3,2)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h3680 && xx < 15'h3920 && yy > 15'h2680 && yy < 15'h2920)
					$display("pass move to (3,2)");
				disable timeout14;
			end
		join
	end
	else if(pos_x===3 && pos_y===3) begin
		fork
			begin: timeout15
				repeat(clks2wait) @(posedge clk);
				$display("fail move to (3,3)"); $stop();
			end
			begin
				@(posedge resp_rdy);
				assert(xx > 15'h3680 && xx < 15'h3920 && yy > 15'h3680 && yy < 15'h3920)
					$display("pass move to (3,3)");
				disable timeout15;
			end
		join
	end
	assert(resp === 8'ha5);
endtask


///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

/*
task automatic waitForResponse(ref clk, ref[7:0]resp, ref resp_rdy);
    fork 
        begin: timeout1
            repeat (10000000) @ (posedge clk); 
            $display("Error: waiting for response timed out.");
            $stop();
        end 
        begin
            @ (posedge resp_rdy) assert(resp === 8'hA5);
            $display("Waiting for response = A5 passed.");
            disable timeout1;
        end 
    join 
endtask

// waiting for calibration to be done 
task automatic wait4caldone(ref clk, ref[7:0]resp, input int clks2wait);
	fork
		begin: timeout
			repeat(clks2wait) @(posedge clk);
			$display("Error: calibration failed");
			$stop();
		end
		begin
			@(posedge iDUT.iCMD.cal_done);
			$display("Calibration is successful");
			disable timeout;
		end
	join
endtask

// waiting for move_complete
task automatic wait4mv_cmplt(ref clk, input int clks2wait);
		fork
		begin: timeout
			repeat(clks2wait) @(posedge clk);
			$display("Error: the mv_cmplt failed");
			$stop();
		end
		begin
			@(posedge iDUT.iNAV.mv_cmplt);
			$display("The mv_cmplt is successful");
			disable timeout;
		end
	join
endtask

// checking if maze solved 
task automatic maze_solve(ref clk, input int clks2wait);
		fork
		begin: timeout
			repeat(clks2wait) @(posedge clk);
			$display("Maze solve failed");
			// $stop();
			$display(iPHYS.xx);
			$display(iPHYS.yy);
		end
		begin
			@(posedge iDUT.sol_cmplt);
			$display("The sol_complt is successful");
			disable timeout;
		end
	join
endtask

// checking heading against expected 
// this is typically used after the mv_cmplt task has verified that there is a mv_cmplt 
task automatic check_heading_direction(ref clk, input[12:0] expected_heading);
	assert(($signed(iDUT.iCNTRL.actl_hdng) - $signed(expected_heading) < 10'h20) || ($signed(expected_heading) - $signed(iDUT.iCNTRL.actl_hdng) < 10'h20)) $display("The robot is pointing in the %d direction", iDUT.iCNTRL.actl_hdng);
	else begin
	    $display("Error: the robot is pointing in the %d direction", iDUT.iCNTRL.actl_hdng);
        // $display(iDUT.iCNTRL.actl_hdng - expected_heading);
        // $display(expected_heading - iDUT.iCNTRL.actl_hdng);
	end	
endtask

// checking xx and yy positions against expected values
// this is typically used after the mv_cmplt task has verified that there is a mv_cmplt 
task automatic check_robot_position(ref clk, input [14:0]expected_xx, input [14:0]expected_yy);
    if ((iPHYS.xx - expected_xx < 14'h150 || expected_xx - iPHYS.xx < 14'h150) && (iPHYS.yy - expected_yy < 14'h150 || expected_yy - iPHYS.yy < 14'h150)) begin
        $display("The robot is correctly at x = %d and y = %d", iPHYS.xx, iPHYS.yy);
    end else begin
	    $display("Error: the robot is incorrectly at x = %d and y = %d", iPHYS.xx, iPHYS.yy);
	end	
endtask

// checking xx and yy positions against expected values
// this is typically used after the mv_cmplt task has verified that there is a mv_cmplt 
task automatic check_robot_positionF(ref clk, input [14:0]expected_xx, input [14:0]expected_yy);
    if ((iPHYS.xx - expected_xx < 14'h200 || expected_xx - iPHYS.xx < 14'h200) && (iPHYS.yy - expected_yy < 14'h150 || expected_yy - iPHYS.yy < 14'h150)) begin
        $display("The robot is correctly at x = %d and y = %d", iPHYS.xx, iPHYS.yy);
    end else begin
	    $display("Error: the robot is incorrectly at x = %d and y = %d", iPHYS.xx, iPHYS.yy);
	end	
endtask
*/

