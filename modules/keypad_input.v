module keypad_input (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  row,           // Keypad row input
    input  wire [3:0]  fpga_keys,     // FPGA keys input
    output reg  [3:0]  col,           // Keypad column output
    input  wire        game_mode,     // 0: 1P, 1: 2P
    output reg         p1_fwd,        // Player 1 forward
    output reg         p1_bwd,        // Player 1 backward
    output reg         p1_attack,     // Player 1 attack
    output reg         p1_any_button, // Any button from player 1
    output reg         p2_fwd,        // Player 2 forward
    output reg         p2_bwd,        // Player 2 backward
    output reg         p2_attack      // Player 2 attack
);

    // Keypad column scanning
    reg [1:0] col_scan;
    reg [3:0] row_data;
    reg [3:0] col_data;

    // Debounce registers for keypad
    reg [3:0] p2_fwd_reg;
    reg [3:0] p2_bwd_reg;
    reg [3:0] p2_attack_reg;

    // Debounce registers for FPGA keys
    reg [3:0] p1_fwd_reg;
    reg [3:0] p1_bwd_reg;
    reg [3:0] p1_attack_reg;

    // Column scanning
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            col_scan <= 2'b00;
            col <= 4'b0000;
        end else begin
            case (col_scan)
                2'b00: col <= 4'b1110;
                2'b01: col <= 4'b1101;
                2'b10: col <= 4'b1011;
                2'b11: col <= 4'b0111;
            endcase
            col_scan <= col_scan + 1;
        end
    end

    // Row data capture
    always @(posedge clk) begin
        row_data <= row;
    end

    // Keypad mapping for Player 2
    // Row 0: 1, 2, 3, A
    // Row 1: 4, 5, 6, B
    // Row 2: 7, 8, 9, C
    // Row 3: *, 0, #, D
    // P2: 1(forward), 3(backward), 2(attack)

    // FPGA key mapping for Player 1
    // KEY[3]: forward
    // KEY[2]: backward
    // KEY[1]: attack
    // KEY[0]: any button

    // Debounce and input processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset keypad debounce registers
            p2_fwd_reg <= 4'b0000;
            p2_bwd_reg <= 4'b0000;
            p2_attack_reg <= 4'b0000;
            
            // Reset FPGA key debounce registers
            p1_fwd_reg <= 4'b0000;
            p1_bwd_reg <= 4'b0000;
            p1_attack_reg <= 4'b0000;
            
            // Reset outputs
            p1_fwd <= 1'b0;
            p1_bwd <= 1'b0;
            p1_attack <= 1'b0;
            p1_any_button <= 1'b0;
            p2_fwd <= 1'b0;
            p2_bwd <= 1'b0;
            p2_attack <= 1'b0;
        end else begin
            // Player 1 controls (FPGA keys)
            p1_fwd_reg <= {p1_fwd_reg[2:0], ~fpga_keys[3]};  // KEY[3] for forward
            p1_bwd_reg <= {p1_bwd_reg[2:0], ~fpga_keys[2]};  // KEY[2] for backward
            p1_attack_reg <= {p1_attack_reg[2:0], ~fpga_keys[1]};  // KEY[1] for attack

            // Player 2 controls (keypad)
            p2_fwd_reg <= {p2_fwd_reg[2:0], (col_scan == 2'b00 && row_data == 4'b1011)};
            p2_bwd_reg <= {p2_bwd_reg[2:0], (col_scan == 2'b10 && row_data == 4'b1011)};
            p2_attack_reg <= {p2_attack_reg[2:0], (col_scan == 2'b00 && row_data == 4'b1101)};

            // Debounced outputs for Player 1
            p1_fwd <= &p1_fwd_reg;
            p1_bwd <= &p1_bwd_reg;
            p1_attack <= &p1_attack_reg;

            // Debounced outputs for Player 2
            p2_fwd <= &p2_fwd_reg;
            p2_bwd <= &p2_bwd_reg;
            p2_attack <= &p2_attack_reg;

            // Any button from player 1 (using KEY[0])
            p1_any_button <= ~fpga_keys[0];

            // In 1P mode, disable player 2 controls
            if (!game_mode) begin
                p2_fwd <= 1'b0;
                p2_bwd <= 1'b0;
                p2_attack <= 1'b0;
            end
        end
    end

endmodule 