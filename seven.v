
`timescale 1ns / 1ps

module seven(
    input wire [3:0] dig,
    output wire [6:0] seven_seg_display
);

reg[6:0] seven_segment;

/* 
Switch statement: for every digit 0 through 9
    Turn on different lines in the display to represent that number
    Where the display lines are held in 'seven_segment' register

    And the input is in 'dig'

    default case = display 8 (all lines are on)

*/

always @ (*) begin
    case(dig)
        4'h0: seven_segment = 7'b1000000;
        4'h1: seven_segment = 7'b1111001;
        4'h2: seven_segment = 7'b0100100;
        4'h3: seven_segment = 7'b0110000;
        4'h4: seven_segment = 7'b0011001;
        4'h5: seven_segment = 7'b0010010;
        4'h6: seven_segment = 7'b0000010;
        4'h7: seven_segment = 7'b1111000;
        4'h8: seven_segment = 7'b0000000;
        4'h9: seven_segment = 7'b0010000;
        default:
            seven_segment = 7'b1111111;
    endcase
    end

assign seven_seg_display = seven_segment;
endmodule