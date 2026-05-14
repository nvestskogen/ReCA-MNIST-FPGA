`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
// 
// Module Name: Flatten
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Flattens the output from the Maxpool module, one clock at the time, and stores the output in a shift register.
//
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
// 
//////////////////////////////////////////////////////////////////////////////////


module Flatten #(
    parameter int N = 28,
    parameter int M = 28,
    parameter int ITER = 8
    )(
    input logic clk,
    input logic rst,
    input logic enable_flatten,                       // Enables flattening once the first maxpool output is ready
    input logic [N/2-1:0]maxpool_output[M/2-1:0],     // Output from Maxpool module
    output logic  [(((N/2)*(M/2))*ITER)-1:0]flattened // Input to the perceptron layer, once all iterations has been shifted in
    );
  
  localparam int ROWS = M/2;               // Number of rows in the maxpool output
  localparam int COLS = N/2;               // Number of columns in the maxpool output
  localparam int SHIFT_LEN = ROWS*COLS;    // Number of bits shifted in each clock cycle
  localparam int OUT_LEN = SHIFT_LEN*ITER; // Total number of bits that will neeed to be shifted in after all iterations

  logic [SHIFT_LEN-1:0] maxpool_flat;     // Registers that stores the flattened maxpool output
  logic [OUT_LEN-1:0] shift_reg;          // Registers that stores all the flattened maxpool outputs after all iterations has been shifted in

  assign flattened = shift_reg; 

  // Flattening the maxpool output
  int r;
  int c;
  always_comb begin
    for (r = 0; r < ROWS; r++) begin
      for (c = 0; c < COLS; c++) begin
        maxpool_flat[r*COLS + c] = maxpool_output[r][c];
      end
    end
  end

  // Shifting inn the flattened output
  always_ff @(posedge clk) begin
    if (rst) begin
      shift_reg <= '0;
    end else if (enable_flatten) begin
      shift_reg <= {maxpool_flat, shift_reg[OUT_LEN-1:SHIFT_LEN]};
    end
  end

endmodule