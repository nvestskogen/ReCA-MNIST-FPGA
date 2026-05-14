`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: PerceptronLayer
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Connects all the modules in the perceptron layer together. 
//              Takes the input from resevoir, and computes the logits for each output neuron sequentually. 
//              After each output neuron logit has been computed, the argmax function in WinnerTakesAll
//              compares the current output neuron logit with the previous largest logit, and updates the prediction yhat.
//              When the final output neuron has been processed, the value in yhat is the final prediction of the model.
//              The parameters, weights and biases, are updated if yhat != ytrue. 
//
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////

module PerceptronLayer #(
    parameter NUM_CLASSES = 10,
    parameter WIDTH_W = 6,  
    parameter WIDTH_B = 7,
    parameter N = 4,
    parameter M = 4,
    parameter ITERS = 2,
    localparam NUM_INPUTS = (N/2)*(M/2)*ITERS
  )(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [$clog2(NUM_CLASSES)-1:0] ytrue, // Input label
    input logic [NUM_INPUTS-1:0] input_neurons,  // Input from the resevoir layer
    input logic training,                        // 1'b1: Update parameters, 1'b0: inference only
    output logic update_complete,                // 1'b1 when parameters have been updated
    output logic [$clog2(NUM_CLASSES)-1:0] yhat, // Model prediction
    // Debugging ports
    input  logic [$clog2(NUM_CLASSES*(N/2)*(M/2)*ITERS)-1:0] weight_read_address,
    output logic [WIDTH_W-1:0] weight_read_data,
    input  logic [$clog2(NUM_CLASSES)-1:0] bias_read_address,
    output logic [WIDTH_B-1:0] bias_read_data    
  );

logic write_enable_bias;                      // 1'b1: Update bias, 1'b0: No update
logic write_enable_weight;                    // 1'b1: Update weight, 1'b0: No update
logic add_sub;                                // Weight update variable 1'b1 = add 1, 1'b0 = subtract 1
logic [$clog2(NUM_INPUTS):0] update_index;    // Index of the weight we want to update
logic [$clog2(NUM_CLASSES)-1:0] update_class; // Index of the class we want to update
logic enable_WTA;     // WinnerTakesAll processes the value of an output neuron, and compares with the previous largest output neuron
logic done_WTA;       // 1'b1 when the WinnerTakesAll module has finished comparing the current output neuron logit with the previous largest logit
logic rst_logit;      // Resets the OutputNeuron module to start computing a new logit value for the next output neuron
logic logit_done;     // 1'b1 when the OutputNeuron module has finished computing the logit value for the current output neuron
logic [$clog2(NUM_INPUTS)-1:0] fetch_index;   // Weight index, used for accessing weights
logic [$clog2(NUM_CLASSES)-1:0] fetch_class;  // Class index, used for accessing both weights and biases
logic [WIDTH_W-1:0] W;  // Weight value
logic [WIDTH_B-1:0] b;  // Bias value
logic [$clog2((N/2)*(M/2)*ITERS*63+64):0] logit; // Value of the output neuron (∑Wijxij+bj)


  ParameterUpdate # (.N(N),.M(M),.ITERS(ITERS),.NUM_CLASSES(NUM_CLASSES),.WIDTH_W(WIDTH_W),.WIDTH_B(WIDTH_B))
  ParameterUpdate_inst (
    .clk(clk),
    .rst(rst),
    .start_update(done_WTA), 
    .ytrue(ytrue),
    .yhat(yhat),
    .x(input_neurons),
    .training(training),
    .add_sub(add_sub),
    .write_enable_weight(write_enable_weight),
    .write_enable_bias(write_enable_bias),
    .update_complete(update_complete), 
    .update_index(update_index), 
    .update_class(update_class) 
  );

  PerceptronControl # (.N(N), .M(M), .ITERS(ITERS),.NUM_CLASSES(NUM_CLASSES))
  PerceptronControl_inst (
    .clk(clk),
    .rst(rst),
    .start(start),
    .enable_WTA(enable_WTA),
    .rst_logit(rst_logit),
    .logit_done(logit_done),
    .fetch_index(fetch_index),
    .fetch_class(fetch_class)
  );

  OutputNeuron # (.N(N),.M(M),.ITERS(ITERS),.WIDTH_W(WIDTH_W),.WIDTH_B(WIDTH_B))
  OutputNeuron_inst (
    .clk(clk),
    .rst(rst),
    .rst_logit(rst_logit),
    .logit_done(logit_done),
    .W(W),
    .b(b),
    .xi(input_neurons[fetch_index]),
    .logit(logit)
  );

  WinnerTakesAll # (.N(N),.M(M),.ITERS(ITERS),.NUM_CLASSES(NUM_CLASSES))
  WinnerTakesAll_inst (
    .clk(clk),
    .rst(rst),
    .enable(enable_WTA),
    .logit(logit),
    .yhat(yhat),
    .done(done_WTA)
  );

  Weights # (.N(N),.M(M),.ITERS(ITERS),.NUM_CLASSES(NUM_CLASSES),.WIDTH(WIDTH_W))
  Weights_inst (
    .clk(clk),
    .read_weight_index(fetch_index),
    .read_class_index(fetch_class),
    .read_weights(W),
    .write_enable(write_enable_weight),
    .add_sub(add_sub),
    .write_weight_index(update_index),
    .write_class_index(update_class),
    .weight_read_address(weight_read_address),
    .weight_read_data(weight_read_data)
  );

  Biases # (.NUM_CLASSES(NUM_CLASSES),.WIDTH(WIDTH_B))
  Biases_inst (
    .clk(clk),
    .write_enable(write_enable_bias),
    .add_sub(add_sub),
    .write_class_index(update_class),
    .read_class_index(fetch_class),
    .read_bias(b),
    .bias_read_address(bias_read_address),
    .bias_read_data(bias_read_data)
  );

endmodule
