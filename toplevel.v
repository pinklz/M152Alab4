`timescale 1ns / 1ps

module toplevel(
    input wire clk,			//master clock = 100MHz
    input wire rst,            //right-most pushbutton for reset
    output wire [2:0] red,    //red vga output - 3 bits
    output wire [2:0] green,//green vga output - 3 bits
    output wire [2:0] blue,    //blue vga output - 3 bits
    output wire hsync,        //horizontal sync out
    output wire vsync            //vertical sync out
    );


// VGA display clock interconnect
wire dclk;

clock_divider U1(
	.clk(clk),
	.rst(rst),
	.dclk(dclk)
	);

// VGA controller
display U3(
	.dclk(dclk),
	.rst(rst),
	.hsync(hsync),
	.vsync(vsync),
	.red(red),
	.green(green),
	.blue(blue)
	);
	
endmodule
