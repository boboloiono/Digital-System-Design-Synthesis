module synch_detect(asynch_sig_in, clk, rst_n, fall_edge);
input asynch_sig_in, clk, rst_n;
output fall_edge;
logic q1, q2, q3;

and rstn(asynch_sig_in_rstn, asynch_sig_in, !rst_n);
dff DFF1(.D(asynch_sig_in_rstn), .clk(clk), .Q(q1));
dff DFF2(.D(q1), .clk(clk), .Q(q2));
dff DFF3(.D(q2), .clk(clk), .Q(q3));
and (fall_edge, ~q2, q3);

endmodule