// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required
`include "mux.v"
`include "pc.v"
`include "control_unit.v"
`include "ImmediateGenerator.v"
`include "opcodes.v"
`include "alu.v"
`include "RegisterFile.v"
`include "Forwarding.v"
`include "Hazard_unit.v"
`include "Cache.v"
`include "InstMemory.v"

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  reg [31:0] IF_ID_pc;  
  reg IF_ID_is_stall_check;
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [1:0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_is_halted;
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_ALU_ctrl_unit_input;
  reg [4:0] ID_EX_rd;
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;
  reg [31:0] ID_EX_pc; 
  reg ID_EX_branch; 
  reg ID_EX_is_jal; 
  reg ID_EX_is_jalr; 
  reg ID_EX_pc_to_reg; 
  reg [31:0] ID_EX_inst; 
  wire IF_ID_write; // signal

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_is_halted;
  reg EX_MEM_pc_to_reg; 
  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;
  reg [31:0] EX_MEM_pc;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  reg MEM_WB_is_halted;
  reg MEM_WB_pc_to_reg; 
  // From others
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;
  reg [4:0] MEM_WB_rd;
  reg [31:0] MEM_WB_pc;
   



  //PC
  wire [31:0] next_pc;
  wire [31:0] current_pc;
  wire pc_write;
  //Inst mem
  wire [31:0] dout_inst;

  // RegisterFile
  wire [4:0] rs1;
  
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [31:0] rd_din;

  //control unit
  wire mem_read;
  wire mem_write;
  wire mem_to_reg;
  wire alu_src;
  wire write_enable;
  wire [1:0] alu_op;
  wire is_ecall;
  wire branch;
  wire is_jal;
  wire is_jalr;
  wire pc_to_reg;


  //ImmediateGenerator
  wire [31:0] imm_gen_out;


  // alu / alu_control
  wire [3:0] alu_control;
  wire [31:0] alu_in_1;
  wire [31:0] alu_in_2;
  wire [31:0] alu_result;
  wire [2:0] alu_bcond;

  wire [31:0] alu_in_2_temp;
  
  //Data mem
  wire [31:0] dout_mem;
  
  wire [31:0] mem_to_reg_temp;

  //forwarding | hazard
  wire [1:0] ForwardA;
  wire [1:0] ForwardB;
  wire is_stall;
  wire is_flush;
  wire WB_rs1;
  wire WB_rs2;
  wire [31:0] rs1_temp;
  wire [31:0] rs2_temp;

  wire alu_bcond_temp;
  


  //cache
  wire is_input_valid;
  assign is_input_valid = (EX_MEM_mem_read || EX_MEM_mem_write);
  wire is_hit;
  wire is_output_valid;
  wire is_ready;
  wire for_cache;
  wire cache_stall;
  assign for_cache = (is_input_valid) ? (!is_hit || !is_output_valid || !is_ready) : 1'b0;

  // always @(*) begin
  //   $display("for_cache: %b , is_hit : %b, is_output_valid :%b , is_ready: %b", for_cache, is_hit, is_output_valid, is_ready);
  // end

  // always @(jump_pc) begin
  //   $display("점프 pc!!: %x, ID_EX_pc : %x, ID_EX_imm: %x , jalr인가? : %b, ID_EX_rs1_data : %x", jump_pc, ID_EX_pc ,ID_EX_imm, ID_EX_is_jalr, ID_EX_rs1_data);

  // end

  assign next_pc = current_pc + 4;
  wire [31:0] jump_pc;
  wire [31:0] real_pc;
  assign jump_pc = (ID_EX_is_jalr == 1) ? ((ID_EX_rs1_data + ID_EX_imm) & 32'hfffffffe) : (ID_EX_pc + ID_EX_imm);


  
  wire is_jump;
  assign is_jump = (ID_EX_branch & alu_bcond_temp) || ID_EX_is_jal || ID_EX_is_jalr;
  
  mux_2_to_1 rs1_forward(rs1_dout, mem_to_reg_temp, WB_rs1, rs1_temp);
  mux_2_to_1 rs2_forward(rs2_dout, mem_to_reg_temp, WB_rs2, rs2_temp);
  
  mux_2_to_1 pc_or_mem(mem_to_reg_temp, MEM_WB_pc + 4, MEM_WB_pc_to_reg, rd_din); // jal, jalr일 때 pc+4를 저장하는지 판단
  mux_2_to_1 pc_jump(next_pc, jump_pc, is_jump, real_pc); // bracnh나 jump일 때 nextpc와 jumppc 중 골라줌
  mux_2_to_1 mem_reg(MEM_WB_mem_to_reg_src_1, MEM_WB_mem_to_reg_src_2, MEM_WB_mem_to_reg, mem_to_reg_temp);
  mux_4_to_1 alu_input1(ID_EX_rs1_data, mem_to_reg_temp, EX_MEM_alu_out, ForwardA, alu_in_1);
  mux_4_to_1 alu_input2(ID_EX_rs2_data, mem_to_reg_temp, EX_MEM_alu_out, ForwardB, alu_in_2_temp);
  mux_2_to_1 reg_imm(alu_in_2_temp, ID_EX_imm, ID_EX_alu_src, alu_in_2);

  assign rs1 = (is_ecall) ? 17: IF_ID_inst[19:15];
  
  wire [31:0] rs1_temp_real;
  assign rs1_temp_real = (rs1 == 17 && EX_MEM_rd == 17 && IF_ID_inst[6:0] == `ECALL) ? EX_MEM_alu_out : 
  (rs1 == 17 && MEM_WB_rd == 17 && IF_ID_inst[6:0] == `ECALL) ? MEM_WB_mem_to_reg_src_1 : rs1_temp;
  
  // always @(rs1_dout or WB_rs1 or rs1_temp or rs1_temp_real) begin

  //   $display("rs1_dout: %x, WB_rs1: %b, rs1_temp: %x, rs1_temp_real: %x", rs1_dout, WB_rs1, rs1_temp, rs1_temp_real);
  // end


  wire is_halted_temp;
  assign is_halted_temp = (is_ecall && (rs1_temp_real == 10)) ? 1 : 0;
  assign is_halted = MEM_WB_is_halted;
  
  // always @(*) begin
  //   $display("플러시!!! : %b",is_flush);
  //   // $display("14: %x, 15: %x\n",reg_file.rf[14],reg_file.rf[15]) ;
  //   $display("ID_EX_branch: %b, ||  alu_bcond_temp :%b  || ID_EX_is_jal :%b || ID_EX_is_jalr: %b, and is_jump : %b ",ID_EX_branch,alu_bcond_temp, ID_EX_is_jal, ID_EX_is_jalr, is_jump);
  // end

  //  always @(is_stall) begin
  //   $display("그냥 스톨!!!! : %b", is_stall);
  // end
  

  // always @(*) begin
  //   $display("is_ecall is %b", is_ecall);
  // end
  always @(current_pc) begin
    // $display("14: %x, 15: %x\n",reg_file.rf[14],reg_file.rf[15]) ;
  end

  integer i;
  // always @(*) begin
  //   if(current_pc >= 12'h8f8) begin
  //     for (i = 0; i < 32; i = i + 1)
  //       $display("%d %x\n", i, reg_file.rf[i]);
  //     $display("캐시");
  //     for (i = 0; i < 16; i = i + 1)
  //       $display("%d %x, %x, %x, %x\n", i, cache.cache_line[i][127:96], cache.cache_line[i][95:64], cache.cache_line[i][63:32], cache.cache_line[i][31:0]);

  //      $display("데이터 메모리 %x, %x, %x, %x", cache.data_mem.mem[766][127:96], cache.data_mem.mem[766][95:64], cache.data_mem.mem[766][63:32], cache.data_mem.mem[766][31:0]);
  //       $finish();
  //   end
  // end


  // always @(current_pc) begin
  //   $display("------ ------- ------ -------- -------- ------ ----- current_pc %x\n", current_pc);
  //   // $display("------ ------- ------ ------ ----- IF_ID_inst %x\n", IF_ID_inst);
  // end
  // always @(*) begin

  //   $display("alu_in_1 %x\n", alu_in_1);
  //   $display("alu_in_2 %x\n", alu_in_2);
   
  // end
  //  always @(*) begin
  //  $display("EX_MEM_alu_out %x\n", EX_MEM_alu_out);
  // end
   

  //  always @(*) begin
  //    $display("MEM_WB_mem_to_reg_src_1 %x", MEM_WB_mem_to_reg_src_1);
  //    $display("MEM_WB_mem_to_reg_src_2 %x", MEM_WB_mem_to_reg_src_2);
  //    $display("MEM_WB_mem_to_reg %x", MEM_WB_mem_to_reg);
  //  end
  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(real_pc),     // input
    .current_pc(current_pc),   // output
    .pc_write(pc_write) // input
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(dout_inst)     // output
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      IF_ID_inst <= 32'b0;
      IF_ID_pc <= 32'b0;
      IF_ID_is_stall_check <= 1'b0;
    end
    else begin
      if(is_flush) begin
        IF_ID_inst <= 32'b0;
        IF_ID_pc <= 32'b0;
        IF_ID_is_stall_check <= 1'b0;
      end 
      else if(IF_ID_write) begin
      
        IF_ID_inst <= dout_inst;
        IF_ID_pc <= current_pc;
        IF_ID_is_stall_check <= 1'b0;
      end
      else if(is_stall) begin
        IF_ID_is_stall_check <= 1'b1;
        // IF_ID_inst <= IF_ID_inst;
        // IF_ID_pc <= IF_ID_pc;
      end
       else if(cache_stall) begin
        IF_ID_is_stall_check <= 1'b0;
        // IF_ID_inst <= IF_ID_inst;
        // IF_ID_pc <= IF_ID_pc;
      end
      else begin
      
      end
    end
  end

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1),          // input
    .rs2 (IF_ID_inst[24:20]),   // input
    .rd (MEM_WB_rd),           // input
    .rd_din (rd_din),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)     // output
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .opcode(IF_ID_inst[6:0]),  // input
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(write_enable),  // output
    .alu_op(alu_op),        // output
    .is_ecall(is_ecall),       // output (ecall inst)
    .branch(branch),
    .is_jal(is_jal),
    .is_jalr(is_jalr),
    .pc_to_reg(pc_to_reg)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IF_ID_inst),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      ID_EX_alu_op <= 2'b0;      
      ID_EX_alu_src <= 0;     
      ID_EX_mem_write <= 0;
      ID_EX_mem_read <= 0;    
      ID_EX_mem_to_reg <= 0;
      ID_EX_reg_write <= 0;  
      ID_EX_rs1_data <= 32'b0;
      ID_EX_rs2_data <= 32'b0;
      ID_EX_imm <= 32'b0;
      ID_EX_ALU_ctrl_unit_input <= 32'b0;
      ID_EX_rd <= 5'b0;
      ID_EX_rs1 <= 5'b0;
      ID_EX_rs2 <= 5'b0;
      ID_EX_pc <= 32'b0; 
      ID_EX_branch <= 1'b0;
      ID_EX_is_jal <= 1'b0;
      ID_EX_is_jalr <= 1'b0;
      ID_EX_pc_to_reg <= 1'b0; 
      ID_EX_inst <= 32'b0;
    end
    else begin
        if (is_stall | is_flush) begin
        //  $display("ID_EX에서 is_stall ");
        // $display("클락 플러시--- : %b", is_flush);
        // $display("이 때 instruction : %b", ID_EX_inst[6:0]);
        ID_EX_alu_op <= 2'b0;
        ID_EX_alu_src <= 0; 
        ID_EX_mem_write <= 0;
        ID_EX_mem_read <= 0; 
        ID_EX_mem_to_reg <= 0;
        ID_EX_reg_write <= 0;
        ID_EX_rs1 <= 5'b0;
        ID_EX_rs2 <= 5'b0;
        ID_EX_rd <=  5'b0;
        ID_EX_rs1_data <= 32'b0;
        ID_EX_rs2_data <= 32'b0;
        ID_EX_imm <= 32'b0;
        ID_EX_ALU_ctrl_unit_input <= 32'b0;
        ID_EX_is_halted <= 0;
        ID_EX_pc <= 32'b0;
        ID_EX_branch <= 1'b0;
        ID_EX_is_jal <= 1'b0;
        ID_EX_is_jalr <= 1'b0;
        ID_EX_pc_to_reg <= 1'b0;  
        ID_EX_inst <= 32'b0;
      end
      else if(cache_stall) begin
        // $display("ID_EX 단계 캐시 스톨!, alu_in_1: %x alu_in_2 :%x alu_result: %x", alu_in_1, alu_in_2, alu_result);
        // $display("ID_EX에서 cache_stall ");
        // ID_EX_alu_op <= ID_EX_alu_op;
        // ID_EX_alu_src <= ID_EX_alu_src; 
        // ID_EX_mem_write <= ID_EX_mem_write;
        // ID_EX_mem_read <= ID_EX_mem_read; 
        // ID_EX_mem_to_reg <= ID_EX_mem_to_reg;
        // ID_EX_reg_write <= ID_EX_reg_write;
        // ID_EX_rs1 <= ID_EX_rs1;
        // ID_EX_rs2 <= ID_EX_rs2;
        // ID_EX_rd <=  ID_EX_rd;
        // ID_EX_rs1_data <= ID_EX_rs1_data;
        // ID_EX_rs2_data <= ID_EX_rs2_data;
        // ID_EX_imm <= ID_EX_imm;
        // ID_EX_ALU_ctrl_unit_input <= ID_EX_ALU_ctrl_unit_input;
        // ID_EX_is_halted <= ID_EX_is_halted;
        // ID_EX_pc <= ID_EX_pc;
        // ID_EX_branch <= ID_EX_branch;
        // ID_EX_is_jal <= ID_EX_is_jal;
        // ID_EX_is_jalr <= ID_EX_is_jalr;
        // ID_EX_pc_to_reg <= ID_EX_pc_to_reg;
        // ID_EX_inst <= ID_EX_inst;
      end
      else begin
      ID_EX_alu_op <= alu_op; 
      ID_EX_alu_src <= alu_src;  
      ID_EX_mem_write <= mem_write;
      ID_EX_mem_read <= mem_read; 
      ID_EX_mem_to_reg <= mem_to_reg;
      ID_EX_reg_write <= write_enable;
      ID_EX_rs1_data <= rs1_temp_real;
      ID_EX_rs2_data <= rs2_temp;
      ID_EX_imm <= imm_gen_out;
      ID_EX_ALU_ctrl_unit_input <= IF_ID_inst;
      ID_EX_is_halted <= is_halted_temp;
      ID_EX_pc <= IF_ID_pc; 
      ID_EX_branch <= branch;
      ID_EX_is_jal <= is_jal;
      ID_EX_is_jalr <= is_jalr;
      ID_EX_pc_to_reg <= pc_to_reg;
      ID_EX_inst <= IF_ID_inst;
      if(IF_ID_inst[6:0] == `ADD) begin
        ID_EX_rs1 <= IF_ID_inst[19:15];
        ID_EX_rs2 <= IF_ID_inst[24:20];
        ID_EX_rd <=  IF_ID_inst[11:7];
      end
      else if(IF_ID_inst[6:0] == `ADDI) begin
        ID_EX_rs1 <= IF_ID_inst[19:15];
        ID_EX_rs2 <= 5'b0;
        ID_EX_rd <=  IF_ID_inst[11:7];
      end
      else if(IF_ID_inst[6:0] == `LW) begin
        ID_EX_rs1 <= IF_ID_inst[19:15];
        ID_EX_rs2 <= 5'b0;
        ID_EX_rd <=  IF_ID_inst[11:7];
      end
      else if(IF_ID_inst[6:0] == `SW) begin
        ID_EX_rs1 <= IF_ID_inst[19:15];
        ID_EX_rs2 <= IF_ID_inst[24:20];
        ID_EX_rd <=  5'b0;
      end
      else if(IF_ID_inst[6:0] == `ECALL) begin
        ID_EX_rs1 <= rs1;
        ID_EX_rs2 <= 5'b0;
        ID_EX_rd <=  5'b0;
      end
      else if(IF_ID_inst[6:0] == `BEQ) begin
        ID_EX_rs1 <= IF_ID_inst[19:15];
        ID_EX_rs2 <= IF_ID_inst[24:20];
        ID_EX_rd <=  5'b0;
      end
      else if(IF_ID_inst[6:0] == `JAL) begin
        ID_EX_rs1 <= 5'b0;
        ID_EX_rs2 <= 5'b0;
        ID_EX_rd <=  IF_ID_inst[11:7];
      end
      else if(IF_ID_inst[6:0] == `JALR) begin
        ID_EX_rs1 <= IF_ID_inst[19:15];
        ID_EX_rs2 <= 5'b0;
        ID_EX_rd <=  IF_ID_inst[11:7];
      end
      end
      
      // $display("ID/EX");
      // $display("ID_EX_alu_op");
    end
  end

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(ID_EX_ALU_ctrl_unit_input),  // input
    .alu_op(ID_EX_alu_op),
    .alu_control(alu_control)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_control(alu_control),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .ID_EX_inst(ID_EX_inst),
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond),     //output
    .alu_bcond_temp(alu_bcond_temp)
  );

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write <= 0;    
      EX_MEM_mem_read <= 0;      
      EX_MEM_mem_to_reg <= 0;    
      EX_MEM_reg_write <= 0;  
      EX_MEM_pc_to_reg <= 0;  
      EX_MEM_alu_out <= 32'b0;
      EX_MEM_dmem_data <= 32'b0; 
      EX_MEM_rd <= 5'b0;
      EX_MEM_is_halted <= 0;
      EX_MEM_pc <= 0;
    end
    else begin
      if(cache_stall) begin
      // $display("EX_MEM 단계 stall!!");
      // EX_MEM_mem_write <= EX_MEM_mem_write;
      // EX_MEM_mem_read <= EX_MEM_mem_read;       
      // EX_MEM_mem_to_reg <= EX_MEM_mem_to_reg;   
      // EX_MEM_reg_write <= EX_MEM_reg_write; 
      // EX_MEM_pc_to_reg <= EX_MEM_pc_to_reg;  
      // EX_MEM_alu_out <= EX_MEM_alu_out; 
      // EX_MEM_dmem_data <= EX_MEM_dmem_data; 
      // EX_MEM_rd <= EX_MEM_rd;
      // EX_MEM_is_halted <= EX_MEM_is_halted;
      // EX_MEM_pc <= EX_MEM_pc;
      end
      else begin
      // $display("EX_MEM 단계 캐시 스톨 아님!! EX_MEM_alu_out : %x", EX_MEM_alu_out);
      EX_MEM_mem_write <= ID_EX_mem_write;
      EX_MEM_mem_read <= ID_EX_mem_read;       
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;   
      EX_MEM_reg_write <= ID_EX_reg_write; 
      EX_MEM_pc_to_reg <= ID_EX_pc_to_reg;  
      EX_MEM_alu_out <= alu_result; 
      EX_MEM_dmem_data <= alu_in_2_temp; 
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_is_halted <= ID_EX_is_halted;
      EX_MEM_pc <= ID_EX_pc;
      end
    end
  end

  // ---------- Data Memory ----------
  //DataMemory dmem(
  //  .reset (reset),      // input
  //  .clk (clk),        // input
  //  .addr (EX_MEM_alu_out),       // input
  //  .din (EX_MEM_dmem_data),        // input
  //  .mem_read (EX_MEM_mem_read),   // input
  //  .mem_write (EX_MEM_mem_write),  // input
  //  .dout (dout_mem)        // output
  //);

  // --------- Cache ----------
  Cache cache(
    .reset (reset),      // input
    .clk (clk),         // input
    .is_input_valid(is_input_valid),    // input
    .addr (EX_MEM_alu_out),        // input
    .mem_read (EX_MEM_mem_read), // input
    .mem_write (EX_MEM_mem_write), // input
    .din (EX_MEM_dmem_data), // input
    .is_ready (is_ready), // output
    .is_output_valid(is_output_valid), // output
    .dout (dout_mem) , // output
    .is_hit(is_hit) // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg <= 0;
      MEM_WB_reg_write <= 0;
      MEM_WB_mem_to_reg_src_1 <= 32'b0;
      MEM_WB_mem_to_reg_src_2 <= 32'b0;
      MEM_WB_rd <= 5'b0;
      MEM_WB_is_halted <= 0;
      MEM_WB_pc_to_reg <= 0;
      MEM_WB_pc <= 0;
    end
    else begin
      if(cache_stall) begin

      end
      else begin
        MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
        MEM_WB_reg_write <= EX_MEM_reg_write;
        MEM_WB_mem_to_reg_src_1 <= dout_mem;
        MEM_WB_mem_to_reg_src_2 <= EX_MEM_alu_out;
        MEM_WB_rd <= EX_MEM_rd;
        MEM_WB_is_halted <= EX_MEM_is_halted;
        MEM_WB_pc_to_reg <= EX_MEM_pc_to_reg;
        MEM_WB_pc <= EX_MEM_pc;
      end
    end
  end

  ForwardingUnit forward(
    .rs1(ID_EX_rs1), //input
    .rs2(ID_EX_rs2), //input
    .EX_MEM_rd(EX_MEM_rd), //input
    .MEM_WB_rd(MEM_WB_rd), //input
    .EX_MEM_reg_write(EX_MEM_reg_write), //input
    .MEM_WB_reg_write(MEM_WB_reg_write), //input
    .ForwardA(ForwardA), //output
    .ForwardB(ForwardB) //output
  );

  HazardDetectionUnit hazard(
   .IF_ID_inst(IF_ID_inst), //input
   .IF_ID_is_stall_check(IF_ID_is_stall_check),
   .ID_EX_rd(ID_EX_rd), //input
   .ID_EX_mem_read(ID_EX_mem_read), //input
   .EX_MEM_rd(EX_MEM_rd),
   .EX_MEM_mem_read(EX_MEM_mem_read),
   .is_jump(is_jump),
   .for_cache(for_cache),
   .pc_write(pc_write), //output
   .IF_ID_write(IF_ID_write), //output
   .is_stall(is_stall), //output
   .is_flush(is_flush),
   .cache_stall(cache_stall)
 );

 MuxControl mux_control(
  .IF_ID_inst(IF_ID_inst),
  .MEM_WB_rd(MEM_WB_rd),
  .WB_rs1(WB_rs1),
  .WB_rs2(WB_rs2)
 );
  
endmodule
