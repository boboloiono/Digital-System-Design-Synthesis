module IR_Math_tb();

  reg lft_opn, rght_opn;
  reg [11:0] lft_IR, rght_IR;
  reg signed [8:0] IR_Dtrm;
  reg en_fusion;
  reg signed [11:0] dsrd_hdng;
  
  wire [11:0] dsrd_hdng_adj;
  
  localparam NOM_IR = 12'h970;

  ////////////////////////////////////////////////////////////////////////////
  // Instantiate IR_Math which adjust desired heading based on IR readings //
  //////////////////////////////////////////////////////////////////////////
  IR_Math #(NOM_IR) iDUT(.lft_opn(lft_opn),.rght_opn(rght_opn),.lft_IR(lft_IR),.rght_IR(rght_IR),
                         .IR_Dtrm(IR_Dtrm),.en_fusion(en_fusion),.dsrd_hdng(dsrd_hdng),
				         .dsrd_hdng_adj(dsrd_hdng_adj));
					 
  initial begin
    lft_opn = 1'b0;
	rght_opn = 1'b1;
	lft_IR = 12'hC00;
	rght_IR = 12'h840;
	IR_Dtrm = 9'h180;	// negative 0x80
	en_fusion = 1'b0;	// no fusion at first
	dsrd_hdng = 12'hABC;	// first desired heading
	
	/////////////////////////////////////////////////////
	// With en_fusion low _adj should match dsrd_hdng //
	///////////////////////////////////////////////////
	#5;
	if (dsrd_hdng_adj!==dsrd_hdng) begin
	  $display("ERR: adjusted heading should match desired at this time");
	  $stop();
	end else
	  $display("GOOD: passed first test");
	  
	lft_opn = 1'b1;
	en_fusion = 1'b1;
	//////////////////////////////////////////////////////
	// With lft_opn & rght_opn only IR_Dtrm is in play //
	////////////////////////////////////////////////////
	#5;
	if (dsrd_hdng_adj!==12'h9bc) begin
	  $display("ERR: adjusted heading only be affected by IR_Dtrm (which is negative)");
	  $stop();
	end else
	  $display("GOOD: passed second test");	
 
 	IR_Dtrm = 9'h060;
	/////////////////////////////////////////////////////////////////////
	// With lft_opn & rght_opn only IR_Dtrm is in play (now positive) //
	//////////////////////////////////////////////////////////////////
	#5;
	if (dsrd_hdng_adj!==12'hb7c) begin
	  $display("ERR: adjusted heading only be affected by IR_Dtrm (which is positive)");
	  $stop();
	end else
	  $display("GOOD: passed third test");	
 
	lft_opn = 1'b1;
	rght_opn = 1'b0;
	IR_Dtrm = 9'h00;
	//////////////////////////////////////////////////
	// Right IR reading vs NOM_IR results in + adj //
	////////////////////////////////////////////////
	#5;
	if (dsrd_hdng_adj!==12'hac0) begin
	  $display("ERR: adjusted affected by positive NOM_IR - IR_rght (of 0x130)");
	  $stop();
	end else
	  $display("GOOD: passed fourth test");	
 
 	rght_IR = 12'h730;			// increase adjust more positive
	IR_Dtrm = 9'h5F;			// change sign of IR_Dtrm
	//////////////////////////////////////////////////
	// Right IR reading vs NOM_IR results in + adj //
	////////////////////////////////////////////////
	#5;
	if (dsrd_hdng_adj!==12'hb83) begin
	  $display("ERR: adjusted affected by positive NOM_IR - IR_rght (of 0x240)");
	  $stop();
	end else
	  $display("GOOD: passed fifth test");
	  
 	lft_opn = 1'b0;
	rght_opn = 1'b1;
	/////////////////////////////////////////////////
	// Left IR reading vs NOM_IR results in + adj //
	///////////////////////////////////////////////
	#5;
	if (dsrd_hdng_adj!==12'hb84) begin
	  $display("ERR: adjusted affected by positive IR_lft - NOM_IR (of 0x290)");
	  $stop();
	end else
	  $display("GOOD: passed sixth test");

 	lft_IR = 12'h730;
	IR_Dtrm = 9'h180;		// take Dtrm negative again
	/////////////////////////////////////////////////
	// Left IR reading vs NOM_IR results in - adj //
	///////////////////////////////////////////////
	#5;
	if (dsrd_hdng_adj!==12'h9b3) begin
	  $display("ERR: adjusted affected by positive IR_lft - NOM_IR (which is negative)");
	  $stop();
	end else
	  $display("GOOD: passed seventh test");

 	lft_IR = 12'hA00;
	rght_opn = 1'b0;
	IR_Dtrm = 9'h000;		// remove Dtrm from the picture
	////////////////////////////////////////////
	// Now it is left - right which is + adj //
	//////////////////////////////////////////
	#5;
	if (dsrd_hdng_adj!==12'hac1) begin
	  $display("ERR: adjusted affected by positive IR_lft - IR_rght");
	  $stop();
	end else
	  $display("GOOD: passed eighth test");	  
	  
	  
    $display("YAHOO!! all tests passed");
	$stop();
	
  end
  
endmodule
  