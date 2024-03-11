module maze_solve(clk, rst_n, cmd_md, cmd0, lft_opn, rght_opn, mv_cmplt, sol_cmplt, strt_hdng, dsrd_hdng, strt_mv, stp_lft, stp_rght);

input clk, rst_n;		// positive edge triggered, reset active low
input logic cmd_md, cmd0, lft_opn, rght_opn, mv_cmplt, sol_cmplt;
output logic strt_hdng, strt_mv, stp_lft, stp_rght;
output logic signed [11:0] dsrd_hdng;

logic [1:0] op_code;
logic [1:0] offset;

always @ (op_code) begin
  case(op_code)
   2'b00 : dsrd_hdng = 12'h000;
   2'b01 : dsrd_hdng = 12'h3ff;
   2'b10 : dsrd_hdng = 12'h7ff;
   2'b11 : dsrd_hdng = 12'hc00;
  endcase
end

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    op_code <= 2'b00;
  else 
    op_code <= op_code + offset;


////////////////////////////
// state machine states   //
///////////////////////////
typedef enum reg[2:0] {IDLE, WAIT_FRWD_SETUP_NEW_HEADING, WAIT_FOR_HEADING, KICK_OFF_FRWD} state_t;
state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n)
if (!rst_n)
state <= IDLE;
else 
state <= nxt_state;


always_comb begin

strt_hdng = 0;
strt_mv = 0;
stp_lft = 0;
stp_rght = 0;
offset = 2'b00;
nxt_state = state;

case(state)

IDLE: if (!cmd_md && cmd0) begin
  strt_mv = 1;
  stp_lft = 1;
  nxt_state = WAIT_FRWD_SETUP_NEW_HEADING;

  end else if (!cmd_md) begin
  strt_mv = 1;
  stp_rght = 1;
  nxt_state = WAIT_FRWD_SETUP_NEW_HEADING;
  end 


WAIT_FRWD_SETUP_NEW_HEADING: if (sol_cmplt) begin
  nxt_state = IDLE;
end else if (cmd0 && mv_cmplt && lft_opn) begin //LEFT_AFFINITY

  nxt_state =START_HEADING;
  offset = 2'b01;

  end else if (cmd0 && mv_cmplt && rght_opn) begin //LEFT_AFFINITY

    nxt_state = START_HEADING;
      offset = 2'b11;

end else if (~cmd0 && mv_cmplt && rght_opn) begin //RIGHT_AFFINITY
   
     nxt_state = START_HEADING;
    offset = 2'b11;
 
end else if (~cmd0 && mv_cmplt && lft_opn) begin //RIGHT_AFFINITY

  nxt_state = START_HEADING;
    offset = 2'b01;


  end else if (mv_cmplt) begin // turn 180 
    
    nxt_state = START_HEADING;
    offset = 2'b10;

  
  end

START_HEADING: begin
  strt_hdng = 1;
  nxt_state = WAIT_FOR_HEADING;
end

WAIT_FOR_HEADING: if (mv_cmplt) begin
  nxt_state = KICK_OFF_FRWD;
end

KICK_OFF_FRWD: begin
  strt_mv = 1;
  nxt_state = WAIT_FRWD_SETUP_NEW_HEADING;
end

endcase

end

  
endmodule