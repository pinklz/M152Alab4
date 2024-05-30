`timescale 1ns / 1ps

module display(
    input wire dclk,            //pixel clock: 25MHz
    input wire rst,             //asynchronous reset
    input wire [9:0] board_x,   // horizontal position of the board
    input wire [9:0] board_y,   // vertical position of the board
    output wire hsync,          // horizontal sync out
    output wire vsync,          // vertical sync out
    output reg [2:0] red,       // red vga output
    output reg [2:0] green,     // green vga output
    output reg [2:0] blue       // blue vga output
    );

// video structure constants
parameter hpixels = 800; // horizontal pixels per line
parameter vlines = 521;  // vertical lines per frame
parameter hpulse = 96;   // hsync pulse length
parameter vpulse = 2;    // vsync pulse length
parameter hbp = 144;     // end of horizontal back porch
parameter hfp = 784;     // beginning of horizontal front porch
parameter vbp = 31;      // end of vertical back porch
parameter vfp = 511;     // beginning of vertical front porch
// active horizontal video is therefore: 784 - 144 = 640
// active vertical video is therefore: 511 - 31 = 480

// white board parameters
parameter board_width = 64;   // 1/10 of 640 pixels
parameter board_height = 8;   // 8 pixels high

// registers for storing the horizontal & vertical counters
reg [9:0] hc;
reg [9:0] vc;

// Horizontal & vertical counters --
always @(posedge dclk or posedge rst)
begin
    // reset condition
    if (rst == 1)
    begin
        hc <= 0;
        vc <= 0;
    end
    else
    begin
        // keep counting until the end of the line
        if (hc < hpixels - 1)
            hc <= hc + 1;
        else
        begin
            hc <= 0;
            if (vc < vlines - 1)
                vc <= vc + 1;
            else
                vc <= 0;
        end
    end
end

// generate sync pulses (active low)
assign hsync = (hc < hpulse) ? 0 : 1;
assign vsync = (vc < vpulse) ? 0 : 1;

// display 100% saturation colorbars
always @(*)
begin
    // first check if we're within vertical active video range
    if (vc >= vbp && vc < vfp)
    begin
        // check if we're within the white board range
        if ((vc >= (vbp+board_y)) && (vc < (vbp+board_y + board_height)) &&
            (hc >= (hbp+board_x)) && (hc < (hbp+board_x + board_width)))
        begin
            red = 3'b111;
            green = 3'b111;
            blue = 3'b111;
        end
        // within active horizontal range
        else if (hc >= hbp && hc < hfp)
        begin
            red = 3'b000;
            green = 3'b111;
            blue = 3'b111;
        end
        // we're outside active horizontal range so display black
        else
        begin
            red = 0;
            green = 0;
            blue = 0;
        end
    end
    // we're outside active vertical range so display black
    else
    begin
        red = 0;
        green = 0;
        blue = 0;
    end
end

endmodule
