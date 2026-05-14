`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: CellularAutomata
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Updates each cell combinationally using the ECA rule 90.
//              The output of the cellular automata is fed back into the cellular automata to keep generating compelex dynamics.
//
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////

module CellularAutomata #(
    parameter int M = 5,
    parameter int N = 9,
    parameter bit wrap_around = 1'b0           // 1'b1 = 1: edge cells take neighbours in the opposite end of the column,
  )(input logic clk,
    input logic rst,
    input logic enable,                        // Enables cellular automata iterations
    input logic bmnist,                        // Initial  to the cellular automata
    input logic [N-1:0] input_matrix [M-1:0],  // Input to the cellular automata, M rows with N bits. Loaded when load = 1'b1 and bmnist = 1'b1
    output logic [N-1:0] output_matrix [M-1:0] // Cellular Automata. M rows with N bits. Input to the maxpool layer.
   );

  // Columns and current_state contain the same information. 
  logic [M-1:0] columns [N-1:0];      // Current iteration of the cellular automata, but the registers contain the columns
  logic [N-1:0] current_state[M-1:0]; // Current iteration of the cellular automata, but the registers contain the rows
  logic [M-1:0] next_state[N-1:0];    // Next iteration of the cellular automata

  // Generating a MxN grid with optional wrap around logic for edge cells
  genvar j;
  generate
    for (j = 0; j < N; j++)
    begin : column_generator
      ResevoirColumns #(
                        .COLUMN_LENGTH(M),
                        .wrap_around(wrap_around)
                      ) ResevoirColumns_inst (
                        .clk(clk),
                        .enable(enable),
                        .current_state(columns[j]),
                        .next_state(next_state[j]) 
                      );
    end
  endgenerate


  // Transform input row vectors into column vectors in order to apply column wise ECA Rule 90
  genvar r1;
  genvar c1;
  generate
    for (c1 = 0; c1 < N; c1++)
    begin : cell_index
      // first select the column, then we iterate over the rows
      for (r1 = 0; r1 < M; r1++)
      begin : row_index
        assign columns[c1][r1] = current_state[r1][c1]; 
      end
    end
  endgenerate

  // Transform the output of ResevoirColumns module into row vectors.
  // This has no other function that to make the programming more intuitive in the maxpool module.
  genvar r2;
  genvar c2;
  generate
    for (r2 = 0; r2 < M; r2++)
    begin: row_index2
      for (c2 = 0; c2 < N; c2++)
      begin: cell_index2
        assign output_matrix[r2][c2] = next_state[c2][r2];
      end
    end
  endgenerate


  always_ff @(posedge clk)
  begin
    if (rst)
    begin
      current_state <= '{default:'0}; // Initalize the matrix with zeroes.
    end
    else if (enable)
    begin
      if (bmnist)
      begin
        current_state <= input_matrix;
      end
      else
      begin
        current_state <= output_matrix;
      end
    end
  end
endmodule
