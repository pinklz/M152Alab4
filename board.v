`timescale 1ns / 1ps

module board(
    input clk,             // Clock signal
    input reset,           // Reset signal
    input pause,
    output reg [9:0] x_pos, // X position of the paddle (10-bit for screen resolution)
    input [9:0] x_initial, // Initial X position of the paddle
    input move_left,       // Signal to move the paddle left
    input move_right,      // Signal to move the paddle right
    input [9:0] screen_width, // Width of the screen
    input [9:0] paddle_width  // Width of the paddle
    input y_initial,
);

// Define the limits for paddle movement
wire [9:0] left_limit = 0;
wire [9:0] right_limit = screen_width - paddle_width;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Reset paddle position to initial value
        x_pos <= x_initial;
    end else begin
        if (!pause) begin
            // Move paddle left
            if (move_left && x_pos > left_limit) begin
                x_pos <= x_pos - 1; // Decrease x_pos to move left
            end
            // Move paddle right
            else if (move_right && x_pos < right_limit) begin
                x_pos <= x_pos + 1; // Increase x_pos to move right
            end
        end else begin
            x_pos <= x_pos;
        end
    end
end

endmodule