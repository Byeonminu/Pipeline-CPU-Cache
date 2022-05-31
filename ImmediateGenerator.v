`include "opcodes.v"

module ImmediateGenerator (input [31:0] part_of_inst, 
                           output reg [31:0] imm_gen_out);


// always @(part_of_inst) begin
//     $display("ImmediateGenerator %x", part_of_inst);
// end

always @(*) begin
case(part_of_inst[6:0])
`LW: imm_gen_out = {{20{part_of_inst[31]}},part_of_inst[31:20]};
`SW: imm_gen_out = {{20{part_of_inst[31]}},part_of_inst[31:25],part_of_inst[11:7]};
`ADDI: imm_gen_out = {{20{part_of_inst[31]}},part_of_inst[31:20]};

`JAL: imm_gen_out = {{11{part_of_inst[31]}},part_of_inst[31],part_of_inst[19:12],part_of_inst[20],part_of_inst[30:21], 1'b0};
`JALR: imm_gen_out = {{20{part_of_inst[31]}},part_of_inst[31:20]};
`BEQ: imm_gen_out = {{19{part_of_inst[31]}},part_of_inst[31],part_of_inst[7],part_of_inst[30:25],part_of_inst[11:8],1'b0};

default : imm_gen_out = {32{1'hx}}; // ADD, SUB, SLL, XOR, SRL, OR, AND


endcase
end
endmodule