module game_state (
    input  wire        clk,
    input  wire        rst,
    input  wire        sw0,           // Game mode select (0: 1P, 1: 2P)
    input  wire        sw1,           // Clock select (0: 60Hz, 1: KEY)
    input  wire        key,           // Player 1 confirm button
    input  wire        p1_any_button, // Any button from player 1
    input  wire [1:0]  health1,       // Player 1 health
    input  wire [1:0]  health2,       // Player 2 health
    input  wire [7:0]  time_counter,  // Game time counter
    output reg  [3:0]  state,         // Current game state
    output reg         game_mode,     // Game mode (0: 1P, 1: 2P)
    output reg         game_start,    // Game start signal
    output reg         game_over,     // Game over signal
    output reg  [1:0]  winner,        // Winner (0: none, 1: P1, 2: P2, 3: draw)
    output reg  [3:0]  countdown,     // Countdown value
    output reg  [3:0]  hex0_data,     // 7-segment display data
    output reg  [3:0]  hex1_data,
    output reg  [3:0]  hex2_data,
    output reg  [3:0]  hex3_data,
    output reg  [3:0]  hex4_data,
    output reg  [3:0]  hex5_data,
    output reg  [9:0]  ledr           // LED outputs
);

    // Game states
    localparam STATE_MENU     = 4'd0;
    localparam STATE_COUNTDOWN = 4'd1;
    localparam STATE_PLAY     = 4'd2;
    localparam STATE_GAMEOVER = 4'd3;

    // Countdown values
    localparam COUNTDOWN_3    = 4'd3;
    localparam COUNTDOWN_2    = 4'd2;
    localparam COUNTDOWN_1    = 4'd1;
    localparam COUNTDOWN_START = 4'd0;

    // Countdown timer
    reg [31:0] countdown_timer;
    localparam COUNTDOWN_DURATION = 32'd60; // 1 second at 60Hz

    // LED blink timer
    reg [31:0] blink_timer;
    localparam BLINK_DURATION = 32'd30; // 0.5 seconds at 60Hz
    reg blink_state;

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_MENU;
            game_mode <= 1'b0;
            game_start <= 1'b0;
            game_over <= 1'b0;
            winner <= 2'b00;
            countdown <= COUNTDOWN_3;
            countdown_timer <= 32'd0;
            blink_timer <= 32'd0;
            blink_state <= 1'b0;
        end else begin
            case (state)
                STATE_MENU: begin
                    game_mode <= sw0;
                    game_start <= 1'b0;
                    game_over <= 1'b0;
                    winner <= 2'b00;
                    countdown <= COUNTDOWN_3;
                    
                    if (p1_any_button) begin
                        state <= STATE_COUNTDOWN;
                        countdown_timer <= COUNTDOWN_DURATION;
                    end
                end

                STATE_COUNTDOWN: begin
                    if (countdown_timer == 0) begin
                        if (countdown == COUNTDOWN_START) begin
                            state <= STATE_PLAY;
                            game_start <= 1'b1;
                        end else begin
                            countdown <= countdown - 1;
                            countdown_timer <= COUNTDOWN_DURATION;
                        end
                    end else begin
                        countdown_timer <= countdown_timer - 1;
                    end
                end

                STATE_PLAY: begin
                    game_start <= 1'b0;
                    
                    // Check for game over conditions
                    if (health1 == 2'b00 || health2 == 2'b00 || time_counter == 8'd99) begin
                        state <= STATE_GAMEOVER;
                        game_over <= 1'b1;
                        blink_timer <= BLINK_DURATION;
                        blink_state <= 1'b0;
                        
                        // Determine winner
                        if (health1 == 2'b00 && health2 == 2'b00) begin
                            winner <= 2'b11; // Draw
                        end else if (health1 == 2'b00) begin
                            winner <= 2'b10; // P2 wins
                        end else if (health2 == 2'b00) begin
                            winner <= 2'b01; // P1 wins
                        end else begin
                            winner <= 2'b11; // Time out - Draw
                        end
                    end
                end

                STATE_GAMEOVER: begin
                    if (blink_timer == 0) begin
                        blink_state <= ~blink_state;
                        blink_timer <= BLINK_DURATION;
                    end else begin
                        blink_timer <= blink_timer - 1;
                    end

                    if (p1_any_button) begin
                        state <= STATE_MENU;
                        game_over <= 1'b0;
                        winner <= 2'b00;
                    end
                end
            endcase
        end
    end

    // 7-segment display data outputs
    always @(*) begin
        case (state)
            STATE_MENU: begin
                // Display "1P" or "2P"
                hex0_data = game_mode ? 4'd2 : 4'd1; // 2 or 1
                hex1_data = 4'd10; // P
                hex2_data = 4'd15; // Off
                hex3_data = 4'd15; // Off
                hex4_data = 4'd15; // Off
                hex5_data = 4'd15; // Off
            end

            STATE_COUNTDOWN: begin
                // Display countdown
                case (countdown)
                    COUNTDOWN_3: begin
                        hex0_data = 4'd3;
                        hex1_data = 4'd15; // Off
                        hex2_data = 4'd15; // Off
                        hex3_data = 4'd15; // Off
                        hex4_data = 4'd15; // Off
                        hex5_data = 4'd15; // Off
                    end
                    COUNTDOWN_2: begin
                        hex0_data = 4'd2;
                        hex1_data = 4'd15; // Off
                        hex2_data = 4'd15; // Off
                        hex3_data = 4'd15; // Off
                        hex4_data = 4'd15; // Off
                        hex5_data = 4'd15; // Off
                    end
                    COUNTDOWN_1: begin
                        hex0_data = 4'd1;
                        hex1_data = 4'd15; // Off
                        hex2_data = 4'd15; // Off
                        hex3_data = 4'd15; // Off
                        hex4_data = 4'd15; // Off
                        hex5_data = 4'd15; // Off
                    end
                    COUNTDOWN_START: begin
                        hex0_data = 4'd10; // A
                        hex1_data = 4'd10; // A
                        hex2_data = 4'd10; // A
                        hex3_data = 4'd10; // A
                        hex4_data = 4'd10; // A
                        hex5_data = 4'd10; // A
                    end
                endcase
            end

            STATE_PLAY: begin
                // Display "FIGHt"
                hex0_data = 4'd15; // F
                hex1_data = 4'd15; // I
                hex2_data = 4'd15; // G
                hex3_data = 4'd15; // H
                hex4_data = 4'd15; // t
                hex5_data = 4'd15; // Off
            end

            STATE_GAMEOVER: begin
                // Display winner and time
                case (winner)
                    2'b01: begin // P1 wins
                        hex0_data = 4'd1;
                        hex1_data = 4'd10; // P
                        hex2_data = 4'd11; // -
                        hex3_data = 4'd11; // -
                        hex4_data = time_counter[7:4]; // Time tens
                        hex5_data = time_counter[3:0]; // Time ones
                    end
                    2'b10: begin // P2 wins
                        hex0_data = 4'd10; // P
                        hex1_data = 4'd2;
                        hex2_data = 4'd11; // -
                        hex3_data = 4'd11; // -
                        hex4_data = time_counter[7:4]; // Time tens
                        hex5_data = time_counter[3:0]; // Time ones
                    end
                    2'b11: begin // Draw
                        hex0_data = 4'd14; // E
                        hex1_data = 4'd15; // q
                        hex2_data = 4'd11; // -
                        hex3_data = 4'd11; // -
                        hex4_data = time_counter[7:4]; // Time tens
                        hex5_data = time_counter[3:0]; // Time ones
                    end
                    default: begin
                        hex0_data = 4'd15; // Off
                        hex1_data = 4'd15; // Off
                        hex2_data = 4'd15; // Off
                        hex3_data = 4'd15; // Off
                        hex4_data = 4'd15; // Off
                        hex5_data = 4'd15; // Off
                    end
                endcase
            end
        endcase
    end

    // LED outputs
    always @(*) begin
        case (state)
            STATE_MENU: begin
                ledr = 10'b0000000000; // All LEDs off
            end

            STATE_PLAY: begin
                // Health indicators
                ledr[2:0] = ~health1; // P1 health (leftmost 3 LEDs)
                ledr[9:7] = ~health2; // P2 health (rightmost 3 LEDs)
                ledr[6:3] = 4'b0000;  // Middle LEDs off
            end

            STATE_GAMEOVER: begin
                // Blinking LEDs
                ledr = blink_state ? 10'b1111111111 : 10'b0000000000;
            end

            default: begin
                ledr = 10'b0000000000;
            end
        endcase
    end

endmodule 
