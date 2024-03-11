module mult_accum(clk,clr,en,A,B,accum);

input clk,clr,en;
input [15:0] A,B;
output reg [63:0] accum;

reg [31:0] prod_reg;
reg en_stg2;

wire gclk1, gclk2;
reg Q1, Q2;

///////////////////////////////////////////
// Generate and flop product if enabled //
/////////////////////////////////////////
always_ff @(posedge gclk1)
	prod_reg <= A*B;

/////////////////////////////////////////////////////
// Pipeline the enable signal to accumulate stage //
///////////////////////////////////////////////////
always_ff @(posedge clk)
    en_stg2 <= en;

always_ff @(posedge gclk2)
    if (clr) accum <= 64'h0000000000000000;
	else accum <= accum + prod_reg;

/////////////// gate 1 /////////////////
always_latch
	if (!clk) Q1 = en;

assign gclk1 = clk & Q1;

////////////// gate 2 /////////////////
always_latch
	if(!clk) Q2 = en_stg2 | clr;

assign gclk2 = clk & Q2;


endmodule
