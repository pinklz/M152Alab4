`timescale 1ns / 1ps

module score(
    input wire clk,
    input wire reset,
    input wire collision,
    
    output wire [3:0] thous,
    output wire [3:0] huns, 
    output wire [3:0] tens, 
    output wire [3:0] ones
    );
    
    reg [3:0] onescnt;
    reg [3:0] tenscnt;
    reg [3:0] hunscnt;
    reg [3:0] thouscnt;
    
   
//    always @(posedge collision) begin
    
//    end
    
    always @(posedge clk) begin
        if (reset) begin
            onescnt <= 0;
            tenscnt <= 0;
            hunscnt <= 0;
            thouscnt <= 0;
        end
        
        if (collision) begin
            if (onescnt == 9) begin
                // ones overflow
                if (tenscnt == 9) begin
                    //tens overflow
                    if (hunscnt == 9) begin
                        //hundrends overflow
                        if (thouscnt == 9) begin
                            onescnt <= 0;
                            tenscnt <= 0;
                            hunscnt <= 0;
                            thouscnt <= 0;
                        end
                        // Increase thousands
                        onescnt <= 0;
                        tenscnt <= 0;
                        hunscnt <= 0;
                        thouscnt <= thouscnt +1; 
                    end
                    // Increase hundreds
                    onescnt <= 0;
                    tenscnt <= 0;
                    hunscnt <= hunscnt +1;
                end
                // Increase tens
                onescnt <=0;
                tenscnt <= tenscnt +1;
            end
            // Increase ones
            onescnt <= onescnt +1;
        end
        
    end    
endmodule
