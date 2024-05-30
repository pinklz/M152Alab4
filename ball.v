`timescale 1ns / 1ps

module ball(
    input clk,              // Clock signal
    input reset,            // Reset signal
    input pause,
    output reg [9:0] x_pos, // X position of the ball (10-bit for example resolution)
    output reg [9:0] y_pos, // Y position of the ball (10-bit for example resolution)
    input [9:0] x_initial,  // Initial X position
    input [9:0] y_initial,  // Initial Y position
    input x_dir, // 1 is move right
    input y_dir, // 1 is move up
);


always @(posedge clk or posedge reset) begin
    if (reset) begin //Need to begin 
        // Reset ball position to initial values
        x_pos <= x_initial;
        y_pos <= y_initial;
        x_dir <= 1; // Reset direction to right
        y_dir <= 0; // Reset direction to down
    end else begin
        if (!pause) begin
            // Update X position
            if (x_dir) begin //Move in positive x direction
                x_pos <= x_pos + 1;
            end else if (!x_dir) begin //Move in negative x direction
                x_pos <= x_pos - 1;
            end

            // Update Y position
            if (y_dir) begin //Move in positive y direction
                y_pos <= y_pos + 1;
            end else if (!y_dir) begin //Move in negative y direction
                y_pos <= y_pos - 1;
            end
        end
        else begin
            x_pos <= x_pos;
            y_pos <= y_pos;
    end
end

endmodule