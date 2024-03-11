module ex03(d, rstn, clk, q);

input d, rstn, clk;
output q;
wire d_in, md, mq, sd;

// asynch active low reset signal
and			and0(d_in, !rstn, d); //!rstn = 1

notif1 #1	trinot1(md, d_in, !clk);
not 		inv1(mq, md);
not (weak0, weak1)	inv2(md, mq);
notif1 #1	trinot2(sd, mq, clk);
not			inv3(q, sd);
not (weak0, weak1)	inv4(sd, q);

endmodule