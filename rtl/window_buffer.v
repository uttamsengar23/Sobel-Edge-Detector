//=====================================================================
// File        : window_buffer.v
// Author      : Uttam Sengar
// Project     : Sobel Edge Detector Accelerator
//
// Description :
// Builds a 3x3 sliding window from a streaming pixel input.
// Uses two line buffers (each of size IMAGE_WIDTH) to hold the
// previous two rows, plus 3-tap shift registers per row to hold
// the last 3 columns.
//
// window_valid asserts once enough rows/columns have streamed in
// to form a complete 3x3 neighborhood (interior pixels only —
// the first 2 rows and first 2 columns of each row do not produce
// a valid window in this version; extend with zero-padding later
// if you want edge pixels included).
//=====================================================================

module window_buffer
#(
    parameter IMAGE_WIDTH  = 256,
    parameter IMAGE_HEIGHT = 256,
    parameter DATA_WIDTH   = 8
)
(
    input  wire                     clk,
    input  wire                     rst,

    input  wire [DATA_WIDTH-1:0]    pixel_in,
    input  wire                     pixel_valid,

    //--------------------------------------------------------------
    // 3x3 Window Output
    //
    //   p00 p01 p02
    //   p10 p11 p12
    //   p20 p21 p22
    //
    // p11 is the center pixel of the window.
    //--------------------------------------------------------------

    output reg [DATA_WIDTH-1:0]     p00, p01, p02,
    output reg [DATA_WIDTH-1:0]     p10, p11, p12,
    output reg [DATA_WIDTH-1:0]     p20, p21, p22,

    output reg                      window_valid
);

    //--------------------------------------------------------------
    // Line Buffers (store previous two rows)
    //--------------------------------------------------------------

    reg [DATA_WIDTH-1:0] line_buf0 [0:IMAGE_WIDTH-1];  // 1 row back
    reg [DATA_WIDTH-1:0] line_buf1 [0:IMAGE_WIDTH-1];  // 2 rows back

    //--------------------------------------------------------------
    // Column / Row Counters
    //--------------------------------------------------------------

    reg [$clog2(IMAGE_WIDTH)-1:0]  col_count;
    reg [$clog2(IMAGE_HEIGHT):0]   row_count;

    //--------------------------------------------------------------
    // Line Buffer Reads (current column, one/two rows back)
    //--------------------------------------------------------------

    wire [DATA_WIDTH-1:0] row1_pixel = line_buf0[col_count];
    wire [DATA_WIDTH-1:0] row2_pixel = line_buf1[col_count];

    //--------------------------------------------------------------
    // 3-Tap Shift Registers (last 3 columns of each row)
    //
    // Index [0] = newest column, Index [2] = oldest column
    //--------------------------------------------------------------

    reg [DATA_WIDTH-1:0] row0_sr [0:2];  // current row
    reg [DATA_WIDTH-1:0] row1_sr [0:2];  // 1 row back
    reg [DATA_WIDTH-1:0] row2_sr [0:2];  // 2 rows back

    integer i;

    //--------------------------------------------------------------
    // Main Sequential Block
    // (window output is driven from the SAME shift-in values used
    //  to update the shift registers, so p00-p22 land in sync with
    //  window_valid instead of lagging it by an extra cycle)
    //--------------------------------------------------------------

    always @(posedge clk)
    begin
        if (rst)
        begin
            col_count    <= 0;
            row_count    <= 0;
            window_valid <= 1'b0;

            p00 <= {DATA_WIDTH{1'b0}};  p01 <= {DATA_WIDTH{1'b0}};  p02 <= {DATA_WIDTH{1'b0}};
            p10 <= {DATA_WIDTH{1'b0}};  p11 <= {DATA_WIDTH{1'b0}};  p12 <= {DATA_WIDTH{1'b0}};
            p20 <= {DATA_WIDTH{1'b0}};  p21 <= {DATA_WIDTH{1'b0}};  p22 <= {DATA_WIDTH{1'b0}};

            for (i = 0; i < 3; i = i + 1)
            begin
                row0_sr[i] <= {DATA_WIDTH{1'b0}};
                row1_sr[i] <= {DATA_WIDTH{1'b0}};
                row2_sr[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (pixel_valid)
        begin
            //--------------------------------------------------
            // Shift each row's 3-tap register
            //--------------------------------------------------

            row0_sr[2] <= row0_sr[1];
            row0_sr[1] <= row0_sr[0];
            row0_sr[0] <= pixel_in;

            row1_sr[2] <= row1_sr[1];
            row1_sr[1] <= row1_sr[0];
            row1_sr[0] <= row1_pixel;

            row2_sr[2] <= row2_sr[1];
            row2_sr[1] <= row2_sr[0];
            row2_sr[0] <= row2_pixel;

            //--------------------------------------------------
            // Update Line Buffers
            //--------------------------------------------------

            line_buf1[col_count] <= row1_pixel;
            line_buf0[col_count] <= pixel_in;

            //--------------------------------------------------
            // Window Output — built from the same values driving
            // the shift above, so it is in sync with window_valid
            //
            //   p00 p01 p02      row2_sr[1] row2_sr[0] row2_pixel
            //   p10 p11 p12  =   row1_sr[1] row1_sr[0] row1_pixel
            //   p20 p21 p22      row0_sr[1] row0_sr[0] pixel_in
            //--------------------------------------------------

            p00 <= row2_sr[1];  p01 <= row2_sr[0];  p02 <= row2_pixel;
            p10 <= row1_sr[1];  p11 <= row1_sr[0];  p12 <= row1_pixel;
            p20 <= row0_sr[1];  p21 <= row0_sr[0];  p22 <= pixel_in;

            //--------------------------------------------------
            // Window Valid — asserted when at least 2 full rows
            // and at least 2 columns of the current row have
            // been streamed in (i.e. a complete 3x3 neighborhood
            // is available this cycle).
            //--------------------------------------------------

            window_valid <= (row_count >= 2) && (col_count >= 2);

            //--------------------------------------------------
            // Advance Column / Row Counters
            //--------------------------------------------------

            if (col_count == IMAGE_WIDTH - 1)
            begin
                col_count <= 0;
                row_count <= row_count + 1;
            end
            else
            begin
                col_count <= col_count + 1;
            end
        end
        else
        begin
            window_valid <= 1'b0;
        end
    end

endmodule