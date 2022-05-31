`include "opcodes.v"

module HazardDetectionUnit (input [31:0] IF_ID_inst,
                            input IF_ID_is_stall_check,
                            input [4:0] ID_EX_rd,
                            input ID_EX_mem_read,
                            input [4:0] EX_MEM_rd,
                            input EX_MEM_mem_read,
                            input is_jump,
                            input for_cache,
                            output reg pc_write,
                            output reg IF_ID_write,
                            output reg is_stall,
                            output reg is_flush,
                            output reg cache_stall);

always @(*) begin
     if(for_cache == 1) begin
                // $display("캐시 스톨");
                pc_write = 0;
                IF_ID_write = 0;
                is_stall = 0;
                is_flush = 0;
                cache_stall = 1;
        end
        else begin
            if (ID_EX_mem_read == 1) begin
                if ((IF_ID_inst[19:15] == ID_EX_rd || IF_ID_inst[24:20] == ID_EX_rd) && ~IF_ID_is_stall_check) begin
                    // $display("그냥 스톨 해저드 유닛");
                    pc_write = 0;
                    IF_ID_write = 0;
                    is_stall = 1;
                    is_flush = 0;
                    cache_stall = 0;
                end
                else begin
                    pc_write = 1;
                    IF_ID_write = 1;
                    is_stall = 0;
                    is_flush = 0;
                    cache_stall = 0;
                    end

            end
            else if(ID_EX_rd == 17 && IF_ID_inst[6:0] == `ECALL) begin // 1 stall
                pc_write = 0;
                IF_ID_write = 0;
                is_stall = 1;
                is_flush = 0;
                cache_stall = 0;
            end
            else if (EX_MEM_mem_read == 1) begin
                if (EX_MEM_rd == 17 && IF_ID_inst[6:0] == `ECALL) begin // load 2 stall
                    pc_write = 0; 
                    IF_ID_write = 0;
                    is_stall = 1;
                    is_flush = 0;
                    cache_stall = 0;
                end
                else begin
                  
                    pc_write = 1;
                    IF_ID_write = 1;
                    is_stall = 0;
                    is_flush = 0;
                    cache_stall = 0;
                end
            end
            else begin
                    pc_write = 1;
                    IF_ID_write = 1;
                    is_stall = 0;
                    is_flush = 0;
                    cache_stall = 0;

            end
        end

end


// always @(*) begin
//     if(for_cache == 1) begin
//         $display("캐시 스톨");
//         pc_write = 0;
//         IF_ID_write = 0;
//         is_stall = 0;
//         is_flush = 0;
//         cache_stall = 1;
//         end
//     else begin
//             pc_write = 1;
//             IF_ID_write = 1;
//             is_stall = 0;
//             is_flush = 0;
//             cache_stall = 0;
//         end

// end

// always @( * ) begin
//    if(is_jump) begin
//        pc_write = 1; 
//        IF_ID_write = 0;
//        is_stall = 0;
//        is_flush = 1;
//    end
//    else begin
//        pc_write = 1; 
//        IF_ID_write = 1;
//        is_stall = 0;
//        is_flush = 0;
//    end
// end




endmodule




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



// module hazard_unit(opcode, function_code, bcond, read1, read2, IDEX_write_reg, EXMEM_write_reg, IDEX_reg_write, IDEX_mem_read,  EXMEM_mem_read, is_stall, is_flush);

// 	input [3:0]		opcode;
// 	input [5:0]		function_code;
// 	input			bcond;
// 	input [1:0]		read1;
// 	input [1:0]		read2;
// 	input [1:0]		IDEX_write_reg;
// 	input [1:0]		EXMEM_write_reg;
// 	input			IDEX_reg_write;
// 	input			IDEX_mem_read;
// 	input			EXMEM_mem_read;

// 	output reg		is_stall;
// 	output reg		is_flush;

	
// 	always @(*) begin
// 		if(IDEX_reg_write && ((((opcode <= `BLZ_OP) || (opcode == `JPR_OP && function_code == `INST_FUNC_JPR) || (opcode == `JRL_OP && function_code == `INST_FUNC_JRL)) && IDEX_write_reg == read1) || ((opcode <= `BLZ_OP) && IDEX_write_reg == read2))) begin
// 			is_stall = 1;
// 		end else if(EXMEM_mem_read && ((((opcode <= `BLZ_OP) || (opcode == `JPR_OP && function_code == `INST_FUNC_JPR) || (opcode == `JRL_OP && function_code == `INST_FUNC_JRL)) && EXMEM_write_reg == read1) || ((opcode <= `BLZ_OP) && EXMEM_write_reg == read2))) begin
// 			is_stall = 1;
// 		end else if(IDEX_mem_read && ((!((opcode <= `BLZ_OP) || (opcode == `JMP_OP) || (opcode == `JAL_OP) || (opcode == `JPR_OP && function_code == `INST_FUNC_JPR) || (opcode == `JRL_OP && function_code == `INST_FUNC_JRL)) && IDEX_write_reg == read1) || ((opcode == `ALU_OP && function_code <= `INST_FUNC_SHR) && IDEX_write_reg == read2))) begin
// 			is_stall = 1;
// 		end else begin
// 			is_stall = 0;
// 		end

// 		if((opcode == `JMP_OP || opcode == `JAL_OP) || (opcode == `JPR_OP && function_code == `INST_FUNC_JPR) || (opcode == `JRL_OP && function_code == `INST_FUNC_JRL) || (bcond && (opcode <= `BLZ_OP)))
// 			is_flush = 1;
// 		else
// 			is_flush = 0;
// 	end
// endmodule