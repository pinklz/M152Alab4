`timescale 1ns / 1ps

module pixel_generation(
    input clk,                              // 100MHz from Basys 3
    input reset,                            // btnC
    input video_on,                         // from VGA controller
    input [9:0] x, y,                       // from VGA controller
    output reg [11:0] rgb,                   // to DAC, to VGA controller

    input [9:0] board_x, board_y,
    input [9:0] brick_x0, brick_y0,
    input [9:0] brick_x1, brick_y1,
    input [9:0] brick_x2, brick_y2,
    input [9:0] brick_x3, brick_y3,
    input [9:0] brick_x4, brick_y4,
    input [9:0] brick_x5, brick_y5,

    output reg collision
    );
    
    parameter X_MAX = 639;                  // right border of display area
    parameter Y_MAX = 479;                  // bottom border of display area
    parameter SQ_RGB = 12'h0FF;             // red & green = yellow for square
    parameter BG_RGB = 12'h0F0;             // green background
    parameter SQUARE_SIZE = 64;             // width of square sides in pixels
    parameter SQUARE_VELOCITY_POS = 2;      // set position change value for positive direction
    parameter SQUARE_VELOCITY_NEG = -2;     // set position change value for negative direction  
    
    // create a 60Hz refresh tick at the start of vsync 
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0;

    parameter BOARD_RGB = 12'hFFF;          // white color for the board
    parameter BRICK_RGB = 12'hF00;          // red color for the brick
    parameter BOARD_WIDTH = 64;             // width of the board in pixels
    parameter BOARD_HEIGHT = 8;             // height of the board in pixels
    parameter BRICK_WIDTH = 30;             // width of the brick in pixels
    parameter BRICK_HEIGHT = 30;            // height of the brick in pixels

    parameter BALL_RGB = 12'h0FF;           // red & green = yellow for ball
    parameter BALL_SIZE = 8;                // width of ball sides in pixels
    parameter BALL_VELOCITY_POS = 2;        // set position change value for positive direction
    parameter BALL_VELOCITY_NEG = -2;       // set position change value for negative direction  

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

    // Define bricks' positions and boundaries
    wire [9:0] brick_x_l[5:0], brick_x_r[5:0];   // brick left and right boundaries
    wire [9:0] brick_y_t[5:0], brick_y_b[5:0];   // brick top and bottom boundaries

    // Assign individual brick coordinates
    assign brick_x_l[0] = brick_x0; assign brick_x_r[0] = brick_x0 + BRICK_WIDTH - 1;
    assign brick_y_t[0] = brick_y0; assign brick_y_b[0] = brick_y0 + BRICK_HEIGHT - 1;

    assign brick_x_l[1] = brick_x1; assign brick_x_r[1] = brick_x1 + BRICK_WIDTH - 1;
    assign brick_y_t[1] = brick_y1; assign brick_y_b[1] = brick_y1 + BRICK_HEIGHT - 1;

    assign brick_x_l[2] = brick_x2; assign brick_x_r[2] = brick_x2 + BRICK_WIDTH - 1;
    assign brick_y_t[2] = brick_y2; assign brick_y_b[2] = brick_y2 + BRICK_HEIGHT - 1;

    assign brick_x_l[3] = brick_x3; assign brick_x_r[3] = brick_x3 + BRICK_WIDTH - 1;
    assign brick_y_t[3] = brick_y3; assign brick_y_b[3] = brick_y3 + BRICK_HEIGHT - 1;

    assign brick_x_l[4] = brick_x4; assign brick_x_r[4] = brick_x4 + BRICK_WIDTH - 1;
    assign brick_y_t[4] = brick_y4; assign brick_y_b[4] = brick_y4 + BRICK_HEIGHT - 1;

    assign brick_x_l[5] = brick_x5; assign brick_x_r[5] = brick_x5 + BRICK_WIDTH - 1;
    assign brick_y_t[5] = brick_y5; assign brick_y_b[5] = brick_y5 + BRICK_HEIGHT - 1;

    // brick status signals
    wire brick_on[5:0];
    assign brick_on[0] = (brick_x_l[0] <= x) && (x <= brick_x_r[0]) && (brick_y_t[0] <= y) && (y <= brick_y_b[0]);
    assign brick_on[1] = (brick_x_l[1] <= x) && (x <= brick_x_r[1]) && (brick_y_t[1] <= y) && (y <= brick_y_b[1]);
    assign brick_on[2] = (brick_x_l[2] <= x) && (x <= brick_x_r[2]) && (brick_y_t[2] <= y) && (y <= brick_y_b[2]);
    assign brick_on[3] = (brick_x_l[3] <= x) && (x <= brick_x_r[3]) && (brick_y_t[3] <= y) && (y <= brick_y_b[3]);
    assign brick_on[4] = (brick_x_l[4] <= x) && (x <= brick_x_r[4]) && (brick_y_t[4] <= y) && (y <= brick_y_b[4]);
    assign brick_on[5] = (brick_x_l[5] <= x) && (x <= brick_x_r[5]) && (brick_y_t[5] <= y) && (y <= brick_y_b[5]);

    // BALL CONTROL
    // ball boundaries and position
    wire [9:0] ball_x_l, ball_x_r;              // ball left and right boundary
    wire [9:0] ball_y_t, ball_y_b;              // ball top and bottom boundary

    reg [9:0] ball_x_reg, ball_y_reg;           // regs to track left, top position
    wire [9:0] ball_x_next, ball_y_next;        // buffer wires

    reg [9:0] x_delta_reg, y_delta_reg;         // track ball speed
    reg [9:0] x_delta_next, y_delta_next;       // buffer regs  

    // register control
    always @(posedge clk or posedge reset)
        if(reset) begin
            ball_x_reg <= board_x + (BOARD_WIDTH / 2) - (BALL_SIZE / 2); // start at the board center
            ball_y_reg <= board_y - BALL_SIZE;  // start just above the board
            x_delta_reg <= BALL_VELOCITY_POS;
            y_delta_reg <= BALL_VELOCITY_NEG;
        end
        else begin
            ball_x_reg <= ball_x_next;
            ball_y_reg <= ball_y_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
        end

    // ball boundaries
    assign ball_x_l = ball_x_reg;                   // left boundary
    assign ball_y_t = ball_y_reg;                   // top boundary
    assign ball_x_r = ball_x_l + BALL_SIZE - 1;     // right boundary
    assign ball_y_b = ball_y_t + BALL_SIZE - 1;     // bottom boundary

    // ball status signal
    wire ball_on;
    assign ball_on = (ball_x_l <= x) && (x <= ball_x_r) &&
                     (ball_y_t <= y) && (y <= ball_y_b);

    // new ball position
    assign ball_x_next = (refresh_tick) ? ball_x_reg + x_delta_reg : ball_x_reg;
    assign ball_y_next = (refresh_tick) ? ball_y_reg + y_delta_reg : ball_y_reg;

    //Collision detection
    reg hit;

    // RGB control
    always @(*) begin
        if (~video_on) begin
            rgb = 12'h000;          // black (no value) outside display area
        end
        else if (board_on) begin
            rgb = BOARD_RGB; 
        end       // white board
        else begin
            rgb = BG_RGB;           // green background
            if (brick_on[0]) begin
                rgb = BRICK_RGB;
            end
            if (brick_on[1]) begin
                rgb = BRICK_RGB;
            end
            if (brick_on[2]) begin
                rgb = BRICK_RGB;
            end
            if (brick_on[3]) begin
                rgb = BRICK_RGB;
            end
            if (brick_on[4]) begin
                rgb = BRICK_RGB;
            end
            if (brick_on[5]) begin
                rgb = BRICK_RGB;
            end

            if (ball_on) begin
                rgb = BALL_RGB;
            end
        end

        // BALL MOVEMENT
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;
        if(ball_y_t < 1) begin                             // collide with top display edge
            y_delta_next = BALL_VELOCITY_POS;         // change y direction (move down)
        end
        if (ball_y_t > Y_MAX) begin
            y_delta_next = BALL_VELOCITY_NEG;
        end
        else if((ball_y_b >= board_y && ball_y_b <= board_y + BOARD_HEIGHT &&  // collide with the board
                ball_x_r >= board_x && ball_x_l <= board_x + BOARD_WIDTH ))begin
            y_delta_next = BALL_VELOCITY_NEG;         // change y direction (move up)
            x_delta_next = -x_delta_reg;              // bounce horizontally
        end 
        else begin
            if ((ball_y_b >= brick_y_t[0] && ball_y_b <= brick_y_b[0] && ball_x_r >= brick_x_l[0] && ball_x_l <= brick_x_r[0]) ||
                (ball_y_b >= brick_y_t[1] && ball_y_b <= brick_y_b[1] && ball_x_r >= brick_x_l[1] && ball_x_l <= brick_x_r[1]) ||
                (ball_y_b >= brick_y_t[2] && ball_y_b <= brick_y_b[2] && ball_x_r >= brick_x_l[2] && ball_x_l <= brick_x_r[2]) ||
                (ball_y_b >= brick_y_t[3] && ball_y_b <= brick_y_b[3] && ball_x_r >= brick_x_l[3] && ball_x_l <= brick_x_r[3]) ||
                (ball_y_b >= brick_y_t[4] && ball_y_b <= brick_y_b[4] && ball_x_r >= brick_x_l[4] && ball_x_l <= brick_x_r[4]) ||
                (ball_y_b >= brick_y_t[5] && ball_y_b <= brick_y_b[5] && ball_x_r >= brick_x_l[5] && ball_x_l <= brick_x_r[5])) begin
                y_delta_next = BALL_VELOCITY_NEG;
                x_delta_next = -x_delta_reg;
                hit <= 1;
            end
        end
        if(ball_x_l < 1) begin                    // collide with left display edge
            x_delta_next = BALL_VELOCITY_POS;         // change x direction (move right)
        end
        else if(ball_x_r > X_MAX) begin                     // collide with right display edge
            x_delta_next = BALL_VELOCITY_NEG;         // change x direction (move left)
        end
    end
assign collision = hit;
endmodule


//`timescale 1ns / 1ps

//module pixel_generation(
//    input clk,                              // 100MHz from Basys 3
//    input reset,                            // btnC
//    input video_on,                         // from VGA controller
//    input [9:0] x, y,                       // from VGA controller
//    output reg [11:0] rgb,                   // to DAC, to VGA controller

//    input [9:0] board_x, board_y,
//    input [9:0] brick_x, brick_y
//    );
    
//    parameter X_MAX = 639;                  // right border of display area
//    parameter Y_MAX = 479;                  // bottom border of display area
//    parameter SQ_RGB = 12'h0FF;             // red & green = yellow for square
//    parameter BG_RGB = 12'hF00;             // blue background
//    parameter SQUARE_SIZE = 64;             // width of square sides in pixels
//    parameter SQUARE_VELOCITY_POS = 2;      // set position change value for positive direction
//    parameter SQUARE_VELOCITY_NEG = -2;     // set position change value for negative direction  
    
//    // create a 60Hz refresh tick at the start of vsync 
//    wire refresh_tick;
//    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0;

//    parameter BOARD_RGB = 12'hFFF;          // white color for the board
//    parameter BRICK_RGB = 12'hFFF;          // red color for the brick
//    parameter BOARD_WIDTH = 64;             // width of the board in pixels
//    parameter BOARD_HEIGHT = 8;             // height of the board in pixels
//    parameter BRICK_SIZE = 50;              // size of the brick in pixels

//    parameter BALL_RGB = 12'h0FF;           // red & green = yellow for ball
//    parameter BALL_SIZE = 8;                // width of ball sides in pixels
//    parameter BALL_VELOCITY_POS = 1;        // set position change value for positive direction
//    parameter BALL_VELOCITY_NEG = -1;       // set position change value for negative direction  

    
//    // // square boundaries and position
//    // wire [9:0] sq_x_l, sq_x_r;              // square left and right boundary
//    // wire [9:0] sq_y_t, sq_y_b;              // square top and bottom boundary
    
//    // reg [9:0] sq_x_reg, sq_y_reg;           // regs to track left, top position
//    // wire [9:0] sq_x_next, sq_y_next;        // buffer wires
    
//    // reg [9:0] x_delta_reg, y_delta_reg;     // track square speed
//    // reg [9:0] x_delta_next, y_delta_next;   // buffer regs    

//    // Calculate board boundaries
//    wire [9:0] board_x_l, board_x_r;        // board left and right boundary
//    wire [9:0] board_y_t, board_y_b;        // board top and bottom boundary

//    assign board_x_l = board_x;
//    assign board_x_r = board_x + BOARD_WIDTH - 1;
//    assign board_y_t = board_y;
//    assign board_y_b = board_y + BOARD_HEIGHT - 1;

//    // board status signal
//    wire board_on;
//    assign board_on = (board_x_l <= x) && (x <= board_x_r) &&
//                      (board_y_t <= y) && (y <= board_y_b);



//    // Calculate brick boundaries
//    wire [9:0] brick_x_l, brick_x_r;        // brick left and right boundary
//    wire [9:0] brick_y_t, brick_y_b;        // brick top and bottom boundary

//    assign brick_x_l = brick_x;
//    assign brick_x_r = brick_x + BRICK_SIZE - 1;
//    assign brick_y_t = brick_y;
//    assign brick_y_b = brick_y + BRICK_SIZE - 1;

//    // brick status signal
//    wire brick_on;
//    assign brick_on = (brick_x_l <= x) && (x <= brick_x_r) &&
//                      (brick_y_t <= y) && (y <= brick_y_b);



//// BALL CONTROL
//    // ball boundaries and position
//    wire [9:0] ball_x_l, ball_x_r;              // ball left and right boundary
//    wire [9:0] ball_y_t, ball_y_b;              // ball top and bottom boundary

//    reg [9:0] ball_x_reg, ball_y_reg;           // regs to track left, top position
//    wire [9:0] ball_x_next, ball_y_next;        // buffer wires

//    reg [9:0] x_delta_reg, y_delta_reg;         // track ball speed
//    reg [9:0] x_delta_next, y_delta_next;       // buffer regs  

    
//    // register control
//    always @(posedge clk or posedge reset)
//        if(reset) begin
//            ball_x_reg <= board_x + (BOARD_WIDTH / 2) - (BALL_SIZE / 2); // start at the board center
//            ball_y_reg <= board_y - BALL_SIZE;  // start just above the board
//            x_delta_reg <= BALL_VELOCITY_POS;
//            y_delta_reg <= BALL_VELOCITY_NEG;
//        end
//        else begin
//            ball_x_reg <= ball_x_next;
//            ball_y_reg <= ball_y_next;
//            x_delta_reg <= x_delta_next;
//            y_delta_reg <= y_delta_next;
//        end

//    // ball boundaries
//    assign ball_x_l = ball_x_reg;                   // left boundary
//    assign ball_y_t = ball_y_reg;                   // top boundary
//    assign ball_x_r = ball_x_l + BALL_SIZE - 1;     // right boundary
//    assign ball_y_b = ball_y_t + BALL_SIZE - 1;     // bottom boundary

//    // ball status signal
//    wire ball_on;
//    assign ball_on = (ball_x_l <= x) && (x <= ball_x_r) &&
//                     (ball_y_t <= y) && (y <= ball_y_b);

//    // new ball position
//    assign ball_x_next = (refresh_tick) ? ball_x_reg + x_delta_reg : ball_x_reg;
//    assign ball_y_next = (refresh_tick) ? ball_y_reg + y_delta_reg : ball_y_reg;

    

//    // RGB control
//    always @(*) begin
//        if (~video_on) begin
//            rgb = 12'h000;          // black (no value) outside display area
//        end
//        else if (board_on) begin
//            rgb = BOARD_RGB; 
//        end       // white board
//        else if (brick_on) begin
//            rgb = BRICK_RGB;        // red brick
//        end
//        else if (ball_on) begin
//            rgb = BALL_RGB;
//        end
//        else begin
//            rgb = BG_RGB;           // green background
//        end


//        // BALL MOVEMENT
//        x_delta_next = x_delta_reg;
//        y_delta_next = y_delta_reg;
//        if(ball_y_t < 1) begin                             // collide with top display edge
//            y_delta_next = BALL_VELOCITY_POS;         // change y direction (move down)
//        end
//        else if((ball_y_b >= board_y && ball_y_b <= board_y + BOARD_HEIGHT &&  // collide with the board
//                ball_x_r >= board_x && ball_x_l <= board_x + BOARD_WIDTH ))begin
//            y_delta_next = BALL_VELOCITY_NEG;         // change y direction (move up)
//            x_delta_next = -x_delta_reg;              // bounce horizontally
//        end
//        else if ( (ball_y_b >= brick_y_t && ball_y_b <= brick_y + 50 &&  // collide with the board
//                 ball_x_r >= brick_x && ball_x_l <= brick_x + 50) ) begin
//               y_delta_next = BALL_VELOCITY_NEG;
//               x_delta_next = -x_delta_reg;                         
//        end 
//        else if(ball_x_l < 1) begin                    // collide with left display edge
//            x_delta_next = BALL_VELOCITY_POS;         // change x direction (move right)
//        end
//        else if(ball_x_r > X_MAX) begin                     // collide with right display edge
//            x_delta_next = BALL_VELOCITY_NEG;         // change x direction (move left)
//        end
//    end


///******** BOUNCING SQUARE original code ********/
//    // // register control
//    // always @(posedge clk or posedge reset)
//    //     if(reset) begin
//    //         sq_x_reg <= 0;
//    //         sq_y_reg <= 0;
//    //         x_delta_reg <= 10'h002;
//    //         y_delta_reg <= 10'h002;
//    //     end
//    //     else begin
//    //         sq_x_reg <= sq_x_next;
//    //         sq_y_reg <= sq_y_next;
//    //         x_delta_reg <= x_delta_next;
//    //         y_delta_reg <= y_delta_next;
//    //     end
    
//    // // square boundaries
//    // assign sq_x_l = sq_x_reg;                   // left boundary
//    // assign sq_y_t = sq_y_reg;                   // top boundary
//    // assign sq_x_r = sq_x_l + SQUARE_SIZE - 1;   // right boundary
//    // assign sq_y_b = sq_y_t + SQUARE_SIZE - 1;   // bottom boundary
    
//    // // square status signal
//    // wire sq_on;
//    // assign sq_on = (sq_x_l <= x) && (x <= sq_x_r) &&
//    //                (sq_y_t <= y) && (y <= sq_y_b);
                   
//    // // new square position
//    // assign sq_x_next = (refresh_tick) ? sq_x_reg + x_delta_reg : sq_x_reg;
//    // assign sq_y_next = (refresh_tick) ? sq_y_reg + y_delta_reg : sq_y_reg;
    
//    // // new square velocity 
//    // always @* begin
//    //     x_delta_next = x_delta_reg;
//    //     y_delta_next = y_delta_reg;
//    //     if(sq_y_t < 1)                              // collide with top display edge
//    //         y_delta_next = SQUARE_VELOCITY_POS;     // change y direction(move down)
//    //     else if(sq_y_b > Y_MAX)                     // collide with bottom display edge
//    //         y_delta_next = SQUARE_VELOCITY_NEG;     // change y direction(move up)
//    //     else if(sq_x_l < 1)                         // collide with left display edge
//    //         x_delta_next = SQUARE_VELOCITY_POS;     // change x direction(move right)
//    //     else if(sq_x_r > X_MAX)                     // collide with right display edge
//    //         x_delta_next = SQUARE_VELOCITY_NEG;     // change x direction(move left)
//    // end
    
//    // // RGB control
//    // always @*
//    //     if(~video_on)
//    //         rgb = 12'h000;          // black(no value) outside display area
//    //     else
//    //         if(sq_on)
//    //             rgb = SQ_RGB;       // yellow square
//    //         else
//    //             rgb = BG_RGB;       // blue background
    
//endmodule
