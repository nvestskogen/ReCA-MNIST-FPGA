`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: NeuromorphicAccelerator
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Connects the resevoir and the perceptron layer together.
//
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////

module NeuromorphicAccelerator #(
    parameter NUM_CLASSES = 10,     // Number of output classes (0-9)
    parameter N = 28,               // Number of rows in the input image
    parameter M = 28,               // Number of columns in the input image
    parameter ITERS = 8,            // Number of cellular automata (CA) iterations
    parameter WIDTH_W = 6,          // Width of the weights
    parameter WIDTH_B = 7,          // Width of the bias
    parameter wrap_around = 1'b0,   // 1'b1: The CA layer has wrap around logic, 1'b0: no wrap around
    parameter RECA = 1'b1,          // 1'b1: Use the Resevoir Computing with Cellular Automata, 1'b0: Use a fully connected layer without the CA layer, useful for testing the training of the fully connected layer in isolation.
    localparam N_MAXPOOL = N/2,     // Number of rows after maxpooling
    localparam M_MAXPOOL = M/2,     // Number of columns after maxpooling
    localparam NUM_INPUTS = RECA ? N_MAXPOOL*M_MAXPOOL*ITERS : M*N // Number of inputs to the peceptron layer, either the flattened output of the CA layer or the original image when RECA = 1'b0
  )(
    input logic clk,
    input logic rst,
    input logic start, 
    input logic [M*N-1:0] bmnist_1d,             // Input image
    input logic [$clog2(NUM_CLASSES)-1:0] ytrue, // Input label
    input logic training,                        // 1'b1: Update parameters, 1'b0: inference only
    output logic [$clog2(NUM_CLASSES)-1:0] yhat, // Model prediction
    output logic busy,                           // 1'b1 when we are processing the input
    output logic ready,                          // 1'b1 when we are ready to process a new input
    output logic update_complete,                // 1'b1 when parameters have been updated
    // Ports for extracting the parameters
    input  logic [$clog2(NUM_CLASSES*N/2*M/2*ITERS)-1:0]  weight_read_address, // Weight we want to read
    output logic [WIDTH_W-1:0] weight_read_data,                            // Weight at the given address
    input  logic [$clog2(NUM_CLASSES)-1:0] bias_read_address,               // Bias we want to read
    output logic [WIDTH_B-1:0] bias_read_data                               // Bias at the given address
  );
localparam IDLE = 3'b001, RESEVOIR= 3'b010, PECEPTRON = 3'b100;

logic start_resevoir;                       // Starts the resevoir layer
logic iter_done;                            // High when the resevoir layer has completed all cellular automata iterations, and the corresponding maxpool operation.
logic start_peceptron;                      // Starts the peceptron layer
logic iter_done_delayed;                    // Delay peceptron layer by 1 clock in order for the flattened output of the resevoir layer to latch 
logic [N-1:0] bmnist [M-1:0];               // 2D representation of the 1D input image
logic [(N/2)*(M/2)*ITERS-1:0] flattened;    // Output of the resevoir layer
logic [NUM_INPUTS-1:0] input_perceptron;     // Input to the perceptron layer. 

logic [2:0] current_state, next_state; 

// Convert 1D input to 2D for row and column indexing in the resevoir layer
always_comb
begin
for (int i = 0; i < M; i++)
    bmnist[i] = bmnist_1d[i*N +: N];
end


// If RECA = 1'b1, then the perceptron layer will see the resevoir output, else the input image will be sent
assign input_perceptron = (RECA ? flattened : bmnist_1d); 

// Delay perceptron layer by 1 clock in order for the flattened output of the resevoir be ready 
always_ff @(posedge clk)
begin
    iter_done_delayed <= iter_done;
end


always_comb
begin
case (current_state)
    IDLE:
    begin
    busy = 1'b0;
    ready = 1'b1;
    next_state = IDLE;
    start_resevoir = 1'b0;
    start_peceptron = 1'b0;
    if (start)
    begin
        if (RECA)
        begin
        start_resevoir = 1'b1;
        next_state = RESEVOIR;
        end
        else
        begin
        start_peceptron = 1'b1;
        next_state = PECEPTRON;
        end
    end
    end

    RESEVOIR:
    begin
    busy = 1'b1;
    ready = 1'b0;
    start_resevoir = 1'b0;
    next_state = RESEVOIR;
    start_peceptron = 1'b0;
    if (iter_done_delayed)
    begin
        start_peceptron = 1'b1;
        next_state = PECEPTRON;
    end
    end

    PECEPTRON:
    begin
    busy = 1'b1;
    ready = 1'b0;
    start_resevoir = 1'b0;
    start_peceptron = 1'b0;
    next_state =  PECEPTRON;
    if (update_complete)
        next_state = IDLE;
    end

    default:
    begin
    busy = 1'b1;
    ready = 1'b0;
    next_state = IDLE;
    start_resevoir = 1'b0;
    start_peceptron = 1'b0;
    end
endcase
end


always_ff @(posedge clk)
begin
if (rst) begin
    current_state <= IDLE;
end
else begin
    current_state <= next_state;
end
end


ResevoirLayer #(
                .N(N), 
                .M(M), 
                .ITERS(ITERS), 
                .wrap_around(wrap_around)
            ) ResevoirLayer_inst (
                .clk(clk),
                .rst(rst),
                .start(start_resevoir),
                .binary_mnist(bmnist), // Input to the resevoir layer
                .flattened(flattened), // Input to the peceptron layer
                .iter_done(iter_done) // 1'b1 when we have completed ITERS cellular automata generations
            );

PerceptronLayer #(
                .NUM_CLASSES(NUM_CLASSES),
                .WIDTH_W(WIDTH_W),
                .WIDTH_B(WIDTH_B),
                .N(N), 
                .M(M), 
                .ITERS(RECA ? ITERS : 4) // If we are not using the resevoir, then the ITERS are set to 4 to make the input size of the peceptron layer the same size as the input image (784).
            ) PerceptronLayer_inst (
                .clk(clk),
                .rst(rst),
                .start(start_peceptron), // Starts one clock after the flattened module in the resevoir is done
                .input_neurons(input_perceptron), // Input to the peceptron layer. Either the output of the resevoir or the input image.
                .ytrue(ytrue),
                .training(training),
                .yhat(yhat),
                .update_complete(update_complete), // 1'b1 inference is done (training = 1'b0) or parameters have been updated (training = 1'b1)
                .weight_read_address(weight_read_address),
                .weight_read_data(weight_read_data),
                .bias_read_address(bias_read_address),
                .bias_read_data(bias_read_data)
                );

endmodule