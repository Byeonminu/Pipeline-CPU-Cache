// You don't have to use constants below if you want to define yours.
// You can modify and define constants for your convenience

// OPCODE
// R-type instruction opcodes
`define JAL             7'b1101111
`define JALR            7'b1100111
`define BEQ             7'b1100011
`define BNE             7'b1100011
`define BLT             7'b1100011
`define BGE             7'b1100011

`define LW              7'b0000011

`define SW              7'b0100011

`define ADDI            7'b0010011
`define XORI            7'b0010011
`define ORI             7'b0010011
`define ANDI            7'b0010011
`define SLLI            7'b0010011
`define SRLI            7'b0010011

`define ADD             7'b0110011
`define SUB             7'b0110011
`define SLL             7'b0110011

`define XOR             7'b0110011
`define SRL             7'b0110011

`define OR              7'b0110011
`define AND             7'b0110011




`define ECALL           7'b1110011

// FUNCT3
`define FUNCT3_BEQ      3'b000
`define FUNCT3_BNE      3'b001
`define FUNCT3_BLT      3'b100
`define FUNCT3_BGE      3'b101

`define FUNCT3_LW       3'b010
`define FUNCT3_SW       3'b010

`define FUNCT3_ADD      3'b000
`define FUNCT3_SUB      3'b000
`define FUNCT3_SLL      3'b001
`define FUNCT3_XOR      3'b100
`define FUNCT3_OR       3'b110
`define FUNCT3_AND      3'b111
`define FUNCT3_SRL      3'b101

// FUNCT7
`define FUNCT7_SUB      7'b0100000
`define FUNCT7_OTHERS   7'b0000000

`define IF 0
`define ID 1
`define EX 2
`define MEM 3
`define WB 4
`define INIT 7


// `define ARITHMETIC      7'b0110011
// // I-type instruction opcodes
// `define ARITHMETIC_IMM  7'b0010011
// `define LOAD            7'b0000011
// `define JALR            7'b1100111
// // S-type instruction opcodes
// `define STORE           7'b0100011
// // B-type instruction opcodes
// `define BRANCH          7'b1100011
// // U-type instruction opcodes
// //`define LUI             7'b0110111
// //`define AUIPC           7'b0010111
// // J-type instruction opcodes
// `define JAL             7'b1101111