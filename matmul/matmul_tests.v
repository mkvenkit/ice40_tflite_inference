/*

matmul1.v

read_verilog matmul.v ; opt ; synth_ice40 -dsp

*/

module matmul (
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

// define tests here 
//`define TEST1
//`define TEST2
`define TEST3


`ifdef TEST1
reg [7:0] index;

always@(posedge clk) begin
    
    if (!resetn) begin
        D <= 32'd0;
        index <= 0;
    end
    else begin

        if (index < N) begin
           D <= D + A[index] * B[index]; 
        end

        index <= index + 1;
    end
end
`endif 


`ifdef TEST2
reg [7:0] index;
reg [31:0] sum1;
reg [31:0] sum2;

localparam sIDLE        = 2'b00;
localparam sCOMPUTING   = 2'b01;
localparam sDONE        = 2'b10;

reg [1:0] state;

always@(posedge clk) begin
    
    if (!resetn) begin
        D <= 32'd0;
        index <= 0;
        state <= sIDLE;
        sum1 <= 0;
        sum2 <= 0;
    end
    else begin

        case (state)
            sIDLE: begin
                index <= 0;
                sum1 <= 0;
                sum2 <= 0;
                state <= sCOMPUTING; 
            end

            sCOMPUTING: begin
                if (index < N/2) begin
                    sum1 <= sum1 + A[index] * B[index];
                    sum2 <= sum2 + A[index + N/2] * B[index + N/2];
                    index <= index + 1;
                end
                else 
                    state <= sDONE; 
            end
 
            sDONE: begin
                D <= sum1 + sum2;
                state <= sIDLE;                
            end
 
            default: 
                state <= sIDLE;
        endcase

    end
end
`endif 

`ifdef TEST3

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
                // add up sum across P units 
                if (index < P) begin
                    D <= D + sum[index];
                    index <= index + 1;
                end
                else begin
                    index <= 0;
                    state <= sSUM3;
                end
            end

            sSUM2: begin
                // add up remaining sum for K < P 
                // (when N is not an integer multiple of P.)
                if (index < K) begin
                    D <= D + A[index + P*M];
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
`endif 


endmodule
