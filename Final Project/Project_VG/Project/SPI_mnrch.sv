module SPI_mnrch(
	// Initializing the signals.
	input clk, rst_n,
	input wrt,
	input [15:0] cmd,
	output logic done,
	output [15:0] rspns,
	input MISO,
	output SCLK,MOSI,
	output logic SS_n
);
	
	//other declared logics
	logic MISO_smpl;
	logic init, shft, smpl; // for the state machine
	logic [15:0] shft_reg;
	logic [3:0] bit_cntr;
	logic done15; // input for the state machine
	logic ld_SCLK;
	logic [4:0]SCLK_div;
	logic set_done; // output of the state machine
	
	typedef enum logic [1:0] {IDLE, SMPL_WAIT, MAIN, BACK_PORCH} state_t;
	state_t state, nxt_state;
	
	//logic for MISO_smpl
	always_ff @(posedge clk)
		if(smpl)
			MISO_smpl <= MISO; // sampling otherwise keeping the same value
			
	
	//logic for the shift register
	always_ff @(posedge clk)
		if(init)
			shft_reg <= cmd; // getting the data.
		else if(shft)
			shft_reg <= {shft_reg[14:0], MISO_smpl}; // shifting occurs
	
	assign MOSI = shft_reg[15];
			
	
	//logic for the bit counter
	always_ff @(posedge clk)
		if(init)
			bit_cntr <= 4'b0000;
		else if(shft)
			bit_cntr <= bit_cntr + 1;
	
	assign done15 = &bit_cntr; // checking if the counter is at 15.
	
	//SCLK_div logic
	always_ff @(posedge clk)
		if(ld_SCLK)
			SCLK_div <= 5'b10111;
		else
			SCLK_div <= SCLK_div + 1;
	
	assign SCLK = SCLK_div[4];
	
	 //SM
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
		
   //SM control
always_comb begin
// inializing the outputs to prevent latches
init = 0;
ld_SCLK = 0;
nxt_state = state;
smpl = 0;
shft = 0;
set_done = 0 ;

case(state)
	default: begin // is IDLE
		ld_SCLK = 1;
		if(wrt) begin
			init = 1;
			nxt_state = SMPL_WAIT;
		end
	end
	
	SMPL_WAIT: begin
		if (SCLK_div == 5'b01111) begin // only sampling
			smpl = 1;
			nxt_state = MAIN;
		end
	end
	
	MAIN: begin
		// the main state where both sampling and shifting takes place
		if (SCLK_div == 5'b01111) begin
			smpl = 1;
		end
		if (SCLK_div == 5'b11111) begin
			shft = 1;
		end
		if(done15) nxt_state = BACK_PORCH; // after 15 samples 
	end 
	
	BACK_PORCH: begin
		if (SCLK_div == 5'b01111) begin
			smpl = 1;
		end
		if (SCLK_div == 5'b11111) begin
			shft = 1;
			ld_SCLK = 1; // clear
			set_done = 1;
			nxt_state = IDLE; // back to IDLE waiting for further instructions.
		end
	end

endcase

end

//flop for SS_n;

always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		SS_n <= 1;
	else if(init)
		SS_n <= 0;
	else if(set_done)
		SS_n <= 1;

// flop for done
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		done <= 0;
	else if(init)
		done <= 0;
	else if(set_done)
		done <= 1;	

assign rspns = shft_reg; // 
	

endmodule
