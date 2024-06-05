`timescale 1ns / 1ps


module debouncer(
    input clk,
    input button_in,

    output button_out
);

reg [3:0] mask;      // counter register
reg button = 0;

always @(posedge clk) begin
    if (button_in == 0) begin
        mask <= 0;
        button <= 0;
    end
    else begin
        mask <= mask + 1;
        if (mask == 4'b1111) begin
            button <= 1;
            mask <= 0;
        end
    end
end

assign button_out = button;
endmodule
