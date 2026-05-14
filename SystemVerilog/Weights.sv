`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: Weights
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Stores the weights, and includes weight update logic with clamping between 0 and 63.
//
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////

module Weights #(
parameter N = 28, 
parameter M = 28, 
parameter ITERS = 8,
parameter NUM_CLASSES = 10,
parameter WIDTH =6,                         // Int6 weights
localparam NUM_WEIGHTS = (N/2)*(M/2)*ITERS, // Number of weights per class
localparam DEPTH = NUM_CLASSES*NUM_WEIGHTS, // Total number of bits used for weights
localparam ADDRESS_WIDTH = $clog2(DEPTH)    // Address width
)(
  input logic clk,
  input logic write_enable,                                 // 1'b1: Update parameter, 1'b0: No update
  input logic add_sub,                                      // 1'b1 = add 1 to the weight, or 1'b0 = subtract 1
  input logic [$clog2(NUM_WEIGHTS)-1:0] read_weight_index,  // index we want to read
  input logic [$clog2(NUM_CLASSES)-1:0] read_class_index,   // class index we want to read
  output logic [WIDTH-1:0] read_weights,                    // Weight used for computing logits in the OutputNeuron module
  input logic [$clog2(NUM_WEIGHTS):0] write_weight_index,   // index we want to write
  input logic [$clog2(NUM_CLASSES)-1:0] write_class_index,  // class index we want to write to
  // Ports for extracting the parameters
  input logic [$clog2(NUM_CLASSES*(N/2)*(M/2)*ITERS)-1:0] weight_read_address,
  output logic [WIDTH-1:0] weight_read_data 
);

logic [WIDTH-1:0] weights [DEPTH-1:0]; // 10 classes, each with NUM_WEIGHTS weights with WIDTH bits.

int i;
initial
begin
    for (i = 0; i<DEPTH; i++)
        begin
          weights[i] = 6'b100000; //initialized to 32
    end
end

/*
We we want to use the pretrained weights from the github. In order for the neural network to work properly, 
the following parameters in NeuromorphicAccelerator has to be:
N=28, M=28, NUM_CLASSES = 10, ITERS = 8, WIDTH_W = 6
*/

//initial begin
//    $readmemh("weights.mem", weights);
//end

logic [ADDRESS_WIDTH-1:0]read_address;  // Weight we want to read
logic [ADDRESS_WIDTH-1:0]write_address; // Weight we want to write to
logic [WIDTH-1:0] temp;                 // Temporary weight used for the calculation of the new weight before writing it to weights
logic signed [WIDTH:0] sum;             // We need WIDTH+1 bits due to the signed addition of the add_sub (+-1).

// A single array of weights
// Class_0 has positions 0-1567, and class_1 from 1568-....
assign read_address = read_class_index * NUM_WEIGHTS + read_weight_index;
assign write_address = write_class_index * NUM_WEIGHTS + write_weight_index;


always_ff @(posedge clk)
begin
if (write_enable)
begin
  // Convert unsigned to signed for the signed addition, and then back to unsigned to store in weights
  sum = $signed({1'b0, weights[write_address]}) + (add_sub ? 1 : -1); 

  /*
  Clamp weight between (0,63)
  */
  if (sum > 63)
  begin
    weights[write_address] <= 63;
  end
  else if (sum < 0)
  begin
    weights[write_address] <= 0;
  end
  else
  begin
    weights[write_address] <= sum[WIDTH-1:0];
  end
end
end

always_comb begin
    read_weights <= weights[read_address]; 
    weight_read_data <= weights[weight_read_address]; 
end
endmodule





