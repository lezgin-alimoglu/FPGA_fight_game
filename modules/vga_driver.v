module vga_driver (
    input  wire       clock,      // 25 MHz pixel clock
    input  wire       reset,      // Active high
    input  wire [7:0] color_in,   // Pixel color data (RRRGGGBB)
    output wire [9:0] next_x,     // X coordinate of next pixel
    output wire [9:0] next_y,     // Y coordinate of next pixel
    output wire       hsync,      // HSYNC to VGA
    output wire       vsync,      // VSYNC to VGA
    output wire [7:0] red,        // RED DAC to VGA
    output wire [7:0] green,      // GREEN DAC to VGA
    output wire [7:0] blue,       // BLUE DAC to VGA
    output wire       sync,       // SYNC (unused)
    output wire       clk,        // CLK to VGA (pass-through)
    output wire       blank       // BLANK to VGA
);

    // Horizontal timing (in pixel clocks)
    parameter [9:0] H_ACTIVE = 10'd639;
    parameter [9:0] H_FRONT  = 10'd15;
    parameter [9:0] H_PULSE  = 10'd95;
    parameter [9:0] H_BACK   = 10'd47;

    // Vertical timing (in lines)
    parameter [9:0] V_ACTIVE = 10'd479;
    parameter [9:0] V_FRONT  = 10'd9;
    parameter [9:0] V_PULSE  = 10'd1;
    parameter [9:0] V_BACK   = 10'd32;

    // Signal levels
    parameter LOW  = 1'b0;
    parameter HIGH = 1'b1;

    // Horizontal states
    parameter [1:0] H_STATE_ACTIVE = 2'd0;
    parameter [1:0] H_STATE_FRONT  = 2'd1;
    parameter [1:0] H_STATE_PULSE  = 2'd2;
    parameter [1:0] H_STATE_BACK   = 2'd3;

    // Vertical states
    parameter [1:0] V_STATE_ACTIVE = 2'd0;
    parameter [1:0] V_STATE_FRONT  = 2'd1;
    parameter [1:0] V_STATE_PULSE  = 2'd2;
    parameter [1:0] V_STATE_BACK   = 2'd3;

    // Registers
    reg         hsync_reg;
    reg         vsync_reg;
    reg  [7:0]  red_reg;
    reg  [7:0]  green_reg;
    reg  [7:0]  blue_reg;
    reg         line_done;

    reg  [9:0]  h_counter;
    reg  [9:0]  v_counter;

    reg  [1:0]  h_state;
    reg  [1:0]  v_state;

    // Main FSM: horizontal & vertical timing
    always @(posedge clock) begin
        if (reset) begin
            // Initialize everything on reset
            h_counter <= 10'd0;
            v_counter <= 10'd0;
            h_state   <= H_STATE_ACTIVE;
            v_state   <= V_STATE_ACTIVE;
            line_done <= LOW;
        end else begin
            // ─── Horizontal FSM ───────────────────────────────────────────────
            case (h_state)
                H_STATE_ACTIVE: begin
                    if (h_counter == H_ACTIVE) begin
                        h_counter <= 10'd0;
                        h_state   <= H_STATE_FRONT;
                    end else begin
                        h_counter <= h_counter + 10'd1;
                        h_state   <= H_STATE_ACTIVE;
                    end
                    hsync_reg <= HIGH;
                    line_done <= LOW;
                end

                H_STATE_FRONT: begin
                    if (h_counter == H_FRONT) begin
                        h_counter <= 10'd0;
                        h_state   <= H_STATE_PULSE;
                    end else begin
                        h_counter <= h_counter + 10'd1;
                        h_state   <= H_STATE_FRONT;
                    end
                    hsync_reg <= HIGH;
                end

                H_STATE_PULSE: begin
                    if (h_counter == H_PULSE) begin
                        h_counter <= 10'd0;
                        h_state   <= H_STATE_BACK;
                    end else begin
                        h_counter <= h_counter + 10'd1;
                        h_state   <= H_STATE_PULSE;
                    end
                    hsync_reg <= LOW;
                end

                H_STATE_BACK: begin
                    if (h_counter == H_BACK) begin
                        h_counter <= 10'd0;
                        h_state   <= H_STATE_ACTIVE;
                    end else begin
                        h_counter <= h_counter + 10'd1;
                        h_state   <= H_STATE_BACK;
                    end
                    hsync_reg <= HIGH;
                    // Mark end-of-line one cycle before the next ACTIVE
                    line_done <= (h_counter == (H_BACK - 1)) ? HIGH : LOW;
                end

                default: begin
                    h_counter <= 10'd0;
                    h_state   <= H_STATE_ACTIVE;
                    hsync_reg <= HIGH;
                    line_done <= LOW;
                end
            endcase

            // ─── Vertical FSM ─────────────────────────────────────────────────
            case (v_state)
                V_STATE_ACTIVE: begin
                    if (line_done == HIGH) begin
                        if (v_counter == V_ACTIVE) begin
                            v_counter <= 10'd0;
                            v_state   <= V_STATE_FRONT;
                        end else begin
                            v_counter <= v_counter + 10'd1;
                            v_state   <= V_STATE_ACTIVE;
                        end
                    end
                    vsync_reg <= HIGH;
                end

                V_STATE_FRONT: begin
                    if (line_done == HIGH) begin
                        if (v_counter == V_FRONT) begin
                            v_counter <= 10'd0;
                            v_state   <= V_STATE_PULSE;
                        end else begin
                            v_counter <= v_counter + 10'd1;
                            v_state   <= V_STATE_FRONT;
                        end
                    end
                    vsync_reg <= HIGH;
                end

                V_STATE_PULSE: begin
                    if (line_done == HIGH) begin
                        if (v_counter == V_PULSE) begin
                            v_counter <= 10'd0;
                            v_state   <= V_STATE_BACK;
                        end else begin
                            v_counter <= v_counter + 10'd1;
                            v_state   <= V_STATE_PULSE;
                        end
                    end
                    vsync_reg <= LOW;
                end

                V_STATE_BACK: begin
                    if (line_done == HIGH) begin
                        if (v_counter == V_BACK) begin
                            v_counter <= 10'd0;
                            v_state   <= V_STATE_ACTIVE;
                        end else begin
                            v_counter <= v_counter + 10'd1;
                            v_state   <= V_STATE_BACK;
                        end
                    end
                    vsync_reg <= HIGH;
                end

                default: begin
                    v_counter <= 10'd0;
                    v_state   <= V_STATE_ACTIVE;
                    vsync_reg <= HIGH;
                end
            endcase

            // ─── Color Output ──────────────────────────────────────────────────
            if (h_state == H_STATE_ACTIVE && v_state == V_STATE_ACTIVE) begin
                red_reg   <= {color_in[7:5], 5'd0};
                green_reg <= {color_in[4:2], 5'd0};
                blue_reg  <= {color_in[1:0], 6'd0};
            end else begin
                red_reg   <= 8'd0;
                green_reg <= 8'd0;
                blue_reg  <= 8'd0;
            end
        end
    end

    // ─── Output Assignments ────────────────────────────────────────────────
    assign hsync  = hsync_reg;
    assign vsync  = vsync_reg;
    assign red    = red_reg;
    assign green  = green_reg;
    assign blue   = blue_reg;
    assign clk    = clock;
    assign sync   = 1'b0;
    assign blank  = hsync_reg & vsync_reg;
    assign next_x = (h_state == H_STATE_ACTIVE) ? h_counter : 10'd0;
    assign next_y = (v_state == V_STATE_ACTIVE) ? v_counter : 10'd0;

endmodule
