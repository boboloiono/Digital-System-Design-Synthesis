module dff(D,clk,Q);

input D;
input clk;
output reg Q;

always @(posedge clk)
  Q <= D;
  
endmodule