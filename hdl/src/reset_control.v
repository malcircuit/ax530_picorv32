`timescale 1ns / 1ps
`default_nettype none 

//! @title Reset Controller
//! @author Mallory Sutter (sir.oslay@gmail.com)
//! @version 1.0
//! @date 2022-08-28

module reset_control(
        input  wire         clk_0,
        input  wire         external_reset,
        
        input  wire         clk_1,

        output wire por_reset,          //! Power-on reset (active high)
        output reg debounced_reset = 0 
    );

    localparam RESET_CYCLES = 4'd10;
    localparam DEBOUNCE_CYCLES = 16;

    reg clk_0_por_reset = 1;
    reg [3:0] clk_0_reset_cycles = RESET_CYCLES;

    always @(posedge clk_0) begin
        if (clk_0_reset_cycles > 4'd0) begin
            clk_0_reset_cycles <= clk_0_reset_cycles - 1;
        end else begin
            clk_0_por_reset <= 0;
        end
    end

    reg clk_1_por_reset = 1;
    reg [3:0] clk_1_reset_cycles = RESET_CYCLES;

    always @(posedge clk_1) begin
        if (clk_1_reset_cycles > 4'd0) begin
            clk_1_reset_cycles <= clk_1_reset_cycles - 1;
        end else begin
            clk_1_por_reset <= 0;
        end
    end

    assign por_reset = clk_0_por_reset | clk_1_por_reset;

    reg [DEBOUNCE_CYCLES:0] reset_shift_reg = 0;
    wire all_ones  =  &reset_shift_reg;
    wire all_zeros = ~|reset_shift_reg;

    always @(posedge clk_0) begin
        reset_shift_reg <= {reset_shift_reg[DEBOUNCE_CYCLES-1:0], external_reset};

        if (all_ones) begin
            debounced_reset <= 1;
        end

        if (all_zeros) begin
            debounced_reset <= 0;
        end
    end



endmodule