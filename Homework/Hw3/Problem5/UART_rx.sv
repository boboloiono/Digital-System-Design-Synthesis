module UART_rx(clk, rst_n, RX, clr_rdy, rx_data, rdy);
	input clk, rst_n, RX, clr_rdy;
	output reg [7:0] rx_data;
	output reg rdy;
	
	logic state, nxt_state;
	localparam START = 0, RECIEVING = 1;
	
	logic start, recieving, set_rdy;
	
	reg [11:0]	baud_cnt;
	reg [8:0]	rx_shift_reg;
	reg [3:0]	bit_cnt;
	reg RX_ff1, RX_ff2;
	
	assign shift = (baud_cnt==12'h0) ? 1 : 0;
	
	always_comb begin
		start = 1'b0;
		recieving = 1'b0;
		set_rdy = 1'b0;
		nxt_state = state;
		case(state) 
			START: begin
				if(RX_ff2==1'b0) begin
					start = 1'b1;
					nxt_state = RECIEVING;
				end
			end
			RECIEVING: begin
				recieving = 1'b1;
				if(bit_cnt == 10 && baud_cnt == 0) begin
					set_rdy = 1'b1;
					nxt_state = START;
				end
			end
		endcase
	end
	
	always_ff @(posedge clk) begin
		// after each data transmitted, we sample each data at half to make sure the data is though and correct
		if (start) baud_cnt <= 12'd1302;
		else if (shift) baud_cnt <= 12'd2604;
		else if (recieving) baud_cnt <= baud_cnt - 1'b1;
		else baud_cnt <= baud_cnt;
	end
	
	always_ff @(posedge clk) begin
		if(shift) begin
			rx_shift_reg <= {RX_ff2, rx_shift_reg[8:1]}; // ??
			rx_data <= rx_shift_reg[7:0]; //???
		end
		else rx_shift_reg <= rx_shift_reg;
	end
	
	always_ff @(posedge clk) begin
		if(start) bit_cnt <= 4'h0;
		else if(shift) bit_cnt <= bit_cnt + 1'b1;
		else bit_cnt <= bit_cnt;
	end
	
	// Reset = 0, Set = 1
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) rdy <= 1'b0;
		else if(start | clr_rdy) rdy <= 1'b0;
		else if(set_rdy) begin
			$display("set_rdy", $time);
			rdy <= 1'b1;
		end
	end
	
	// meta-stability
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) RX_ff1 <= 1'b1;				// meta-stability flops on RX should be preset
		else RX_ff1 <= RX;
	end
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) RX_ff2 <= 1'b1;
		else RX_ff2 <= RX_ff1;
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= 1'b0;
		else state <= nxt_state;
	end
	
endmodule