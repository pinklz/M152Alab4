`timescale 1ns / 1ps

module pixel_generation(
    input clk,                              // 100MHz from Basys 3
    input reset,                            // btnC
    input video_on,                         // from VGA controller
    input [9:0] x, y,                       // from VGA controller
    output reg [11:0] rgb,                   // to DAC, to VGA controller

    input [9:0] board_x, board_y
    );
    
    parameter X_MAX = 639;                  // right border of display area
    parameter Y_MAX = 479;                  // bottom border of display area
    parameter SQ_RGB = 12'h0FF;             // red & green = yellow for square
    parameter BG_RGB = 12'hF00;             // blue background
    parameter SQUARE_SIZE = 64;             // width of square sides in pixels
    parameter SQUARE_VELOCITY_POS = 2;      // set position change value for positive direction
    parameter SQUARE_VELOCITY_NEG = -2;     // set position change value for negative direction  
    
    // create a 60Hz refresh tick at the start of vsync 
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0;

    parameter BOARD_RGB = 12'hFFF;          // white color for the board
    parameter BRICK_RGB = 12'hF00;          // red color for the brick
    parameter BG_RGB = 12'h0F0;             // green background
    parameter BOARD_WIDTH = 64;             // width of the board in pixels
    parameter BOARD_HEIGHT = 8;             // height of the board in pixels
    parameter BRICK_SIZE = 50;              // size of the brick in pixels
    
    // // square boundaries and position
    // wire [9:0] sq_x_l, sq_x_r;              // square left and right boundary
    // wire [9:0] sq_y_t, sq_y_b;              // square top and bottom boundary
    
    // reg [9:0] sq_x_reg, sq_y_reg;           // regs to track left, top position
    // wire [9:0] sq_x_next, sq_y_next;        // buffer wires
    
    // reg [9:0] x_delta_reg, y_delta_reg;     // track square speed
    // reg [9:0] x_delta_next, y_delta_next;   // buffer regs    

    // Calculate board boundaries
    wire [9:0] board_x_l, board_x_r;        // board left and right boundary
    wire [9:0] board_y_t, board_y_b;        // board top and bottom boundary

    assign board_x_l = board_x;
    assign board_x_r = board_x + BOARD_WIDTH - 1;
    assign board_y_t = board_y;
    assign board_y_b = board_y + BOARD_HEIGHT - 1;

    // board status signal
    wire board_on;
    assign board_on = (board_x_l <= x) && (x <= board_x_r) &&
                      (board_y_t <= y) && (y <= board_y_b);



    // Calculate brick boundaries
    wire [9:0] brick_x_l, brick_x_r;        // brick left and right boundary
    wire [9:0] brick_y_t, brick_y_b;        // brick top and bottom boundary

    assign brick_x_l = brick_x;
    assign brick_x_r = brick_x + BRICK_SIZE - 1;
    assign brick_y_t = brick_y;
    assign brick_y_b = brick_y + BRICK_SIZE - 1;

    // brick status signal
    wire brick_on;
    assign brick_on = (brick_x_l <= x) && (x <= brick_x_r) &&
                      (brick_y_t <= y) && (y <= brick_y_b);
    

    // RGB control
    always @*
        if (~video_on)
            rgb = 12'h000;          // black (no value) outside display area
        else if (board_on)
            rgb = BOARD_RGB;        // white board
        else if (brick_on)
            rgb = BRICK_RGB;        // red brick
        else
            rgb = BG_RGB;           // green background


/******** BOUNCING SQUARE original code ********/
    // // register control
    // always @(posedge clk or posedge reset)
    //     if(reset) begin
    //         sq_x_reg <= 0;
    //         sq_y_reg <= 0;
    //         x_delta_reg <= 10'h002;
    //         y_delta_reg <= 10'h002;
    //     end
    //     else begin
    //         sq_x_reg <= sq_x_next;
    //         sq_y_reg <= sq_y_next;
    //         x_delta_reg <= x_delta_next;
    //         y_delta_reg <= y_delta_next;
    //     end
    
    // // square boundaries
    // assign sq_x_l = sq_x_reg;                   // left boundary
    // assign sq_y_t = sq_y_reg;                   // top boundary
    // assign sq_x_r = sq_x_l + SQUARE_SIZE - 1;   // right boundary
    // assign sq_y_b = sq_y_t + SQUARE_SIZE - 1;   // bottom boundary
    
    // // square status signal
    // wire sq_on;
    // assign sq_on = (sq_x_l <= x) && (x <= sq_x_r) &&
    //                (sq_y_t <= y) && (y <= sq_y_b);
                   
    // // new square position
    // assign sq_x_next = (refresh_tick) ? sq_x_reg + x_delta_reg : sq_x_reg;
    // assign sq_y_next = (refresh_tick) ? sq_y_reg + y_delta_reg : sq_y_reg;
    
    // // new square velocity 
    // always @* begin
    //     x_delta_next = x_delta_reg;
    //     y_delta_next = y_delta_reg;
    //     if(sq_y_t < 1)                              // collide with top display edge
    //         y_delta_next = SQUARE_VELOCITY_POS;     // change y direction(move down)
    //     else if(sq_y_b > Y_MAX)                     // collide with bottom display edge
    //         y_delta_next = SQUARE_VELOCITY_NEG;     // change y direction(move up)
    //     else if(sq_x_l < 1)                         // collide with left display edge
    //         x_delta_next = SQUARE_VELOCITY_POS;     // change x direction(move right)
    //     else if(sq_x_r > X_MAX)                     // collide with right display edge
    //         x_delta_next = SQUARE_VELOCITY_NEG;     // change x direction(move left)
    // end
    
    // // RGB control
    // always @*
    //     if(~video_on)
    //         rgb = 12'h000;          // black(no value) outside display area
    //     else
    //         if(sq_on)
    //             rgb = SQ_RGB;       // yellow square
    //         else
    //             rgb = BG_RGB;       // blue background
    
endmodule
