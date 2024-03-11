// a. The comments about the latch
module latch(d,clk,q);
 input d, clk;
 output reg q;
 
 always @(clk) // -> always @(d), because latch changes on any of these signals can cause the output to change state instead of waiting for the clk changing.
	 if (clk)
	 q <= d;
endmodule

// b. D-FF with an active low synchronous reset
module D_ff(input d, input clk, input rstn, output reg q);
	always @(posedge clk) begin
		if(!rstn) q <= 1'b0;
		else q <= d;
	end
endmodule

// c. D-FF with asynchronous active low reset and an active high enable
module D_ff(input d, input clk, input rstn, input en, output reg q);
	always @(posedge clk or negedge rstn) begin
		if(!rstn) q <= 1'b0;
		else if (en) q <= d;
	end
endmodule

// d. SR-FF with active low asynchronous reset.
module SR_ff(input s, input r, input clk, input rstn, output q, output q_bar);

	reg s, r, clk;
	reg q, q_bar;
	 
	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			q <= 1'b0;
			q_bar <= 1'b1;
		end
		else begin
			case({s,r})
			{1'b0,1'b0}: begin q<=q; q_bar<=q_bar; end
			{1'b0,1'b1}: begin q<=1'b0; q_bar<=1'b1; end
			{1'b1,1'b0}: begin q<=1'b1; q_bar<=1'b0; end
			{1'b1,1'b1}: begin q<=1'bx; q_bar<=1'bx; end
			endcase
		end
	end
	
endmodule

// e. Does the use of the always_ff construct ensure the logic will infer a flop?
// Yes! 
// We can only use non-blocking statements when we are modeling sequential logic circuits in always_ff blocks. Moreover, we need to include a sensitivity list when using the SystemVerilog always_ff block.
// However, the latch should be written in combinational logic and don't need a sensitivity list. Therefore, always_FF only refer to a flip.
