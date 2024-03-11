module UART_rx(clk, rst_n, RX, clr_rdy, rx_data, rdy);
	input clk, rst_n, RX, clr_rdy;
	output reg [7:0] rx_data;
	output reg rdy;
	
	typedef enum reg {START, RECIEVING} state_i;
	state_i state, nxt_state;
	
	reg [11:0]	baud_cnt;
	reg [8:0]	rx_shift_reg;
	reg [3:0]	bit_cnt;
	reg RX_ff1, RX_ff2;
	logic start, recieving, set_rdy;
	
	assign shift = (baud_cnt==0) ? 1 : 0;
	
	always_comb begin
		start = 1'b0;
		recieving = 1'b0;
		set_rdy = 1'b0;
		nxt_state = state;
		case(state) 
			START: begin
				if(RX_ff2==1'b0) begin	// RX_ff2 == 1'b1 is in reset. So if RX_ff2 is not equal to 1'b1, it is getting recieve data. 
					start = 1'b1;
					nxt_state = RECIEVING;
				end
			end
			default: begin
				recieving = 1'b1;
				// shift a total of 10 times. Start bit will “fall off the end” of the 9-bit shift register.
				if(bit_cnt == 10) begin
					set_rdy = 1'b1;
					nxt_state = START;
				end
			end
		endcase
	end
	
	// for falling edge of Start bit. Counts off ½ a bit time and starts shifting
	// after each data transmitted, we sample each data at half to make sure the data is though and correct
	always_ff @(posedge clk) begin
		if (start) baud_cnt <= 12'd1302;
		else if (shift) baud_cnt <= 12'd2604;
		else if (recieving) baud_cnt <= baud_cnt - 1'b1;
	end
	
	// use rx_shift_reg to store shifted rx_data
	always_ff @(posedge clk) begin
		if(shift) begin
			rx_shift_reg <= {RX_ff2, rx_shift_reg[8:1]};
		end
	end
	
	// reciever get from rx_shift_reg directly exclusive MSB
	assign rx_data = rx_shift_reg[7:0];
	
	always_ff @(posedge clk) begin
		if(start) bit_cnt <= 4'h0;
		else if(shift) bit_cnt <= bit_cnt + 1'b1;
		else bit_cnt <= bit_cnt;
	end
	
	// Reset = 0, Set = 1
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) rdy <= 1'b0;
		else if(start | clr_rdy) rdy <= 1'b0;
		else if(set_rdy) rdy <= 1'b1;
	end
	
	// meta-stability
	// meta-stability flops on RX should be preset
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) RX_ff1 <= 1'b1;
		else RX_ff1 <= RX;
	end
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) RX_ff2 <= 1'b1;
		else RX_ff2 <= RX_ff1;
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= START;
		else state <= nxt_state;
	end
	
endmodule