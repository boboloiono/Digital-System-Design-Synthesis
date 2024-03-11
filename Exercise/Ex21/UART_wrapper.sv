module UART_wrapper(clk, rst_n, RX, cmd_rdy, cmd, clr_cmd_rdy, trmt, resp, tx_done, TX);
	input clk, rst_n, trmt;
	input RX;				// Receive line from Bluetooth module (19200 baud)
	input [7:0] resp;		// resp is sent to Bluetooth module upon a pulse on trmt
	input clr_cmd_rdy;		// Used to knock down cmd_rdy.
	output reg cmd_rdy;		// When cmd_rdy is asserted, cmd is 16-bit command received
	output reg [15:0] cmd;
	output reg tx_done, TX;	// Transmit line to Bluetooth module
	
	logic rx_rdy, clr_rx_rdy; 
	logic [7:0] rx_data, tx_data;
	
	typedef enum reg[1:0] {IDLE, HIGH, LOW} state_t;
	state_t state, nxt_state;
	
	logic en_hld, set_cmd_rdy;
	reg [7:0] cmd_reg;
	
	UART iUART(.clk(clk),.rst_n(rst_n),.RX(RX),.TX(TX),.rx_rdy(rx_rdy),.clr_rx_rdy(clr_rx_rdy),
			.rx_data(rx_data),.trmt(trmt),.tx_data(tx_data),.tx_done(tx_done));
	
	assign tx_data = (trmt) ? resp : 8'b0;
	
	always_comb begin
		en_hld = 1'b0;
		clr_rx_rdy = 1'b0;
		set_cmd_rdy = 1'b0;
		nxt_state = state;
		case(state)
			IDLE: begin
				set_cmd_rdy = 1'b0;
				if(rx_rdy) begin
					nxt_state = HIGH;
					clr_rx_rdy = 1;
					en_hld = 1;			// hold on high byte, let rx_date store in a reg
				end
			end
			HIGH: begin
				if(rx_rdy) begin
					en_hld = 0;			// after wrap high 8 bits, close en_hld	
					nxt_state = LOW;
				end
			end
			LOW: begin
				// after high and low byte are wrapped, command is ready to recieve
				// assign rx_data to low 8 bits of command directly
				set_cmd_rdy = 1;
				clr_rx_rdy = 1;	// ?
				nxt_state = IDLE;
			end
		endcase
	end
	
	// when HIGH byte wrapping state, rx_data assign to com_reg used to store in high command
	always_ff @(posedge clk) begin
		if(en_hld) cmd_reg <= rx_data;
	end
	
	// package two bytes into asingle 16-bit command
	// low byte is wrapped directly, not need to control by ff
	assign cmd = {cmd_reg, rx_data};

	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) cmd_rdy <= 1'b0;
		else if(set_cmd_rdy) cmd_rdy <= 1'b1;
		else if(en_hld | clr_cmd_rdy) cmd_rdy <= 1'b0;
		else cmd_rdy <= 1'b0;
		// during wrapping high bytes, cmd_rdy has not asserted yet
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= IDLE;
		else state <= nxt_state;
	end
	
endmodule