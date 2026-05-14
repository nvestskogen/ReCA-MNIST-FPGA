`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
// 
// Module Name: OutputNeuron
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Calculates the value of the output neuron, also called a logit. Cj = ∑(Wij*xi)+bj.
// 
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
// 
//////////////////////////////////////////////////////////////////////////////////


module OutputNeuron #(
    parameter N =6,
    parameter M = 6,
    parameter ITERS = 8,
    parameter WIDTH_W = 6,
    parameter WIDTH_B = 7
    )(
    input logic clk,
    input logic rst,
    input logic rst_logit,      // Reset the OutputNeuron module to start computing a new logit
    input logic logit_done,     // All wi*xwi have been accumulated, and now we can add the bias
    input logic [WIDTH_W-1:0]W, // Weight (wi)
    input logic [WIDTH_B-1:0]b, // Bias 
    input logic xi,             // Input neuron
    output logic [$clog2((N/2)*(M/2)*ITERS*(63)+64):0]logit // Output
    );
    
   
logic [$clog2((N/2)*(M/2)*ITERS*(63)+64):0]accumulated_sum; // Accumulates the the partial sums ∑(Wi*xi)+b

always_ff @(posedge clk) begin
    if (rst_logit || rst) begin
        accumulated_sum <= 0;
    end
    else begin
        // Computes Wi*xi per clock cycle
        accumulated_sum <= accumulated_sum + (xi ? W : 0); //Wi*0 = 0 or Wi*1 = Wi
        if (logit_done) begin
            // Adds the bias when all the Wi*xi has been computed
            logit<=accumulated_sum+b;
        end
    end
end
endmodule
