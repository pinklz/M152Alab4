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

    input [9:0] current_x,
    input move_clk,

    output start_out,
    
    output reg [9:0] x_pos // X position of the paddle (10-bit for screen resolution)
);

reg start = 1;
reg s;

// Define the limits for paddle movement
wire [9:0] left_limit = 0;
wire [9:0] right_limit = screen_width - paddle_width;


//// Process to handle start and reset signals
//always @(posedge clk) begin
//    if (reset || start) begin
//        x_pos <= x_initial;
//        s <= start;
//    end else begin
//        if (move_left || move_right) begin
//            s <= 0;
//            start <= 0;
//        end
//    end
//end

//// Process to move the paddle
//always @(posedge move_clk) begin
//    //if (!reset && !pause && !start) begin
//        // Move paddle left
//        s <= 0;    // Begin game
//                if (!pause) begin
//                   // Move paddle left
//                   if (move_left ) begin//&& current_x-1 > left_limit) begin
//                       x_pos <= x_pos - 1; // Decrease x_pos to move left
//                   end
//                   // Move paddle right
//                   else if (move_right) begin// && current_x+1 < right_limit) begin
//                       x_pos <= x_pos + 1; // Increase x_pos to move right
//                   end
//               end else begin
//                   x_pos <= x_pos;
//               end
//    //end
//end


always @(posedge clk) begin
    if (reset || start) begin
        x_pos <= x_initial;
        s <= 0;
    end
    if (s == 0) begin
        if (!pause) begin
               // Move paddle left
               if (move_left ) begin//&& current_x-1 > left_limit) begin
                   x_pos <= x_pos - 1; // Decrease x_pos to move left
               end
               // Move paddle right
               else if (move_right) begin// && current_x+1 < right_limit) begin
                   x_pos <= x_pos + 1; // Increase x_pos to move right
               end
           end else begin
               x_pos <= x_pos;
           end
    end
    else begin
        s <= 0;    // Begin game
        if (!pause) begin
           // Move paddle left
           if (move_left ) begin//&& current_x-1 > left_limit) begin
               x_pos <= x_pos - 1; // Decrease x_pos to move left
           end
           // Move paddle right
           else if (move_right) begin// && current_x+1 < right_limit) begin
               x_pos <= x_pos + 1; // Increase x_pos to move right
           end
       end else begin
           x_pos <= x_pos;
       end
    end
end

assign start_out = s;

endmodule
