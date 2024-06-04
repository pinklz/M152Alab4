`timescale 1ns / 1ps

module bricks(
    input clk,
    input reset,
    input x_pos,
    input [9:0] y_pos,
    input killBrick,
    output isAlive
    );
    
    reg alive;

    always@(posedge clk or posedge reset) begin
        if (reset) begin
            alive <= 1;
        end
        else begin
            if (killBrick) begin
                alive <= 0;
            end
            else begin
                alive <= 1;
            end
        end
    end
    
    assign isAlive = alive;
endmodule
