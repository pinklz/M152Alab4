`timescale 1ns / 1ps

module toplevel(
    input wire clk,           // master clock = 100MHz
    input wire rst,           // right-most pushbutton for reset
    input wire l,       // move left button
    input wire r,       // move right button
    input pause,

    output wire hsync,        // horizontal sync out
    output wire vsync,         // vertical sync out

    output [11:0] rgb,       // to DAC, 3 bits to VGA port on Basys 3

    
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
    

    wire reset;
    wire paus;

    wire beginning_of_game;
    
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
wire boardhz;

clock_divider U1(
    .clk(clk),
    .rst(rst),
    .dclk(dclk),
    .segment_clk(seghz),
    .board_clk(boardhz)
    );
    

// Board position parameters to center the board
wire [9:0] board_x_init = 320 - 32; // 640/2 - 64/2
wire [9:0] board_y = 300 - 4;  // 480/2 - 8/2

wire [9:0] board_x;

board paddle(
    .clk(boardhz),
    .reset(reset),
    .pause(pause),
    .move_left(left),
    .move_right(right),
    .x_initial(board_x),
    .y_initial(board_y),

    .start_out(beginning_of_game),
    .x_pos(board_x)
);

wire [9:0] ball_x;
wire [9:0] ball_y;


wire [9:0] brick1_x = 70 - 32; //middle is 320 -32
wire [9:0] brick1_y = 60;

wire [9:0] brick2_x = 170 - 32; //middle is 320 -32
wire [9:0] brick2_y = 60;

wire [9:0] brick3_x = 270 - 32; //middle is 320 -32
wire [9:0] brick3_y = 60;

wire [9:0] brick4_x = 370 - 32; //middle is 320 -32
wire [9:0] brick4_y = 60;

wire [9:0] brick5_x = 470 - 32; //middle is 320 -32
wire [9:0] brick5_y = 60;

wire [9:0] brick6_x = 570 - 32; //middle is 320 -32
wire [9:0] brick6_y = 60;


wire w_video_on, w_p_tick;
wire [9:0] w_x, w_y;
reg [11:0] rgb_reg;
wire[11:0] rgb_next;


    
vga_controller vc(.clk_100MHz(clk), .reset(rst), .video_on(w_video_on), .hsync(hsync), 
                      .vsync(vsync), .p_tick(w_p_tick), .x(w_x), .y(w_y));
pixel_generation pg(.clk(clk), .reset(rst), .pause(pause), .video_on(w_video_on), 
                        .x(w_x), .y(w_y), .rgb(rgb_next),
                        .board_x(board_x), 
                        .board_y(board_y),
                        .brick_x0(brick1_x), 
                        .brick_y0(brick1_y),
                        .brick_x1(brick2_x),
                        .brick_y1(brick2_y),
                        .brick_x2(brick3_x),
                        .brick_y2(brick3_y),
                        .brick_x3(brick4_x),
                        .brick_y3(brick4_y),
                        .brick_x4(brick5_x),
                        .brick_y4(brick5_y),
                        .brick_x5(brick6_x),
                        .brick_y5(brick6_y),
                        .thous(thouscnt),
                        .huns(hunscnt),
                        .tens(tenscnt),
                        .ones(onescnt)
                        
                        
                        );
                        //.collision(hit));
    
always @(posedge clk) begin
        if(w_p_tick)
            rgb_reg <= rgb_next;
end
            
 assign rgb = rgb_reg;


    
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