module RemoteComm(clk, rst_n, RX, TX, cmd, send_cmd, cmd_sent, resp_rdy, resp);

input clk, rst_n;		// clock and active low reset
input RX;				// serial data input
input send_cmd;			// indicates to tranmit 24-bit command (cmd)
input [15:0] cmd;		// 16-bit command

output TX;				// serial data output
output logic cmd_sent;		// indicates transmission of command complete
output resp_rdy;		// indicates 8-bit response has been received
output [7:0] resp;		// 8-bit response from DUT


//<<<  Your declaration stuff here >>>
logic sel;
logic trmt;
logic set_cmd_sent;
logic tx_done;
logic [7:0] low_byte;
logic [7:0] tx_data;

///////////////////////////////////////////////
// Instantiate basic 8-bit UART transceiver //
/////////////////////////////////////////////
UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
           .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(resp_rdy));

//<<< Your implementation here >>>
typedef enum logic [1:0] {IDLE, HIGH, LOW} state_t;
state_t state, nxt_state;

  //SM
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
		
   //SM control
always_comb begin
	// default the outputs to prevent latches
	nxt_state  = state;
	trmt = 0;
	sel = 0;
	set_cmd_sent = 0;
	case(state)
		default: begin // is IDLE
			if(send_cmd)begin  // if send_cmd we begin the process
				sel = 1;
				trmt = 1;
				nxt_state = HIGH; // high byte is processed first
			end
		end
		
		HIGH: begin
			if(tx_done) begin
				trmt = 1;
				nxt_state = LOW; // after done, low byte is processed. 
			end
		end
		
		LOW: begin
			if(tx_done) begin
				set_cmd_sent = 1; // letting the wrapper know both bytes are sent.
				nxt_state = IDLE; // switching to IDLE and wait for further instructions.
		    end
		end
	endcase	
end

// logic for send_cmd
always_ff @(posedge clk)
	if(send_cmd)
		low_byte <= cmd[7:0];

assign tx_data = (sel)? cmd[15:8] : low_byte; // sel asserts the high byte to process.

// logic for cmd_sent
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		cmd_sent <= 1'b0;
	else if(send_cmd)
		cmd_sent <= 1'b0;
	else if(set_cmd_sent)
		cmd_sent <= 1'b1;

endmodule	
