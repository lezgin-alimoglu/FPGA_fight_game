module keypad_controller (
    input clk,
    input rst,
    input [3:0] rows,       // Inputs from keypad rows (active low)
    output reg [3:0] cols,  // Outputs to keypad columns (active low scan)
    output reg fwd,
    output reg bwd,
    output reg attack,
    output reg up
);

    reg [1:0] col_sel;
    reg [15:0] key_state;

    // Define key indices in the 4x4 matrix (row * 4 + col)
    localparam KEY_LEFT   = 4'd3;  // row 3, col 0
    localparam KEY_RIGHT  = 4'd7;  // row 3, col 1
    localparam KEY_ATTACK = 4'd11;  // row 3, col 2
    localparam KEY_UP     = 4'd15;  // row 3, col 3

    wire [3:0] curr_col_mask = ~(4'b0001 << col_sel);  // Active low scan for current column

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cols <= 4'b1111;
            col_sel <= 0;
            key_state <= 16'b0;
            fwd <= 0;
            bwd <= 0;
            attack <= 0;
            up <= 0;
        end else begin
            // Output active low column select for scanning
            cols <= curr_col_mask;

            // Scan rows for current column: active low means pressed key = 0
            for (i = 0; i < 4; i = i + 1) begin
                key_state[i*4 + col_sel] <= ~rows[i];
            end

            // Move to next column (wrap around 0 to 3)
            col_sel <= col_sel + 1;

            // Update outputs based on key_state
            bwd <= key_state[KEY_LEFT];
            fwd <= key_state[KEY_RIGHT];
            attack <= key_state[KEY_ATTACK];
            up <= key_state[KEY_UP];
        end
    end

endmodule
