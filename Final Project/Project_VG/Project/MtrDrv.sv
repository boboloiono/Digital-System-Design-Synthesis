module MtrDrv(clk, rst_n, lft_spd, vbatt, rght_spd, lftPWM1, lftPWM2, rghtPWM1, rghtPWM2);
	input clk, rst_n;
	input signed [11:0] lft_spd, rght_spd;
	input [11:0] vbatt;
	output logic lftPWM1, lftPWM2;
	output logic rghtPWM1, rghtPWM2;
	
	logic [5:0] batt_level;
	logic signed [12:0] scale;
	logic signed [23:0] lft_prod, rght_prod;
	logic signed [23:0] lft_prod_ff, rght_prod_ff;
	logic signed [11:0] lft_spd_ff, rght_spd_ff;
	logic signed [11:0] lft_scaled, rght_scaled;
	
	logic [11:0] lft_scaled_unsigned, rght_scaled_unsigned;
	logic signed [12:0] lft_prod_div, rght_prod_div;
	
	DutyScaleROM iROM(clk, batt_level, scale);
	PWM12 iPWM12_lft(clk, rst_n, lft_scaled_unsigned, lftPWM1, lftPWM2);
	PWM12 iPWM12_rght(clk, rst_n, rght_scaled_unsigned, rghtPWM1, rghtPWM2);
	
	localparam sat_pos_12 = 12'h7FF;
	localparam sat_neg_12 = 12'h800;
	
	
		// normalize about any battery voltage in normal range of batteries
	assign batt_level = vbatt[9:4];
	
			//flopping the inputs
		always_ff @(posedge clk, negedge rst_n) begin
			if(!rst_n)begin
				lft_spd_ff <= 12'h000;
				rght_spd_ff <= 12'h000;
			end
			else begin
				lft_spd_ff <= lft_spd;
				rght_spd_ff <= rght_spd;
			end
		end
	
		// acceleration/speed/braking regardless of battery level
	assign lft_prod = $signed(scale) * lft_spd_ff;
	assign rght_prod = $signed(scale) * rght_spd_ff;
	
		//flopping the product
		always_ff @(posedge clk, negedge rst_n) begin
			if(!rst_n)begin
				lft_prod_ff <= 24'h000000;
				rght_prod_ff <= 24'h000000;
			end
			else begin
				lft_prod_ff <= lft_prod;
				rght_prod_ff <= rght_prod;
			end
		end
		
		// divided 2048
		assign lft_prod_div = lft_prod_ff[23:11];
		assign rght_prod_div = rght_prod_ff[23:11];
		
		// 12-bit sat
		assign lft_scaled = (!lft_prod_div[12] && (|lft_prod_div[11])) ? sat_pos_12 :
					(lft_prod_div[12] && (!lft_prod_div[11])) ? sat_neg_12 :
					lft_prod_div[11:0];
					
	    assign rght_scaled = (!rght_prod_div[12] && |rght_prod_div[11]) ? sat_pos_12 :
					(rght_prod_div[12] && !rght_prod_div[11]) ? sat_neg_12 :
					rght_prod_div[11:0];
			
		// convert the 12 bit signed duty cycle to unsigned. done by adding 0x800.
		assign lft_scaled_unsigned = lft_scaled + (12'h800);
		assign rght_scaled_unsigned = (12'h800) - rght_scaled;
	
endmodule