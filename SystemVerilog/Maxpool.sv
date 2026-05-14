//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: Maxpool
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Reduces input size from MxN to M/2xN/2
//
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////


module Maxpool # (
   parameter N = 5,
    parameter M = 5
  )(
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [N-1:0]input_matrix[M-1:0],      // Output of the CellularAutomata module
    output logic [N/2-1:0]output_matrix[M/2-1:0] // Input to the Flatten module
  );

  // Calculates the number of row pairs, and how many calculations within each row:
  //    M_new = (M - 2 (kernel height))/2(stride) +1 = M/2 with kernelwidth = 2 and stride = 2
  //    N_new = (N - 2 (kernel width))/2(stride) +1 = N/2 with kernelwidth = 2 and stride = 2
  localparam M_NEW = M/2; // New row width
  localparam N_NEW = N/2; // New column depth

  logic [N_NEW-1:0]maxpool_grid[M_NEW-1:0];

  assign output_matrix = maxpool_grid;

  // Reduces input dimensions.
  // For cell (0,0) in the maxpool_grid, we take the maximum value of (0,0), (0,1), (1,0) and (1,1) cells in the input.
  genvar row_num;
  genvar cell_num;
  generate
    for (row_num = 0; row_num < M_NEW; row_num++)
    begin: rows
      for (cell_num = 0; cell_num < N_NEW; cell_num++)
      begin: cells
        MaxpoolCell MaxpoolCell_inst (
                       .clk(clk),
                       .rst(rst),
                       .enable(enable),
                       .kernel({input_matrix[2*row_num + 1][2*cell_num +:2], input_matrix[2*row_num][2*cell_num +:2]}), // Iterating over cell pairs in neighbouring rows (eg cell i and cell i+1 in row0 and row1)
                       .maxpool_cell(maxpool_grid[row_num][cell_num])
                     );
      end
    end
  endgenerate

endmodule
