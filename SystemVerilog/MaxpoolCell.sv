//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: MaxpoolCell
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Takes the largest value in the 2x2 submatrix. If any of the cells are one, then the output is one.
// 
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////


module MaxpoolCell(
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [1:0]kernel[1:0], // 2x2 grid
    output logic maxpool_cell 
  );

  always @(posedge clk)
  begin
    if (rst)
    begin
      maxpool_cell <= 0;
    end
    else if (enable)
    begin
      maxpool_cell <= kernel[0][0] | kernel[0][1] | kernel[1][0] | kernel[1][1];
    end
  end

endmodule
