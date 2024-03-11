module UART_tx(clk, rst_n, TX, trmt, tx_data, tx_done);
	input clk, rst_n, trmt;
	input [7:0] tx_data;
	output reg TX, tx_done;
	
	reg [3:0] bit_cnt;
	reg [11:0] baud_cnt;
	reg [8:0] tx_shft_reg;
	
	logic init, transmitting, shift, set_done;
	
	typedef enum reg {IDLE, TRANSMITTING} state_t;
	state_t state, nxt_state;
	
	assign shift = (baud_cnt==12'd2604) ? 1'b1 : 1'b0;
	
	always_comb begin
		init = 1'b0;
		transmitting = 1'b0;
		set_done = 1'b0;
		nxt_state = state;
		case(state)
			IDLE: begin
				if(trmt) begin
					init = 1'b1;
					nxt_state = TRANSMITTING;
				end
			end
			default: begin
				transmitting = 1'b1;
				if(bit_cnt==4'd10) begin
					nxt_state = IDLE;
					set_done = 1'b1;
				end
			end
		endcase
	end
	
	// bit count (when counts to 10, it finish transmitting)
	always_ff @(posedge clk) begin
		if(init) bit_cnt <= 4'h0;
		else if (shift) bit_cnt <= bit_cnt + 1'b1;
	end
	
	// baud count (when counts to 2604, it will shift >> 1.)
	always_ff @(posedge clk) begin
		if(init | shift) baud_cnt <= 12'h0;
		else if (transmitting) baud_cnt <= baud_cnt + 1'b1;
	end
	
	// shift register (if shift is true, do right shifting by concate)
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) tx_shft_reg <= 9'h1FF;		// tx_shft_reg should reset to all 1's
		else if(init) tx_shft_reg <= {tx_data, 1'b0};
		else if (shift) tx_shft_reg <= {1'b1, tx_shft_reg[8:1]};
	end
	
	// tx_done (if set, done is true; if reset, done is equal to init)
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) tx_done <= 1'b0;
		else if(init) tx_done <= 1'b0;
		else if(set_done) tx_done <= 1'b1;
	end
	
	// change state by flip flop
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) state <= IDLE;
		else state <= nxt_state;
	end
	
	// set TX is the LSB of shift reg
	assign TX = tx_shft_reg[0];
	
endmodule