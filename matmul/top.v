/*

top.v

A Simple UART TX example.

*/

// Never forget this!
`default_nettype none

module top(
  input clk_25mhz,
  input  [6:0] btn,     // BTN_PWRn (btn[0])
  output ftdi_rxd,      // serial output 
  output [7:0] led   // LED 
);

// reset signal for modules 
wire resetn = btn[0];

// UART signals 
reg [7:0] data;
reg data_ready;
wire busy;
// UART module 
uart_tx uart1(
    .clk_25mhz(clk_25mhz),
    .resetn(resetn),
    .data(data),
    .start_tx(data_ready),
    .busy(busy),
    .tx(ftdi_rxd)
);

// send data 
localparam sWAITING = 2'b00;
localparam sSENDING = 2'b01;
localparam sUPDATE = 2'b10;

reg [1:0] curr_state;

always @(posedge clk_25mhz) begin
    if (!resetn) begin
        data <= 8'd0;
        data_ready <= 1'b1;
        curr_state <= sWAITING;
    end
    else begin
        case (curr_state)
            sWAITING: begin
                if (busy)
                    curr_state <= sSENDING;
            end 

            sSENDING: begin
                if (!busy)
                    curr_state <= sUPDATE;
            end

            sUPDATE: begin
                data <= data + 1;
                curr_state <= sWAITING;
            end
            default: 
                curr_state <= sWAITING;
        endcase
    end
end


// LED blink
reg [22:0] counter;
reg RL;
always @ (posedge clk_25mhz)
    begin 
        counter <= counter + 1;
        if(!counter)
            RL = ~RL;
    end

// set LEDs
assign led[0] = RL;
assign led[7:1] = {7{0}};

endmodule
