/*
    yosys -p 'synth_ice40;' test.v

*/

module test(input clk, wen, input [8:0] addr, input [7:0] wdata, output reg [7:0] rdata);
  reg [7:0] mem [0:511];
  initial mem[0] = 255;
  always @(posedge clk) begin
        if (wen) 
            mem[addr] <= wdata;
        rdata <= mem[addr];
  end
endmodule
