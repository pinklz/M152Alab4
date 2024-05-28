`timescale 1ns / 1ps

module clock_divider(
	input wire clk,		//master clock: 100MHz
	input wire rst,		//asynchronous reset
	output wire dclk		//pixel clock: 25MHz
	);

// 17-bit counter variable
reg [17:0] q;

// Clock divider --
// Each bit in q is a clock signal that is
// only a fraction of the master clock.
always @(posedge clk or posedge rst)
begin
	// reset condition
	if (rst == 1)
		q <= 0;
	// increment counter by one
	else
		q <= q + 1;
end

// 100Mhz ÷ 4 = 25MHz --bottom 2 bits will count from 0 to 4
assign dclk = q[0] & q[1];

endmodule
