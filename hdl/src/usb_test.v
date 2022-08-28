`timescale 1ns / 1ps
`default_nettype none 

//! @title USB FIFO test module
//! @author Mallory Sutter (sir.oslay@gmail.com)
//! @version 1.0
//! @date 2022-08-26

//! @brief FX2LP USB FIFO test module for the ALINX AX530 dev board
//! @details If the FIFO of EP2 is not empty and the EP6 is not full, Read the 16bit data from EP2 FIFO and send to EP6 FIFO.

module usb_test(
        input  wire         clk,            //! Clock (50 MHz)
        input  wire         reset_n,        //! Reset 
        
        input  wire         usb_ifclk,      //! CY68013 interface clock

        input  wire         usb_flaga,      //! CY68013 FIFO programmable flag (default bahavior, except for EP4)
        input  wire         usb_flagb,      //! CY68013 FIFO full flag (active low)
        input  wire         usb_flagc,      //! CY68013 FIFO empty flag (active low)
        input  wire         usb_flagd,      //! CY68013 EP4 programmable flag (active low when FIFO byte count >= 1)

        output reg          usb_slrd,       //! CY68013 read control (active low)
        output reg          usb_slwr,       //! CY68013 write control (active low)
        output reg          usb_sloe,       //! CY68013 data output enable (active low)
        output reg          usb_pktend,     //! CY68013 packet end marker (active low - only used when sending data to the host)

        output reg   [1:0]  usb_fifoaddr,   //! CY68013 FIFO Address - 2'b00: EP2 (from host), 2'b01: EP4 (from host), 2'b10: EP6 (to host), 2'b11: EP8 (to host)
        inout  wire [15:0]  usb_fd,         //! CY68013 FIFO data bus

        output reg usb_ifclk_dup,   //! Duplicate for debugging
        output reg usb_flaga_dup,   //! Duplicate for debugging
        output reg usb_flagb_dup,   //! Duplicate for debugging
        output reg usb_flagc_dup,   //! Duplicate for debugging
        output reg usb_flagd_dup,   //! Duplicate for debugging
        output reg usb_sloe_dup,    //! Duplicate for debugging
        output reg usb_slrd_dup,    //! Duplicate for debugging
        output reg usb_slwr_dup,    //! Duplicate for debugging
        output reg usb_pktend_dup,  //! Duplicate for debugging

        output wire [ 1:0] usb_fifoaddr_dup,    //! Duplicate for debugging
        output wire [15:0] usb_fd_dup,          //! Duplicate for debugging

        output wire [7:0] SMG_Data,     //! Seven segment LED signals (active low)
        output wire [5:0] Scan_Sig      //! Determines which segment is active (active low)
    );

    genvar n;
    generate
        for (n = 0; n < 16; n = n  +  1)
        begin : thing
            assign usb_fd_dup[n] = usb_fd[n] ? 1'b1 : 1'b0;
        end
    endgenerate

    always @*
    begin : duplicate_signals
        usb_ifclk_dup = usb_ifclk;
        usb_flaga_dup = usb_flaga;
        usb_flagb_dup = usb_flagb;
        usb_flagc_dup = usb_flagc;
        usb_flagd_dup = usb_flagd;
        usb_sloe_dup  = usb_sloe;
        usb_slrd_dup  = usb_slrd;
        usb_slwr_dup  = usb_slwr;
        usb_pktend_dup = usb_pktend;
    end

    reg  [15:0] fifo_in;
    reg  fifo_rd = 0, fifo_wr;
    wire fifo_empty, fifo_full;
    wire [15:0] fifo_out;
    wire [7:0] fifo_count;
    reg  [23:0] rx_count;
   
    fifo fifo_inst (
        .clock (        clk),
        .aclr  (   ~reset_n),
        .data  (    fifo_in),
        .rdreq (    fifo_rd),
        .wrreq (    fifo_wr),
        .empty ( fifo_empty),
        .full  (  fifo_full),
        .q     (   fifo_out),
        .usedw ( fifo_count)
	);
    
    seven_seg_scan seg_scan_inst (
        .clk       (            clk),
        .reset_n   (        reset_n), 
        .en        (           1'b1),

        .SMG_Data  (       SMG_Data),
        .Scan_Sig  (       Scan_Sig),

        .seg_0_val (rx_count[ 3: 0]),
        .seg_1_val (rx_count[ 7: 4]),
        .seg_2_val (rx_count[11: 8]),
        .seg_3_val (rx_count[15:12]),
        .seg_4_val (rx_count[19:16]),
        .seg_5_val (rx_count[23:20])
    );

    reg [15:0] data_reg;    //! Temporary read/write data storage
    reg usb_fd_en;          //! Tri-state output enable for `usb_fd`

    assign usb_fd = usb_fd_en ? data_reg : 16'bz;

endmodule
