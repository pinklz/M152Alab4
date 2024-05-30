`timescale 1ns / 1ps

module toplevel(
    input wire clk,           // master clock = 100MHz
    input wire rst,           // right-most pushbutton for reset
    input wire l,       // move left button
    input wire r,       // move right button
    
    output wire [2:0] red,    // red vga output - 3 bits
    output wire [2:0] green,  // green vga output - 3 bits
    output wire [2:0] blue,   // blue vga output - 3 bits
    output wire hsync,        // horizontal sync out
    output wire vsync         // vertical sync out
    );
    
    wire [6:0] sevenmin1;
    wire [6:0] sevenmin0;
    wire [6:0] sevensec0;
    wire [6:0] sevensec1;
    wire [6:0] no_val;
    
    wire [3:0] sec0cnt;
    wire [3:0] sec1cnt;
    wire [3:0] min0cnt;
    wire [3:0] min1cnt;
    wire [3:0] ones = 4'b1111;
    
    // TODO: use score module to set sec0, sec1, min0, min1cnt 's
    
    //self-note: board
        // Put button input after debouncing into board.v
        // use board.v to output the x y coords of board
        // which are used as input to display

    wire reset;
    wire paus;
    
    debouncer reset_button(
        .button_in(rst),
        .clk(clk),
        .button_out(reset)
    );
    
    wire left;
    wire right;
    
    debouncer move_left(
        .button_in(l),
        .clk(clk),
        .button_out(left)
    );
    
    debouncer move_right(
            .button_in(r),
            .clk(clk),
            .button_out(right)
        );
    

// VGA display clock interconnect
wire dclk;
wire seghz;

clock_divider U1(
    .clk(clk),
    .rst(rst),
    .dclk(dclk),
    .segment_clk(seghz)
    );
    
    
seven min1(
       .dig(min1cnt),
       .seven_seg_display(sevenmin1)
);
           
seven min0(
       .dig(min0cnt),
       .seven_seg_display(sevenmin0)
);

seven sec1(
       .dig(sec1cnt),
       .seven_seg_display(sevensec1)
);

seven sec0(
       .dig(sec0cnt),
       .seven_seg_display(sevensec0)
);
    
    
seven no_value(
      .dig(ones),
      .seven_seg_display(no_val)
);

// Board position parameters to center the board
parameter board_x = 320 - 32; // 640/2 - 64/2
parameter board_y = 300 - 4;  // 480/2 - 8/2


// VGA controller
display U3(
    .dclk(dclk),
    .rst(rst),
    .board_x(board_x),
    .board_y(board_y),
    .hsync(hsync),
    .vsync(vsync),
    .red(red),
    .green(green),
    .blue(blue)
    );
    
endmodule
