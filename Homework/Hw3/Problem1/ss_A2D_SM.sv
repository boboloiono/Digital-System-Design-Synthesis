module ss_A2D_SM(clk,rst_n,strt_cnv,smp_eq_8,gt,clr_dac,inc_dac,
                 clr_smp,inc_smp,accum,cnv_cmplt);

  input clk,rst_n;			// clock and asynch reset
  input strt_cnv;			// asserted to kick off a conversion
  input smp_eq_8;			// from datapath, tells when we have 8 samples
  input gt;					// gt signal, has to be double flopped
  
  output logic clr_dac;			// clear the input counter to the DAC
  output logic inc_dac;			// increment the counter to the DAC
  output logic clr_smp;			// clear the sample counter
  output logic inc_smp;			// increment the sample counter
  output logic accum;			// asserted to make accumulator accumulate sample
  output logic cnv_cmplt;		// indicates when the conversion is complete

  /////////////////////////////////////////////////////////////////
  // You fill in the SM implementation. I want to see the use   //
  // of enumerated type for state, and proper SM coding style. //
  //////////////////////////////////////////////////////////////
  
  typedef enum reg [2:0] {IDLE, CONV, ACCUM} state_t;
  state_t state, nxt_state;
  
  reg gt_ff1, gt_ff2;
  
  always_comb begin
	  clr_dac = 0;
	  inc_dac = 0;
	  clr_smp = 0;
	  inc_smp = 0;
	  accum = 0;
	  cnv_cmplt = 0;
	  nxt_state = state;
	  case(state) 
		CONV: begin
			if(!gt_ff2) begin
				inc_dac = 1;
				nxt_state = CONV;
			end else begin
				accum = 1;
				nxt_state = ACCUM;
			end
		end
		ACCUM: begin
			if(smp_eq_8) begin
				cnv_cmplt = 1;
				nxt_state = IDLE;
			end else begin
				nxt_state = CONV;
				clr_dac = 1;
				inc_smp = 1;		// because inr_smp has only 8 bits, we cannot count it over 8 bits. 
									// Therefore, we put it at the state of that ACCUM is not sample to 8 and turn back to the state of CONV
			end
		end
		default: begin
			// Need default case to capture for potential alpha particle strike
			if(strt_cnv) begin
				clr_dac = 1;
				clr_smp = 1;
				nxt_state = CONV;
			end else begin
				nxt_state = IDLE;
			end
		end
	  endcase
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) state <= IDLE;
	else state <= nxt_state;
  end
  
  // use double flop "gt"
  // because it originates from an "analog" comparator so it would be "asynch" to our clk
  // we need to double flop it for metastability reasons
  always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		gt_ff1 <= 1'b0;
		gt_ff2 <= 1'b0;
	end else if (clr_dac) begin
		gt_ff1 <= 1'b0;
		gt_ff2 <= 1'b0;
	end else begin
		gt_ff1 <= gt;
		gt_ff2 <= gt_ff1;
	end
  end
endmodule