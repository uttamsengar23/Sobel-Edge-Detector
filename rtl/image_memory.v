//=====================================================================
// File        : image_memory.v
// Author      : Uttam Sengar
// Project     : Sobel Edge Detector Accelerator
// Description : Loads a 24-bit RGB image from a HEX file into internal memory.  Provides one pixel for a given memory address.
//=====================================================================

module image_memory
#(
    parameter IMAGE_WIDTH  = 256,
    parameter IMAGE_HEIGHT = 256,
    parameter DATA_WIDTH   = 24
)
(
    input  wire [$clog2(IMAGE_WIDTH*IMAGE_HEIGHT)-1:0] address,

    output wire [DATA_WIDTH-1:0] pixel
);

    //--------------------------------------------------------------
    // Total Number of Pixels
    //--------------------------------------------------------------

    localparam TOTAL_PIXELS = IMAGE_WIDTH * IMAGE_HEIGHT;

    //--------------------------------------------------------------
    // Image Memory
    //--------------------------------------------------------------

    reg [DATA_WIDTH-1:0] image_mem [0:TOTAL_PIXELS-1];

    //--------------------------------------------------------------
    // Load HEX File
    //--------------------------------------------------------------

    initial
    begin
        $readmemh("images/image_rgb.hex", image_mem);

        $display("---------------------------------------");
        $display(" Image Loaded Successfully");
        $display(" Total Pixels : %d", TOTAL_PIXELS);
        $display("---------------------------------------");
    end

    //--------------------------------------------------------------
    // Read Pixel
    //--------------------------------------------------------------

    assign pixel = image_mem[address];

endmodule