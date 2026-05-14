`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: Biases
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Stores and updates weights, logic with clamping between 0 and 64.
//
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////

module Biases #(
    parameter NUM_CLASSES = 10, 
    parameter WIDTH =7,                            // Int7 bias
    localparam ADDRESS_WIDTH = $clog2(NUM_CLASSES) // Address width
    )(
      input logic clk,
      input logic write_enable,                                // 1'b1: Update parameter, 1'b0: No update
      input logic add_sub,                                     // 1'b1 = add 1, 1'b0 = subtract 1
      input logic [$clog2(NUM_CLASSES)-1:0] write_class_index, // index we want to update
      input logic [$clog2(NUM_CLASSES)-1:0] read_class_index,  // idnex we want to read
      output logic [WIDTH-1:0] read_bias,                      // Bias used for computing logits in the OutputNeuron module
      // Ports for extracting the parameters
      input  logic [$clog2(NUM_CLASSES)-1:0] bias_read_address,// Bias we want to read
      output logic signed [WIDTH-1:0] bias_read_data           // Bias at the given address
    );

  logic [WIDTH-1:0] biases [NUM_CLASSES-1:0]; // Register that store the biases
  logic [ADDRESS_WIDTH-1:0]read_address;  // Bias we want to read
  logic [ADDRESS_WIDTH-1:0]write_address; // Bias we want to write to
  logic signed [WIDTH:0] sum;             // We need WIDTH+1 bits due to the signed addition of the add_sub (+-1).


int i;
initial
begin
for (int i = 0; i < NUM_CLASSES; i++)
    begin
        biases[i] = 7'b0100000 + (i % 9); // (i % 9) to offset the bias value
    end
end

/*
We we want to use the pretrained biases from the github. In order for the neural network to work properly, 
the following parameters in NeuromorphicAccelerator has to be:
NUM_CLASSES = 10, WIDTH_B = 7
*/ 
//initial begin
//    $readmemh("biases.mem", biases);
//end

// Class_0 has position 0, and class_1 has position 1,.... and class NUM_CLASSES-1 has position NUM_CLASSES-1
assign read_address = read_class_index;
assign write_address = write_class_index;

always_ff @(posedge clk)
begin
if (write_enable)
begin
  // Convert unsigned to signed for the signed addition, and then back to unsigned to store in biases
  sum = $signed({1'b0, biases[write_address]}) + (add_sub ? 1 : -1);

  /*
  Clamp bias between (0,64)
  */
  if (sum > 63)
  begin
    biases[write_address] <= 64;
  end
  else if (sum < 0)
  begin
    biases[write_address] <= 0;
  end
  else
  begin
    biases[write_address] <= sum[WIDTH-1:0];
  end
end
end

always_comb
begin
read_bias = biases[read_address];
bias_read_data = biases[bias_read_address]; 
end

endmodule
