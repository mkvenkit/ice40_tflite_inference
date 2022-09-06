/* 

    Testbench.

*/


// Never forget this!
`default_nettype none

module tb();

reg clk;
reg resetn;
reg start;

wire [31:0] c0;
wire [31:0] c1;
wire [31:0] c2;
wire [31:0] c3;
wire [31:0] D;

matmul m1 (
    .clk(clk), 
    .resetn(resetn),
    .start(start),
    .c0(c0),
    .c1(c1),
    .c2(c2),
    .c3(c3),
    .D(D)
);

initial begin
    // initialise values
    clk = 1'b0;
    // reset 
    resetn = 1'b1;
    #4
    resetn = 1'b0;
    #4
    resetn = 1'b1;

    // start 
    start = 1'b0;
    #2
    start = 1'b1;
    #2
    start = 1'b0;

end

// generate clk
always @ ( * ) begin
    #1
    clk <= ~clk; 
end

localparam P = 8;
localparam NROWS = 10;

integer i;
initial begin
    $dumpfile("testbench.vcd");
    $dumpvars;
    #10000
    $finish;
end
endmodule