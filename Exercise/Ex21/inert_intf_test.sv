module inert_intf_test(clk, RST_n, MISO, INT, SS_n, SCLK, MOSI, LED);
	input reg clk, RST_n;
	input reg MISO, INT;
	output reg SS_n, SCLK, MOSI;
	output reg [7:0] LED;
	
	typedef enum reg [1:0]{IDLE, DISP, CAL} state_t;
	state_t state, nxt_state;
	
	logic [16:0] tmr;
	logic sel;
	
	reg rst_n;
	reg strt_cal, cal_done;
	reg [12:0] heading;
	reg rdy;
	
	localparam FAST_SIM = 1;
	
	reset_synch iRESET(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));
	inert_intf #(FAST_SIM) iINTF(.clk(clk),.rst_n(rst_n),.strt_cal(strt_cal),.cal_done(cal_done),.heading(heading),.rdy(rdy),.IR_Dtrm(9'h0),
								.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),.INT(INT),.moving(1'b1),.en_fusion(1'b0));
	
	//////////////////////////////////////////////////////
	/////////////////// State Machine ////////////////////
	//////////////////////////////////////////////////////
	always_comb begin
		sel = 1'b0;
		strt_cal = 1'b0;
		nxt_state = state;
		case(state)
			IDLE: begin
				sel = 1'b0;
				if(&tmr) begin	// After 17-bit timer is full, asserts strt_cal
					nxt_state = CAL;
					strt_cal = 1'b1;
				end
			end
			CAL: begin
				sel = 1'b1; // calibration is asserts
				if(cal_done) nxt_state = DISP; // waits for cal_done
			end
			DISP: begin
				sel = 1'b0; // calibration is over
			end
		endcase
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= IDLE;
		else state <= nxt_state;
	end
	
	//////////////////////////////////////////////////////
	////////////// 17-bit free running timer /////////////
	//////////////////////////////////////////////////////
	always_ff @(posedge clk) begin
		if(!rst_n) tmr <= 17'b0;
		else tmr <= tmr + 1'b1;
	end
	
	//////////////////////////////////////////////////////////////////////////////
	//  While in calibration is asserts sel, constant 0xA5 is display on LED.	//
	//  Once calibration is over, the LEDs will display upper 8-bits of heading.//
	//////////////////////////////////////////////////////////////////////////////
	assign LED = (sel) ? 8'hA5 : heading[11:4];
	
endmodule