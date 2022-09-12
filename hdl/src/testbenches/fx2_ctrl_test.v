`timescale 1ns / 1ps
`default_nettype none 

module fx2_ctrl_test();

    reg clk = 1;
    reg reset_n = 1;

    // 50 MHz clock
    always #10 clk <= ~clk;

    wire fx2_ifclk;
    wire fx2_flaga;
    wire fx2_flagb;
    wire fx2_flagc;
    wire fx2_flagd;

    wire fx2_slrd;
    wire fx2_slwr;
    wire fx2_sloe;
    wire fx2_pktend;
    wire [ 1:0] fx2_fifoaddr;
    wire [15:0] fx2_fd;

    usb_test usb_test_inst (
        .clk            (              clk),
        .reset_n        (          reset_n),
        .usb_ifclk      (        fx2_ifclk),
        .usb_flaga      (        fx2_flaga),
        .usb_flagb      (        fx2_flagb),
        .usb_flagc      (        fx2_flagc), 
        .usb_flagd      (        fx2_flagd), 
        .usb_slrd       (         fx2_slrd),
        .usb_slwr       (         fx2_slwr),
        .usb_sloe       (         fx2_sloe),
        .usb_pktend     (       fx2_pktend),
        .usb_fifoaddr   (     fx2_fifoaddr), 
        .usb_fd         (           fx2_fd)
    );

    fx2_sim fx2_inst (
        .fx2_ifclk      (        fx2_ifclk), 
        .fx2_flaga      (        fx2_flaga),     
        .fx2_flagb      (        fx2_flagb),     
        .fx2_flagc      (        fx2_flagc),      
        .fx2_flagd      (        fx2_flagd),      
        .fx2_slrd       (         fx2_slrd),       
        .fx2_slwr       (         fx2_slwr),       
        .fx2_sloe       (         fx2_sloe),      
        .fx2_pktend     (       fx2_pktend),     
        .fx2_fifoaddr   (     fx2_fifoaddr),   
        .fx2_fd         (           fx2_fd)
    );

endmodule