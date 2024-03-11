module sqrt(clk,rst_n,go,op,sqrt,done,err);

input clk,rst_n;		// clock and active low asynch reset
input go;				// rise edge will kick off computation of square root
input [15:0] op;		// the signed number this module takes sqrt of
output [7:0] sqrt;		// the result of the computation
output reg done;		// asserted when the result is valid
output reg err;			// asserted when op was negative (no real sqrt)

  //////////////////////////////
  // Define Needed Registers //
  ////////////////////////////
  reg [7:0] sqrt,cnt_msk;
  
  ////////////////////////////
  // Define any SM outputs //
  //////////////////////////
  logic set_done, set_err, update, init;

  wire lteq;				// test mult result was <= the op
  wire [15:0] product;		// holds sqrt*sqrt for comparison against op
  wire [7:0] nxt_sqrt;
  
  typedef enum reg [1:0] {IDLE,COMPUTE,DELAY} state_t;

  state_t state,nxt_state;
  
  ///////////////////////////
  // Infer state register //
  /////////////////////////
  always @(posedge clk, negedge rst_n)
    if (!rst_n)
	  state <= IDLE;
	else
	  state <= nxt_state;
	  
  /////////////////////////////
  // Infer cnt_msk register //
  ///////////////////////////
  always @(posedge clk)
    if (init)
	  cnt_msk <= 8'h80;
	else if (update)
	  cnt_msk <= {1'b0,cnt_msk[7:1]};
	  
  /////////////////////
  // Infer done bit //
  ///////////////////  
  always @(posedge clk, negedge rst_n)
    if (!rst_n)
	  done <= 1'b0;
	else if (init)
	  done <= 1'b0;
    else if (set_done)
	  done <= 1'b1;
 
  /////////////////////
  // Infer err flag //
  ///////////////////  
  always @(posedge clk, negedge rst_n)
    if (!rst_n)
	  err <= 1'b0;
    else if (set_err)
	  err <= 1'b1;
	else if (init)
	  err <= 1'b0;
	  
	  
  //////////////////////////////////////////
  // Successive approximation.  Multiply //
  // sqrt by itself and compare to op  //
  ///////////////////////////////////////
  assign product = sqrt*sqrt;
  assign lteq = (product>op) ? 1'b0 : 1'b1;	// is product less than or equal to op
  //// if so keep bit set and set next bit, if not clear current msk bit and set next ////
  assign nxt_sqrt = (lteq) ? (sqrt | {1'b0,cnt_msk[7:1]}) : (~cnt_msk&sqrt) | {1'b0,cnt_msk[7:1]};
  
  //////////////////////////
  // Infer sqrt register //
  ////////////////////////	  
  always @(posedge clk)
    if (init)
	  sqrt <= 8'h80;
	else if (update)
	  sqrt <= nxt_sqrt;

  always_comb begin
    ////////////////////////////////////
	// Default state machine outputs //
	//////////////////////////////////
	init = 0;
	set_done = 0;
	set_err = 0;
	update = 0;
	nxt_state = IDLE;
	case (state)
	  IDLE : begin
	    if (go) begin
		  init = 1;
		  if (op[15]) 	// negative operand
			nxt_state = DELAY;
		  else
		    nxt_state = COMPUTE;
		end
	  end
	  COMPUTE : begin
	    update = 1;
		if (cnt_msk[0]) begin
		  set_done = 1;
		  nxt_state = IDLE;
		end else
		  nxt_state = COMPUTE;
	  end
	  DELAY : begin
	    set_done = 1;
		set_err = 1;
	  end
	endcase
  end

endmodule