`timescale 1ns / 1ps
`default_nettype none 

//! @title USB FIFO test module
//! @author Mallory Sutter (sir.oslay@gmail.com)
//! @version 1.0
//! @date 2022-08-26

//! @brief FX2LP USB FIFO test module for the ALINX AX530 dev board
//! @details If the FIFO of EP2 is not empty and the EP6 is not full, Read the 16bit data from EP2 FIFO and send to EP6 FIFO.
//! 
//! ### Example read
//! This is an example of the signal trace from receiving 4 bytes (2 16-bit words) from the host sent over the EP4 FIFO. 
//! 
//! In this case, the EP4 programmable flag is triggered (`usb_flagd` goes low), which triggers a read into the local FIFO.
//! Once the 2 words are read from `usb_fd` the empty flag for EP4 is triggered (`usb_flagc` goes low), which stops the read sequence.
//! {
//!     signal: [
//!         {name: 'posedge usb_ifclk',  wave: 'P....'},
//!         {name: 'negedge usb_ifclk',  wave: 'N....', phase: 1},
//!         {name: 'usb_flaga (PF)',     wave: 'x0.1x'},
//!         {name: 'usb_flagc (EF)',     wave: 'x1.0x'},
//!         {name: 'usb_flagd (EP4 EF)', wave: '01..0.', phase: 2},
//!         {name: 'usb_slrd',           wave: '1.0.1', phase: 1},
//!         {name: 'usb_sloe',           wave: '10.1.', phase: 1},
//!         {name: 'usb_fifoaddr',       wave: 'x3..x', data: ["2'b01 (EP4 FIFO)"], phase: 1},
//!         {name: 'usb_fd',             wave: 'x==x.', data: ["n", "n + 1"]}
//!     ],
//!     head:{tick:0},
//!     config: { hscale: 2 }
//! }

module usb_test(
        input  wire         clk,            //! Clock (50 MHz)
        input  wire         reset_n,        //! Reset 
        
        input  wire         usb_ifclk,      //! CY68013 interface clock

        input  wire         usb_flaga,      //! CY68013 EP2 empty flag (active low)
        input  wire         usb_flagb,      //! CY68013 EP4 empty flag (active low)
        input  wire         usb_flagc,      //! CY68013 EP6 full flag (active low)
        input  wire         usb_flagd,      //! CY68013 EP8 full flag (active low)

        output wire         usb_slrd,       //! CY68013 read control (active low)
        output wire         usb_slwr,       //! CY68013 write control (active low)
        output wire         usb_sloe,       //! CY68013 data output enable (active low)
        output wire         usb_pktend,     //! CY68013 packet end marker (active low - only used when sending data to the host)

        output wire   [1:0]  usb_fifoaddr,   //! CY68013 FIFO Address - 2'b00: EP2 (from host), 2'b01: EP4 (from host), 2'b10: EP6 (to host), 2'b11: EP8 (to host)
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

        output reg [ 1:0] usb_fifoaddr_dup,    //! Duplicate for debugging
        output wire [15:0] usb_fd_dup,          //! Duplicate for debugging

        output wire [7:0] SMG_Data,     //! Seven segment LED signals (active low)
        output wire [5:0] Scan_Sig      //! Determines which segment is active (active low)
    );

    wire [15:0] fx2_fd_in = usb_fd;
    wire [15:0] fx2_fd_out;

    genvar n;
    generate
        for (n = 0; n < 16; n = n  +  1)
        begin : usb_fd_tri_state_mux
            assign usb_fd[n]     = usb_sloe ?         1'bZ : fx2_fd_out[n];
            assign usb_fd_dup[n] = usb_sloe ? fx2_fd_in[n] : fx2_fd_out[n];
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
        usb_fifoaddr_dup = usb_fifoaddr;
    end

    wire por_rst, debounced_rst;

    wire internal_reset = por_rst | debounced_rst;

    reset_control rst_ctrl (
        .clk_0 (clk),
        .external_reset (~reset_n),
        .clk_1 (usb_ifclk),
        .por_reset (por_rst),
        .debounced_reset (debounced_rst)
    );

    wire fifo_wr_full, fifo_wr_empty;
    // wire fifo_rd_full, fifo_rd_empty;
    wire [15:0] fifo_out;
    wire [7:0] fifo_count;
    reg  [23:0] rx_count;

    wire [15:0]  command_rx_data;
    wire         command_rx_req;
    reg          command_rx_ack = 0;
    wire         command_rx_valid;

    wire command_rx_pending =  command_rx_req & ~command_rx_ack;
    wire command_rx_stopped = ~command_rx_req &  command_rx_ack;
    wire command_rx_active  =  command_rx_req &  command_rx_ack;

    always @(negedge usb_ifclk) begin
        if (internal_reset) begin
            rx_count[7:0] <= 0;    
        end

        if (command_rx_pending & ~fifo_wr_full) begin
            command_rx_ack <= 1;
        end
        
        if (command_rx_stopped | fifo_wr_full) begin
            command_rx_ack <= 0;
            rx_count[7:0] <= fifo_count + !fifo_wr_empty;
        end
    end

    // Set the fifo write clock to be negedge usb_ifclk, gated to command_rx_active & command_rx_valid
    wire fifo_wr_clk = usb_ifclk & command_rx_active & command_rx_valid;
   
    fifo fifo_inst (
        .aclr       (  internal_reset),

        .rdclk      (             clk),
        .q          (        fifo_out),
        .rdreq      (            1'b0),
        // .rdempty    (      fifo_empty),
        // .rdfull     (                ),
        // .rdusedw    (                ),

        .wrclk      (     fifo_wr_clk),
        .wrreq      (  command_rx_req),
        .data       ( command_rx_data),
        .wrfull     (    fifo_wr_full),
        .wrempty    (   fifo_wr_empty),
        .wrusedw    (      fifo_count)
	);


    fx2_controller fx2_ctrl (
        .reset              (internal_reset),
        .fx2_ifclk          (   ~usb_ifclk), 
        .fx2_flaga          (    usb_flaga),     
        .fx2_flagb          (    usb_flagb),     
        .fx2_flagc          (    usb_flagc),      
        .fx2_flagd          (    usb_flagd),      
        .fx2_slrd           (     usb_slrd),       
        .fx2_slwr           (     usb_slwr),       
        .fx2_sloe           (     usb_sloe),      
        .fx2_pktend         (   usb_pktend),     
        .fx2_fifoaddr       ( usb_fifoaddr),   
        .fx2_fd_in          (    fx2_fd_in),
        .fx2_fd_out         (   fx2_fd_out),

        .command_rx_data    (  command_rx_data),     
        .command_rx_req     (   command_rx_req),        
        .command_rx_ack     (   command_rx_ack),
        .command_rx_valid   ( command_rx_valid)
    );
    
    seven_seg_scan seg_scan_inst (
        .clk       (            clk),
        .reset_n   (~internal_reset), 
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

endmodule
