//=====================================================================
// File        : tb_sobel_edge_detector.v
// Author      : Uttam Sengar
// Project     : Sobel Edge Detector Accelerator
//
// Description :
// Testbench for the top-level sobel_edge_detector.
//
// What it does:
//   1. Generates clk/rst, pulses start once.
//   2. Captures every edge_pixel into a full-size output image
//      buffer, placed correctly using out_row/out_col (so the
//      1-pixel border that never gets written stays 0 = black,
//      which is the expected/documented behavior).
//   3. Waits for frame_done with a watchdog timeout, so a broken
//      DUT hangs the sim with a clear error instead of forever.
//   4. Self-checks: counts how many edge_valid pulses fired and
//      compares against the expected interior-pixel count, and
//      tracks the observed row/col range to confirm it matches
//      the documented crop [1, H-2] x [1, W-2].
//   5. Writes the captured image out to results/edge_output.hex
//      so hex_to_image.py can turn it into a viewable PNG.
//
// NOTE on timing: frame_done and the very last edge_valid pulse
// become true on the EXACT SAME clock edge (by design -- see
// sobel_edge_detector.v). Waiting only one extra @(posedge clk)
// after frame_done lands on that same edge as the capture block
// below, which is a same-edge race whose outcome is simulator-
// defined, not guaranteed by the Verilog standard. We wait a FULL
// extra cycle (two @(posedge clk)) to guarantee the capture block
// has completely finished before reading pulse_count.
//=====================================================================

`timescale 1ns/1ps
module tb_sobel_edge_detector;
    //--------------------------------------------------------------
    // Parameters (must match sobel_edge_detector.v defaults, or
    // override both here and in the DUT instantiation together)
    //--------------------------------------------------------------

    localparam IMAGE_WIDTH  = 256;
    localparam IMAGE_HEIGHT = 256;
    localparam RGB_WIDTH    = 24;
    localparam GRAY_WIDTH   = 8;
    localparam GRAD_WIDTH   = 11;
    localparam THRESHOLD    = 100;

    localparam TOTAL_PIXELS = IMAGE_WIDTH * IMAGE_HEIGHT;
    localparam ROW_WIDTH    = $clog2(IMAGE_HEIGHT);
    localparam COL_WIDTH    = $clog2(IMAGE_WIDTH);

    // expected number of edge_valid pulses for one full frame
    // (interior pixels only -- 1-pixel border is never produced)
    localparam EXPECTED_PULSES = (IMAGE_WIDTH - 2) * (IMAGE_HEIGHT - 2);

    // generous safety margin: full frame + pipeline drain + slack
    localparam WATCHDOG_LIMIT = TOTAL_PIXELS + 200;

    //--------------------------------------------------------------
    // DUT connections
    //--------------------------------------------------------------

    reg  clk;
    reg  rst;
    reg  start;

    wire [GRAY_WIDTH-1:0] edge_pixel;
    wire                  edge_valid;
    wire [ROW_WIDTH-1:0]  out_row;
    wire [COL_WIDTH-1:0]  out_col;
    wire                  streaming;
    wire                  frame_done;

    sobel_edge_detector #(
        .IMAGE_WIDTH  (IMAGE_WIDTH),
        .IMAGE_HEIGHT (IMAGE_HEIGHT),
        .RGB_WIDTH    (RGB_WIDTH),
        .GRAY_WIDTH   (GRAY_WIDTH),
        .GRAD_WIDTH   (GRAD_WIDTH),
        .THRESHOLD    (THRESHOLD)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .edge_pixel (edge_pixel),
        .edge_valid (edge_valid),
        .out_row    (out_row),
        .out_col    (out_col),
        .streaming  (streaming),
        .frame_done (frame_done)
    );

    //--------------------------------------------------------------
    // Clock generation: 100 MHz (10 ns period)
    //--------------------------------------------------------------

    initial clk = 1'b0;
    always #5 clk = ~clk;

    //--------------------------------------------------------------
    // Output image buffer
    //
    // Initialized to 0 so the 1-pixel border that never receives
    // a real edge_valid write correctly stays black in the final
    // image, instead of holding X or leftover garbage.
    //--------------------------------------------------------------

    reg [GRAY_WIDTH-1:0] output_image [0:TOTAL_PIXELS-1];
    integer init_i;

    //--------------------------------------------------------------
    // Self-check bookkeeping
    //--------------------------------------------------------------

    integer pulse_count;
    reg [ROW_WIDTH-1:0] min_row_seen, max_row_seen;
    reg [COL_WIDTH-1:0] min_col_seen, max_col_seen;

    integer watchdog_count;

    //--------------------------------------------------------------
    // Capture every edge_valid pulse into the output buffer,
    // placed at its real (row, col) location.
    //--------------------------------------------------------------

    always @(posedge clk)
    begin
        if (edge_valid)
        begin
            if (pulse_count < 5 || pulse_count >= EXPECTED_PULSES - 5)
                $display("EDGE: count=%0d row=%0d col=%0d", pulse_count + 1, out_row, out_col);

            output_image[out_row * IMAGE_WIDTH + out_col] <= edge_pixel;
            pulse_count <= pulse_count + 1;   // nonblocking -- consistent with everything else in this block

            if (out_row < min_row_seen) min_row_seen <= out_row;
            if (out_row > max_row_seen) max_row_seen <= out_row;
            if (out_col < min_col_seen) min_col_seen <= out_col;
            if (out_col > max_col_seen) max_col_seen <= out_col;
        end
    end

    //--------------------------------------------------------------
    // Watchdog: if frame_done never arrives, fail loudly instead
    // of hanging the simulation forever.
    //--------------------------------------------------------------

    always @(posedge clk)
    begin
        if (start || streaming)
            watchdog_count <= watchdog_count + 1;

        if (watchdog_count > WATCHDOG_LIMIT)
        begin
            $display("*** FATAL: watchdog timeout -- frame_done never asserted after %0d cycles ***", WATCHDOG_LIMIT);
            $display("*** Check: is pixel_valid/streaming actually toggling? Is the DUT stuck in reset? ***");
            $finish;
        end
    end

    //--------------------------------------------------------------
    // Main stimulus / sequencing
    //--------------------------------------------------------------

    initial
    begin
        // ---- init ----
        rst            = 1'b1;
        start          = 1'b0;
        pulse_count    = 0;
        watchdog_count = 0;
        min_row_seen   = {ROW_WIDTH{1'b1}};   // start at max value
        max_row_seen   = {ROW_WIDTH{1'b0}};
        min_col_seen   = {COL_WIDTH{1'b1}};
        max_col_seen   = {COL_WIDTH{1'b0}};

        for (init_i = 0; init_i < TOTAL_PIXELS; init_i = init_i + 1)
            output_image[init_i] = {GRAY_WIDTH{1'b0}};

        // ---- reset pulse ----
        repeat (5) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        // ---- start the frame ----
        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        $display("---------------------------------------------------");
        $display(" Simulation started -- streaming %0d x %0d image", IMAGE_WIDTH, IMAGE_HEIGHT);
        $display("---------------------------------------------------");

        // ---- wait for the pipeline to fully drain ----
        @(posedge frame_done);

        // frame_done and the LAST edge_valid pulse become true on
        // the exact same clock edge -- see note at top of file.
        // Wait a FULL extra cycle (not just one) before reading
        // pulse_count, to guarantee the capture block above has
        // completely finished.
        @(posedge clk);
        @(posedge clk);

        // ---- results ----
        $display("===================================================");
        $display("FRAME DONE - Pulse count = %0d / %0d, Row = [%0d,%0d] expected [1,%0d], Col = [%0d,%0d] expected [1,%0d]",
            pulse_count,
            EXPECTED_PULSES,
            min_row_seen,
            max_row_seen,
            IMAGE_HEIGHT-2,
            min_col_seen,
            max_col_seen,
            IMAGE_WIDTH-2);

        if (pulse_count === EXPECTED_PULSES)
            $display("PASS: pulse count");
        else
            $display("FAIL: pulse count");

        if (min_row_seen === 1 && max_row_seen === IMAGE_HEIGHT-2 && min_col_seen === 1 && max_col_seen === IMAGE_WIDTH-2)
            $display("PASS: coordinate range");
        else
            $display("FAIL: coordinate range");

        $display("===================================================");

        // ---- write result image ----
        $writememh("results/edge_output.hex", output_image);
        $display("Wrote results/edge_output.hex");
        $finish;
    end

    //--------------------------------------------------------------
    // Optional waveform dump -- uncomment if you want to inspect
    // signals in a viewer (gtkwave etc).
    //--------------------------------------------------------------
    initial begin
        $dumpfile("sobel_edge_detector.vcd");
        $dumpvars(0, tb_sobel_edge_detector);
    end
endmodule