module lshift_rot(src, rot, amt, res);
	input unsigned [15:0] src;	// Input vector to be shifted/rotated
	input rot;			// If asserted rotate instead of shift
	input unsigned [3:0] amt;	// Specifies shift amount 0 to 15
	output [15:0] res;	// Result of shift
	
	assign res = (rot) ?	(amt == 0) ? src : 
							(amt == 1) ? {src[14:0], src[15]} :
							(amt == 2) ? {src[13:0], src[15:14]} :
							(amt == 3) ? {src[12:0], src[15:13]} :
							(amt == 4) ? {src[11:0], src[15:12]} :
							(amt == 5) ? {src[10:0], src[15:11]} :
							(amt == 6) ? {src[ 9:0], src[15:10]} :
							(amt == 7) ? {src[ 8:0], src[15: 9]} :
							(amt == 8) ? {src[ 7:0], src[15: 8]} :
							(amt == 9) ? {src[ 6:0], src[15: 7]} :
							(amt == 10) ? {src[5:0], src[15: 6]} :
							(amt == 11) ? {src[4:0], src[15: 5]} :
							(amt == 12) ? {src[3:0], src[15: 4]} :
							(amt == 13) ? {src[2:0], src[15: 3]} :
							(amt == 14) ? {src[1:0], src[15: 2]} :
							(amt == 15) ? {src[0], src[15:1]} :
							src:
							(amt == 0) ? src : 
							(amt == 1) ? {src[14:0], 1'b0} :
							(amt == 2) ? {src[13:0], 2'b0} :
							(amt == 3) ? {src[12:0], 3'b0} :
							(amt == 4) ? {src[11:0], 4'b0} :
							(amt == 5) ? {src[10:0], 5'b0} :
							(amt == 6) ? {src[ 9:0], 6'b0} :
							(amt == 7) ? {src[ 8:0], 7'b0} :
							(amt == 8) ? {src[ 7:0], 8'b0} :
							(amt == 9) ? {src[ 6:0], 9'b0} :
							(amt == 10) ? {src[5:0], 10'b0} :
							(amt == 11) ? {src[4:0], 11'b0} :
							(amt == 12) ? {src[3:0], 12'b0} :
							(amt == 13) ? {src[2:0], 13'b0} :
							(amt == 14) ? {src[1:0], 14'b0} :
							(amt == 15) ? {src[0], 15'b0} :
							src;
	
	// assign res = (amt > 1) ? (rot) ? {src[(15-amt) : 0], src[15 : (1-amt)]} : {src[0 +: (16-amt)], {amt{1'b0}}} : src;
	/// -> error: Range must be bounded by constant expressions, because any hardware should make sure its design numbers before implement.
							
	//////////// rotate //////////////
	// amt = 1: {scr[14:0], scr[15]}
	// amt = 2: {scr[13:0], scr[15:14]}
	
	///////////// shift /////////////
	// amt = 1: {scr[14:0], {1{0}}}
	// amt = 2: {scr[13:0], {2{0}}}
	
endmodule