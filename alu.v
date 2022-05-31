`include "opcodes.v"


module ALU (input [31:0] alu_in_1,
			input [31:0] alu_in_2,
			input [3:0] alu_control,
			input [31:0] ID_EX_inst,
			output reg signed [31:0] alu_result,
			output [2:0] alu_bcond,
			output reg alu_bcond_temp);

	// always @(alu_result) begin
	// alu_bcond = {(alu_result > 0),(alu_result < 0), (alu_result == 0)};
	// end

	//assign alu_bcond[0] = (alu_result == 0) ? 1 : 0 ; //beq bne bge
	//assign alu_bcond[1] = (alu_result < 0) ? 1 : 0; // blt
	//assign alu_bcond[2] = (alu_result > 0) ? 1 : 0; // bge

	assign alu_bcond = (alu_result == 0) ? 3'b001 :
	                   (alu_result < 0) ? 3'b010 :
				    	(alu_result > 0) ? 3'b100 : 3'b000;

	always @(alu_bcond) begin
	alu_bcond_temp = (ID_EX_inst[14:12] == 3'b000 & alu_bcond[0] == 1) ? 1: 
	(ID_EX_inst[14:12] == 3'b001 & alu_bcond[0] == 0) ? 1 :
	(ID_EX_inst[14:12] == 3'b100 & alu_bcond[1] == 1) ? 1 : 
	(ID_EX_inst[14:12] == 3'b101 & (alu_bcond[0] == 1 | alu_bcond[2] == 1 )) ? 1 : 1'b0;
	end


//  always @(*) begin
//  	$display("alu input first %x , second %x", alu_in_1, alu_in_2);
//  end

// always @(*) begin
// 	 $display("alu_result is %x", alu_result);
// 	 $display("alu_bcond is %b, %b, %b", alu_bcond[0], alu_bcond[1], alu_bcond[2]);
// end

always @(*) begin
	
	// $display("ALU alu_control %b", alu_control);	
	case(alu_control)
	4'b0000: alu_result = alu_in_1 & alu_in_2; // AND
	4'b0001: alu_result = alu_in_1 | alu_in_2; // OR
	4'b0010: alu_result = alu_in_1 + alu_in_2; // add
	4'b0110: alu_result = alu_in_1 - alu_in_2; // subtract
	4'b0011: alu_result = alu_in_1 << alu_in_2; // sll
	4'b0111: alu_result = alu_in_1 ^ alu_in_2; // xor
	4'b1000: alu_result = alu_in_1 >> alu_in_2; // srl
	default: alu_result = {32{1'bx}};	
	endcase
	


end
endmodule


//set alu_control by using instruction 
module ALUControlUnit (input [31:0] part_of_inst,
					   input [1:0] alu_op,
					   output reg [3:0] alu_control);

wire [2:0] funct3;
wire inst30;

assign funct3 = part_of_inst[14:12];
assign inst30 = part_of_inst[30];


// 
// always @(*) begin
// case(part_of_inst[6:0])
// 7'b0110011 : aluop = 2'b10; // R-type
// 7'b0000011 : aluop = 2'b00; // lw-type
// 7'b0100011 : aluop = 2'b00; // s-type
// 7'b1100011 : aluop = 2'b01; // sb-type
// 7'b0010011 : aluop = 2'b11; // I-type
// 7'b1100111 : aluop = 2'b00; // jalr-type
// 7'b1101111 : aluop = 2'b00; // jal-type
// default : aluop    = 2'bxx;
// endcase
// end

// always @(*) begin
//  $display("alu control unit alu_op: %b", alu_op);
// end

always @(*) begin
	case(alu_op)
		2'b00 : alu_control = 4'b0010;
		2'b01 : alu_control = 4'b0110; 
		2'b10 : case({inst30,funct3})
		4'b0000 : alu_control = 4'b0010; // add
		4'b1000 : alu_control = 4'b0110; // sub
		4'b0111 : alu_control = 4'b0000; // and
		4'b0110 : alu_control = 4'b0001; // or
		4'b0001 : alu_control = 4'b0011; // sll
		4'b0100 : alu_control = 4'b0111; // xor
		4'b0101 : alu_control = 4'b1000; // srl
		default : alu_control = 4'bxxxx;
		endcase
		2'b11 : case(funct3) 
		3'b000 : alu_control = 4'b0010; // addi
		3'b100 : alu_control = 4'b0111; // xori
		3'b110 : alu_control = 4'b0001; // ori
		3'b111 : alu_control = 4'b0000; // andi
		3'b001 : alu_control = 4'b0011; // slli
		3'b101 : alu_control = 4'b1000; // srli
		default : alu_control = 4'bxxxx;
	endcase
endcase
end

// always @(part_of_inst) begin
// 	$display("ALUControlUnit %x", part_of_inst);
// end
	

endmodule


// always @(*) begin
// 	$display("ALUControlUnit");
// 	alu_control = (part_of_inst[6:0] == `JAL || part_of_inst[6:0] == `JALR || part_of_inst[6:0] == `LW || part_of_inst[6:0] == `SW) ? 3'b000 :  //JAL&JALR -> add
// 	(part_of_inst[30] == 1) ? 3'b010 :  //SUB -> sub
// 	part_of_inst[14:12];


// end 
// endmodule