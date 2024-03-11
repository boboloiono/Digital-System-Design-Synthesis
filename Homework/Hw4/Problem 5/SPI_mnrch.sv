module SPI_mnrch(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, wt_data, done, rd_data);
	input clk, rst_n;			// 50MHz system clock and reset
	output logic SS_n, SCLK, MOSI;	// SPI protocal signal: 3 out 1 in
	input MISO;					// SPI protocal signal: 3 out 1 in
	input wrt;					// A high for 1 clock period would initiate a SPI transaction
	input [15:0] wt_data;		// Date(command) begin sent to inertial sensor
	output reg done;			// Asserted when SPI transaction is complete. Should stay assertted till next wrt
	output reg [15:0] rd_data;	// Data from SPI serf. For internal sensor we will only ever use [7:0]
	
	reg [15:0] shft_reg;
	reg [4:0] SCLK_div;
	reg [3:0] bit_cntr;
	reg MISO_smpl;
	
	logic ld_SCLK, init, smpl, shft, set_done;
	
	typedef enum reg [1:0] {IDLE, FWRD_PRCH, BITS, BACK_PRCH} state_t;
	state_t state, nxt_state;
	
	///////////////////////////////////////////////////////////////
	/////////// "bit_cntr" to keep track of how many //////////////
	/////////// times the shift regiter has shifted. //////////////
	///////////////////////////////////////////////////////////////
	
	always @(posedge clk) begin
		if(init) bit_cntr <= 4'b0000;
		else if(shft) bit_cntr <= bit_cntr + 1'b1;
		else bit_cntr <= bit_cntr;
	end
	
	//////////////////////////////////////////////////////////////
	///////////////////////// SCLK_div //////////////////////////
	//////////////////////////////////////////////////////////////

	always @(posedge clk) begin
		// A synchronous reset of SCLK_div to a value like 10111 can help with the creation of a “front porch”.
		if(ld_SCLK) SCLK_div <= 5'b10111;
		else SCLK_div <= SCLK_div + 1'b1;
	end
	
	assign SCLK = SCLK_div[4];

	/////////////////////////////////////////////////////////////////
	/////////////////// MISO_smple and shft_reg /////////////////////
	////////////////////////////////////////////////////////////////
	
	// SCLK
	always @(posedge clk) begin
		if(smpl) MISO_smpl <= MISO;
		else MISO_smpl <= MISO_smpl;
	end
	
	// SCLK
	always @(posedge clk) begin
		if(init) shft_reg <= wt_data;
		else if(!init & shft) shft_reg <= {shft_reg[14:0], MISO_smpl};
		else shft_reg <= shft_reg;
	end
	
	assign MOSI = shft_reg[15];
	assign rd_data = shft_reg;
	
	/////////////////////////////////////////////////////////////
	///////////////////// SPI SM Implement /////////////////////
	////////////////////////////////////////////////////////////
	
	////// SS_n should be preset
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) SS_n <= 1'b1;
		else if(init) SS_n <= 1'b0;
		else if(set_done) SS_n <= 1'b1;
	end
	////// done should be reset
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) done <= 1'b0;
		else if(init) done <= 1'b0;
		else if(set_done) done <= 1'b1;
	end
	
	always_comb begin
		ld_SCLK = 1'b0;
		init = 1'b0;
		set_done = 1'b0;
		shft = 1'b0;
		smpl = 1'b0;
		nxt_state = state;
		case(state)
			IDLE: begin
				ld_SCLK = 1'b1;
				if(wrt) begin
					init = 1'b1;
					nxt_state = FWRD_PRCH;
				end
			end
			FWRD_PRCH: begin
				if(&SCLK_div) begin
					nxt_state = BITS;
				end
			end
			BITS: begin
				///////// when that 6 bit counter equals 5'b01111, SCLK "rise" happens on the next clk.
				smpl = (SCLK_div == 5'b01111) ? 1'b1 : 1'b0;
				///////// when that 5 bit counter equals 5'b11111, SCLK "fall" happens on the next clk.
				shft = (&SCLK_div) ? 1'b1 : 1'b0;
				if(&bit_cntr) // bit_cntr==15 means transaction is complete.
					nxt_state = BACK_PRCH;
			end
			BACK_PRCH: begin
				smpl = (SCLK_div == 5'b01111) ? 1'b1 : 1'b0;
				if(&SCLK_div) begin
					shft = 1'b1;
					set_done = 1'b1;
					nxt_state = IDLE;
				end
			end
		endcase
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= IDLE;
		else state <= nxt_state;
	end
endmodule