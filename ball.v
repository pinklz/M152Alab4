`timescale 1ns / 1ps

module ball(
    input clk,              // Clock signal
    input reset,            // Reset signal
    input pause,
    output reg [9:0] x_pos, // X position of the ball (10-bit for example resolution)
    output reg [9:0] y_pos, // Y position of the ball (10-bit for example resolution)
    input [9:0] x_initial,  // Initial X position
    input [9:0] y_initial,  // Initial Y position
    input [1:0] x_dir, // 10 is move right, 01 is move left, 00 is no x component
    input [1:0] y_dir // 10 is move up, 01 is move down, 00 is no y component
);


always @(posedge clk or posedge reset) begin
    if (reset) begin //Need to begin 
        // Reset ball position to initial values
        x_pos <= x_initial;
        y_pos <= y_initial;
//        x_dir <= 2b'00; // Reset direction to no x component
//        y_dir <= 2b'00; // Reset direction to down
    end else begin
        if (!pause) begin
            // Update X position
            if (x_dir == 2) begin //Move in positive x direction
                x_pos <= x_pos + 1;
            end else if (x_dir == 1) begin //Move in negative x direction
                x_pos <= x_pos - 1;
            end else if (x_dir == 0 || x_dir == 3) begin
                x_pos <= x_pos;
            end

            // Update Y position
            if (y_dir == 2) begin //Move in positive y direction
                y_pos <= y_pos + 1;
            end else if (y_dir == 1) begin //Move in negative y direction
                y_pos <= y_pos - 1;
            end else if (y_dir == 0 || y_dir == 3) begin
                y_pos <= y_pos;
            end
        end
        else begin
            x_pos <= x_pos;
            y_pos <= y_pos;
    end
    end
end

endmodule