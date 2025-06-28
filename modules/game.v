module game (
    input  wire        clk,
    input  wire        rst,
    input  wire        key,
    input  wire        sw_in,
    input  wire        fwd1,
    input  wire        bwd1,
    input  wire        attack1,
    input  wire        fwd2,
    input  wire        bwd2,
    input  wire        attack2,
    input  wire [9:0]  vga_x,
    input  wire [9:0]  vga_y,
    input  wire [9:0]  sprite_y,
    output wire [3:0]  state1,
    output wire [3:0]  state2,
    output wire        attacking1,
    output wire        attacking2,
    output wire [7:0]  pixel_color,
    output wire        hit1,
    output wire        hit2,
    output wire [1:0]  health1,
    output wire [1:0]  health2,
    output wire        game_over,
    output wire [7:0]  time_display,
    output wire [7:0]  health_display,
    output wire [1:0]  block1,
    output wire [1:0]  block2
);

    // Registers
    reg [1:0] health1_reg = 2'b11, health2_reg = 2'b11;
    reg [1:0] block1_reg = 2'b11, block2_reg = 2'b11;
    reg hitstun1 = 0, hitstun2 = 0, blockstun1 = 0, blockstun2 = 0;
    reg [4:0] stun_counter1 = 0, stun_counter2 = 0;
    reg [7:0] time_counter = 8'd99;
    reg [31:0] frame_counter = 0;
    reg prev_key;

    localparam HITSTUN_FRAMES = 10, BLOCKSTUN_FRAMES = 5, FRAMES_PER_SECOND = 60;
    localparam TIME_X_START = 280, TIME_X_END = 360, TIME_Y_START = 20, TIME_Y_END = 40;
    localparam HEALTH1_X_START = 20, HEALTH1_X_END = 60, HEALTH2_X_START = 580, HEALTH2_X_END = 620;
    localparam HEALTH_Y_START = 20, HEALTH_Y_END = 40;

    wire manual_clk_pulse = (prev_key && !key);
    wire game_tick = (!sw_in) ? clk : manual_clk_pulse;

    wire [7:0] pixel_color1, pixel_color2;
    wire [9:0] pos_x1, pos_x2;

    always @(posedge clk or posedge rst)
        if (rst) prev_key <= 1;
        else     prev_key <= key;

    character1 #(.INIT_X(10'd20)) player1 (
        .clk(game_tick), .rst(rst),
        .fwd(~fwd1), .bwd(~bwd1), .attack(~attack1),
        .vga_x(vga_x), .vga_y(vga_y), .sprite_y(sprite_y),
        .state(state1), .attacking(attacking1), .pixel_color(pixel_color1), .pos_x(pos_x1)
    );

    character2 #(.INIT_X(10'd550)) player2 (
        .clk(game_tick), .rst(rst),
        .fwd(bwd2), .bwd(fwd2), .attack(attack2),
        .vga_x(vga_x), .vga_y(vga_y), .sprite_y(sprite_y),
        .state(state2), .attacking(attacking2), .pixel_color(pixel_color2), .pos_x(pos_x2)
    );

    wire [9:0] p1_hitbox_left = pos_x1 + 90, p1_hitbox_right = pos_x1 + 115;
    wire [9:0] p1_hitbox_top = sprite_y - 75, p1_hitbox_bottom = sprite_y - 15;
    wire [9:0] p1_hurtbox_left = pos_x1 + 40, p1_hurtbox_right = pos_x1 + 80;
    wire [9:0] p1_hurtbox_top = sprite_y - 90, p1_hurtbox_bottom = sprite_y + 30;

    wire [9:0] p2_hitbox_left = pos_x2 - 115, p2_hitbox_right = pos_x2 - 90;
    wire [9:0] p2_hitbox_top = sprite_y - 75, p2_hitbox_bottom = sprite_y - 15;
    wire [9:0] p2_hurtbox_left = pos_x2 - 80, p2_hurtbox_right = pos_x2 - 40;
    wire [9:0] p2_hurtbox_top = sprite_y - 90, p2_hurtbox_bottom = sprite_y + 30;

    wire p1_blocking = bwd1 && (block1_reg > 0);
    wire p2_blocking = bwd2 && (block2_reg > 0);

    wire p1_hitbox_overlaps_p2 = attacking1 &&
        (p1_hitbox_right >= p2_hurtbox_left && p1_hitbox_left <= p2_hurtbox_right &&
         p1_hitbox_bottom >= p2_hurtbox_top && p1_hitbox_top <= p2_hurtbox_bottom);

    wire p2_hitbox_overlaps_p1 = attacking2 &&
        (p2_hitbox_right >= p1_hurtbox_left && p2_hitbox_left <= p1_hurtbox_right &&
         p2_hitbox_bottom >= p1_hurtbox_top && p2_hitbox_top <= p1_hurtbox_bottom);

    always @(posedge game_tick or posedge rst) begin
        if (rst) begin
            time_counter <= 99;
            frame_counter <= 0;
        end else if (!game_over) begin
            if (frame_counter >= FRAMES_PER_SECOND - 1) begin
                frame_counter <= 0;
                if (time_counter > 0) time_counter <= time_counter - 1;
            end else frame_counter <= frame_counter + 1;
        end
    end

    always @(posedge game_tick or posedge rst) begin
        if (rst) begin
            health1_reg <= 3;
            health2_reg <= 3;
            block1_reg <= 3;
            block2_reg <= 3;
            hitstun1 <= 0; hitstun2 <= 0;
            blockstun1 <= 0; blockstun2 <= 0;
            stun_counter1 <= 0; stun_counter2 <= 0;
        end else if (!game_over) begin
            if (stun_counter1 > 0) begin
                stun_counter1 <= stun_counter1 - 1;
                if (stun_counter1 == 1) begin hitstun1 <= 0; blockstun1 <= 0; end
            end
            if (stun_counter2 > 0) begin
                stun_counter2 <= stun_counter2 - 1;
                if (stun_counter2 == 1) begin hitstun2 <= 0; blockstun2 <= 0; end
            end
            if (p1_hitbox_overlaps_p2 && !hitstun2 && !blockstun2) begin
                if (p2_blocking) begin
                    if (block2_reg > 0) block2_reg <= block2_reg - 1;
                    blockstun2 <= 1; stun_counter2 <= BLOCKSTUN_FRAMES;
                end else begin
                    if (health2_reg > 0) health2_reg <= health2_reg - 1;
                    hitstun2 <= 1; stun_counter2 <= HITSTUN_FRAMES;
                end
            end
            if (p2_hitbox_overlaps_p1 && !hitstun1 && !blockstun1) begin
                if (p1_blocking) begin
                    if (block1_reg > 0) block1_reg <= block1_reg - 1;
                    blockstun1 <= 1; stun_counter1 <= BLOCKSTUN_FRAMES;
                end else begin
                    if (health1_reg > 0) health1_reg <= health1_reg - 1;
                    hitstun1 <= 1; stun_counter1 <= HITSTUN_FRAMES;
                end
            end
        end
    end

    assign in_time_display = (vga_x >= TIME_X_START && vga_x < TIME_X_END && vga_y >= TIME_Y_START && vga_y < TIME_Y_END);
    assign in_health1_bar = (vga_x >= 20 && vga_x < 20 + health1_reg * 13 && vga_y >= 20 && vga_y < 40);
    assign in_health2_bar = (vga_x >= 620 - health2_reg * 13 && vga_x < 620 && vga_y >= 20 && vga_y < 40);

    assign time_display = in_time_display ? 8'b00011100 : 0;
    assign health_display = (in_health1_bar || in_health2_bar) ? 8'b11111100 : 0;
    assign pixel_color = (pixel_color1 != 0) ? pixel_color1 : pixel_color2;

    assign hit1 = p2_hitbox_overlaps_p1 && !p1_blocking;
    assign hit2 = p1_hitbox_overlaps_p2 && !p2_blocking;
    assign health1 = health1_reg;
    assign health2 = health2_reg;
    assign block1 = block1_reg;
    assign block2 = block2_reg;
    assign game_over = (health1_reg == 0 || health2_reg == 0 || time_counter == 0);

endmodule
