`timescale 1ns / 1ps
`default_nettype none 

module fx2_ctrl_test();

    reg clk = 1;
    always #20 clk <= ~clk;

    wire por_rst, debounced_rst;
    wire internal_reset = por_rst | debounced_rst;

    reset_control rst_ctrl (
        .clk_0 (clk),
        .external_reset (1'b0),
        .clk_1 (clk),
        .por_reset (por_rst),
        .debounced_reset (debounced_rst)
    );

    reg fx2_flaga = 1;
    reg fx2_flagb = 1;
    reg fx2_flagc = 1;
    reg fx2_flagd = 1;

    wire fx2_slrd;
    wire fx2_slwr;
    wire fx2_sloe;
    wire fx2_pktend;
    wire [1:0] fx2_fifoaddr;

    reg  [15:0] fx2_fd = 16'hFFFF;
    reg  [15:0] fx2_fd_in = 0;
    wire [15:0] fx2_fd_out;

    wire [15:0] command_rx_data;
    wire        command_rx_req;
    reg         command_rx_ack = 0;
    wire        command_rx_valid;

    fx2_controller fx2_ctrl (
        .reset              (   internal_reset),
        .fx2_ifclk          (              clk), 
        .fx2_flaga          (        fx2_flaga),     
        .fx2_flagb          (        fx2_flagb),     
        .fx2_flagc          (        fx2_flagc),      
        .fx2_flagd          (        fx2_flagd),      
        .fx2_slrd           (         fx2_slrd),       
        .fx2_slwr           (         fx2_slwr),       
        .fx2_sloe           (         fx2_sloe),      
        .fx2_pktend         (       fx2_pktend),     
        .fx2_fifoaddr       (     fx2_fifoaddr),   
        .fx2_fd_in          (        fx2_fd_in),
        .fx2_fd_out         (       fx2_fd_out),

        .command_rx_data    (  command_rx_data),     
        .command_rx_req     (   command_rx_req),        
        .command_rx_ack     (   command_rx_ack),
        .command_rx_valid   ( command_rx_valid)
    );

    always @(posedge clk) begin
        if (command_rx_req & ~command_rx_ack) begin
            command_rx_ack <= 1'b1;
        end 
        
        if (~command_rx_req & command_rx_ack) begin
            command_rx_ack <= 1'b0;
        end 
    end
    
    always @(*) begin
        if (~fx2_sloe) begin
            #10 fx2_fd_in <= fx2_fd;
        end else begin
            #10 fx2_fd_in <= 0;
        end
    end

    reg [8:0] byte_count = 9'd3;

    always @(posedge clk) begin
        if (~fx2_slrd) begin
            fx2_fd <= fx2_fd - 1;
            byte_count <= byte_count - 1;

            if (byte_count == 1) begin
                fx2_flagb <= 0;
            end
        end

    end

endmodule