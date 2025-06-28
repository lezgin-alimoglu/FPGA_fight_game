module background_renderer (
    input [9:0] vga_x,
    input [9:0] vga_y,
    output reg [7:0] bg_pixel
);

    // Image size (resized .png)
    localparam WIDTH = 240;
    localparam HEIGHT = 180;

    // Screen size (VGA)
    localparam SCREEN_WIDTH = 640;
    localparam SCREEN_HEIGHT = 480;

    reg [7:0] bg_mem [0:WIDTH*HEIGHT-1];

    initial begin
        $readmemh("background.mem", bg_mem);
    end

    // Calculate scaled coordinates
    wire [8:0] img_x; // enough for 80
    wire [8:0] img_y; // enough for 60

    assign img_x = (vga_x * WIDTH) / SCREEN_WIDTH;
    assign img_y = (vga_y * HEIGHT) / SCREEN_HEIGHT;

    always @(*) begin
        bg_pixel = bg_mem[img_y * WIDTH + img_x];
    end
endmodule
