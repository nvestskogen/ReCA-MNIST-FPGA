`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: PerceptronControl
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: FSM for the peceptron layer. Controls the flow of data and order of operations in the PeceptronLayer module.
//              Starts by computing the logit for the first output neuron, then enables the WinnerTakesAll module to compare with the current largest logit value.
//              This process is repeated for all output neurons, and when all output neurons have been processed, the final yhat value is our final prediction.
//
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////

module PerceptronControl#(
    parameter N = 6,
    parameter M = 6,
    parameter ITERS = 6,
    parameter NUM_CLASSES = 10,
    localparam NUM_WEIGHTS = (N/2)*(M/2)*ITERS)(
    input logic clk,
    input logic rst,
    input logic start,
    output logic enable_WTA,     // Enables WinnerTakesAll module 
    output logic rst_logit,      // Reset the OutputNeuron module to start computing a new logit
    output logic logit_done,     // Cj = ∑Wijxij+bj has been computed
    output logic [$clog2(NUM_WEIGHTS)-1:0] fetch_index, // Weight index, used for accessing the weights to be computed in OutputNeuron module
    output logic [$clog2(NUM_CLASSES)-1:0] fetch_class  // Class index, used for accessing both weights and biases
    );

  localparam IDLE = 3'b001, COMPUTE = 3'b010, DONE = 3'b100;

  logic [$clog2(NUM_WEIGHTS)-1:0] wi; // Weight index
  logic [$clog2(NUM_CLASSES)-1:0] ci; // Class index
  logic computing_logits;             // 1'b1 when we are computing logits for all output neruons.
  logic [2:0] current_state, next_state;

  assign fetch_index = wi; 
  assign fetch_class = ci; 

  always_comb
  begin
    case (current_state)
      IDLE:
      begin
        next_state = IDLE;
        rst_logit = 1'b1;
        logit_done = 1'b0;
        enable_WTA = 1'b0;
        if (start || computing_logits)
          next_state = COMPUTE;
      end

      COMPUTE:
      begin
        next_state = COMPUTE;
        rst_logit = 1'b0;
        logit_done = 1'b0;
        enable_WTA = 1'b0;
        if (wi >= NUM_WEIGHTS)
        begin
          logit_done = 1'b1; // OutputNeuron has computed a logit
          next_state = DONE;
        end
      end

      DONE:
      begin
        next_state = IDLE;
        rst_logit = 1'b1; // Resets the OutputNeuron module for the the next logit calculation
        logit_done = 1'b0;
        enable_WTA = 1'b1; // WinnerTakesAll compares the current logit with the previous largest logit
      end

      default:
      begin
        next_state = IDLE;
        rst_logit = 1'b0;
        logit_done = 1'b0;
        enable_WTA = 1'b0;
      end
    endcase
  end

  always_ff @(posedge clk)
  begin
    if (rst)
    begin
      current_state <= IDLE;
      wi <= '0;
      ci <= '0;
      computing_logits  <= 1'b0;
    end
    else
    begin
      current_state <= next_state;

      case (current_state)
        IDLE:
        begin
          wi <= '0; // reset weight index for each new class
          if (start)
          begin
            ci <= '0; // fresh start: reset class index
            computing_logits <= 1'b1;
          end
          // else: computing_r stays high, ci already points to next class
        end

        COMPUTE:
        begin
          if (wi < NUM_WEIGHTS)
            wi <= wi + 1;
        end

        DONE:
        begin
          if (ci < NUM_CLASSES - 1)
          begin
            ci <= ci + 1;  // move to next class
            computing_logits <= 1'b1;
          end
          else
          begin
            ci <= '0; // all classes done, reset for next sample
            computing_logits <= 1'b0;
          end
          wi <= '0;
        end

        default:
        begin
          wi <= '0;
          ci <= '0;
          computing_logits <= 1'b0;
        end
      endcase
    end
  end


endmodule
