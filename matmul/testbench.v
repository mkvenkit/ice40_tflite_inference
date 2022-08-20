/* 

    Testbench.

*/


// Never forget this!
`default_nettype none

module tb();

reg clk;
reg resetn;
reg start;

wire [31:0] D;

matmul m1 (
    .clk(clk), 
    .resetn(resetn),
    .start(start),
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
integer i;
initial begin
    $dumpfile("testbench.vcd");
    $dumpvars;
    for (i = i < P; i++; i++) begin
        $dumpvars(0, m1.sum[i]);
    end
    #10000
    $finish;
end
endmodule