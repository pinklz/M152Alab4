`timescale 1ns / 1ps

module score_tb;

    // Inputs
    reg clk;
    reg reset;
    reg collision;

    // Outputs
    wire [3:0] thous;
    wire [3:0] huns;
    wire [3:0] tens;
    wire [3:0] ones;

    // Instantiate the Unit Under Test (UUT)
    score uut (
        .clk(clk),
        .reset(reset),
        .collision(collision),
        .thous(thous),
        .huns(huns),
        .tens(tens),
        .ones(ones)
    );

    // Clock generation
    always #5 clk = ~clk; // Clock period of 10 time units (100 MHz)

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 0;
        collision = 0;

        // Apply reset
        reset = 1;
        #10;
        reset = 0;

        // Wait for some time
        #20;

        // Generate collisions and observe the score increments
        repeat (10) begin
            collision = 1;
            #10;
            collision = 0;
            #10;
        end

        // Wait and observe output
        #100;

        // Reset and observe if score resets
        reset = 1;
        #10;
        reset = 0;

        // Wait and observe output
        #100;

        // Finish simulation
        $stop;
    end

    initial begin
        // Monitor outputs
        $monitor("At time %t: thous = %d, huns = %d, tens = %d, ones = %d",
                 $time, thous, huns, tens, ones);
    end
endmodule
