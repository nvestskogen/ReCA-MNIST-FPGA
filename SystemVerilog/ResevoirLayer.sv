`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
// 
// Module Name: ResevoirLayer
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Connects all the modules in the resevoir layer. ISt takes the binary MNIST image as input, 
//              and generates cellular automata (CA) iterations based on the input and the previous state of the CA.
//              The output of the CA is then downsampled, using maxpooling, then flattened and sent to the perceptron layer.
// 
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
// 
//////////////////////////////////////////////////////////////////////////////////


module ResevoirLayer#(
    parameter int N = 6,
    parameter int M = 6,
    parameter int ITERS = 8,
    parameter bit wrap_around = 1'b0,
    localparam NUM_INPUTS = ((N/2)*(M/2))*ITERS
    )(
    input logic clk,
    input logic rst,
    input logic start,                       // Starts once the system and input is ready
    input logic [N-1:0] binary_mnist[M-1:0], // Input image
    output logic [NUM_INPUTS-1:0]flattened,  // Outputs the flattened output of the maxpool of all the cellular automata iterations 
    output logic iter_done                   // Start signal for the perceptron layer
    );

logic enable_ca;                          // Enables  CA iterations
logic enable_maxpool;                     // Enables maxpool to reduce CA dimensions
logic enable_flatten;                     // Enables the maxpool output to be flattened
logic bmnist;                             // 1'b1 when the original input image has been processed by the CA
logic [NUM_INPUTS-1:0]flattened_temp;     // Output of the maxpool module gets shifted into this register
logic [N-1:0] output_ca [M-1:0];          // CA output
logic [N/2-1:0] output_maxpool [M/2-1:0]; // Maxpool output

always_ff @(posedge clk) begin
    if(iter_done) begin
        flattened <= flattened_temp; // Input to the perceptron layer
  end
end

ResevoirControl # (
    .N(N),
    .M(M),
    .ITER(ITERS)
  )
  ResevoirControl_inst (
    .clk(clk),
    .rst(rst),
    .start(start),
    .enable(enable_maxpool),
    .enable_flatten(enable_flatten),
    .enable_ca(enable_ca),
    .bmnist(bmnist),
    .iter_done(iter_done)
  );

CellularAutomata # (
    .M(M),
    .N(N),
    .wrap_around(wrap_around)
  )
  CellularAutomata_inst (
    .clk(clk),
    .rst(rst),
    .enable(enable_ca),
    .bmnist(bmnist),
    .input_matrix(binary_mnist),
    .output_matrix(output_ca)
  );
 
Maxpool # (
    .N(N),
    .M(M)
  )
  Maxpool_inst (
    .clk(clk),
    .rst(rst),
    .enable(enable_maxpool), 
    .input_matrix(output_ca),
    .output_matrix(output_maxpool)
  );

  Flatten # (
    .N(N),
    .M(M),
    .ITER(ITERS)
  )
  Flatten_inst (
    .clk(clk),
    .rst(rst),
    .enable_flatten(enable_flatten),
    .maxpool_output(output_maxpool),
    .flattened(flattened_temp)
  );

endmodule