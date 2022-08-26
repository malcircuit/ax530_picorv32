`timescale 1ns / 1ps
`default_nettype none 

module ax530_top(
    

input wire clk,                       //FPGA Clock Input 50Mhz
        input wire reset_n,                         //FPGA Reset input
        output reg [1:0] usb_fifoaddr,         //CY68013 FIFO Address
        output reg usb_slcs,                   //CY68013 Chipset select
        output reg usb_sloe,                   //CY68013 Data output enable
        output reg usb_slrd,                   //CY68013 READ indication
        output reg usb_slwr,                   //CY68013 Write indication
        inout [15:0] usb_fd,                   //CY68013 Data
        input usb_flaga,                //CY68013 EP2 FIFO empty indication; 1:not empty; 0: empty
        input usb_flagb,               //CY68013 EP4 FIFO empty indication; 1:not empty; 0: empty
        input usb_flagc,                        //CY68013 EP6 FIFO full indication; 1:not full; 0: full
		  );
		  
		  endmodule