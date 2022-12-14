/*

dotp.v

read_verilog dotp.v ; opt ; synth_ice40 -dsp

*/

`default_nettype none

module matmul #(parameter NROWS = 8'd4, parameter NCOLS = 8'd10) (
    input clk,
    input resetn,
    input start,
    output [31:0] c0,
    output [31:0] c1,
    output [31:0] c2,
    output [31:0] c3,
    output reg [31:0] D
);

reg [7:0] A[0:NROWS-1][0:NCOLS-1];
reg [7:0] B[0:NCOLS-1];
reg [31:0] C[0:NROWS-1];

assign c0 = C[0];
assign c1 = C[1];
assign c2 = C[2];
assign c3 = C[3];

integer i, j;
initial begin
    for (i = 0; i < NROWS; i = i+1) begin
        for (j = 0; j < NCOLS; j = j+1)
            A[i][j] = i + j;
    end
    for (i = 0; i < NCOLS; i++) begin
        B[i] = i;
    end
end

localparam sIDLE        = 3'b000;
localparam sSUM1        = 3'b001;
localparam sSUM2        = 3'b010;
localparam sSUM3        = 3'b011;
localparam sSUM4        = 3'b100;

// NCOLS= M*P + K
// P = 8 (number of MAC units)
// M is number of multiples of P  
// K < P is remaining elements 
localparam P = 8'd8;
localparam M = 8'd1;
localparam K = 8'd2;

reg [2:0] state;

reg [7:0] index;

reg [31:0] sum[0:P-1];

// For adder tree
`define USER_ADDER_TREE
// partial sums
wire [31:0] S01 = sum[0] + sum[1];
wire [31:0] S23 = sum[2] + sum[3];
wire [31:0] S45 = sum[4] + sum[5];
wire [31:0] S67 = sum[6] + sum[7];
wire [31:0] S0 = S01 + S23;
wire [31:0] S1 = S45 + S67;
wire [31:0] S = S0 + S1;

reg [$clog2(NROWS): 0] row_index;

always@(posedge clk) begin
    
    if (!resetn) begin
        D <= 32'd0;
        index <= 0;
        for (i = 0; i < P; i++) begin
            sum[i] <= 0;
        end 
        row_index <= 0;
        state <= sIDLE;
    end
    else begin

        case (state)
            sIDLE: begin
                index <= 0;
                D <= 32'd0;
                for (i = 0; i < P; i=i+1) begin
                    sum[i] <= 0;
                end 
                row_index <= 0;
                if (start) begin
                    for (i = 0; i < NROWS; i=i+1) begin
                        C[i] <= 0;
                    end 
                    state <= sSUM1; 
                end
            end

            sSUM1: begin
                // for each P-chunk of data 
                if (index < M) begin
                    // parallel computation on P units
                    for (i = 0; i < P; i++) begin
                        sum[i] <= sum[i] + A[row_index][i + index*P] * B[i + index*P];
                    end
                    // incr index
                    index <= index + 1;
                end
                else begin
                    index <= 0;                    
                    state <= sSUM2; 
                end
            end

            sSUM2: begin
`ifdef USER_ADDER_TREE
                D <= S;
                state <= sSUM3;
`else
                // add up sum across P units 
                if (index < P) begin
                    D <= D + sum[index];
                    index <= index + 1;
                end
                else begin
                    index <= 0;
                    state <= sSUM3;
                end
`endif 
            end

            sSUM3: begin
                // add up remaining sum for K < P 
                // (when N is not an integer multiple of P.)
                if (index < K) begin
                    D <= D + A[row_index][index + P*M] * B[index + P*M];
                    index <= index + 1;
                end
                else begin
                    state <= sSUM4;
                end
            end

            sSUM4: begin
                // set data 
                C[row_index] <= D;
                // incr row
                row_index <= row_index + 1;
                // reset index
                index <= 0;
                D <= 32'd0;
                for (i = 0; i < P; i=i+1) begin
                    sum[i] <= 0;
                end 
                // last row 
                if (row_index == (NROWS-1))
                    state <= sIDLE;
                else 
                    state <= sSUM1;
            end

            default: 
                state <= sIDLE;
        endcase

    end
end

endmodule
