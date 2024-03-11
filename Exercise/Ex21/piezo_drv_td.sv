module piezo_drv_tb();

/////////////////////////////////////////////
//tester for piezo_drv                    //
///////////////////////////////////////////

logic clk;
logic rst_n;
logic Batt_low;
logic fanfare;
logic piezo;
logic piezo_n;

//module piezo_drv(clk,rst_n,Batt_low, fanfare, piezo, piezo_n);

piezo_drv ipiezo_drv(.clk(clk), .rst_n(rst_n), .Batt_low(Batt_low), .fanfare(fanfare), .piezo(piezo), .piezo_n(piezo_n));

always
#5 clk = ~clk;


initial begin

clk = 0;
rst_n = 0;
Batt_low = 0;

@(negedge clk);
rst_n = 1;

@(posedge clk);

fanfare = 1;
@(posedge clk);
fanfare = 0;

repeat (4000000) @(posedge clk);


Batt_low = 1;

repeat (4000000) @(posedge clk);

Batt_low = 0;

repeat (10000) @(posedge clk);


$stop;

end
	  
endmodule
