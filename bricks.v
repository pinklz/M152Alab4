`timescale 1ns / 1ps

module bricks(
    input clk,
    input reset,
    input [9:0] x_pos,
    input [9:0] y_pos,
    input killBrick,
    output isAlive,
    );

    always@(posedge clk or posedge reset) begin
        if (reset) begin
            isAlive <= 1;
        end
        else begin
            if (killBrick) begin
                isAlive <= 0;
            end
            else begin
                isAlive <= 1;
            end
        end
    end
endmodule