module piezo_drv(clk,rst_n,Batt_low, fanfare, piezo, piezo_n);

parameter FAST_SIM = 1;

input clk;
input rst_n;
input logic Batt_low;
input logic fanfare;
output logic piezo;
output reg piezo_n;

logic [24:0] durationCounter;
logic [15:0] frequencyCounter;
logic [4:0] incrementAmount;

logic init;

logic freq_init;

////////////////////////////////////////////
// generate if for FAST_SIM logic         //
////////////////////////////////////////////
generate if (FAST_SIM)   
assign incrementAmount = 16;
else
assign incrementAmount = 1;
endgenerate

////////////////////////////////////////////
// duration counter                       //
////////////////////////////////////////////
always_ff@(posedge clk, negedge rst_n)
if (!rst_n)
  durationCounter <= 0;
else if (init)
  durationCounter <= 0;
else 
  durationCounter <= durationCounter + incrementAmount;

/////////////////////////////////////////////
// frequency counter                      //
////////////////////////////////////////////
always_ff@(posedge clk, negedge rst_n)
if (!rst_n) 
frequencyCounter <= 0;
else if (freq_init)
frequencyCounter <= 0;
else
frequencyCounter <= frequencyCounter + 1;

//piezo_n should be the opposite of piezo

assign piezo_n = ~piezo;

//state machine states 
typedef enum logic [3:0] {IDLE, FG6, FC7, F1E7, F1G7, F2G7, F2E7, FG72, LG6, LC7, LE7} state_t;
state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n)
if (!rst_n)
state <= IDLE;
else 
state <= nxt_state;

////////////////////////////////////
// state machine                 //
//////////////////////////////////

//we used the formula CLK_FREQ/2/desired_frep
// for Freq: 1568, we have 15943
// for Freq: 2093, we have 11945
// for Freq: 2637, we have 9480
// for Freq: 3136, we have 7972

always_comb begin

piezo = 0;
init = 0;
nxt_state = state;
freq_init = 0;

case(state)

IDLE: begin
  if (Batt_low) begin
    nxt_state = LG6;
    init = 1;
    freq_init = 1;
  end else if (fanfare) begin
    nxt_state = FG6;
    init = 1;
    freq_init = 1;
  end

  end

  FG6: begin
  if (durationCounter == 24'h800000) begin
  init = 1;
  freq_init = 1;
  nxt_state = FC7;
  end

  if (frequencyCounter < 15944 ) begin
  piezo = 1;
  end else if (frequencyCounter >= 15944 && frequencyCounter <= 31888) begin
  piezo = 0;
  end else if (frequencyCounter > 31888) begin
  freq_init = 1;
  end

end

FC7: begin

  if (durationCounter == 24'h800000) begin
  init = 1;
  nxt_state = F1E7;
  freq_init = 1;
  end

  if (frequencyCounter < 11945 ) begin
  piezo = 1;
  end else if (frequencyCounter >= 11945 && frequencyCounter <= 23889) begin
  piezo = 0;
  end else if (frequencyCounter > 23889 ) begin
  freq_init = 1;
  end
  
  end


F1E7: begin

if (durationCounter == 24'h800000) begin
  init = 1;
  nxt_state = F1G7;
  freq_init = 1;
end

  if (frequencyCounter <= 9480 ) begin
  piezo = 1;
  end else if (frequencyCounter > 9480 && frequencyCounter <= 18961) begin
  piezo = 0;
  end else if (frequencyCounter > 18961) begin
  freq_init = 1;
  end
end


F1G7: begin

if (durationCounter == 24'h800000) begin
  init = 1;
  nxt_state = F2G7;
  freq_init = 1;
end

  if (frequencyCounter <= 7972 ) begin
  piezo = 1;
  end else if (frequencyCounter > 7972 && frequencyCounter <= 15944 ) begin
  piezo = 0;
  end else if (frequencyCounter > 15944) begin
  freq_init = 1;
  end


end


F2G7: begin

if (durationCounter == 24'h400000) begin
  init = 1;
  nxt_state = F2E7;
  freq_init = 1;
end

  if (frequencyCounter <= 7972 ) begin
  piezo = 1;
  end else if (frequencyCounter > 7972 && frequencyCounter <= 15944 ) begin
  piezo = 0;
  end else if (frequencyCounter > 15944) begin
  freq_init = 1;
  end


end


F2E7: begin

if (durationCounter == 24'h400000) begin
init = 1;
nxt_state = FG72;
freq_init = 1;
end

  if (frequencyCounter <= 9480 ) begin
  piezo = 1;
  end else if (frequencyCounter > 9480 && frequencyCounter <= 18961) begin
  piezo = 0;
  end else if (frequencyCounter > 18961) begin
  freq_init = 1;
  end

end



FG72: begin
if (durationCounter == 25'h1000000) begin
init = 1;
nxt_state = IDLE;
freq_init = 1;
end

  if (frequencyCounter <= 7972 ) begin
  piezo = 1;
  end else if (frequencyCounter > 7972 && frequencyCounter <= 15944) begin
  piezo = 0;
  end else if (frequencyCounter > 15944) begin
  freq_init = 1;
  end



end

LG6:  begin

if (durationCounter == 24'h800000) begin
init = 1;
nxt_state = LC7;
freq_init = 1;
end

  if (frequencyCounter <= 15944 ) begin
  piezo = 1;
  end else if (frequencyCounter > 15944 && frequencyCounter <= 31888) begin
  piezo = 0;
  end else if (frequencyCounter > 31888) begin
  freq_init = 1;
  end

end


LC7: begin

if (durationCounter == 24'h800000) begin
init = 1;
nxt_state = LE7;
freq_init = 1;
end

  if (frequencyCounter <= 11945 ) begin
  piezo = 1;
  end else if (frequencyCounter > 11945 && frequencyCounter <= 23889) begin
  piezo = 0;
  end else if (frequencyCounter > 23889) begin
  freq_init = 1;
  end

end


default: begin

if (!Batt_low) begin
nxt_state = IDLE;
freq_init = 1;
init = 1;
end else if (durationCounter == 24'h800000) begin
init = 1;
nxt_state = LG6;
freq_init = 1;
end

  if (frequencyCounter <= 9480 ) begin
  piezo = 1;
  end else if (frequencyCounter > 9480 && frequencyCounter <= 18961) begin
  piezo = 0;
  end else if (frequencyCounter > 18961) begin
  freq_init = 1;
  end

end






  endcase


  end





	  
endmodule
