module ex03(d, rstn, clk, q);

input d, rstn, clk;
output q;
wire md, mq, sd;

// asynch active low reset signal
// and			and0(d_in, !rstn, d); //!rstn = 1

notif1 #1	trinot1(md, d, !clk);
not 		inv1(mq, md);
// not (weak0, weak1)	inv2(md, mq);
and			and1(md, rstn, mq);	// asyn low
notif1 #1	trinot2(sd, mq, clk);
not			inv3(q, sd);
// not (weak0, weak1)	inv4(sd, q);
and			and2(sd, rstn, q);

endmodule