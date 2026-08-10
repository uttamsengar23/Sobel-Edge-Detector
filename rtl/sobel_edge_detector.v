//=====================================================================
// File        : sobel_edge_detector.v
// Author      : Uttam Sengar
// Project     : Sobel Edge Detector Accelerator
//
// Description :
// Top-level module. On a `start` pulse, streams every pixel of the
// image out of image_memory in raster order, converts to grayscale,
// and feeds it through window_buffer -> sobel_core -> threshold.
//
// Reports the (row, col) coordinate of every valid edge_pixel via
// out_row/out_col, so the testbench never has to guess where each
// output pixel belongs -- it just reads out_row/out_col whenever
// edge_valid is high.
//
// Pipeline latency (a pixel entering window_buffer -> edge_valid
// asserted for the window centered on it):
//   window_buffer : 1 cycle
//   sobel_core    : 2 cycles
//   threshold     : 1 cycle
//   TOTAL         : 4 cycles  (see PIPE_DEPTH below)
//
// Output coverage:
// window_buffer needs a full 3x3 neighborhood centered on each
// pixel, and streaming ends the instant the last pixel is read, so
// edge_valid only pulses for interior pixels:
//   out_row in [1, IMAGE_HEIGHT-2]
//   out_col in [1, IMAGE_WIDTH-2]
// The outermost 1-pixel border of the image is never produced.
// This is expected -- size your output buffer/image accordingly,
// or zero-pad the border when writing results.
//=====================================================================

module sobel_edge_detector
#(
    parameter IMAGE_WIDTH  = 256,
    parameter IMAGE_HEIGHT = 256,
    parameter RGB_WIDTH    = 24,
    parameter GRAY_WIDTH   = 8,
    parameter GRAD_WIDTH   = 11,
    parameter THRESHOLD    = 100
)
(
    input  wire clk,
    input  wire rst,
    input  wire start,                       // pulse 1 cycle to begin streaming a frame

    output wire [GRAY_WIDTH-1:0]            edge_pixel,
    output wire                             edge_valid,
    output wire [$clog2(IMAGE_HEIGHT)-1:0]  out_row,   // valid only when edge_valid is high
    output wire [$clog2(IMAGE_WIDTH)-1:0]   out_col,   // valid only when edge_valid is high

    output wire streaming,                   // high while image_memory is being read
    output wire frame_done                   // pulses 1 cycle once the pipeline has fully drained
);

    localparam TOTAL_PIXELS = IMAGE_WIDTH * IMAGE_HEIGHT;
    localparam ADDR_WIDTH   = $clog2(TOTAL_PIXELS);
    localparam COL_WIDTH    = $clog2(IMAGE_WIDTH);
    localparam ROW_WIDTH    = $clog2(IMAGE_HEIGHT);
    localparam PIPE_DEPTH   = 4;   // window_buffer(1) + sobel_core(2) + threshold(1)

    //--------------------------------------------------------------
    // Address / row / col generation for image_memory
    //--------------------------------------------------------------

    reg [ADDR_WIDTH-1:0] addr;
    reg [COL_WIDTH-1:0]  in_col;
    reg [ROW_WIDTH-1:0]  in_row;
    reg                  in_streaming;

    wire last_pixel_this_cycle = in_streaming &&
                                  (in_row == IMAGE_HEIGHT-1) &&
                                  (in_col == IMAGE_WIDTH-1);

    always @(posedge clk)
    begin
        if (rst)
        begin
            addr         <= {ADDR_WIDTH{1'b0}};
            in_col       <= {COL_WIDTH{1'b0}};
            in_row       <= {ROW_WIDTH{1'b0}};
            in_streaming <= 1'b0;
        end
        else if (start && !in_streaming)
        begin
            addr         <= {ADDR_WIDTH{1'b0}};
            in_col       <= {COL_WIDTH{1'b0}};
            in_row       <= {ROW_WIDTH{1'b0}};
            in_streaming <= 1'b1;
        end
        else if (in_streaming)
        begin
            if (last_pixel_this_cycle)
            begin
                in_streaming <= 1'b0;        // this cycle's pixel is the last one
            end
            else
            begin
                addr <= addr + 1'b1;

                if (in_col == IMAGE_WIDTH - 1)
                begin
                    in_col <= 0;
                    in_row <= in_row + 1'b1;
                end
                else
                begin
                    in_col <= in_col + 1'b1;
                end
            end
        end
    end

    assign streaming = in_streaming;

    //--------------------------------------------------------------
    // image_memory -> rgb_to_gray (both combinational, 0-cycle)
    //--------------------------------------------------------------

    wire [RGB_WIDTH-1:0]  rgb_pixel;
    wire [GRAY_WIDTH-1:0] gray_pixel;

    image_memory #(
        .IMAGE_WIDTH  (IMAGE_WIDTH),
        .IMAGE_HEIGHT (IMAGE_HEIGHT),
        .DATA_WIDTH   (RGB_WIDTH)
    ) u_image_memory (
        .address (addr),
        .pixel   (rgb_pixel)
    );

    rgb_to_gray u_rgb_to_gray (
        .rgb_pixel  (rgb_pixel),
        .gray_pixel (gray_pixel)
    );

    //--------------------------------------------------------------
    // window_buffer (1 cycle latency)
    //--------------------------------------------------------------

    wire [GRAY_WIDTH-1:0] p00, p01, p02;
    wire [GRAY_WIDTH-1:0] p10, p11, p12;
    wire [GRAY_WIDTH-1:0] p20, p21, p22;
    wire window_valid;

    window_buffer #(
        .IMAGE_WIDTH  (IMAGE_WIDTH),
        .IMAGE_HEIGHT (IMAGE_HEIGHT),
        .DATA_WIDTH   (GRAY_WIDTH)
    ) u_window_buffer (
        .clk         (clk),
        .rst         (rst),
        .pixel_in    (gray_pixel),
        .pixel_valid (in_streaming),
        .p00 (p00), .p01 (p01), .p02 (p02),
        .p10 (p10), .p11 (p11), .p12 (p12),
        .p20 (p20), .p21 (p21), .p22 (p22),
        .window_valid (window_valid)
    );

    //--------------------------------------------------------------
    // sobel_core (2 cycle latency)
    //--------------------------------------------------------------

    wire [GRAD_WIDTH-1:0] gradient_mag;
    wire                  gradient_valid;

    sobel_core #(
        .DATA_WIDTH (GRAY_WIDTH)
    ) u_sobel_core (
        .clk (clk),
        .rst (rst),
        .p00 (p00), .p01 (p01), .p02 (p02),
        .p10 (p10), .p11 (p11), .p12 (p12),
        .p20 (p20), .p21 (p21), .p22 (p22),
        .window_valid   (window_valid),
        .gradient_mag   (gradient_mag),
        .gradient_valid (gradient_valid)
    );

    //--------------------------------------------------------------
    // threshold (1 cycle latency)
    //--------------------------------------------------------------

    threshold #(
        .DATA_WIDTH (GRAY_WIDTH),
        .GRAD_WIDTH (GRAD_WIDTH),
        .THRESHOLD  (THRESHOLD)
    ) u_threshold (
        .clk (clk),
        .rst (rst),
        .gradient_mag   (gradient_mag),
        .gradient_valid (gradient_valid),
        .edge_pixel     (edge_pixel),
        .edge_valid     (edge_valid)
    );

    //--------------------------------------------------------------
    // Coordinate tracking
    
    // window_buffer's center pixel p11 always corresponds to
    // (row-1, col-1) relative to whichever pixel is currently
    // being fed in as pixel_in (that pixel becomes the window's
    // p22 corner one cycle later). So we push (in_row-1, in_col-1)
    // into a PIPE_DEPTH-deep shift register -- NOT the raw
    // in_row/in_col -- so out_row/out_col line up with the actual
    // center pixel each edge_valid pulse refers to, not the corner.
    //--------------------------------------------------------------

    reg [ROW_WIDTH-1:0] row_pipe [0:PIPE_DEPTH-1];
    reg [COL_WIDTH-1:0] col_pipe [0:PIPE_DEPTH-1];
    integer k;

    always @(posedge clk)
    begin
        if (rst)
        begin
            for (k = 0; k < PIPE_DEPTH; k = k + 1)
            begin
                row_pipe[k] <= {ROW_WIDTH{1'b0}};
                col_pipe[k] <= {COL_WIDTH{1'b0}};
            end
        end
        else
        begin
            row_pipe[0] <= in_row - 1'b1;   // -1: corner -> center row
            col_pipe[0] <= in_col - 1'b1;   // -1: corner -> center col

            for (k = 1; k < PIPE_DEPTH; k = k + 1)
            begin
                row_pipe[k] <= row_pipe[k-1];
                col_pipe[k] <= col_pipe[k-1];
            end
        end
    end

    assign out_row = row_pipe[PIPE_DEPTH-1];
    assign out_col = col_pipe[PIPE_DEPTH-1];

    //--------------------------------------------------------------
    // frame_done -- pulses once the last input pixel has fully
    // drained through the pipeline (PIPE_DEPTH cycles after it
    // entered window_buffer).
    //--------------------------------------------------------------

    reg [PIPE_DEPTH-1:0] last_pixel_sr;
    always @(posedge clk)
    begin
        if (rst)
            last_pixel_sr <= {PIPE_DEPTH{1'b0}};
        else
            last_pixel_sr <= {last_pixel_sr[PIPE_DEPTH-2:0], last_pixel_this_cycle};
    end

    assign frame_done = last_pixel_sr[PIPE_DEPTH-1];

endmodule