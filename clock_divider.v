`timescale 1ns / 1ps

module clock_divider(
	input wire clk,		//master clock: 100MHz
	input wire rst,		//asynchronous reset
	output wire dclk,		//pixel clock: 25MHz

	output wire segment_clk,  // for 7-segment display	
	output wire board_clk
	);

	//For segment clock frequency of 500hz
    localparam toSegmentHz = 10000; //1000
	reg [31:0] segment_clock_counter;
	reg seg;

	localparam boardHz = 100000;
	reg [17:0] boardCounter;
	reg board;

	// 17-bit counter variable
	reg [17:0] q;

	// Clock divider --
	// Each bit in q is a clock signal that is
	// only a fraction of the master clock.
	always @(posedge clk or posedge rst)
	begin
		// reset condition
		if (rst == 1) begin
			q <= 0;
			boardCounter <= 0;
		// increment counter by one
		end
		else begin
			q <= q + 1;
			boardCounter <= boardCounter + 1;
			end


		/**** SEVEN SEGMENT DISPLAY ****/ 
		if (rst == 1) begin 
			segment_clock_counter <= 32'b0;
			seg <= 1;
		end
		else if (segment_clock_counter == toSegmentHz - 1) begin
			segment_clock_counter <= 32'b0;
			seg <= ~segment_clk;
		end
		else begin
			segment_clock_counter <= segment_clock_counter + 32'b1;
			seg <= segment_clk;
		end

		if (rst == 1) begin
			boardCounter <= 17'b0;
			board <= 1;
		end
		else if (boardCounter >= boardHz - 1) begin
			boardCounter <= 17'b0;
			board <= ! board_clk;
		end
		else begin
			boardCounter <= boardCounter + 1;
			board <= board_clk;
		end

	end

// 100Mhz ÷ 4 = 25MHz --bottom 2 bits will count from 0 to 4
assign dclk = q[0] & q[1];
assign segment_clk = seg;
assign board_clk = board;

endmodule
