module maze_solve_tb();


/////////////////////////////////////////////
//////////////////////////////////////
logic clk, rst_n;		// positive edge triggered, reset active low
logic cmd_md, cmd0, lft_opn, rght_opn, mv_cmplt, sol_cmplt;
logic strt_hdng, strt_mv, stp_lft, stp_rght;
logic signed [11:0] dsrd_hdng;

logic mv_complt_ff1;
logic mv_complt_ff2;
logic mv_complt_ff3;


//module maze_solve(clk, rst_n, cmd_md, cmd0, lft_opn, rght_opn, mv_cmplt, sol_cmplt, strt_hdng, dsrd_hdng, strt_mv, stp_lft, stp_rght);

maze_solve iMaze_solve(.clk(clk), .rst_n(rst_n), .cmd_md(cmd_md), 
  .cmd0(cmd0), .lft_opn(lft_opn), .rght_opn(rght_opn), .mv_cmplt(mv_complt_ff3), 
  .sol_cmplt(sol_cmplt), .strt_hdng(strt_hdng), .dsrd_hdng(dsrd_hdng), .strt_mv(strt_mv),
  .stp_lft(stp_lft), .stp_rght(stp_rght));


assign mv_cmplt = (strt_hdng | strt_mv) ?  1 : 0;

always_ff @(posedge clk, negedge rst_n) begin
if (!rst_n) begin
mv_complt_ff1 <= mv_cmplt;
mv_complt_ff2 <= mv_complt_ff1;
mv_complt_ff3 <= mv_complt_ff2;
end else begin
mv_complt_ff1 <= mv_cmplt;
mv_complt_ff2 <= mv_complt_ff1;
mv_complt_ff3 <= mv_complt_ff2;
end
end


initial begin
clk = 0;
rst_n = 0;
@(negedge clk);
rst_n = 1;

cmd_md = 1;
cmd0 = 1;
rght_opn = 0;
lft_opn = 1; //return left
repeat (5) @(posedge clk); 
lft_opn = 0;
rght_opn = 1; //return right 
repeat (10) @(posedge clk);
lft_opn = 0;
rght_opn = 0; //no open 
repeat (10) @(posedge clk);


rst_n = 0;
repeat (10) @(posedge clk);
rst_n = 1;
cmd_md = 1;
cmd0 = 0; //left affinity
rght_opn = 1;
lft_opn = 0;
repeat (10) @(posedge clk); 
lft_opn = 0;
rght_opn = 0;
repeat (10) @(posedge clk); 




$stop;







end 


always
  #5 clk = ~clk;

endmodule
