module game_clock (
    input  wire        clk,           // System clock (50MHz)
    input  wire        rst,           // Reset signal
    input  wire        sw1,           // Clock select (0: 60Hz, 1: KEY)
    input  wire        key,           // Manual clock input
    input  wire        game_start,    // Game start signal
    input  wire        game_over,     // Game over signal
    output reg         game_clk,      // Game clock output
    output reg  [7:0]  time_counter   // Time counter output
);

    // Constants
    localparam CLOCK_FREQ = 50_000_000;  // 50MHz system clock
    localparam GAME_FREQ = 60;           // 60Hz game clock
    localparam CLOCK_DIV = CLOCK_FREQ / GAME_FREQ;  // Clock division factor
    localparam INITIAL_TIME = 8'd99;     // Initial time (99 seconds)

    // Registers
    reg [31:0] clock_counter;
    reg [7:0]  time_reg;
    reg        prev_key;

    // Clock divider for 60Hz
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clock_counter <= 32'd0;
            game_clk <= 1'b0;
        end else if (!sw1) begin  // 60Hz mode
            if (clock_counter >= CLOCK_DIV - 1) begin
                clock_counter <= 32'd0;
                game_clk <= ~game_clk;
            end else begin
                clock_counter <= clock_counter + 1;
            end
        end else begin  // Manual clock mode
            game_clk <= 1'b0;  // Default to 0 in manual mode
        end
    end

    // Manual clock detection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_key <= 1'b0;
        end else begin
            prev_key <= key;
        end
    end

    // Manual clock generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            game_clk <= 1'b0;
        end else if (sw1) begin  // Manual clock mode
            if (key && !prev_key) begin  // Rising edge detection
                game_clk <= 1'b1;
            end else begin
                game_clk <= 1'b0;
            end
        end
    end

    // Time counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            time_reg <= INITIAL_TIME;
        end else if (game_start && !game_over) begin
            if (game_clk) begin  // Count on game clock
                if (time_reg > 0) begin
                    time_reg <= time_reg - 1;
                end
            end
        end else if (!game_start) begin
            time_reg <= INITIAL_TIME;  // Reset time at menu
        end
    end

    // Output assignment
    always @(*) begin
        time_counter = time_reg;
    end

endmodule 