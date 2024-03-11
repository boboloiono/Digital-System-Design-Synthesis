module maze_solve(clk, rst_n, cmd_md, cmd0, lft_opn, rght_opn, mv_cmplt, sol_cmplt, strt_hdng, dsrd_hdng, strt_mv, stp_lft, stp_rght);

input clk, rst_n;
input cmd_md, cmd0;
input lft_opn, rght_opn;
input mv_cmplt, sol_cmplt;
output logic strt_hdng; 
output logic [11:0] dsrd_hdng;
output logic strt_mv, stp_lft, stp_rght;

//////////////////////////////////////////////
// Flop to hold on to solver affinity       //
//////////////////////////////////////////////
logic l_affinity, set_affinity;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) 
    l_affinity <= 1'b0;
  else if (set_affinity) 
    l_affinity <= cmd0;
  // else holds 

//////////////////////////////////////////////
// FSM logic                                //
//////////////////////////////////////////////

// required for desired heading
//       the FSM sets an offset
//       the offset is added to a counter flop
//       the counter is mapped to a mux decoder to reach desired heading 

// the offset has 00, 01, 10, 11 mapped to 000, 3FF, 7FF, C00 respectively
logic [1:0]offset; 

typedef enum logic[2:0] {IDLE, WAIT_DONE_SET_NEW_HDNG, KICKOFF_STRT_HDNG, WAIT_HDNG, KICKOFF_FWD_MV} state_t;
state_t current_state, next_state;

// typical FSM FF logic
  always_ff @(posedge clk, negedge rst_n) 
     if (!rst_n) 
	    current_state <= IDLE;
     else 
        current_state <= next_state;


  // combinational FSM logic 

  always_comb begin

    // default outputs and next_state 
    strt_hdng = 0;
    strt_mv = 0;
    stp_lft = 0;
    stp_lft = 0;
    offset = 2'b00;
    set_affinity = 0;
    next_state = current_state;

    case (current_state)

        // start moving forward in this state 
        default: begin                                      // IDLE

            if (!cmd_md) begin                              // move to the next state when cmd_md drops
                strt_mv = 1;
                set_affinity = 1;
                next_state = WAIT_DONE_SET_NEW_HDNG;           
                if (l_affinity) begin                             // defines which affinity is being performed 
                    stp_lft = 1;
                    stp_rght = 0;
                end else begin
                    stp_rght = 1;
                    stp_lft = 0;
                end 
            end 

        end 

        // when moving stops (due to blockage or opening) 
        WAIT_DONE_SET_NEW_HDNG: begin

        // carries the bulk of the stopping, turning and finish logic

            if (sol_cmplt) begin
                next_state = IDLE;
            end 

            else if (mv_cmplt) begin

                next_state = KICKOFF_STRT_HDNG;
                // cannot assert start heading in this flop because opcode does not get new value until next clk - navigat ewill give move complete immediately 

                // left affinity 
                if (l_affinity) begin
                    if (lft_opn) begin
                        offset = 2'b01;
                    end else if (rght_opn) begin
                        offset = 2'b11;
                    end else begin                      // turn 180 if both shut 
                        offset = 2'b10;
                    end
                end
                // right affinity - if !l_affinity
                else begin                          
                    if (rght_opn) begin
                        offset = 2'b11;
                    end else if (lft_opn) begin
                        offset = 2'b01;
                    end else begin
                        offset = 2'b10;
                    end
                end
            end

        end

        // for chanigng desired heading 
        KICKOFF_STRT_HDNG: begin
                strt_hdng = 1;
                next_state = WAIT_HDNG;
        end

        // waiting a clock cycle for dsrd_hdng to be loaded in (it is flopped)
        WAIT_HDNG: begin
            if (mv_cmplt) begin
                next_state = KICKOFF_FWD_MV; 
            end
        end

        // moving foward after the turn 
        KICKOFF_FWD_MV: begin
            strt_mv = 1;
            next_state = WAIT_DONE_SET_NEW_HDNG;
        end 

    endcase 
  end 

//////////////////////////////////////////////
// FF for dsrd_hdng counter                 //
//////////////////////////////////////////////
 
 logic [1:0] counter;

 always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) 
        counter <= 2'b00;
    else 
        counter <= counter + offset;


//////////////////////////////////////////////
// Decoder mux for dsrd_hdng                //
//////////////////////////////////////////////

    always_comb begin
        case (counter) 
            2'b00: dsrd_hdng = 12'h000;
            2'b01: dsrd_hdng = 12'h3FF;
            2'b10: dsrd_hdng = 12'h7FF;
            2'b11: dsrd_hdng = 12'hC00;
        endcase
    end                 

endmodule


// assign dsrd_hdng = (counter == 2'b00) ? 12'h000 : (counter == 2'b01) ? 12'h3FF : (counter == 2'b10) ? 12'h7FF : 12'hC00;