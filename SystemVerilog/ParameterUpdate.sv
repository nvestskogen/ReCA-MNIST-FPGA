`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
// 
// Module Name: ParameterUpdate
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: A FSM that controls the parameter updates. 
//              We are only updating the parameters associated with the input that contributed to the wrong prediction:
//                  * If x[i] = 1'b0, then we will not update weight[i]
//                  * If x[i] = 1'b1, then we will update weight[i] for both ytrue and yhat
//
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////


module ParameterUpdate #(
    parameter N = 6,
    parameter M = 6,
    parameter ITERS = 6,
    parameter NUM_CLASSES = 10,
    parameter WIDTH_W = 6,
    parameter WIDTH_B = 7,
    localparam NUM_INPUTS = (N/2)*(M/2)*ITERS
)(
    input logic clk,
    input logic rst,
    input logic start_update,                           // WinnerTakesAll outputs 1'b1 when we have the model predictionm yhat. 
    input logic training,                               // 1'b1: Update parameters, 1'b0: inference only. 
    input logic [$clog2(NUM_CLASSES)-1:0] ytrue,        // Input label
    input logic [$clog2(NUM_CLASSES)-1:0] yhat,         // Model prediction
    input logic [NUM_INPUTS-1:0] x,                     // Input from the resevoir layer, used to determine which weights to update
    output logic add_sub,                               // Weight update variable 1'b1 = add 1, 1'b0 = subtract 1
    output logic write_enable_weight,                   // 1'b1: Update weight, 1'b0: No update
    output logic write_enable_bias,                     // 1'b1: Update bias, 1'b0: No update
    output logic update_complete,                       // 1'b1 when all the parameters, weights and biases, have been updated.
    output logic [$clog2(NUM_INPUTS):0] update_index,   // Weight index we want to update
    output logic [$clog2(NUM_CLASSES)-1:0] update_class // Weight and bias class index we want to update
);
 
localparam IDLE = 4'b0001, UPDATE_YTRUE = 4'b0010, UPDATE_YHAT = 4'b0100, DONE = 4'b1000;
 

logic x_update;                         // Variable used to determine if we should update a weight
logic bias_updated;                     // 1'b1 if we have updated the bias. Used to make sure that we do not update the bias more than once.
logic update_complete;                  // 1'b1 when we have completed the update of all parameters
logic [$clog2(NUM_INPUTS)-1:0] wi;      // Weight index for  the weights we want to update
logic [$clog2(NUM_CLASSES)-1:0] ci;     // Class index for the parameters we want to update
logic [3:0] current_state, next_state; 

assign update_index = wi; 
assign update_class = ci; 

always_comb x_update = x[wi]; 
assign write_enable_weight = training && x_update && ((current_state == UPDATE_YTRUE) || (current_state == UPDATE_YHAT));
assign write_enable_bias = training && !bias_updated && ((current_state == UPDATE_YTRUE) || (current_state == UPDATE_YHAT));

/*
The FSM starts when WinnerTakesAll module outputs the start signal, start_update.
          If yhat = ytrue, then we transition to the DONE state, in order to avoid updating the parameters.
          If yhat != ytrue, then we update the weights and biases for both classes.
                 We reinforce the true class by adding 1 to both weight and biases.
                 We punish the predicted class by subtracting 1 from both weight and biases.   
*/
always_comb begin
    next_state = current_state;
    add_sub = 1'b0;  
    case (current_state)
        IDLE: begin
            add_sub = 1'b0;
            if (start_update)
                // We only update if the prediction is wrong, otherwise we can skip the update and save update computations
                next_state = (yhat == ytrue) ? DONE : UPDATE_YTRUE;
        end
        UPDATE_YTRUE: begin
            add_sub = 1'b1;
            if (wi >= NUM_INPUTS - 1)
                next_state = UPDATE_YHAT;
        end
        UPDATE_YHAT: begin
            add_sub = 1'b0;
            if (wi >= NUM_INPUTS - 1)
                next_state = DONE;
        end
        DONE: begin 
             next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end
 
always_ff @(posedge clk) begin
    if (rst) begin
        current_state <= IDLE;
        wi <= '0;
        ci <= '0;
        bias_updated <= 1'b1;
        update_complete <= 1'b0;
    end else begin
        current_state <= next_state;
        case (current_state)
            IDLE: begin
                wi <= '0;
                update_complete <= 1'b0;
                bias_updated <= 1'b1;
                if (start_update && yhat != ytrue)
                    ci <= ytrue;
            end
            UPDATE_YTRUE: begin
                ci <= ytrue;
                wi <= wi + 1;
                bias_updated <= (wi != '0);
                if (wi >= NUM_INPUTS - 1)
                    wi <= '0;
            end
            UPDATE_YHAT: begin
                ci <= yhat;
                wi <= wi + 1;
                bias_updated <= (wi != '0);
            end
            DONE: begin
                update_complete <= 1'b1;
                wi <= '0;
                bias_updated <= 1'b1;
            end
            default: begin
                wi <= '0;
                ci <= '0;
                update_complete <= 1'b0;
                bias_updated <= 1'b1;
            end
        endcase
    end
end
 
endmodule