`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: ResevoirNeuron
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Instantiates one cell with rule 90
// 
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
// 
//////////////////////////////////////////////////////////////////////////////////


module ResevoirNeuron(
    input logic clk,
    input logic enable,
    input logic up,
    input logic down,
    output logic C);

always_comb begin
    if (enable) begin
        // ECA Rule 90
        C <= up ^ down;
    end
end

endmodule
