module UART_rx(
	input clk, rst_n,		// 50MHz system clock & asynch active low reset
	input RX,				// serial data input
	input clr_rdy,			// makes rdy low
	output [7:0]rx_data,	
	output logic rdy		
);

	logic start;				
	logic receiving;			
	logic set_rdy;				
	logic shift;				
	logic [8:0]rx_shft_reg;		
	logic [11:0]baud_cnt;		// baud counter
	logic [3:0]bit_cnt;			// bit counter
	logic RX_FF2;				// double flopped RX input
	logic RX_FF1;				// first flopped value

	typedef enum logic {IDLE, RECEIVING} state_t;
	state_t state, nxt_state;

	// double flop RX to synchronize
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			// pre set RX_FF2 for UART
			RX_FF1 <= 1'b1;
			RX_FF2 <= 1'b1;
		end
		else begin
			RX_FF1 <= RX;
			RX_FF2 <= RX_FF1;
		end

	// the shift register
	always_ff @(posedge clk)
		if(shift)
			rx_shft_reg <= {RX_FF2, rx_shft_reg[8:1]};		// append the data with a start bit

	assign rx_data = rx_shft_reg[7:0];		

	// the baud counter
	always_ff @(posedge clk)
		if(start)
			baud_cnt <= 12'd1302;		// set the baud counter to half of a baud period at the start of a RECEIVINGiving
		else if(shift)
			baud_cnt <= 12'd2604;		// set the baud counter to the full baud period when shifting
		else if(receiving)
			baud_cnt <= baud_cnt - 1;		// count up when transmitting

	assign shift = (baud_cnt == 12'h000);		// assert shift when baud_cnt reaches 0

	// the bit counter
	always_ff @(posedge clk)
		if(start)
			bit_cnt <= 4'h0;		// reset the bit counter if init is asserted
		else if(shift)
			bit_cnt <= bit_cnt + 1;		// count up when shifted a bit

	// SM state register
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
			
	// control SM
	always_comb begin
		
		nxt_state = state;
		start = 1'b0;
		receiving = 1'b0;
		set_rdy = 1'b0;
		
		case(state)
			RECEIVING: begin
				receiving = 1'b1;
				if(bit_cnt == 4'd10) begin		// finish receiving when all 10 bits are received.
					set_rdy = 1'b1;
					nxt_state = IDLE;
				end
			end
			default:			// is IDLE
				if(RX_FF2 == 1'b0) begin			// wait until RX is low to begin receiving
					start = 1'b1;
					nxt_state = RECEIVING;
				end
		endcase
	end

	// SR flop generating tx_done, set_rdy is S, (start | clr_rdy) is R
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			rdy <= 1'b0;
		else if(start | clr_rdy)
			rdy <= 1'b0;
		else if(set_rdy)
			rdy <= 1'b1;

endmodule