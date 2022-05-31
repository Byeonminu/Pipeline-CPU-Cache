module mux_2_to_1(
                input [31:0] first,
                input [31:0] second,
                input signal,
                output [31:0] result);


assign result = (signal) ? second : first;

// always @(result) begin
// $display("result is %x", result);
// end

endmodule

module mux_4_to_1(
                input [31:0] first,
                input [31:0] second,
                input [31:0] third,
                input [1:0] signal,
                output reg [31:0] result);


always @(*) begin

    case (signal)
        2'b00: result = first;
        2'b01: result = {{29{1'b0}}, second};
        2'b10: result = third;
    endcase
end

endmodule