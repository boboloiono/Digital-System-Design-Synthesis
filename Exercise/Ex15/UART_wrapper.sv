module UART_wrapper(clk, rst_n, RX, cmd_rdy, cmd, clr_cmd_rdy, trmt, resp, tx_done, TX);
	input clk, rst_n, trmt, RX;
	input [7:0] resp;
	input clr_cmd_rdy;
	output reg cmd_rdy;
	output wire tx_done, TX;
	output wire [15:0] cmd;
	
	reg rx_rdy, clr_rx_rdy; 
	reg [7:0] rx_data, tx_data;
	
	localparam IDLE = 0, LOW = 1, HIGH = 2;
	reg [1:0] state, nxt_state;
	reg en_hld, set_cmd_rdy;
	reg [7:0] cmd_reg;
	
	UART iUART(.clk(clk),.rst_n(rst_n),.RX(RX),.TX(TX),.rx_rdy(rx_rdy),.clr_rx_rdy(clr_rx_rdy),.rx_data(rx_data),.trmt(trmt),.tx_data(tx_data), .tx_done(tx_done));
	
	assign tx_data = (trmt) ? resp : 8'b0;
	
	always_comb begin
		nxt_state = state;
		case(state)
			IDLE: begin
				if(rx_rdy) begin
					nxt_state = HIGH;
					en_hld = 1;
					clr_rx_rdy = 1;
				end
			end
			HIGH: begin
				if(rx_rdy) begin
					en_hld = 0;
					nxt_state = LOW;
				end
			end
			LOW: begin
				set_cmd_rdy = 1;
				nxt_state = IDLE;
			end
		endcase
	end
	
	always_ff @(posedge clk) begin
		if(en_hld) cmd_reg <= rx_data;
	end
	assign cmd = {cmd_reg, rx_data};
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) cmd_rdy <= 1'b0;
		else if(set_cmd_rdy) cmd_rdy <= 1'b1;
		else if(en_hld | clr_cmd_rdy) cmd_rdy <= 1'b0;
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= IDLE;
		else state <= nxt_state;
	end
endmodule