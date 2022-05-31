module ForwardingUnit (input [4:0] rs1,
			input [4:0] rs2,
			input [4:0] EX_MEM_rd,
            input [4:0] MEM_WB_rd,
		    input EX_MEM_reg_write,
            input MEM_WB_reg_write,
            output reg [1:0] ForwardA,
            output reg [1:0] ForwardB
            );

// always @(*) begin
//     $display("rs1 : %d , rs2 : %d, EX_MEM_rd: %d MEM_WB_rd : %d", rs1, rs2, EX_MEM_rd, MEM_WB_rd);        
// end

always @(*) begin
    if ((rs1 != 5'b0) && (rs1 == EX_MEM_rd))
        ForwardA = 2'b10;
    else if ((rs1 != 5'b0) && (rs1 == MEM_WB_rd))
        ForwardA = 2'b01;
    else
        ForwardA = 2'b00;
        
    if ((rs2 != 5'b0) && (rs2 == EX_MEM_rd))
        ForwardB = 2'b10;
    else if ((rs2 != 5'b0) && (rs2 == MEM_WB_rd))
        ForwardB = 2'b01;
    else
        ForwardB = 2'b00;

    // if (rs1 == 17 && EX_MEM_rd == 17) begin // 1 stall 
    //     ForwardA = 2'b10;
    // end
end



// always @(*) begin
//     $display("ForwardA : %b , ForwardB : %b", ForwardA, ForwardB);
// end

endmodule

module MuxControl (input [31:0] IF_ID_inst,
			input [4:0] MEM_WB_rd, // write location 
            output reg WB_rs1,
            output reg WB_rs2);

always @(*) begin

    if ((IF_ID_inst[19:15] != 5'b0) && (IF_ID_inst[19:15] == MEM_WB_rd))
         WB_rs1 = 1;
    else
         WB_rs1 = 0;
    if ((IF_ID_inst[24:20] != 5'b0) && (IF_ID_inst[24:20] == MEM_WB_rd))
         WB_rs2 = 1;
    else
         WB_rs2 = 0;
end

endmodule