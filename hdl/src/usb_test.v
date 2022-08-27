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
        
        input  wire         usb_flaga,      //! CY68013 EP2 FIFO empty flag; 1:not empty; 0: empty
        input  wire         usb_flagb,      //! CY68013 EP4 FIFO empty flag; 1:not empty; 0: empty
        input  wire         usb_flagc,      //! CY68013 EP6 FIFO full flag; 1:not full; 0: full
        output reg          usb_slcs,       //! CY68013 chip select (active low)
        output reg          usb_slrd,       //! CY68013 read control (active low)
        output reg          usb_slwr,       //! CY68013 write control (active low)
        output reg          usb_sloe,       //! CY68013 data output enable (active low)
        output reg   [1:0]  usb_fifoaddr,   //! CY68013 FIFO Address
        inout  wire [15:0]  usb_fd,         //! CY68013 FIFO data bus

        output reg clk_dup,             //! Duplicate for debugging
        output reg usb_sloe_dup,        //! Duplicate for debugging
        output reg usb_slrd_dup,        //! Duplicate for debugging
        output reg usb_slwr_dup,        //! Duplicate for debugging
        output wire [15:0] usb_fd_dup,  //! Duplicate for debugging
        output reg usb_flaga_dup,       //! Duplicate for debugging
        output reg usb_flagb_dup,       //! Duplicate for debugging
        output reg usb_flagc_dup        //! Duplicate for debugging

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
        clk_dup = clk;
        usb_sloe_dup = usb_sloe;
        usb_slrd_dup = usb_slrd;
        usb_slwr_dup = usb_slwr;
        usb_flaga_dup = usb_flaga;
        usb_flagb_dup = usb_flagb;
        usb_flagc_dup = usb_flagc;
    end

    reg [15:0] data_reg;    //! Temporary read/write data storage

    reg bus_busy;   //! Active high when the module is sending or receiving data
    wire access_req = usb_flaga & usb_flagc & (bus_busy == 1'b0); //! Active high when it's possible to read or write to/from the FIFO
    reg usb_fd_en;  //! Tri-state output enable for `usb_fd`

    // Possible states
    `define IDLE		6'b000001
    `define EP2_RD_CMD	6'b000010
    `define EP2_RD_DATA 6'b000100
    `define EP2_RD_OVER 6'b001000
    `define EP6_WR_CMD  6'b010000
    `define EP6_WR_OVER 6'b100000

    reg [5:0] usb_state;    //! State machine register
    reg [4:0] delay_count;  //! Used to delay state changes

    always @(posedge clk or negedge reset_n)
    begin : rd_wr_state_machine
        if (~reset_n)
        begin
            usb_fifoaddr <= 2'b00;
            usb_slcs <= 1'b0;
            usb_sloe <= 1'b1;
            usb_slrd <= 1'b1;
            usb_slwr <= 1'b1;
            usb_fd_en <= 1'b0;
            usb_state <= `IDLE;
        end
        else
        begin
            case(usb_state)
                `IDLE:
                begin
                    usb_fifoaddr <= 2'b00;
                    delay_count <= 0;
                    usb_fd_en <= 1'b0;
                    if (access_req == 1'b1)
                    begin
                        usb_state <= `EP2_RD_CMD;
                        bus_busy <= 1'b1;
                    end
                    else
                    begin
                        bus_busy <= 1'b0;
                        usb_state <= `IDLE;
                    end
                end
                `EP2_RD_CMD:
                begin      //EP2 FIFO Read Command
                    if(delay_count == 2)
                    begin
                        usb_slrd <= 1'b1;
                        usb_sloe <= 1'b0;
                        delay_count <= delay_count + 1'b1;
                    end
                    else if(delay_count == 8)
                    begin
                        usb_slrd <= 1'b0;
                        usb_sloe <= 1'b0;
                        delay_count <= 0;
                        usb_state <= `EP2_RD_DATA;
                    end
                    else
                    begin
                        delay_count <= delay_count + 1'b1;
                    end
                end
                `EP2_RD_DATA:
                begin      //EP2 FIFO Read Data
                    if(delay_count == 8)
                    begin
                        usb_slrd <= 1'b1;
                        usb_sloe <= 1'b0;
                        delay_count <= 0;
                        usb_state <= `EP2_RD_OVER;
                        data_reg <= usb_fd;
                    end
                    else
                    begin
                        usb_slrd <= 1'b0;
                        usb_sloe <= 1'b0;
                        delay_count <= delay_count + 1'b1;
                    end
                end
                `EP2_RD_OVER:
                begin
                    if(delay_count == 4)
                    begin
                        usb_slrd <= 1'b1;
                        usb_sloe <= 1'b1;
                        delay_count <= 0;
                        usb_fifoaddr <= 2'b10;
                        usb_state <= `EP6_WR_CMD;
                    end
                    else
                    begin
                        usb_slrd <= 1'b1;
                        usb_sloe <= 1'b0;
                        delay_count <= delay_count + 1'b1;
                    end
                end
                `EP6_WR_CMD:
                begin
                    if(delay_count == 8)
                    begin
                        usb_slwr <= 1'b1;
                        delay_count <= 0;
                        usb_state <= `EP6_WR_OVER;
                    end
                    else
                    begin
                        usb_slwr <= 1'b0;
                        usb_fd_en <= 1'b1;
                        delay_count <= delay_count + 1'b1;
                    end
                end
                `EP6_WR_OVER:
                begin
                    if(delay_count == 4)
                    begin
                        usb_fd_en <= 1'b0;
                        bus_busy <= 1'b0;
                        delay_count <= 0;
                        usb_state <= `IDLE;
                    end
                    else
                    begin
                        delay_count <= delay_count + 1'b1;
                    end
                end
                default:
                    usb_state <= `IDLE;
            endcase
        end
    end

    assign usb_fd = usb_fd_en ? data_reg : 16'bz;

endmodule
