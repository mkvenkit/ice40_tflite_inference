/*

dotp.v

read_verilog dotp.v ; opt ; synth_ice40 -dsp

*/

module dotp (
    input clk,
    input resetn,
    input start,
    output reg [31:0] D
);

localparam N = 8'd70;
reg [7:0] A[N-1:0];
reg [7:0] B[N-1:0];

integer i;
initial begin
    for (i = 0; i < N; i++) begin
        A[i] = i+1;
        B[i] = i+1;
    end
end

localparam sIDLE        = 2'b00;
localparam sSUM1        = 2'b01;
localparam sSUM2        = 2'b10;
localparam sSUM3        = 2'b11;

// N = M*P + K
localparam P = 8'd8;
localparam M = 8'd8;
localparam K = 8'd6;

reg [1:0] state;

localparam IWIDTH = $clog2(M) + 1;
reg [IWIDTH-1:0] index;

reg [31:0] sum[P-1:0];

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

always@(posedge clk) begin
    
    if (!resetn) begin
        D <= 32'd0;
        index <= 0;
        for (i = 0; i < P; i++) begin
            sum[i] <= 0;
        end 
        state <= sIDLE;
    end
    else begin

        case (state)
            sIDLE: begin
                index <= 0;
                for (i = 0; i < P; i++) begin
                    sum[i] <= 0;
                end 
                if (start)
                    state <= sSUM1; 
            end

            sSUM1: begin
                // for each P-chunk of data 
                if (index < M) begin
                    // parallel computation on P units
                    for (i = 0; i < P; i++) begin
                        sum[i] <= sum[i] + A[i + index*P] * B[i + index*P];
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
                    D <= D + A[index + P*M] * B[index + P*M];
                    index <= index + 1;
                end
                else begin
                    state <= sIDLE;
                end
            end
 
            default: 
                state <= sIDLE;
        endcase

    end
end

endmodule
