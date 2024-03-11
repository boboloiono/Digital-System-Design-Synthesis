module ex03_tb();
logic d, rstn, clk, q;
ex03 iDUT(.d(d), .rstn(rstn), .clk(clk), .q(q));

// Testcase
initial begin
	clk = 0;
	d = 0;
	rstn = 1;	// reset is high initially and then
	// active circuit at low
	d = 1;
	repeat (1) @(posedge clk);
	#3 rstn = 0;	// active circuit at low
	repeat (1) @(negedge clk);
	#3 rstn = 1;
	repeat (8) @(posedge clk);
	#3 rstn = 0;
	//#17 rstn = 1;
	#50 $stop();
end

// Generate clok
always #5 clk <= ~clk;

endmodule