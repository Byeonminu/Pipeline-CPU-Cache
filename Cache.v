`include "DataMemory.v"
`include "CLOG2.v"

module Cache #(parameter LINE_SIZE = 16,
               parameter NUM_SETS = 16,
               parameter NUM_WAYS = 1) (
    input reset,
    input clk,

    input is_input_valid,
    input [31:0] addr,
    input mem_read,
    input mem_write,
    input [31:0] din,

    output is_ready,
    output is_output_valid,
    output [31:0] dout,
    output is_hit);



//  always @(*) begin
//     $display("mem_write: %b is_hit: %b , is_evicted : %b, real_addr: %x, address_index: %d, evicted_data[3]: %x evicted_data[2]: %x evicted_data[1]: %x evicted_data[0]: %x, address_block_offset: %d, din: %x",mem_write, is_hit, is_evicted, real_addr, address_index, evicted_data[127:96],evicted_data[95:64], evicted_data[63:32], evicted_data[31:0], address_block_offset, din );
//   end

  
//  always @(*) begin
//     $display("cache_tag : %x, address_tag : %x, real_addr: %x, real_addr >> `CLOG2(LINE_SIZE) : %x address_index: %d ", cache_tag, address_tag, real_addr, (real_addr >> (`CLOG2(LINE_SIZE))), address_index);
//   end



  // always @(*) begin
  //   if(mem_write && is_hit) begin
  //     $display("cache_line[%d], address_block_offset : %b, din : %x", address_index, address_block_offset, din);
  //   end
  // end

  // Wire declarations
  wire is_data_mem_ready;
  // Reg declarations
  // You might need registers to keep the status.

  reg [153:0]        cache_line[0:15];
  wire [23:0]        cache_tag;
  wire               cache_valid;
  wire               cache_dirty;
  wire [127:0]       cache_data;
 
  assign cache_tag = cache_line[address_index][153:130];
  assign cache_valid = cache_line[address_index][129];
  assign cache_dirty = cache_line[address_index][128];
  assign cache_data = cache_line[address_index][127:0];

  wire [23:0]        address_tag;
  wire [3:0]         address_index;
  wire [1:0]         address_block_offset;

  assign address_tag = addr[31:8];
  assign address_index = addr[7:4];
  assign address_block_offset = addr[3:2];

  assign dout =  (is_hit && address_block_offset == 0) ? cache_data[31:0] :
  (is_hit && address_block_offset == 1) ? cache_data[63:32] :
  (is_hit && address_block_offset == 2) ? cache_data[95:64] :
  (is_hit && address_block_offset == 3) ? cache_data[127:96] : 32'b0;

  assign is_hit = (cache_tag == address_tag) && cache_valid;
  assign is_ready = is_data_mem_ready; // data main memory의 delay counter가 0일 때 1 -> 준비 완료!


  wire[127:0]         mem_dout;
  wire[127:0]         evicted_data;
  wire               is_evicted;
  assign is_evicted = ((mem_read || mem_write) && !is_hit) && cache_dirty ? 1'b1 : 1'b0;
  reg [31:0] counter;
  // reg [31:0] for_miss_counter;
  // always @(*) begin
  //   if(is_evicted) begin
  //     cache_line[address_index][128] = 0;
  //   end
  // end

  assign evicted_data = is_evicted ? cache_data : 128'b0;

  wire [31:0]         real_addr;
  assign real_addr = (is_evicted) ? {cache_tag, address_index, 4'b0000} : addr;


  // 메모리 주소 24: 태그, 4: 인덱스, 2: blockoffset, 2: 무시
  // 캐시 라인: 24:태그, 1: valid , 1: dirty 32 * 4 :data bank
  integer i;
  always @(posedge clk) begin
    if(reset) begin
      for( i =0 ; i < 16; i = i + 1) begin
      cache_line[i] <= 0;
      end
    end
    else begin
      if((mem_read || mem_write) && ~is_hit && is_data_mem_ready && ~is_evicted && is_output_valid_mem ) begin
        // $display("miss이므로 캐시에 새로 써주기 이 때 real_addr: %x", real_addr);
        cache_line[address_index] <= {address_tag, 1'b1, 1'b0, mem_dout};
      end
      else if(mem_write && is_hit ) begin
          // $display("store이므로 캐시에 값 써주기 " );
        if(address_block_offset == 0) 
          cache_line[address_index] <= {address_tag, 1'b1, 1'b1, cache_data[127:96], cache_data[95:64], cache_data[63:32], din};
        else if(address_block_offset == 1) 
          cache_line[address_index] <= {address_tag, 1'b1, 1'b1, cache_data[127:96], cache_data[95:64], din, cache_data[31:0] };
        else if(address_block_offset == 2) 
          cache_line[address_index] <= {address_tag, 1'b1, 1'b1, cache_data[127:96], din, cache_data[63:32], cache_data[31:0] };
        else if(address_block_offset == 3) 
          cache_line[address_index] <= {address_tag, 1'b1, 1'b1, din, cache_data[95:64], cache_data[63:32], cache_data[31:0] };
      end

       if(is_evicted) begin
         counter <= counter + 1;
      end
      else begin
        counter <= 0;
      end

      if(counter >= 50 && is_data_mem_ready) begin
        counter <= 0;
        cache_line[address_index][128] <= 0;
      end

      
      // if((mem_read || mem_write) && ~is_hit && is_data_mem_ready && ~is_evicted) begin
      //   for_miss_counter <= for_miss_counter +1;
      // end
      // else for_miss_counter <= 0;

      // if(for_miss_counter >= 50) for_miss_counter <= 0;
      
    end
  end
  
  wire is_output_valid_mem;
  assign is_output_valid = is_hit || is_output_valid_mem;

  //read hit : dout = ~
  //read miss : 50 stall -> cache에 mem_dout을 write -> 여기서 어떻게 스톨을 할까? stall -> dout = ~
  //write hit : cache에 가져온 거를 write   && dirty bit가 1
  //write miss : 50 stall -> cache에 mem_dout을 write -> 여기서 어떻게 스톨을 할까? 1stall -> cache에 write - dirty bit가 1
  
  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),
    .is_input_valid(is_input_valid),  // is data memory ready to accept request?
    .addr(real_addr >> (`CLOG2(LINE_SIZE))),        // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read((~is_hit) && (~is_evicted)), 
    .mem_write((~is_hit) && is_evicted && (counter < 50)),
    .din(evicted_data),
    .is_output_valid(is_output_valid_mem),
    .dout(mem_dout),
    .mem_ready(is_data_mem_ready)

    // is output from the data memory valid?



    // send inputs to the data memory.
   
  
   

  );

  
endmodule

