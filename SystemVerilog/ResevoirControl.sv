`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author(s): Niklas Vestskogen
//
// Module Name: ResevoirControl
// Project Name: MNIST Classification using Resevoir Computing with Cellular Automata
// Description: Finite State Machine that controls the cellular automata, maxpool and the flattening modules.
// 
// Target Devices: Ultra96-v2
// Tool Versions: Vivado 2025.2
//
//////////////////////////////////////////////////////////////////////////////////


module ResevoirControl#(
    parameter N = 6,
    parameter M = 6,
    parameter ITER = 8)(
    input logic clk,
    input logic rst,
    input logic start,
    output logic enable,         // Enables Maxpool module
    output logic enable_flatten, // Enables Flatten module
    output logic enable_ca,      // Enables CellularAutomata module
    output logic bmnist,         // 1'b1 when the original input image has been processed by CellularAutomata
    output logic iter_done       // Start signal for the perceptron layer
);

localparam IDLE = 4'b0001, COMPUTE_BMNIST = 4'b0010, ITERATE = 4'b0100, DONE = 4'b1000;
localparam counter_width =$clog2(ITER+1); 

logic [counter_width-1:0] counter;
logic [3:0]current_state, next_state;

  
always@(current_state, start, counter) begin
    case (current_state)
        IDLE: begin
            iter_done = 1'b0;
            enable = 1'b0;
            enable_ca = 1'b0;
            enable_flatten = 1'b0;
            if (start == 1'b1) begin
                next_state = COMPUTE_BMNIST;
                enable_ca = 1'b1;
                bmnist = 1'b1;
            end 
            else begin
                bmnist = 1'b0;
                next_state = IDLE; 
            end
        end
        
        COMPUTE_BMNIST: begin // Compute the input image
            iter_done = 1'b0;
            enable = 1'b1;
            enable_flatten = 1'b0;
            enable_ca = 1'b1;
            bmnist = 1'b1;
            next_state = ITERATE;

        end
        
        ITERATE: begin // Compute CA iterations
            iter_done = 1'b0;
            enable = 1'b1;
            enable_flatten = 1'b1;
            enable_ca = 1'b1;
            bmnist = 1'b0;
            if (counter == 0) begin
                next_state = DONE;
            end 
            else begin
                next_state = ITERATE;
            end
        end
        
        DONE: begin
            iter_done = 1'b1; 
            enable = 1'b0; 
            enable_ca= 1'b0;
            bmnist = 1'b0;
            next_state = IDLE; 
        end
        default: begin
            next_state = IDLE;
        end
    endcase
end


always_ff @(posedge clk) begin: state_FFs
    if (rst) begin
        current_state <= IDLE; 
        counter <= ITER+1; 
    end
    else begin
        current_state <= next_state;
        // Reset counter
        if((current_state == DONE)||(current_state == IDLE)) begin
            counter <= ITER+1; //-1 prev logic CAN REMOVE WHEN WORKING
        end
        // Counting down when we generate new CA        
        else if ((current_state == COMPUTE_BMNIST)||(current_state == ITERATE))begin
            counter <= counter - 1; 
        end
    end
end

endmodule