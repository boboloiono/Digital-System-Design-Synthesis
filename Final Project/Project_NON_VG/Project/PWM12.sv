module PWM12(
  // inputs and outputs
  input clk,
  input rst_n,
  input [11:0] duty,
  output logic PWM1,
  output logic PWM2
);

  localparam  NONOVERLAP = 12'h02C;
  logic [11:0] cnt;
  
  //Implementing the counter
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n)
	  cnt <= 12'h000;
	else
	  cnt <= cnt + 1;

  //Set/rest comb logic and the flop
  
   always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) // Asynchronous reset takes priority
      PWM2 <= 1'b0;
    else if (&cnt) // Reset input
      PWM2 <= 1'b0;
    else if (cnt >= (duty + NONOVERLAP)) // Set input
      PWM2 <= 1'b1;
   end
   
   
   //PWM1 logic
   always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) // Asynchronous reset takes priority
      PWM1 <= 1'b0;
    else if (cnt >= duty) // Reset input
      PWM1 <= 1'b0;
	else if (cnt >= NONOVERLAP) // Set input
      PWM1 <= 1'b1;
   end
  

endmodule
	  
