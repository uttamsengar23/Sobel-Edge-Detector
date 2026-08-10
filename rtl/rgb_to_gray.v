//=====================================================================
// File        : rgb_to_gray.v
// Author      : Uttam Sengar
// Project     : Sobel Edge Detector Accelerator
//
// Description :
// Converts a 24-bit RGB pixel into an 8-bit grayscale pixel.
//
// Luminance Formula:
//
// Gray = 0.299R + 0.587G + 0.114B
//
// Integer Approximation:
//
// Gray = (77R + 150G + 29B) >> 8
//
//=====================================================================

module rgb_to_gray
(
    //--------------------------------------------------------------
    // Input RGB Pixel (24-bit)
    //--------------------------------------------------------------

    input  wire [23:0] rgb_pixel,

    //--------------------------------------------------------------
    // Output Gray Pixel (8-bit)
    //--------------------------------------------------------------

    output wire [7:0] gray_pixel
);

    //--------------------------------------------------------------
    // Separate RGB Components
    //--------------------------------------------------------------

    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;

    assign red   = rgb_pixel[23:16];
    assign green = rgb_pixel[15:8];
    assign blue  = rgb_pixel[7:0];

    //--------------------------------------------------------------
    // Fixed-Point Luminance Calculation
    //
    // gray_sum = (77×R) + (150×G) + (29×B)
    //
    // The coefficients are scaled by 256.
    // Therefore,
    //
    // gray_sum = Gray × 256
    //
    //--------------------------------------------------------------

    wire [15:0] gray_sum;

    assign gray_sum =
            (red   * 8'd77)  +
            (green * 8'd150) +
            (blue  * 8'd29);

    //--------------------------------------------------------------
    // Normalize Back to 8-bit Gray
    //
    // Divide by 256
    //
    // >>8  ==  /256
    //
    //--------------------------------------------------------------

    assign gray_pixel = gray_sum >> 8;

endmodule