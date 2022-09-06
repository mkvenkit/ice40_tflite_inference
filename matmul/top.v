/*

top.v

*/

`default_nettype none

module top(
  input clk,
  output led   // LED 
);


// BEGIN - init hack
// iCE40 does not allow registers to initialised to 
// anything other than 0
// For workaround see:
// https://github.com/YosysHQ/yosys/issues/103
reg [7:0] resetn_counter = 0;
wire resetn = &resetn_counter;

always @(posedge clk) 
begin
    if (!resetn)
    begin
        resetn_counter <= resetn_counter + 1;
    end
end

reg RL;
reg [22:0] counter;

always @ (posedge clk) begin 
    if (!resetn) begin
        counter <= 0;
    end
    else begin
        counter <= counter + 1;
        if(!counter)
            RL <= ~RL;
    end
end

wire [31:0] D;

matmul m1 (
    .clk(clk), 
    .resetn(resetn),
    .start(1'b1),
    .D(D)
);

// set LED
assign led = &D;

endmodule