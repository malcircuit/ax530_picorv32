`timescale 10ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    usb_test
// Description: If the FIFO of EP2 is not empty and
//              the EP6 is not full, Read the 16bit data from EP2 FIFO
//              and send to EP6 FIFO.
//////////////////////////////////////////////////////////////////////////////////
module usb_test(
        input fpga_gclk,                       //FPGA Clock Input 50Mhz
        input reset_n,                         //FPGA Reset input
        output reg [1:0] usb_fifoaddr,         //CY68013 FIFO Address
        output reg usb_slcs,                   //CY68013 Chipset select
        output reg usb_sloe,                   //CY68013 Data output enable
        output reg usb_slrd,                   //CY68013 READ indication
        output reg usb_slwr,                   //CY68013 Write indication
        inout [15:0] usb_fd,                   //CY68013 Data
        input usb_flaga,                //CY68013 EP2 FIFO empty indication; 1:not empty; 0: empty
        input usb_flagb,               //CY68013 EP4 FIFO empty indication; 1:not empty; 0: empty
        input usb_flagc,                        //CY68013 EP6 FIFO full indication; 1:not full; 0: full


        output reg fpga_gclk_dup,                       //FPGA Clock Input 50Mhz
        //output reg reset_n_dup,                         //FPGA Reset input
        //output reg [1:0] usb_fifoaddr_dup,         //CY68013 FIFO Address
        //output reg usb_slcs_dup,                   //CY68013 Chipset select
        output reg usb_sloe_dup,                   //CY68013 Data output enable
        output reg usb_slrd_dup,                   //CY68013 READ indication
        output reg usb_slwr_dup,                   //CY68013 Write indication
        output wire [15:0] usb_fd_dup,                   //CY68013 Data
        output reg usb_flaga_dup,                //CY68013 EP2 FIFO empty indication; 1:not empty; 0: empty
        output reg usb_flagb_dup,               //CY68013 EP4 FIFO empty indication; 1:not empty; 0: empty
        output reg usb_flagc_dup                        //CY68013 EP6 FIFO full indication; 1:not full; 0: full

    );

    genvar n;
    generate
        for (n = 0; n < 16; n = n  +  1)
        begin : thing
            assign usb_fd_dup[n] = usb_fd[n] ? 1'b1 : 1'b0;
        end
    endgenerate

    always @*
    begin
        fpga_gclk_dup = fpga_gclk;
        //reset_n_dup = reset_n;
        //usb_slcs_dup = usb_slcs;
        usb_sloe_dup = usb_sloe;
        usb_slrd_dup = usb_slrd;
        usb_slwr_dup = usb_slwr;
        //usb_fifoaddr_dup = usb_fifoaddr;
        usb_flaga_dup = usb_flaga;
        usb_flagb_dup = usb_flagb;
        usb_flagc_dup = usb_flagc;
    end

    reg[15:0] data_reg;

    reg bus_busy;
    reg access_req;
    reg usb_fd_en;

    reg [4:0] usb_state;
    reg [4:0] i;

`define IDLE		6'b000001
`define EP2_RD_CMD	6'b000010
`define EP2_RD_DATA 6'b000100
`define EP2_RD_OVER 6'b001000
`define EP6_WR_CMD  6'b010000
`define EP6_WR_OVER 6'b100000

    /* Generate USB read/write access request*/
    always @(*)
    begin
        if (usb_flaga & usb_flagc & (bus_busy == 1'b0))
            access_req <= 1'b1;
        else
            access_req <= 1'b0;
    end


    always @(posedge fpga_gclk or negedge reset_n)
    begin
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
                    i <= 0;
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
                    if(i == 2)
                    begin
                        usb_slrd <= 1'b1;
                        usb_sloe <= 1'b0;
                        i <= i + 1'b1;
                    end
                    else if(i == 8)
                    begin
                        usb_slrd <= 1'b0;
                        usb_sloe <= 1'b0;
                        i <= 0;
                        usb_state <= `EP2_RD_DATA;
                    end
                    else
                    begin
                        i <= i + 1'b1;
                    end
                end
                `EP2_RD_DATA:
                begin      //EP2 FIFO Read Data
                    if(i == 8)
                    begin
                        usb_slrd <= 1'b1;
                        usb_sloe <= 1'b0;
                        i <= 0;
                        usb_state <= `EP2_RD_OVER;
                        data_reg <= usb_fd;
                    end
                    else
                    begin
                        usb_slrd <= 1'b0;
                        usb_sloe <= 1'b0;
                        i <= i + 1'b1;
                    end
                end
                `EP2_RD_OVER:
                begin
                    if(i == 4)
                    begin
                        usb_slrd <= 1'b1;
                        usb_sloe <= 1'b1;
                        i <= 0;
                        usb_fifoaddr <= 2'b10;
                        usb_state <= `EP6_WR_CMD;
                    end
                    else
                    begin
                        usb_slrd <= 1'b1;
                        usb_sloe <= 1'b0;
                        i <= i + 1'b1;
                    end
                end
                `EP6_WR_CMD:
                begin
                    if(i == 8)
                    begin
                        usb_slwr <= 1'b1;
                        i <= 0;
                        usb_state <= `EP6_WR_OVER;
                    end
                    else
                    begin
                        usb_slwr <= 1'b0;
                        usb_fd_en <= 1'b1;
                        i <= i + 1'b1;
                    end
                end
                `EP6_WR_OVER:
                begin
                    if(i == 4)
                    begin
                        usb_fd_en <= 1'b0;
                        bus_busy <= 1'b0;
                        i <= 0;
                        usb_state <= `IDLE;
                    end
                    else
                    begin
                        i <= i + 1'b1;
                    end
                end
                default:
                    usb_state <= `IDLE;
            endcase
        end
    end

    assign usb_fd = usb_fd_en ? data_reg : 16'bz;

endmodule
