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
    output wire vsync,         // vertical sync out
    
    output reg [6:0] seven_seg_display,
    output reg [3:0] an
    );
    
    wire [6:0] thous;
    wire [6:0] huns;
    wire [6:0] tens;
    wire [6:0] ones;
    wire [6:0] no_val;
    
    wire [3:0] onescnt;
    wire [3:0] tenscnt;
    wire [3:0] hunscnt;
    wire [3:0] thouscnt;
    wire [3:0] novalue = 4'b1111;
    
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
    
    
/******* SCORE COUNTING ********/
wire hit = 0;
score score(
    .clk(clk),
    .reset(rst),
    .collision(hit),
    .thous(thouscnt),
    .huns(hunscnt),
    .tens(tenscnt),
    .ones(onescnt)
);
    
seven thousand(
       .dig(thouscnt),
       .seven_seg_display(thous)
);
           
seven hundred(
       .dig(hunscnt),
       .seven_seg_display(huns)
);

seven ten(
       .dig(tenscnt),
       .seven_seg_display(tens)
);

seven one(
       .dig(onescnt),
       .seven_seg_display(ones)
);
    
    
seven no_value(
      .dig(novalue),
      .seven_seg_display(no_val)
);

// Board position parameters to center the board
wire [9:0] board_x_init = 320 - 32; // 640/2 - 64/2
wire [9:0] board_y = 300 - 4;  // 480/2 - 8/2

wire [9:0] board_x;

board paddle(
    .clk(clk),
    .reset(reset),
    .move_left(left),
    .move_right(right),
    .x_initial(board_x_init),    // TODO: figure out how to do input x and output x
    .y_initial(board_y) 
);

wire [9:0] ball_x;
wire [9:0] ball_y;

ball ball(
    .clk(clk),
    .reset(rst),
    .pause(paus),
    .x_initial(board_x_init)  
);

wire [9:0] brick1_x = 320 - 32;
wire [9:0] brick1_y = 300;
bricks brick(
    .clk(clk),
    .reset(rst),
    .x_pos(brick1_x),
    .y_pos(brick1_y)
);

// VGA controller
display U3(
    .dclk(dclk),
    .rst(rst),
    .board_x(board_x_init),
    .board_y(board_y),
    .hsync(hsync),
    .vsync(vsync),
    .red(red),
    .green(green),
    .blue(blue)
    );
    
    
/***** DISPLAY SCORE ******/
reg [1:0] which_digit = 2'b00;

always @(posedge seghz) begin
    if (which_digit == 0) begin
        which_digit <= 1;
        an <= 4'b0111;
        seven_seg_display <= thous;
    end
    if (which_digit == 1) begin
        which_digit <=2;
        an <= 4'b1011;
        seven_seg_display <= huns;
    end
    if (which_digit == 2) begin
        which_digit <= 3;
        an <= 4'b1101;
        seven_seg_display <= tens;
    end
    if (which_digit == 3) begin
        which_digit <= 0;
        an <= 4'b1110;
        seven_seg_display <= ones;
    end
end
    
endmodule
