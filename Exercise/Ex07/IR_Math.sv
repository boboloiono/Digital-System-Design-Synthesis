module IR_Math(lft_opn, rght_opn, lft_IR, rght_IR, IR_Dtrm, en_fusion, dsrd_hdng, dsrd_hdng_adj);

	input lft_opn, rght_opn;				// Indicate left/right IR sensors have no reading (the path is open)
	input [11:0] lft_IR, rght_IR;					// IR readings (decrease closer object (maze wall) is)
	input signed [8:0] IR_Dtrm;					// Derivative of IR readings, comes from sensor_intf block
	input en_fusion;						// IR fused with gyro only when moving at decent speed
	input signed [11:0] dsrd_hdng;					// Desired heading of MazeRunner (comes from cmd_proc)
	output signed [11:0] dsrd_hdng_adj;			// What we are making….the adjusted desired heading

	parameter NOM_IR = 12'h900;
	
	wire signed [12:0] IR_diff;
	wire signed [11:0] div_ext;
	wire signed [12:0] sum_IR_Dtrm;
	
	assign IR_diff = {1'd0, lft_IR} - {1'd0, rght_IR};
	assign div_ext = (lft_opn & rght_opn) ? 12'h000 : 
					lft_opn ? (NOM_IR - rght_IR) : 
					rght_opn ? (lft_IR - NOM_IR) : IR_diff[12:1];
	assign sum_IR_Dtrm = {{6{div_ext[11]}}, div_ext[11:5]} + {{2{IR_Dtrm[8]}}, {IR_Dtrm[8:2], 2'd0}};
	assign dsrd_hdng_adj = en_fusion ? (dsrd_hdng + sum_IR_Dtrm[12:1]) : dsrd_hdng;
	
endmodule