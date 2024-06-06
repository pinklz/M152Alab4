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
    input board_height,
    input ball_start_posx,
    input ball_start_posy,
    input board_start_posx,
    input board_start_posy,
    input brick_posx,
    input brick_posy,
    input brick_width,
    output render_boardx,
    output render_boardy,
    output render_ballx,
    output render_bally,
    output render_brickx,
    output render_bricky
);

parameter NUM_BRICKS = 32;
wire [9:0] ball_x, ball_y;
reg [1:0] ball_x_direction;
reg [1:0] ball_y_direction;

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
    .x_initial(ball_start_posx), // Example start position
    .y_initial(ball_start_posy),
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
    .x_initial(board_start_posx),
    .move_left(board_left),
    .move_right(board_right),
    .screen_width(screen_width),
    .screen_height(screen_height),
    .board_width(board_width),
    .y_initial(board_start_posy)
);

//wire [9:0] brick_pos_x = 0;
//wire [9:0] brick_pos_y = 0;

bricks brick_obj(
    .clk(clk),
    .reset(reset),
    .x_pos(brick_posx),
    .y_pos(brick_posy),
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
    if ((ball_x >= board_x) && (ball_x <= board_x + board_width) && (ball_y >= board_start_posy) && (ball_y <= board_start_posy + board_height)) begin
        if (board_left) begin
            ball_x_direction <= 2'b01;
            ball_y_direction <= ~ball_y_direction;
        end
        else if (board_right) begin
            ball_x_direction <= 2'b10;
            ball_y_direction <= ~ball_y_direction;
        end
        else begin
            ball_x_direction <= ~ball_x_direction;
            ball_y_direction <= ~ball_y_direction;
        end
    end

    //Detects ball collision with brick (Still need to insert dead/alive logic)
    else if ((ball_x >= brick_posx) && (ball_x <= brick_posx + brick_width) && (ball_y >= brick_posy) && (ball_y <= brick_posy + brick_width)) begin
        ball_x_direction <= ~ball_x_direction;
        ball_y_direction <= ~ball_y_direction;
    end

    //Detects ball collision with border
    else if ((ball_x == 0) || (ball_x == screen_width) || (ball_y == screen_height)) begin
        ball_x_direction <= ~ball_x_direction;
        ball_y_direction <= ~ball_y_direction;
    end

    //Game over detection
    else if ((ball_y == 0)) begin
        //reset the game/handle gameover logic
    end
    
end

endmodule