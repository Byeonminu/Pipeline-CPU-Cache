`include "opcodes.v"

module ControlUnit (input [6:0] opcode,
                    output alu_src, mem_to_reg, write_enable, mem_read, mem_write, is_ecall, branch, is_jal, is_jalr, pc_to_reg,
                    output reg [1:0] alu_op);


reg [9:0] control;

assign {alu_src, mem_to_reg, write_enable, mem_read, mem_write, is_ecall, branch, is_jal, is_jalr, pc_to_reg} = control;

always @(*) begin
case (opcode)
    7'b0110011 : control = 10'b0110000000; // R-type
    7'b0000011 : control = 10'b1011000000; // lw-type
    7'b0100011 : control = 10'b1000100000; // s-type
    7'b0010011 : control = 10'b1110000000; // I-type
    7'b1100011 : control = 10'b0000001000; // sb-type
    7'b1100111 : control = 10'b1110000011; //jalr-type
    7'b1101111 : control = 10'b1110000101; // jal-type
    7'b1110011 : control = 10'b0000010000; // ecall
    default : control = 10'b0000000000;
endcase
end

always @(*) begin
case (opcode) 
    7'b0110011 : alu_op = 2'b10; // R-type
    7'b0000011 : alu_op = 2'b00; // lw-type
    7'b0100011 : alu_op = 2'b00; // s-type
    7'b0010011 : alu_op = 2'b11; // I-type
    7'b1100011 : alu_op = 2'b01; // sb-type
    7'b1100111 : alu_op = 2'b00; //jalr-type
    default : alu_op = 2'b00;
endcase
end

endmodule




// reg [8:0] control;

// assign {alu_src, mem_to_reg, reg_write, mem_read, mem_write, branch, is_jal, is_jalr, pc_to_reg} = control;

// always @(*) begin
// case(part_of_inst[6:0])
// 7'b0110011 : control = 9'b001000000; // R-type
// 7'b0000011 : control = 9'b111100000; // lw-type
// 7'b0100011 : control = 9'b1x0010000; // s-type
// 7'b1100011 : control = 9'b0x0001000; // sb-type
// 7'b0010011 : control = 9'b101000000; // I-type
// 7'b1100111 : control = 9'b111xx0011; // jalr-type
// 7'b1101111 : control = 9'b111xx0101; // jal-type
// 7'b1110011 : control = 9'bxxxxx000x; // ecall
// default : control    = 9'bxxxxxxxxx;
// endcase

// end



