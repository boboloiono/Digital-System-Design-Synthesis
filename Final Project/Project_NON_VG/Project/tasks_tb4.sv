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
			//$display(iPHYS.xx);
			//$display(iPHYS.yy);
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
	assert((iDUT.iCNTRL.actl_hdng - expected_heading < 10'h20) || (expected_heading - iDUT.iCNTRL.actl_hdng < 10'h20) || (($signed(iDUT.iCNTRL.actl_hdng) < $signed(12'd32)) && ($signed(iDUT.iCNTRL.actl_hdng) > $signed(-12'd32)))) begin
		// note: this last condition above was added because for heaidng = 000, the negative value from wrapping around was not being correctly recognised
		$display("The robot is pointing in the %d direction", iDUT.iCNTRL.actl_hdng);
	end else begin
	    $display(iDUT.iCNTRL.actl_hdng - expected_heading);
            $display(expected_heading - iDUT.iCNTRL.actl_hdng);
	    $display("Error: the robot is pointing in the %d direction", iDUT.iCNTRL.actl_hdng);
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
