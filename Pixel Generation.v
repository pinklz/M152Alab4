`timescale 1ns / 1ps

module pixel_generation(
    input clk,                              // 100MHz from Basys 3
    input reset,                            // btnC
    input pause,
    input video_on,                         // from VGA controller
    input [9:0] x, y,                       // from VGA controller
    output reg [11:0] rgb,                  // to DAC, to VGA controller

    input [9:0] board_x, board_y,
    input [9:0] brick_x0, brick_y0,
    input [9:0] brick_x1, brick_y1,
    input [9:0] brick_x2, brick_y2,
    input [9:0] brick_x3, brick_y3,
    input [9:0] brick_x4, brick_y4,
    input [9:0] brick_x5, brick_y5,

    output reg collision,
    output wire [3:0] thous,
    output wire [3:0] huns,
    output wire [3:0] tens,
    output wire [3:0] ones
);

    wire [3:0] onescnt;
    wire [3:0] tenscnt;
    wire [3:0] hunscnt;
    wire [3:0] thouscnt;

    parameter X_MAX = 639;                  // right border of display area
    parameter Y_MAX = 479;                  // bottom border of display area
    parameter SQ_RGB = 12'h0FF;             // red & green = yellow for square
    parameter BG_RGB = 12'h000;             // green background 12'h0F0
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
    parameter BALL_VELOCITY_POS = 1;        // set position change value for positive direction
    parameter BALL_VELOCITY_NEG = -1;       // set position change value for negative direction  

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
                      
                          // BALL CONTROL
                      wire [9:0] ball_x_l, ball_x_r, ball_y_t, ball_y_b;  // ball top and bottom boundary
                      reg [9:0] ball_x_reg, ball_y_reg;           // ball x and y registers
                      reg [9:0] ball_x_next, ball_y_next;         // ball x and y next state
                      reg ball_x_delta_reg, ball_y_delta_reg;     // registers to track direction of ball
                      reg ball_x_delta_next, ball_y_delta_next;   // next state to track direction of ball
                      wire [9:0] x_delta, y_delta;                // position increment for ball

    // Define bricks' positions and boundaries
    wire [9:0] brick_x_l[5:0], brick_x_r[5:0];   // brick left and right boundaries
    wire [9:0] brick_y_t[5:0], brick_y_b[5:0];   // brick top and bottom boundaries

    // Assign individual brick coordinates
    assign brick_x_l[0] = brick_x0; 
    assign brick_x_r[0] = brick_x0 + BRICK_WIDTH - 1;
    assign brick_y_t[0] = brick_y0; 
    assign brick_y_b[0] = brick_y0 + BRICK_HEIGHT - 1;

    assign brick_x_l[1] = brick_x1; 
    assign brick_x_r[1] = brick_x1 + BRICK_WIDTH - 1;
    assign brick_y_t[1] = brick_y1; 
    assign brick_y_b[1] = brick_y1 + BRICK_HEIGHT - 1;

    assign brick_x_l[2] = brick_x2; 
    assign brick_x_r[2] = brick_x2 + BRICK_WIDTH - 1;
    assign brick_y_t[2] = brick_y2; 
    assign brick_y_b[2] = brick_y2 + BRICK_HEIGHT - 1;

    assign brick_x_l[3] = brick_x3; 
    assign brick_x_r[3] = brick_x3 + BRICK_WIDTH - 1;
    assign brick_y_t[3] = brick_y3; 
    assign brick_y_b[3] = brick_y3 + BRICK_HEIGHT - 1;

    assign brick_x_l[4] = brick_x4; 
    assign brick_x_r[4] = brick_x4 + BRICK_WIDTH - 1;
    assign brick_y_t[4] = brick_y4; 
    assign brick_y_b[4] = brick_y4 + BRICK_HEIGHT - 1;

    assign brick_x_l[5] = brick_x5; 
    assign brick_x_r[5] = brick_x5 + BRICK_WIDTH - 1;
    assign brick_y_t[5] = brick_y5; 
    assign brick_y_b[5] = brick_y5 + BRICK_HEIGHT - 1;

    // Brick visibility states
    reg [5:0] brick_visible;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            brick_visible <= 6'b111111; // all bricks visible at start
        end else if (collision) begin
            if (ball_y_b >= brick_y_t[0] && ball_y_b <= brick_y_b[0] && ball_x_r >= brick_x_l[0] && ball_x_l <= brick_x_r[0])
                brick_visible[0] <= 0;
            if (ball_y_b >= brick_y_t[1] && ball_y_b <= brick_y_b[1] && ball_x_r >= brick_x_l[1] && ball_x_l <= brick_x_r[1])
                brick_visible[1] <= 0;
            if (ball_y_b >= brick_y_t[2] && ball_y_b <= brick_y_b[2] && ball_x_r >= brick_x_l[2] && ball_x_l <= brick_x_r[2])
                brick_visible[2] <= 0;
            if (ball_y_b >= brick_y_t[3] && ball_y_b <= brick_y_b[3] && ball_x_r >= brick_x_l[3] && ball_x_l <= brick_x_r[3])
                brick_visible[3] <= 0;
            if (ball_y_b >= brick_y_t[4] && ball_y_b <= brick_y_b[4] && ball_x_r >= brick_x_l[4] && ball_x_l <= brick_x_r[4])
                brick_visible[4] <= 0;
            if (ball_y_b >= brick_y_t[5] && ball_y_b <= brick_y_b[5] && ball_x_r >= brick_x_l[5] && ball_x_l <= brick_x_r[5])
                brick_visible[5] <= 0;
        end
    end

    // Brick status signals
    wire brick_on[5:0];
    assign brick_on[0] = brick_visible[0] && (brick_x_l[0] <= x) && (x <= brick_x_r[0]) && (brick_y_t[0] <= y) && (y <= brick_y_b[0]);
    assign brick_on[1] = brick_visible[1] && (brick_x_l[1] <= x) && (x <= brick_x_r[1]) && (brick_y_t[1] <= y) && (y <= brick_y_b[1]);
    assign brick_on[2] = brick_visible[2] && (brick_x_l[2] <= x) && (x <= brick_x_r[2]) && (brick_y_t[2] <= y) && (y <= brick_y_b[2]);
    assign brick_on[3] = brick_visible[3] && (brick_x_l[3] <= x) && (x <= brick_x_r[3]) && (brick_y_t[3] <= y) && (y <= brick_y_b[3]);
    assign brick_on[4] = brick_visible[4] && (brick_x_l[4] <= x) && (x <= brick_x_r[4]) && (brick_y_t[4] <= y) && (y <= brick_y_b[4]);
    assign brick_on[5] = brick_visible[5] && (brick_x_l[5] <= x) && (x <= brick_x_r[5]) && (brick_y_t[5] <= y) && (y <= brick_y_b[5]);

    // Initialize position increment values for ball movement
    assign x_delta = (ball_x_delta_reg) ? BALL_VELOCITY_POS : BALL_VELOCITY_NEG;
    assign y_delta = (ball_y_delta_reg) ? BALL_VELOCITY_POS : BALL_VELOCITY_NEG;

    // Ball direction control
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ball_x_reg <= 320 - 32;
            ball_y_reg <= 280;
            ball_x_delta_reg <= 1'b1;
            ball_y_delta_reg <= 1'b1;
        end else begin
            ball_x_reg <= ball_x_next;
            ball_y_reg <= ball_y_next;
            ball_x_delta_reg <= ball_x_delta_next;
            ball_y_delta_reg <= ball_y_delta_next;
        end
    end

    // ball left right top bottom values
    assign ball_x_l = ball_x_reg;
    assign ball_x_r = ball_x_reg + BALL_SIZE - 1;
    assign ball_y_t = ball_y_reg;
    assign ball_y_b = ball_y_reg + BALL_SIZE - 1;

    // BALL ANIMATION
    always @* begin
        ball_x_next = ball_x_reg;
        ball_y_next = ball_y_reg;
        ball_x_delta_next = ball_x_delta_reg;
        ball_y_delta_next = ball_y_delta_reg;
        collision = 0;

        if (refresh_tick && !pause) begin
            // check boundary
            if (ball_x_r >= X_MAX)
                ball_x_delta_next = 1'b0; // moving to the left
            if (ball_x_l <= 0)
                ball_x_delta_next = 1'b1; // moving to the right
            if (ball_y_b >= Y_MAX)
                ball_y_delta_next = 1'b0; // moving up
            if (ball_y_t <= 0)
                ball_y_delta_next = 1'b1; // moving down
            // check collision with board
            if ((ball_y_b >= board_y_t) && (ball_y_b <= board_y_b) &&
                (ball_x_r >= board_x_l) && (ball_x_l <= board_x_r)) begin
                ball_y_delta_next = 1'b0;
            end
            // check collision with bricks
            if (brick_visible[0] && (ball_y_b >= brick_y_t[0] && ball_y_b <= brick_y_b[0] && ball_x_r >= brick_x_l[0] && ball_x_l <= brick_x_r[0])) begin
                ball_y_delta_next = ~ball_y_delta_reg;
                collision = 1;
            end
            if (brick_visible[1] && (ball_y_b >= brick_y_t[1] && ball_y_b <= brick_y_b[1] && ball_x_r >= brick_x_l[1] && ball_x_l <= brick_x_r[1])) begin
                ball_y_delta_next = ~ball_y_delta_reg;
                collision = 1;
            end
            if (brick_visible[2] && (ball_y_b >= brick_y_t[2] && ball_y_b <= brick_y_b[2] && ball_x_r >= brick_x_l[2] && ball_x_l <= brick_x_r[2])) begin
                ball_y_delta_next = ~ball_y_delta_reg;
                collision = 1;
            end
            if (brick_visible[3] && (ball_y_b >= brick_y_t[3] && ball_y_b <= brick_y_b[3] && ball_x_r >= brick_x_l[3] && ball_x_l <= brick_x_r[3])) begin
                ball_y_delta_next = ~ball_y_delta_reg;
                collision = 1;
            end
            if (brick_visible[4] && (ball_y_b >= brick_y_t[4] && ball_y_b <= brick_y_b[4] && ball_x_r >= brick_x_l[4] && ball_x_l <= brick_x_r[4])) begin
                ball_y_delta_next = ~ball_y_delta_reg;
                collision = 1;
            end
            if (brick_visible[5] && (ball_y_b >= brick_y_t[5] && ball_y_b <= brick_y_b[5] && ball_x_r >= brick_x_l[5] && ball_x_l <= brick_x_r[5])) begin
                ball_y_delta_next = ~ball_y_delta_reg;
                collision = 1;
            end
            // update ball position
            ball_x_next = ball_x_reg + x_delta;
            ball_y_next = ball_y_reg + y_delta;


        end
    end


score score(
        .clk(clk),
        .reset(reset),
        .collision(collision),

        .thous(thouscnt),
        .huns(hunscnt),
        .tens(tenscnt),
        .ones(onescnt)
    );

    assign ones = onescnt;
    assign tens = tenscnt;
    assign huns = hunscnt;
    assign thous = thouscnt;

    // VIDEO ON/OFF
    always @* begin
        if (video_on) begin
            if (board_on)
                rgb = BOARD_RGB;
            else if (brick_on[0] || brick_on[1] || brick_on[2] || brick_on[3] || brick_on[4] || brick_on[5])
                rgb = BRICK_RGB;
            else if ((ball_x_l <= x) && (x <= ball_x_r) && (ball_y_t <= y) && (y <= ball_y_b))
                rgb = BALL_RGB;
            else
                rgb = BG_RGB;
        end else
            rgb = 0;
    end

endmodule
