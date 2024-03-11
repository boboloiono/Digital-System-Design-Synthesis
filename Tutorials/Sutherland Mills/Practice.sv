enum logic [2:0] {WHAT=3'b001, LOAD=3'b010, READY=3'100} state, next_state;
// same size variable
// assignments are illegal
enum logic [1:0] {READ=3'b101, SET=3'b010, GO=3'b110} mode_control; // -> error when compile
struct{ logic [7:0] opcode;
		logic [31:0] data;
		logic		 status;
} operation;
operation = {8'h55, 1024, 1'b0};	// assgin entire structure
operation.data = 32'hFRDFFR25;	// assgin to structure member
// bundle related signal together under one same name-> eliminate mismatch or missed assignments

typedef logic [31:0] bus32_t;
typedef enum [7:0] {ADD, SUB, MULT, DIV, SHIFT, ROT, XOR, NOP} opcodes_t;
typedef enum logic {FALSE, TRUE} boolean_t;
typedef struct{
	opcode_t opcode;
	bus32_t data;
	boolean_t status;
}	operation_t;

module ALU(input opcodes_t operation, output bus32_t result};
opcodes_t registered_op;
// define complex types once and use many times
// ensure consitency throughout a module


package project_types;
	typedef logic [31:0] bus32_t;
	typedef enum [7:0] {ADD, SUB, MULT, DIV, SHIFT, ROT, XOR, NOP} opcodes_t;
	typedef enum struct {...} operation_t;
	typedef automatic crc_gen;
endpackage

module ALU
	import project_types*;
	(input operation_t operation, output bus32_t result);
	operation_t registered_op;
endmodule
// ensure consistency, makes code easier to maintain and reuse then `include

// package array
logic [3:0][7:0] b;	
// unpacked array enhancement: 1. C-like array, assign to entire array at once, copy array
logic [7:0] a1 [0:1][0:3];
logic [7:0] a2 [2][4];
a1 = '{'{7,3,0,5}, '{default:'1};	// assign values to entire array
a2 = a1;		// code entire array

package design_types;
	typedef struct{
		// this structure bundles 54 variables together
		logic [3:0] GFC;
		logic [7:0] VPI;
		logic [15:0] VCI;
		logic		CLP;
		logic [2:0] T;
		logic [7:0] HEC;
		logic [7:0] Payload [48];
	} uni_t;			// UNI cell definition
endpackage

module transmit_reg (output design_types:: uni_t data_reg,
					input design_types:: uni_t data_packet,
					input logic			clock resetN);
	// 4 lines of code replaces 216 lindes of old verilog.
	always @(posedge clk, negedge resetN)
		if(!resetN) data_reg <= '{default:0};
		else data_reg <= data_packet;
endmodule



