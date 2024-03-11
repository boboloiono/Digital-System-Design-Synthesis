//////////////////////////////////////////////////////
// Interfaces with ST 6-axis inertial sensor.  In  //
// this application we only use Z-axis gyro for   //
// heading of mazeRunner.  Fusion correction     //
// comes from IR_Dtrm when en_fusion is high.   //
/////////////////////////////////////////////////
module inert_intf(clk,rst_n,strt_cal,cal_done,heading,rdy,IR_Dtrm,
                  SS_n,SCLK,MOSI,MISO,INT,moving,en_fusion);

	parameter FAST_SIM = 1;	// used to speed up simulation

	input clk, rst_n;
	input MISO;							// SPI input from inertial sensor
	input INT;							// goes high when measurement ready
	input strt_cal;						// initiate claibration of yaw readings
	input moving;							// Only integrate yaw when going
	input en_fusion;						// do fusion corr only when forward at decent clip
	input [8:0] IR_Dtrm;					// derivative term of IR sensors (used for fusion)

	output cal_done;				// pulses high for 1 clock when calibration done
	output signed [11:0] heading;	// heading of robot.  000 = Orig dir 3FF = 90 CCW 7FF = 180 CCW
	output rdy;						// goes high for 1 clock when new outputs ready (from inertial_integrator)
	output SS_n,SCLK,MOSI;			// SPI outputs


	////////////////////////////////////////////
	// Declare any needed internal registers //
	//////////////////////////////////////////
	reg CYL, CYH;
	reg [7:0] yawH, yawL;	// holding registers
	reg [15:0] timer;		// timer
	reg INT_ff1, INT_ff2;	// double flop of INT

	//////////////////////////////////////
	// Outputs of SM are of type logic //
	////////////////////////////////////
	logic wrt;
	logic vld, vld_ff;
	logic [15:0] cmd;
	
	//////////////////////////////////////////////////////////////
	// Declare any needed internal signals that connect blocks //
	////////////////////////////////////////////////////////////
	wire done;
	wire [15:0] inert_data;		// Data back from inertial sensor (only lower 8-bits)
	wire signed [15:0] yaw_rt;
	
	///////////////////////////////////////
	// Create enumerated type for state //
	/////////////////////////////////////
	typedef enum logic [2:0] {INIT1, INIT2, INIT3, READL, READH, WAIT} state_t;
	state_t state, nxt_state;
	
	////////////////////////////////////////////////////////////
	// Instantiate SPI monarch for Inertial Sensor interface //
	//////////////////////////////////////////////////////////
	SPI_mnrch iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),
				 .MISO(MISO),.MOSI(MOSI),.wrt(wrt),.done(done),
				 .rspns(inert_data),.cmd(cmd));
				  
	////////////////////////////////////////////////////////////////////
	// Instantiate Angle Engine that takes in angular rate readings  //
	// and gaurdrail info and produces a heading reading            //
	/////////////////////////////////////////////////////////////////
	inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal),
						.vld(vld_ff),.rdy(rdy),.cal_done(cal_done), .yaw_rt(yaw_rt),.moving(moving),
						.en_fusion(en_fusion),.IR_Dtrm(IR_Dtrm),.heading(heading));


	//<< remaining logic (SM, timer, holding registers...) >>

	always_comb begin
		wrt = 1'b0;
		CYL = 1'b0; CYH = 1'b0;
		vld = 1'b0;
		cmd = 16'h0000;
		nxt_state = state;
		case(state)
			INIT1: begin
				cmd = 16'h0D02;	// Enable interrupt upon data ready
				if(&timer) begin
					wrt = 1'b1;
					nxt_state = INIT2;
				end
			end
			INIT2: begin
				cmd = 16'h1160;	// Setup gyro for 416Hz data rate, +/-250°/sec range
				if(done) begin
					wrt = 1'b1;
					nxt_state = INIT3;
				end
			end
			INIT3: begin
				cmd = 16'h1440;	// Turn rounding on for gyro readings
				if(done) begin
					nxt_state = WAIT;
				end
			end
			READL: begin
				if(done) begin
					CYL = 1'b1;
				    cmd = 16'hA700;	// use the address to tell sensor that we are going to read YawH
					wrt = 1'b1;
					nxt_state = READH;
				end
			end
			READH: begin
				if(done) begin
					CYH = 1'b1;
					vld = 1'b1;
					nxt_state = WAIT;
				end
			end
			default: begin
				if(INT_ff2==1'b1) begin
					cmd = 16'hA600;	// use the address to tell sensor that we are going to read YawL
					wrt = 1'b1;
					nxt_state = READL;
				end
			end
		endcase
	end
	
	//////////////////////////////////////////////////////////////
	////////////////////// State Machine ////////////////////////
	/////////////////////////////////////////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= INIT1;
		else state <= nxt_state;
	end
	
	//////////////////////////////////////////////////////////////
	////////////////////////// Timer ////////////////////////////
	/////////////////////////////////////////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) timer <= 16'b0;
		else timer <= timer + 1'b1;
	end
	
	//////////////////////////////////////////////////////////////
	/////////////////// double flop of INT //////////////////////
	/////////////////////////////////////////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			INT_ff1 <= 1'b0;
			INT_ff2 <= 1'b0;
		end
		else begin
			INT_ff1 <= INT;
			INT_ff2 <= INT_ff1;
		end
	end
		
	//////////////////////////////////////////////////////////////
	///////////////////// holding registers /////////////////////
	/////////////////////////////////////////////////////////////
	always_ff @(posedge clk) begin
		if(CYL) yawL <= inert_data[7:0];
		else if(CYH) yawH <= inert_data[7:0];
		vld_ff <= vld;
	end
	
	assign yaw_rt = {yawH, yawL};
	
endmodule
	  