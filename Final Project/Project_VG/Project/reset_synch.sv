module reset_synch(input clk, input RST_n, output reg rst_n);
	reg rst_n_pre;
	always_ff @(negedge clk) begin
		if(!RST_n) begin
			rst_n_pre <= 1'b0;
			rst_n <= 1'b0;
		end else begin
			rst_n_pre <= 1'b1;
			rst_n <= rst_n_pre;
		end
	end
endmodule