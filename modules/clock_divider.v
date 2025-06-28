module clock_divider #(parameter DIV_FACTOR = 2)( // Factor determines frequency of clk_out
    input wire clk,      
    input wire rst,      
    output reg clk_out   
);

    reg [31:0] counter = 0;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == (DIV_FACTOR / 2 - 1))   // This determines Duty Cycle
				begin
                clk_out <= ~clk_out;
                counter <= 0;
            end 
				else 
				begin
                counter <= counter + 1;
            end
        end
    end

endmodule
