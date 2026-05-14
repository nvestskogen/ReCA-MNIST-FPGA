`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: module ResevoirColumns 
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Updates the state of a column of neurons. Each neuron takes the previous state of it's vertical neighbours as input (up and down neighbour).
// 
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////


module ResevoirColumns #(
    parameter int COLUMN_LENGTH = 10, 
    parameter bit wrap_around = 1'b0 
  )(input logic clk,
    input logic enable,
    input logic [COLUMN_LENGTH-1:0] current_state, 
    output logic [COLUMN_LENGTH-1:0] next_state 
   );

genvar i;
generate
  for (i = 0; i < COLUMN_LENGTH; i++) begin : generating_neurons

    logic up;
    logic down;

    // wrap_around = 1'b1: edge cells take neighbours in the opposite end of the row.
    // wrap_around = 1'b0: edge cells treat the non-existing neighbour as 1'b0.
    if (wrap_around)
    begin: wrap
      assign up = current_state[(i == 0) ? COLUMN_LENGTH-1 : i-1];
      assign down = current_state[(i == COLUMN_LENGTH-1) ? 0 : i+1];
    end
    else
    begin: no_wrap
      assign up = (i == 0) ? 1'b0 : current_state[i-1];
      assign down = (i == COLUMN_LENGTH-1) ? 1'b0 : current_state[i+1];
    end

    ResevoirNeuron ResevoirNeuron_i(
              .clk(clk),
              .enable(enable),          
              .up(up),
              .down(down),
              .C(next_state[i])
            );
  end
endgenerate

endmodule
