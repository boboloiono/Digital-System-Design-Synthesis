module cmd_proc(clk, rst_n, cmd, cmd_rdy, clr_cmd_rdy, send_resp, strt_cal, cal_done, in_cal, sol_cmplt,
				strt_hdng, strt_mv, stp_lft, stp_rght, dsrd_hdng, mv_cmplt, cmd_md);
	
	input clk, rst_n;
	
	// to/from UART_WRAPPER;
	input [15:0] cmd;
	input cmd_rdy;
	output logic clr_cmd_rdy, send_resp;
	
	// from/to inert_inft
	input cal_done;
	output logic strt_cal, in_cal;
	
	// Magnet found
	input sol_cmplt;
	
	// to navigate
	input mv_cmplt;
	output logic strt_hdng, strt_mv, stp_lft, stp_rght;
	output logic [11:0] dsrd_hdng;
	
	// navigate muxing
	output logic cmd_md;		// to determines whether control signals to navigate unit
								// come from "cmd_proc", or "maze_solve" unit.	logic cmd_snt;	logic resp_rdy
	
	logic hdng_rdy;				// used to pace frwrd_spd increments
	logic at_hdng;				// asserted by PID when new heading is close enough
	logic lft_opn;				// from IR sensor....indicates opening in maze to left
	logic rght_opn;				// from IR sensor....indicates opening in maze to right
	logic frwrd_opn;			// from IR sensor....indicates opening in front
	logic moving;				// should be asserted at all times not in IDLE
	logic en_fusion;			// should be asserted whenever frwrd_spd>MAX_FRWRD
	logic [10:0] frwrd_spd;		// the primary output...forward motor speed

	logic stp_lft_en, stp_rght_en, dsrd_hdng_en;
	
	typedef enum logic[2:0] {IDLE, CAL, HEADING, MOVE, SOLVE_MAZE, WAIT} state_t;
	state_t state, nxt_state;
	
	always_comb begin
		strt_cal = 1'b0;
		in_cal = 1'b0;
		send_resp = 1'b0;
		dsrd_hdng_en = 12'b0;
		strt_hdng = 1'b0;
		stp_lft_en = 1'b0;
		stp_rght_en = 1'b0;
		strt_mv = 1'b0;
		cmd_md = 1'b1;
		clr_cmd_rdy = 1'b0;
		nxt_state = state;
		case(state)
			IDLE: begin
				if(cmd_rdy) begin
					clr_cmd_rdy = 1'b1;
					if(cmd[15:13]==3'b000) begin
						strt_cal = 1'b1;
						nxt_state = CAL;
					end else if (cmd[15:13]==3'b001) begin
						// dsrd_hdng_reg = cmd[11:0];
						dsrd_hdng_en = 1'b1;
						strt_hdng = 1'b1;
						nxt_state = HEADING;
					end else if (cmd[15:13]==3'b010) begin
						strt_mv = 1'b1;
						stp_lft_en = cmd[1];	// bit[1] means movement should stop at a left
						stp_rght_en = cmd[0];	// bit[0] means movement should stop at a right
						nxt_state = MOVE;
					end else if (cmd[15:13]==3'b011) begin
						cmd_md = 1'b0;
						nxt_state = SOLVE_MAZE;
					end
				end
			end
			CAL: begin
				in_cal = 1'b1;	// only between strt_cal and cal_don
				if(cal_done) begin
					send_resp = 1'b1;
					in_cal = 1'b0;
					nxt_state = IDLE;
				end
			end
			HEADING: begin // HEAD_OR_MOVE so that we dont need default state
				if(mv_cmplt) begin
					send_resp = 1'b1;
					nxt_state = IDLE;
				end
			end
			MOVE: begin
				// cmd[0] determines affinity.
				// 1 -> left affinity, 0 -> right affinity
				if(mv_cmplt) begin
					send_resp = 1'b1;
					nxt_state = IDLE;
				end
			end
			SOLVE_MAZE: begin
				cmd_md = 1'b0;
				// sol_cmpt asserts when the hall sensor detects a magnet.
				if(sol_cmplt) begin
					nxt_state = IDLE;
				end
			end
			default: begin
				if(cmd_rdy) begin
					clr_cmd_rdy = 1'b1;
					nxt_state <= IDLE;
				end
			end
		endcase
	end
	
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= IDLE;
		else state <= nxt_state;
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			stp_lft <= 1'b0;
			stp_rght <= 1'b0;
			dsrd_hdng <= 12'b0;
		end
		else if(dsrd_hdng_en) dsrd_hdng <= cmd[11:0];
		else if(stp_lft_en) stp_lft <= 1'b1;
		else if(stp_rght_en) stp_rght <= 1'b1;
		else if(mv_cmplt) begin
			stp_lft <= 1'b0;
			stp_rght <= 1'b0;
			dsrd_hdng <= 12'b0;
		end
	end
endmodule