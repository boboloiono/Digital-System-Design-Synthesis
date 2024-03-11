module IR_Math (
  input clk,
  input rst_n,
  input lft_opn,
  input rght_opn,
  input [11:0] lft_IR,
  input [11:0] rght_IR,
  input signed [11:0] dsrd_hdng,
  input signed [8:0] IR_Dtrm,
  input en_fusion,
  output signed [11:0] dsrd_hdng_adj
);

  // Module implementation goes here
  parameter NOM_IR = 12'h900;
  
  logic signed [12:0] IR_diff;
  
  logic signed [11:0] temp;
 
  logic signed [12:0] div_by_32_and_ex;
  
  //IR_Dtrm logics
  logic signed [10:0]IR_Dtrm_mult;
  logic signed [12:0] sum_Div32_IR_Dtrm;
  logic signed [11:0] last_div;
  
  // P component
  assign IR_diff = {1'b0,lft_IR} - {1'b0,rght_IR};
  
  assign temp = (lft_opn && rght_opn) ? 12'h000:
		(lft_opn && !rght_opn)? (NOM_IR - rght_IR):
		(!lft_opn && rght_opn)? (lft_IR - NOM_IR):
		IR_diff[12:1];
  
  //assign div_by_32 = temp >> 5;
  assign div_by_32_and_ex = {{6{temp[11]}},temp[11:5]}; // dividing by 32 and then sign extending
  
  // IR_Dtrm .........................
  assign IR_Dtrm_mult = IR_Dtrm << 2; // multiply by 4
  
  assign sum_Div32_IR_Dtrm = div_by_32_and_ex + {{2{IR_Dtrm_mult[10]}},IR_Dtrm_mult}; // sum of the terms
  
  assign last_div = sum_Div32_IR_Dtrm >> 1;
  
  assign dsrd_hdng_adj = (en_fusion)? (last_div + dsrd_hdng): dsrd_hdng;


	
  
endmodule

