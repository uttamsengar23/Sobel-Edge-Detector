//=====================================================================
// File        : sobel_core.v
// Author      : Uttam Sengar
// Project     : Sobel Edge Detector Accelerator
//
// Description :
// Computes the Sobel gradient magnitude from a 3x3 pixel window.
//
// Sobel Kernels:
//
//   Gx = [-1  0  +1]        Gy = [-1 -2 -1]
//        [-2  0  +2]             [ 0  0  0]
//        [-1  0  +1]             [+1 +2 +1]
//
// Gx = (p02 + 2*p12 + p22) - (p00 + 2*p10 + p20)
// Gy = (p20 + 2*p21 + p22) - (p00 + 2*p01 + p02)
//
// Gradient Magnitude (Manhattan approximation, hardware-cheap):
//
// G = |Gx| + |Gy|
//
// Pipeline latency: 2 clock cycles from window_valid to
// gradient_valid (Gx/Gy computed cycle 1, abs+sum computed
// cycle 2). gradient_valid is pipelined through the same two
// stages so it lines up exactly with gradient_mag.
//=====================================================================

module sobel_core
#(
    parameter DATA_WIDTH = 8
)
(
    input  wire                     clk,
    input  wire                     rst,

    //--------------------------------------------------------------
    // 3x3 Window Input (from window_buffer)
    //--------------------------------------------------------------

    input  wire [DATA_WIDTH-1:0]    p00, p01, p02,
    input  wire [DATA_WIDTH-1:0]    p10, p11, p12,
    input  wire [DATA_WIDTH-1:0]    p20, p21, p22,
    input  wire                     window_valid,

    //--------------------------------------------------------------
    // Gradient Magnitude Output
    //
    // Max |Gx| or |Gy| = 4 * 255 = 1020 -> fits in 12-bit signed.
    // Max G = |Gx| + |Gy| = 2040 -> needs 11 bits unsigned.
    //--------------------------------------------------------------

    output reg  [10:0]              gradient_mag,
    output reg                      gradient_valid
);

    //--------------------------------------------------------------
    // Stage 1: Gx, Gy (signed, zero-extended pixels)
    //--------------------------------------------------------------

    reg signed [11:0] gx;
    reg signed [11:0] gy;
    reg                stage1_valid;

    //--------------------------------------------------------------
    // Stage 2: |Gx| + |Gy|
    //
    // gx_abs_w / gy_abs_w are plain wires so they can be
    // part-selected ([10:0]) below -- Icarus (and some other
    // simulators) don't allow slicing an inline ternary
    // expression directly, only a named signal.
    //--------------------------------------------------------------

    wire signed [11:0] gx_abs_w = gx[11] ? (-gx) : gx;
    wire signed [11:0] gy_abs_w = gy[11] ? (-gy) : gy;

    //--------------------------------------------------------------
    // Main Pipeline
    //--------------------------------------------------------------

    always @(posedge clk)
    begin
        if (rst)
        begin
            gx             <= 12'sd0;
            gy             <= 12'sd0;
            stage1_valid   <= 1'b0;

            gradient_mag   <= 11'd0;
            gradient_valid <= 1'b0;
        end
        else
        begin
            //--------------------------------------------------
            // Stage 1: compute Gx and Gy from current window
            //--------------------------------------------------

            gx <= ($signed({4'd0, p02}) + ($signed({4'd0, p12}) <<< 1) + $signed({4'd0, p22}))
                - ($signed({4'd0, p00}) + ($signed({4'd0, p10}) <<< 1) + $signed({4'd0, p20}));

            gy <= ($signed({4'd0, p20}) + ($signed({4'd0, p21}) <<< 1) + $signed({4'd0, p22}))
                - ($signed({4'd0, p00}) + ($signed({4'd0, p01}) <<< 1) + $signed({4'd0, p02}));

            stage1_valid <= window_valid;

            //--------------------------------------------------
            // Stage 2: absolute value + sum, from Stage 1 results
            // (gx_abs_w/gy_abs_w above are combinational off the
            //  gx/gy registers, so this is still exactly 2 cycles
            //  total from window_valid to gradient_valid)
            //--------------------------------------------------

            gradient_mag   <= gx_abs_w[10:0] + gy_abs_w[10:0];
            gradient_valid <= stage1_valid;
        end
    end

endmodule