module ex03_tb();
logic d, rstn, clk, q;
ex03 iDUT(.d(d), .rstn(rstn), .clk(clk), .q(q));

// Generate clok
always #5 clk = ~clk;

// Testcase
initial begin
	clk = 0;
	d = 0;
	rstn = 1;	// reset is high initially and then
	#5 rstn = 0;	// active circuit at low
	repeat (10) @(negedge clk) d = !d;
	#50 $stop();
end

endmodule