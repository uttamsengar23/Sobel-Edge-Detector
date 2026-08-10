//=====================================================================
// File        : threshold.v
// Author      : Uttam Sengar
// Project     : Sobel Edge Detector Accelerator
//
// Description :
// Binarizes the Sobel gradient magnitude into a black/white edge
// pixel by comparing against a fixed threshold.
//
// edge_pixel = (gradient_mag > THRESHOLD) ? 8'hFF : 8'h00
//
// Pipeline latency: 1 clock cycle from gradient_valid to
// edge_valid.
//=====================================================================

module threshold
#(
    parameter DATA_WIDTH   = 8,
    parameter GRAD_WIDTH   = 11,
    parameter THRESHOLD    = 100   // tune this to control edge sensitivity
)
(
    input  wire                     clk,
    input  wire                     rst,

    //--------------------------------------------------------------
    // Gradient Magnitude Input (from sobel_core)
    //--------------------------------------------------------------

    input  wire [GRAD_WIDTH-1:0]    gradient_mag,
    input  wire                     gradient_valid,

    //--------------------------------------------------------------
    // Binarized Edge Pixel Output
    //--------------------------------------------------------------

    output reg  [DATA_WIDTH-1:0]    edge_pixel,
    output reg                      edge_valid
);

    //--------------------------------------------------------------
    // Main Sequential Block
    //--------------------------------------------------------------

    always @(posedge clk)
    begin
        if (rst)
        begin
            edge_pixel <= {DATA_WIDTH{1'b0}};
            edge_valid <= 1'b0;
        end
        else
        begin
            //--------------------------------------------------
            // Compare gradient magnitude against threshold
            //--------------------------------------------------

            edge_pixel <= (gradient_mag > THRESHOLD[GRAD_WIDTH-1:0])
                          ? {DATA_WIDTH{1'b1}}   // 8'hFF - edge
                          : {DATA_WIDTH{1'b0}};  // 8'h00 - no edge

            edge_valid <= gradient_valid;
        end
    end

endmodule