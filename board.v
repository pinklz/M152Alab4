`timescale 1ns / 1ps

module board(
    input clk,             // Clock signal
    input reset,           // Reset signal
    input pause,
    
    input [9:0] x_initial, // Initial X position of the paddle
    input move_left,       // Signal to move the paddle left
    input move_right,      // Signal to move the paddle right
    input [9:0] screen_width, // Width of the screen
    input [9:0] paddle_width,  // Width of the paddle
    input [9:0] y_initial,

    output start_out,
    
    output reg [9:0] x_pos // X position of the paddle (10-bit for screen resolution)
);

// Define the limits for paddle movement
wire [9:0] left_limit = 0;
wire [9:0] right_limit = screen_width - paddle_width;

reg start = 1;

always @(posedge clk) begin
    if (reset or start) begin
        x_pos <= x_initial;
        start_out <= start;
    end
    else begin
        if (move_left || move_right) begin
            start_out <= 0;
        end
        start_out <= ~start;    // Begin game
        if (!pause) begin
           // Move paddle left
           if (move_left && current_x-1 > left_limit) begin
               x_pos <= current_x - 1; // Decrease x_pos to move left
           end
           // Move paddle right
           else if (move_right && current_x+1 < right_limit) begin
               x_pos <= current_x + 1; // Increase x_pos to move right
           end
       end else begin
           x_pos <= current_x;
       end
    end
    start_out <= start;
end

endmodule
