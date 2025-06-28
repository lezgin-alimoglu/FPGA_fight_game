module character2 #(
    parameter INIT_X = 10'd400
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        fwd,
    input  wire        bwd,
    input  wire        attack,
    input  wire [9:0]  vga_x,
    input  wire [9:0]  vga_y,
    input  wire [9:0]  sprite_y,
    output reg  [3:0]  state,
    output wire        attacking,
    output wire [7:0]  pixel_color,
    output wire [9:0]  pos_x
);

    // Boundary
    localparam SCREEN_LEFT   = 10'd0;
    localparam SCREEN_RIGHT  = 10'd576;

    // Frame Numbers (from Table 1)
    localparam BASIC_STARTUP_FRAMES  = 5;
    localparam BASIC_ACTIVE_FRAMES   = 2;
    localparam BASIC_RECOVERY_FRAMES = 16;
    localparam DIR_STARTUP_FRAMES    = 4;
    localparam DIR_ACTIVE_FRAMES     = 3;
    localparam DIR_RECOVERY_FRAMES   = 15;

    // State Encoding
    localparam STATE_IDLE                  = 4'd0,
               STATE_MOVING_FORWARD        = 4'd1,
               STATE_MOVING_BACKWARD       = 4'd2,
               STATE_ATTACK_BASIC_STARTUP  = 4'd3,
               STATE_ATTACK_BASIC_ACTIVE   = 4'd4,
               STATE_ATTACK_BASIC_RECOVERY = 4'd5,
               STATE_ATTACK_DIR_STARTUP    = 4'd6,
               STATE_ATTACK_DIR_ACTIVE     = 4'd7,
               STATE_ATTACK_DIR_RECOVERY   = 4'd8,
               STATE_HITSTUN              = 4'd9,
               STATE_BLOCKSTUN            = 4'd10;

    reg [9:0]  sprite_x_reg;
    reg [4:0]  frame_cnt;

    // Input synchronize registers
    reg attack_reg, fwd_reg, bwd_reg;

    // Synchronize inputs to prevent glitches
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            attack_reg <= 0;
            fwd_reg    <= 0;
            bwd_reg    <= 0;
        end else begin
            attack_reg <= attack;
            fwd_reg    <= fwd;
            bwd_reg    <= bwd;
        end
    end

    // Initial position
    initial begin
        sprite_x_reg = INIT_X;
        sprite_x_render = INIT_X;
    end

    // FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= STATE_IDLE;
            sprite_x_reg <= INIT_X;
            frame_cnt    <= 5'd0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (attack_reg && (fwd_reg || bwd_reg)) begin
                        state     <= STATE_ATTACK_DIR_STARTUP;
                        frame_cnt <= DIR_STARTUP_FRAMES - 1;
                    end else if (attack_reg) begin
                        state     <= STATE_ATTACK_BASIC_STARTUP;
                        frame_cnt <= BASIC_STARTUP_FRAMES - 1;
                    end else if (fwd_reg & ~bwd_reg) begin
                        state <= STATE_MOVING_FORWARD;
                    end else if (bwd_reg & ~fwd_reg) begin
                        state <= STATE_MOVING_BACKWARD;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end

                STATE_MOVING_FORWARD: begin
                    if (attack_reg) begin
                        state     <= STATE_ATTACK_DIR_STARTUP;
                        frame_cnt <= DIR_STARTUP_FRAMES - 1;
                    end else if (!(fwd_reg & ~bwd_reg)) begin
                        state <= STATE_IDLE;
                    end
                end

                STATE_MOVING_BACKWARD: begin
                    if (attack_reg) begin
                        state     <= STATE_ATTACK_DIR_STARTUP;
                        frame_cnt <= DIR_STARTUP_FRAMES - 1;
                    end else if (!(bwd_reg & ~fwd_reg)) begin
                        state <= STATE_IDLE;
                    end
                end

                STATE_ATTACK_BASIC_STARTUP: begin
                    if (frame_cnt != 0) begin
                        frame_cnt <= frame_cnt - 1;
                        state     <= STATE_ATTACK_BASIC_STARTUP;
                    end else begin
                        state     <= STATE_ATTACK_BASIC_ACTIVE;
                        frame_cnt <= BASIC_ACTIVE_FRAMES - 1;
                    end
                end

                STATE_ATTACK_BASIC_ACTIVE: begin
                    if (frame_cnt != 0) begin
                        frame_cnt <= frame_cnt - 1;
                        state     <= STATE_ATTACK_BASIC_ACTIVE;
                    end else begin
                        state     <= STATE_ATTACK_BASIC_RECOVERY;
                        frame_cnt <= BASIC_RECOVERY_FRAMES - 1;
                    end
                end

                STATE_ATTACK_BASIC_RECOVERY: begin
                    if (frame_cnt != 0) begin
                        frame_cnt <= frame_cnt - 1;
                        state     <= STATE_ATTACK_BASIC_RECOVERY;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end

                STATE_ATTACK_DIR_STARTUP: begin
                    if (frame_cnt != 0) begin
                        frame_cnt <= frame_cnt - 1;
                        state     <= STATE_ATTACK_DIR_STARTUP;
                    end else begin
                        state     <= STATE_ATTACK_DIR_ACTIVE;
                        frame_cnt <= DIR_ACTIVE_FRAMES - 1;
                    end
                end

                STATE_ATTACK_DIR_ACTIVE: begin
                    if (frame_cnt != 0) begin
                        frame_cnt <= frame_cnt - 1;
                        state     <= STATE_ATTACK_DIR_ACTIVE;
                    end else begin
                        state     <= STATE_ATTACK_DIR_RECOVERY;
                        frame_cnt <= DIR_RECOVERY_FRAMES - 1;
                    end
                end

                STATE_ATTACK_DIR_RECOVERY: begin
                    if (frame_cnt != 0) begin
                        frame_cnt <= frame_cnt - 1;
                        state     <= STATE_ATTACK_DIR_RECOVERY;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end

                STATE_HITSTUN: begin
                    if (frame_cnt != 0) begin
                        frame_cnt <= frame_cnt - 1;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end

                STATE_BLOCKSTUN: begin
                    if (frame_cnt != 0) begin
                        frame_cnt <= frame_cnt - 1;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase

            // Movement logic
            if ((state == STATE_IDLE || state == STATE_MOVING_FORWARD || state == STATE_MOVING_BACKWARD)) begin
                if (fwd_reg & ~bwd_reg && sprite_x_reg <= SCREEN_RIGHT - 2)
                    sprite_x_reg <= sprite_x_reg + 3;  // move right
                else if (bwd_reg & ~fwd_reg && sprite_x_reg >= SCREEN_LEFT + 2)
                    sprite_x_reg <= sprite_x_reg - 2;  // move left
            end
        end
    end

    // Attack state
    assign attacking = (state >= STATE_ATTACK_BASIC_STARTUP && state <= STATE_ATTACK_DIR_RECOVERY);

    // Sprite position synchronization
    reg [9:0] sprite_x_render;
    always @(posedge clk or posedge rst)
        if (rst) sprite_x_render <= INIT_X;
        else     sprite_x_render <= sprite_x_reg;

    // Screen coordinates to sprite position
    wire signed [9:0] rel_x_signed = vga_x - sprite_x_render;
    wire [5:0] rel_x = rel_x_signed[5:0];  // max 64 px
    wire [7:0] rel_y = vga_y - sprite_y;   // max 240 px
    wire inside = (vga_x >= sprite_x_render && vga_x < sprite_x_render + 64 &&
                  vga_y >= sprite_y - 150   && vga_y < sprite_y + 90);

    // Mirror logic for character 2
    wire [5:0] mirrored_rel_x = 6'd63 - rel_x;  // Flip horizontally (0..63 range)
    wire [13:0] pixel_addr = (rel_y * 64) + mirrored_rel_x;  // total 15360 pixels

    // Hurtbox (damage area)
    wire [9:0] hb_l = sprite_x_render + 20,
               hb_r = sprite_x_render + 44,
               hb_t = sprite_y - 90,
               hb_b = sprite_y + 30;
    wire in_hurtbox = inside &&
                      (vga_x >= hb_l && vga_x < hb_r) &&
                      (vga_y >= hb_t && vga_y < hb_b);

    // Hitbox (attack area)
    wire [9:0] hx_l = sprite_x_render + 45,
               hx_r = sprite_x_render + 58,
               hx_t = sprite_y - 75,
               hx_b = sprite_y - 15;
    wire in_hitbox = ((state == STATE_ATTACK_BASIC_ACTIVE) || (state == STATE_ATTACK_DIR_ACTIVE)) &&
                     (vga_x >= hx_l && vga_x < hx_r) &&
                     (vga_y >= hx_t && vga_y < hx_b);

    wire in_hurtbox_out = ((state == STATE_ATTACK_BASIC_RECOVERY || state == STATE_ATTACK_DIR_RECOVERY) &&
                          (vga_x >= hx_l && vga_x < hx_r) &&
                          (vga_y >= hx_t && vga_y < hx_b));

    // Sprite memory
    reg [7:0] sprite_mem [0:15360-1];  // 64x240 pixels
    initial begin
        $readmemh("character2.mem", sprite_mem);
    end

    // Pixel color output
    assign pixel_color = in_hitbox      ? 8'b11100000 :  // Red for hitbox
                        in_hurtbox      ? 8'b11111100 :  // Yellow for hurtbox
                        in_hurtbox_out  ? 8'b11111100 :  // Yellow for recovery hurtbox
                        inside          ? sprite_mem[pixel_addr] :
                                        8'd0;

    assign pos_x = sprite_x_render;

endmodule
