module ring_osc_tb(); // a testbench is self-contained (has no inputs/outputs)
reg en; // stiumulus to DUT declared as type reg or logic
// Instantiate DUT = Device Under Test //
ring_osc DUT(.en(en), .out());

initial begin // stimulus typically provided in an initial block
en = 0;
#15 en = 1;
#60 $stop(); // wait 5 more time units then stop the simulation
end
endmodule