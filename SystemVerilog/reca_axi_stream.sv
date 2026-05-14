`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/19/2026 03:03:13 PM
// Design Name: 
// Module Name: reca_axi_stream
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module reca_axi_stream(
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] s_axis_tdata,
    input  logic        s_axis_tvalid,
    output logic        s_axis_tready,
    input  logic        s_axis_tlast,
    output logic [783:0] bmnist_1d,
    output logic         start
);

localparam WORDS = 25; // 784 bits / 32 = 24.5, rounded up to 25

logic [783:0] shift_reg;
logic [$clog2(WORDS):0] word_count;

assign s_axis_tready = 1'b1; // always ready to receive

always_ff @(posedge clk) begin
    if (rst) begin
        shift_reg  <= '0;
        word_count <= '0;
        start      <= '0;
        bmnist_1d  <= '0;
    end
    else begin
        start <= 1'b0; // default
        if (s_axis_tvalid) begin
            // Shift in each 32-bit word
            shift_reg  <= {s_axis_tdata, shift_reg[783:32]};
            word_count <= word_count + 1;
            if (s_axis_tlast) begin
                bmnist_1d  <= {s_axis_tdata, shift_reg[783:32]};
                start      <= 1'b1;
                word_count <= '0;
            end
        end
    end
end

endmodule