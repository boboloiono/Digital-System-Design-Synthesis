module piezo_drv_test(clk, RST_n, Batt_low, fanfare, piezo, piezo_n);

/////////////////////////////////////////////
//tester for piezo_drv                    //
///////////////////////////////////////////

input clk;
input RST_n;
input batt_low;
input fanfare;
output piezo;
output piezo_n;

logic rst_n;

//module piezo_drv(clk,rst_n,batt_low, fanfare, piezo, piezo_n);
//module reset_synch(clk,rst_n, RST_n);
localparam FAST_SIM = 0;

piezo_drv #(FAST_SIM) ipiezo_drv(.clk(clk), .rst_n(rst_n), .Batt_low(batt_low), .fanfare(fanfare), .piezo(piezo), .piezo_n(piezo_n));
reset_synch iRES(.clk(clk), .rst_n(rst_n), .RST_n(RST_n));

	  
endmodule
