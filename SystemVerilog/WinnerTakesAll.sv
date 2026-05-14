`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
// 
// Create Date: 01/27/2026 01:51:58 PM
// Module Name: WinnerTakesAll
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Takes the output from the OutputNeuron module, and compares with the current largest output neuron value. 
//              If the new value is larger than the current largest value, then the index of the new largest value is stored as our prediction.
//              When all output neurons have been processed, the final yhat value is our final prediction.
//
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
// 
//////////////////////////////////////////////////////////////////////////////////

module WinnerTakesAll #(
    parameter N = 6,
    parameter M = 6,
    parameter ITERS = 6,
    parameter NUM_CLASSES = 10,
    localparam NUM_INPUTS = (N/2)*(M/2)*ITERS
)(
    input logic clk,
    input logic rst,
    input logic enable, // 1'b1 when OutputNeuron has computed a new logit value
    input logic [$clog2(NUM_INPUTS*63+63):0] logit, // Cj = ∑Wijxij+bj
    output logic [$clog2(NUM_CLASSES)-1:0] yhat, // Model predictions
    output logic done // 1b1 when NUM_CLASSES output neurons has been processed
    );
 
logic [$clog2(NUM_INPUTS*63):0] current_max; // Current largest output neuron value we have seen so far
logic [$clog2(NUM_CLASSES):0] yhat_temp; // Class of the neuron with the current largest value
logic [$clog2(NUM_CLASSES):0] counter; // Compares the values over all output neurons
 
always_ff @(posedge clk) begin
    if (rst) begin
        yhat_temp <= '0;
        current_max <= '0;
        counter <= '0;
        done  <= 1'b0;
    end else if (enable) begin
        // Compare the current logit value with the current largest value, and update the class with the largest value.
        if (logit > current_max) begin
            current_max <= logit;
            yhat_temp  <= counter;
        end
        if (counter == NUM_CLASSES - 1) begin
            // Check if the last logit value is the largest, and update yhat_temp if it is.
            yhat  <= (logit > current_max) ? NUM_CLASSES - 1 : yhat_temp;
            done <= 1'b1;
        end
        counter <= counter + 1;
        end
    else begin
        if (counter >= NUM_CLASSES) begin
            done <= 1'b0;
            counter <= '0;
            current_max <= '0;
            yhat_temp <= '0;
        end
    end
end

 
endmodule
 