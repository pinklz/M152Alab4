`timescale 1ns / 1ps

module physics_controller(
    input clk,
    input reset,
    input pause,
    input board_left,
    input board_right,
    input [9:0] screen_width,
    input [9:0] screen_height,
    input [9:0] board_width,
    output wire collision_with_paddle
    //output wire [NUM_BRICKS-1:0] collision_with_bricks
);

parameter NUM_BRICKS = 32;
wire [9:0] ball_x, ball_y;
wire [1:0] ball_x_direction;
wire [1:0] ball_y_direction;

//wire [NUM_BRICKS-1:0] brick_hits;

//Board parameters
wire [9:0] board_x;

//Ball parameters
wire killBrick;
wire isBrickAlive;


// Instantiate ball
ball ball_obj(
    .clk(clk),
    .reset(reset),
    .pause(pause),
    .x_initial(320), // Example start position
    .y_initial(240),
    .x_pos(ball_x),
    .y_pos(ball_y),
    .x_dir(ball_x_direction),
    .y_dir(ball_y_direction)
);

// Instantiate paddle
 board board_obj(
    .clk(clk),
    .reset(reset),
    .pause(pause),
    .x_pos(board_x),
    .x_initial(SET INITIAL X),
    .move_left(board_left),
    .move_right(board_right),
    .screen_width(screen_width),
    .screen_height(screen_height),
    .board_width(SET BOARD WIDTH),
    .y_initial(SET Y INITIAL)
);

brick brick_obj(
    .clk(clk),
    .reset(reset),
    .x_pos(SET X POS),
    .y_pos(SET Y POS),
    .killBrick(killBrick),
    .isAlive(isBrickAlive)
);

/*
// Instantiate bricks
genvar i;
generate
    for (i = 0; i < NUM_BRICKS; i = i + 1) begin : bricks
        brick brick_inst(
            .clk(clk),
            .reset(reset),
            .pos_x(10 + i*32), // Example positions
            .pos_y(50),
            .active(1'b1),
            .hit(brick_hits[i])
        );
    end
endgenerate
*/

// Collision detection logic


always @(posedge clk or posedge reset) begin

    //Detects ball collision with board
    if ((ball_x >= board_x) && (ball_x <= board_x + 64) && (ball_y >= board_y) && (ball_y <= paddle_y + 8)) begin
        if (board_left) begin
            ball_x_direction <= 2b'01;
            ball_y_direction <= ~ball_y_direction;
        end
        else if (board_right) begin
            ball_x_direction <= 2b'10;
            ball_y_direction <= ~ball_y_direction;
        end
        else begin
            ball_x_direction <= ~ball_x_direction;
            ball_y_direction <= ~ball_y_direction;
        end
    end

    //Detects ball collision with brick (Still need to insert dead/alive logic)
    else if ((ball_x >= BRICKPOSX) && (ball_x <= BRICKPOS + BRICKWIDTH) && (ball_y >= BRICKPOSY) && (ball_y <= BRICKPOSY + BRICKHEIGHT)) begin
        ball_x_direction <= ~ball_x_direction;
        ball_y_direction <= ~ball_y_direction;
    end

    //Detects ball collision with border
    else if ((ball_x == SCREENLEFT) || (ball_x == SCREENRIGHT) || (ball_y == SCREENTOP)) begin
        ball_x_direction <= ~ball_x_direction;
        ball_y_direction <= ~ball_y_direction;
    end

    //Game over detection
    else if ((ball_y == SCREENBOTTOM)) begin
        //reset the game/handle gameover logic
    end
end

endmodule