`timescale 1ns / 1ps
`default_nettype none

module fx2_sim(
        output reg           fx2_ifclk = 1,      //! CY68013 interface clock

        //! @virtualbus fx2_flags @dir out Status flags for the FX2 FIFO interface
        //! CY68013 EP2 empty flag (active low)
        output wire          fx2_flaga,
        //! CY68013 EP4 empty flag (active low)
        output wire          fx2_flagb,
        //! CY68013 EP6 full flag (active low)
        output wire          fx2_flagc,
        //! @end CY68013 EP8 full flag (active low)
        output wire          fx2_flagd,

        //! @virtualbus fx2_control @dir out Pins that control the FX2 FIFO interface
        //! CY68013 read control (active low)
        input  wire          fx2_slrd,
        //! CY68013 write control (active low)
        input  wire          fx2_slwr,
        //! CY68013 data output enable (active low)
        input  wire          fx2_sloe,
        //! CY68013 packet end marker (active low - only used when sending data to the host)
        input  wire          fx2_pktend,
        //! @end CY68013 FIFO Address <br><br>
        //! 2'b00: EP2 (bulk data from host) <br>
        //! 2'b01: EP4 (commands from host) <br>
        //! 2'b10: EP6 (bulk data to host) <br>
        //! 2'b11: EP8 (commands to host)
        input  wire   [1:0]  fx2_fifoaddr,
        inout  wire  [15:0]  fx2_fd         //! CY68013 FIFO data bus
    );
    //! 48 MHz clock generator
    always #10.417
    begin : ifclk_gen
        fx2_ifclk <= ~fx2_ifclk;
    end

    reg  [15:0] fd_out;

    localparam EP2_ADDR = 2'b00;
    localparam EP4_ADDR = 2'b01;
    localparam EP6_ADDR = 2'b10;
    localparam EP8_ADDR = 2'b11;

    localparam EP2_SIZE = 1024;
    localparam EP4_SIZE =  512;
    localparam EP6_SIZE = 1024;
    localparam EP8_SIZE =  512;

    reg [8*EP2_SIZE - 1:0] ep2 = 0;
    reg [8*EP2_SIZE - 1:0] ep4 = 0;
    reg [8*EP6_SIZE - 1:0] ep6 = 0;
    reg [8*EP6_SIZE - 1:0] ep8 = 0;

    reg [9:0] ep2_ptr = 0;
    reg [9:0] ep4_ptr = 0;
    reg [9:0] ep6_ptr = 0;
    reg [9:0] ep8_ptr = 0;

    assign fx2_flaga = (ep2_ptr == 0) ? 1'b0 : 1'b1;
    assign fx2_flagb = (ep4_ptr == 0) ? 1'b0 : 1'b1;
    assign fx2_flagc = (ep6_ptr >= EP6_SIZE) ? 1'b0 : 1'b1;
    assign fx2_flagd = (ep8_ptr >= EP8_SIZE) ? 1'b0 : 1'b1;

    function [15:0] fifo_ptr_val(input [8*EP2_SIZE - 1:0] fifo, input [9:0] fifo_ptr);
        begin
            fifo_ptr_val = fifo[(fifo_ptr*8 - 1) -: 16];
        end
    endfunction

    // Function to deal with the edge case when there is an odd number of bytes in the FIFO
    function [15:0] fd_value(input [8*EP2_SIZE - 1:0] fifo, input [9:0] fifo_ptr);
        begin
            if (fifo_ptr == 1)
                fd_value = {8'h00, fifo[(fifo_ptr*8 - 1) -: 8]};
            else
                fd_value = fifo_ptr_val(fifo, fifo_ptr);
        end
    endfunction

    assign fx2_fd = fx2_sloe ? 16'hZZZZ : fd_out;
    
    //! Determines what is output when the sloe signal goes active
    always @(*)
    begin : output_control
        case (fx2_fifoaddr)
            // EP2_ADDR: fd_out = (ep2_ptr == 1) ? {8'h00, ep2[(ep2_ptr*8 - 1) -: 8]} : ep2[(ep2_ptr*8 - 1) -: 16];
            // EP4_ADDR: fd_out = (ep4_ptr == 1) ? {8'h00, ep4[(ep4_ptr*8 - 1) -: 8]} : ep4[(ep4_ptr*8 - 1) -: 16];
            EP2_ADDR: fd_out = fd_value(ep2, ep2_ptr);
            EP4_ADDR: fd_out = fd_value(ep4, ep4_ptr);
            default:  fd_out = 16'h0000;
        endcase
    end

    // Increment an OUT fifo pointer, and assert the full flag if appropriate
    task fifo_write(
        input [8*EP2_SIZE - 1:0] fifo,
        input [9:0] fifo_ptr_in,
        output [9:0] fifo_ptr_out,
        input [9:0] fifo_limit
        );

        begin
            fifo[fifo_ptr_in*8 -: 16] <= fx2_fd;
            fifo_ptr_out <= fifo_ptr_in + 2;

            if (fifo_ptr_in >= (fifo_limit - 2))
                fifo_ptr_out <= fifo_limit; // Don't let the pointer exceed the fifo size
        end
    endtask

    //! Determines where data goes when either reading or writing
    always @(posedge fx2_ifclk)
    begin : fifo_data_switch
        if (~fx2_slrd & fx2_slwr)
        begin
            case (fx2_fifoaddr)
                EP2_ADDR: ep2_ptr <= (ep2_ptr <= 2) ? 0 : ep2_ptr - 2;
                EP4_ADDR: ep4_ptr <= (ep4_ptr <= 2) ? 0 : ep4_ptr - 2;
            endcase
        end

        if (fx2_slrd & ~fx2_slwr)
        begin
            case (fx2_fifoaddr)
                EP6_ADDR:
                    fifo_write(ep6, ep6_ptr, ep6_ptr, EP6_SIZE);
                EP8_ADDR:
                    fifo_write(ep8, ep8_ptr, ep8_ptr, EP8_SIZE);
            endcase
        end
    end

    
    function automatic [15:0] crc;
        input [15:0] crcIn;
        input [15:0] data;
        begin
            crc[0] = (crcIn[0] ^ crcIn[4] ^ crcIn[8] ^ crcIn[11] ^ crcIn[12] ^ data[0] ^ data[4] ^ data[8] ^ data[11] ^ data[12]);
            crc[1] = (crcIn[1] ^ crcIn[5] ^ crcIn[9] ^ crcIn[12] ^ crcIn[13] ^ data[1] ^ data[5] ^ data[9] ^ data[12] ^ data[13]);
            crc[2] = (crcIn[2] ^ crcIn[6] ^ crcIn[10] ^ crcIn[13] ^ crcIn[14] ^ data[2] ^ data[6] ^ data[10] ^ data[13] ^ data[14]);
            crc[3] = (crcIn[3] ^ crcIn[7] ^ crcIn[11] ^ crcIn[14] ^ crcIn[15] ^ data[3] ^ data[7] ^ data[11] ^ data[14] ^ data[15]);
            crc[4] = (crcIn[4] ^ crcIn[8] ^ crcIn[12] ^ crcIn[15] ^ data[4] ^ data[8] ^ data[12] ^ data[15]);
            crc[5] = (crcIn[0] ^ crcIn[4] ^ crcIn[5] ^ crcIn[8] ^ crcIn[9] ^ crcIn[11] ^ crcIn[12] ^ crcIn[13] ^ data[0] ^ data[4] ^ data[5] ^ data[8] ^ data[9] ^ data[11] ^ data[12] ^ data[13]);
            crc[6] = (crcIn[1] ^ crcIn[5] ^ crcIn[6] ^ crcIn[9] ^ crcIn[10] ^ crcIn[12] ^ crcIn[13] ^ crcIn[14] ^ data[1] ^ data[5] ^ data[6] ^ data[9] ^ data[10] ^ data[12] ^ data[13] ^ data[14]);
            crc[7] = (crcIn[2] ^ crcIn[6] ^ crcIn[7] ^ crcIn[10] ^ crcIn[11] ^ crcIn[13] ^ crcIn[14] ^ crcIn[15] ^ data[2] ^ data[6] ^ data[7] ^ data[10] ^ data[11] ^ data[13] ^ data[14] ^ data[15]);
            crc[8] = (crcIn[3] ^ crcIn[7] ^ crcIn[8] ^ crcIn[11] ^ crcIn[12] ^ crcIn[14] ^ crcIn[15] ^ data[3] ^ data[7] ^ data[8] ^ data[11] ^ data[12] ^ data[14] ^ data[15]);
            crc[9] = (crcIn[4] ^ crcIn[8] ^ crcIn[9] ^ crcIn[12] ^ crcIn[13] ^ crcIn[15] ^ data[4] ^ data[8] ^ data[9] ^ data[12] ^ data[13] ^ data[15]);
            crc[10] = (crcIn[5] ^ crcIn[9] ^ crcIn[10] ^ crcIn[13] ^ crcIn[14] ^ data[5] ^ data[9] ^ data[10] ^ data[13] ^ data[14]);
            crc[11] = (crcIn[6] ^ crcIn[10] ^ crcIn[11] ^ crcIn[14] ^ crcIn[15] ^ data[6] ^ data[10] ^ data[11] ^ data[14] ^ data[15]);
            crc[12] = (crcIn[0] ^ crcIn[4] ^ crcIn[7] ^ crcIn[8] ^ crcIn[15] ^ data[0] ^ data[4] ^ data[7] ^ data[8] ^ data[15]);
            crc[13] = (crcIn[1] ^ crcIn[5] ^ crcIn[8] ^ crcIn[9] ^ data[1] ^ data[5] ^ data[8] ^ data[9]);
            crc[14] = (crcIn[2] ^ crcIn[6] ^ crcIn[9] ^ crcIn[10] ^ data[2] ^ data[6] ^ data[9] ^ data[10]);
            crc[15] = (crcIn[3] ^ crcIn[7] ^ crcIn[10] ^ crcIn[11] ^ data[3] ^ data[7] ^ data[10] ^ data[11]);
        end
    endfunction

    localparam DATA_PACKET = 6'b100000;

    task automatic send_packet(
        input [1:0] fifo_addr,
        input [8*EP2_SIZE - 1:0] packet,
        input [9:0] len
        );

        begin
            ep4[0] <= {DATA_PACKET, len};

            ep4_ptr <= 1;
        end
    endtask

    initial
    begin
        #500;
        // send_bytes(EP4_ADDR,  "Hello", 5);
        ep4[8*5 - 1:0] <= "Hello";
        ep4_ptr <= 5;
        #1000;
        // send_bytes(EP4_ADDR, "World!", 6);        
        ep4[8*6 - 1:0] <= "World!";
        ep4_ptr <= 6;
        #500;
        $stop();
    end


endmodule
