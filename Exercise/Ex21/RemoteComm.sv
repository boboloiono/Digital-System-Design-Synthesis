module RemoteComm(clk, rst_n, cmd, snd_cmd, RX, cmd_snt, resp, resp_rdy, TX);
	input clk,rst_n, RX; 
	input [15:0] cmd;
	input snd_cmd;
	output reg cmd_snt, resp_rdy, TX;
	output reg [7:0] resp;
	
	logic trmt;				// in
	reg clr_rx_rdy;			// in
	logic [7:0] tx_data;	// in
	logic tx_done;			// out
	
	typedef enum reg[1:0] {IDLE, UPPER, LOWER} state_t;
	state_t state, nxt_state;
	
	logic sel;
	reg [7:0] low_reg;
	reg set_cmd_snt;
	
	// resp -> rx_data
	// rx_rdy -> resp_rdy
	UART iUART(.clk(clk),.rst_n(rst_n),.RX(RX),.TX(TX),.rx_rdy(resp_rdy),.clr_rx_rdy(clr_rx_rdy),
			.rx_data(resp),.trmt(trmt),.tx_data(tx_data),.tx_done(tx_done));
			
	always_comb begin
		trmt = 1'b0;
		sel = 1'b1;					// default select high byte
		nxt_state = state;
		case(state)
			IDLE: if(snd_cmd) begin	// start to send commend
				nxt_state = UPPER;
				trmt = 1'b1;		// transmit high
			end 
			UPPER: begin
				if(tx_done) begin
				    trmt = 1'b1;	// transmit low
					sel = 1'b0;		// select low byte
					nxt_state = LOWER;
				end
			end
			LOWER: begin
				sel = 1'b0;			// keep select low byte
				if(tx_done) begin	// after all transmit, finish the command send
					set_cmd_snt = 1'b1;
					nxt_state = IDLE;
				end
			end
		endcase
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= IDLE;
		else state <= nxt_state;
	end
	
	// use reg "set_cmd_snt" to control cmd_snt
	// only set_cmd_snt is asserted, cmd_snt could be asserted.
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) cmd_snt <= 1'b0;
		else if(set_cmd_snt) cmd_snt <= 1'b1;
		else if(snd_cmd) cmd_snt <= 1'b0;
		else cmd_snt <= 1'b0;
	end
	
	// when start to send command, set low byte of cmd to low_reg on each posedge edge
	always_ff @(posedge clk) begin
		if(snd_cmd) low_reg <= cmd[7:0];
	end
	
	// high byte of cmd would be sent to tx_data directly when seleting high byte mode
	assign tx_data = (sel) ? cmd[15:8] : low_reg;
	
endmodule