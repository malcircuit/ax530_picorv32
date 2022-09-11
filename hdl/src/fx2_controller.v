`timescale 1ns / 1ps
`default_nettype none 

//! @title USB FIFO controller
//! @author Mallory Sutter (sir.oslay@gmail.com)
//! @version 1.0
//! @date 2022-08-28

//! @brief FX2LP USB 2.0 bulk transfer FIFO controller
//! 
//! ### Example read
//! This is an example of the signal trace from receiving 4 bytes (2 16-bit words) from the host sent over the EP4 FIFO. 
//! 
//! In this case, the EP4 programmable flag is triggered (`fx2_flagd` goes low), which triggers a read into the local FIFO.
//! Once the 2 words are read from `fx2_fd` the empty flag for EP4 is triggered (`fx2_flagc` goes low), which stops the read sequence.
//! {
//!     signal: [
//!         {name: 'posedge fx2_ifclk',  wave: 'P....'},
//!         {name: 'negedge fx2_ifclk',  wave: 'N....', phase: 1},
//!         {name: 'fx2_flaga (PF)',     wave: 'x0.1x'},
//!         {name: 'fx2_flagc (EF)',     wave: 'x1.0x'},
//!         {name: 'fx2_flagd (EP4 EF)', wave: '01..0.', phase: 2},
//!         {name: 'fx2_slrd',           wave: '1.0.1', phase: 1},
//!         {name: 'fx2_sloe',           wave: '10.1.', phase: 1},
//!         {name: 'fx2_fifoaddr',       wave: 'x3..x', data: ["2'b01 (EP4 FIFO)"], phase: 1},
//!         {name: 'fx2_fd',             wave: 'x==x.', data: ["n", "n + 1"]}
//!     ],
//!     head:{tick:0},
//!     config: { hscale: 2 }
//! }

//! {
//!     signal: [
//!         {name: 'posedge fx2_ifclk',  wave:  'P.......'},
//!         {name: 'fx2_flagc (empty)',  wave:  'x.1..0x.'},
//!         {name: 'command_rx_req',     wave: '01.....0.', phase: 2},
//!         {name: 'command_rx_ack',     wave:  '01.....0'},
//!         {name: 'main_state',         wave:  '3.4...x', data: ["IDLE", "READING"]},
//!         {name: 'fx2_slrd',           wave:  '1..0.1.'},
//!         {name: 'fx2_sloe',           wave:  '1.0..1.'},
//!         {name: 'fx2_fifoaddr',       wave:  'x.=...x.', data: ["2'b01 (EP4 FIFO)"]},
//!         {name: 'command_rx_valid',   wave:  '0..1..0'},
//!         {name: 'command_rx_data',    wave:  '0..===0', data: ["word 0", "word 1", "word n"]},
//!       {}
//!     ],
//!     head:{tick:0},
//!     config: { hscale: 2 }
//! }

module fx2_controller(
        input  wire         reset,
        input  wire         fx2_ifclk,      //! CY68013 interface clock

        //! @virtualbus fx2_flags @dir out Status flags for the FX2 FIFO interface 
        //! CY68013 EP2 empty flag (active low)
        input  wire         fx2_flaga,     
        //! CY68013 EP4 empty flag (active low)
        input  wire         fx2_flagb,    
        //! CY68013 EP6 full flag (active low)  
        input  wire         fx2_flagc,      
        //! @end CY68013 EP8 full flag (active low)
        input  wire         fx2_flagd,      

        //! @virtualbus fx2_control @dir out Pins that control the FX2 FIFO interface 
        //! CY68013 read control (active low)
        output reg          fx2_slrd = 1,       
        //! CY68013 write control (active low)
        output reg          fx2_slwr = 1,       
        //! CY68013 data output enable (active low)
        output reg          fx2_sloe = 1,      
        //! CY68013 packet end marker (active low - only used when sending data to the host)
        output reg          fx2_pktend = 1,     
        //! @end CY68013 FIFO Address <br><br>
        //! 2'b00: EP2 (bulk data from host) <br>
        //! 2'b01: EP4 (commands from host) <br>
        //! 2'b10: EP6 (bulk data to host) <br>
        //! 2'b11: EP8 (commands to host)
        output reg   [1:0]  fx2_fifoaddr,   

        input  wire [15:0]  fx2_fd_in,         //! CY68013 FIFO data bus
        output reg  [15:0]  fx2_fd_out = 0,        //! CY68013 FIFO data bus

        //! @virtualbus command_rx @dir out Interface to receive commands/metadata from the host (priority 0)
        //! Data bus
        output reg  [15:0]  command_rx_data = 0,     
        //! Request signal
        output reg          command_rx_req = 0,        
        //! Acknowledge signal
        input  wire         command_rx_ack,
        //! @end Data is valid (active high)
        output reg          command_rx_valid = 0
        
        // //! @virtualbus command_tx @dir in Interface to transmit commands/metadata to the host (priority 1)
        // //! Data bus
        // input  wire  [15:0] command_tx_data,
        // //! Request signal
        // input  wire         command_tx_req,
        // //! @end Acknowledge signal
        // output reg          command_tx_ack,
        
        // //! @virtualbus bulk_rx @dir in Interface to receive bulk data from the host (priority 2)
        // //! Data bus
        // output reg [15:0]   bulk_rx_data,
        // //! Request signal
        // input  wire         bulk_rx_req,
        // //! Acknowledge signal
        // output reg          bulk_rx_ack,
        // //! @end Data is valid (active high)
        // output reg          bulk_rx_valid,
        
        // //! @virtualbus bulk_tx @dir in Interface to transmit bulk data to the host (priority 3)
        // //! Data bus
        // input  wire  [15:0] bulk_tx_data,
        // //! Request signal
        // input  wire         bulk_tx_req,
        // //! @end Acknowledge signal
        // output reg          bulk_tx_ack
    );

    
    // reg [15:0] data_reg;    //! Temporary read/write data storage
    // reg usb_fd_en;          //! Tri-state output enable for `usb_fd`

    // assign usb_fd = usb_fd_en ? data_reg : 16'bz;

    
    localparam IDLE     = 4'b0001;
    localparam READING  = 4'b0100;
    localparam WRITING  = 4'b1000;

    localparam BLK_RX_ADDR = 2'b00; //! EP2 FIFO address (bulk data from host)
    localparam CMD_RX_ADDR = 2'b01; //! EP4 FIFO address (commands from host)
    localparam BLK_TX_ADDR = 2'b10; //! EP6 FIFO address (bulk data to host)
    localparam CMD_TX_ADDR = 2'b11; //! EP8 FIFO address (commands to host)

    reg [3:0] main_state = IDLE;
    
    // reg command_rx_busy = 0;

    // assign command_rx_req = fx2_flagd | command_rx_busy; // automatically send a request when EP4 has bytes in it  
    wire command_rx_stopped =  command_rx_req & ~command_rx_ack; 
    wire command_rx_active  =  command_rx_req &  command_rx_ack;

    always @(posedge fx2_ifclk) begin : main_state_machine
        if (reset) begin
            fx2_fifoaddr <= CMD_TX_ADDR;
            fx2_sloe <= 1;
            fx2_slrd <= 1;
            fx2_slwr <= 1;        
            fx2_pktend <= 1;   
            main_state = IDLE;         
        end else begin
            // Defaults
            // fx2_fifoaddr <= CMD_TX_ADDR;
            // fx2_sloe <= 1;
            // fx2_slrd <= 1;
            fx2_slwr <= 1;        
            fx2_pktend <= 1;

            case (main_state)
                IDLE: begin                
                    if (fx2_flagb) begin
                        command_rx_req <= 1;
                    end 
                    
                    if (command_rx_active) begin
                        main_state <= READING;
                        fx2_fifoaddr <= CMD_RX_ADDR;
                    end 
                    // else if (command_tx_req) begin
                    //     main_state <= WRITING;
                    //     fx2_fifoaddr <= CMD_TX_ADDR;
                    // end
                    // else if (bulk_rx_req) begin
                    //     main_state <= READING;
                    //     fx2_fifoaddr <= BLK_RX_ADDR;
                    // end
                    // else if (bulk_tx_req) begin
                    //     main_state <= WRITING;
                    //     fx2_fifoaddr <= BLK_TX_ADDR;
                    // end
                end
                READING: begin                    
                    if (fx2_sloe) begin // Make sure the output enable is active
                        fx2_sloe <= 0;                    
                    end else begin // wait 1 cycle to read the first word before incrementing the rd pointer
                        command_rx_valid <= 1;

                        if (fx2_slrd) 
                            fx2_slrd <= 0;
                    end 
                    
                    if (command_rx_stopped | ~fx2_flagb) begin   // if the receiver stops OR the FIFO is empty, stop reading and go back to idle
                        fx2_sloe <= 1;
                        fx2_slrd <= 1;
                        fx2_fifoaddr <= CMD_TX_ADDR;
                        
                        command_rx_valid <= 0;                    
                        command_rx_req <= 0;
                        main_state <= IDLE;
                    end 
                end
                // WRITING: begin
                //     if (~fx2_flagb) begin   // FIFO is full, stop writing
                //         main_state <= IDLE;
                //     end      
                    
                // end
                default: main_state <= IDLE;
            endcase
        end
    end
    
    // localparam READ_START = 3'b001;

    // reg [2:0] read_state = READ_START;

    // reg [15:0] data_rx_reg; 
    // reg [15:0] data_tx_reg;

    // always @(posedge fx2_ifclk) begin : read_state_machine
    //     read_state = READ_START;

    //     if (main_state == READING) begin
    //         case (read_state)
    //             READ_START: begin
                    
    //             end
    //             //default: read_state = READ_START;
    //         endcase
    //     end
    // end
    
    // always @(posedge fx2_ifclk) begin : write_state_machine
    //     if (main_state == WRITING) begin
            
    //     end
    // end


    always @* begin : rd_wr_data_mux
        command_rx_data = command_rx_valid ? fx2_fd_in : 16'h0000;
    end

endmodule