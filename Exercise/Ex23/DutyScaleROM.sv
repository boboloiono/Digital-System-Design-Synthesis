module DutyScaleROM(clk,batt_level,scale);

  input clk;
  input [5:0] batt_level;
  output [12:0] scale;
  
  reg [11:0]scaleMem[0:63];
  reg [11:0] entry;
  
  assign scale = {1'b0,entry};	// make it 13-bit positive number
  
  always @(posedge clk)
    entry = scaleMem[batt_level];
	
  initial
    $readmemh("DutyScale.hex",scaleMem);
	
endmodule
  
  