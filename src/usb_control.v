`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/18/2019 01:53:10 PM
// Design Name: 
// Module Name: usb_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`default_nettype none 
//Defines how long after we keep data-bus active - shouldn't need to change
`define REG_RDDLY_LEN 3

`define PICORV_STATE_NUM    3
`define PICORV_RUN      3'b001
`define PICORV_LOAD     3'b010
`define PICORV_RESET    3'b100
`define MEM_TOP 32'h0000_4000

`define USB_STATUS_REG      21'h0000
`define PICORV_STATE_REG    21'h0010
`define PICORV_SERIAL_REG   21'h0020
`define PICORV_MEM_REG      21'h0100

module usb_control(
        input   wire        clk_usb,  // Raw clock signal from external USB connections
        inout   wire [ 7:0] data,     // Data bus
        input   wire [20:0] addr,     // Address bus
        input   wire        rd_en,    // !RD: low when addr valid for read
        input   wire        wr_en,    // !WR: low when data+addr valid for write
        input   wire        cen,      // !CE: not used here
        input   wire        trigger,  // High when trigger requested
        
        input   wire        mem_fifo_full,
        output  reg  [ 7:0] mem_fifo_in,
        output  reg         mem_fifo_wr_en,
        input   wire        mem_fifo_wr_rst_busy,
        
        input   wire        state_fifo_full,
        output  reg  [ 7:0] state_fifo_in,
        output  reg         state_fifo_wr_en,
        input   wire        state_fifo_wr_rst_busy,
        
        input   wire        serial_fifo_empty,
        input   wire [31:0] serial_fifo_out,
        output  reg        serial_fifo_rd_en,
        input   wire        serial_fifo_rd_rst_busy,
        
        output  wire        usb_heartbeat,
        input   wire        reset
    );
    
    reg [`PICORV_STATE_NUM-1:0] picorv_state = `PICORV_RESET;
    wire [7:0] usb_status;
    assign usb_status = {1'b0, serial_fifo_empty, mem_fifo_full, state_fifo_full, 1'b0, serial_fifo_rd_rst_busy, mem_fifo_wr_rst_busy, state_fifo_wr_rst_busy};
    
    wire is_valid_mem_addr;              // Whether the address is in the valid range 
    assign is_valid_mem_addr = ((addr >= `PICORV_MEM_REG) && (addr < (`PICORV_MEM_REG + `MEM_TOP))) ? 1 : 0; 
    
    reg oe;
    
    reg [7:0] data_out;
    
    /* USB CLK Heartbeat */
    reg [24:0] usb_timer_heartbeat;
    always @(posedge clk_usb) begin
        usb_timer_heartbeat <= usb_timer_heartbeat +  25'd1;
    end
    
    assign usb_heartbeat = usb_timer_heartbeat[24];
    
    reg prev_wr_en;    
    wire negedge_wr_en;
    assign negedge_wr_en = prev_wr_en & ~wr_en;
    
    reg prev_rd_en;    
    wire negedge_rd_en;
    assign negedge_rd_en = prev_rd_en & ~rd_en;
           
    always @(negedge clk_usb) begin
        mem_fifo_wr_en <= 0;
        state_fifo_wr_en <= 0;
        
        oe <= wr_en & ~rd_en;
        prev_wr_en <= wr_en;
        
        if (negedge_wr_en) begin
            if (is_valid_mem_addr && ~mem_fifo_full && ~mem_fifo_wr_rst_busy) begin
                mem_fifo_wr_en <= 1;
                mem_fifo_in <= data;
            end
            
            if ((addr == `PICORV_STATE_REG) && ~state_fifo_full && ~state_fifo_wr_rst_busy)  begin
                state_fifo_wr_en <= 1;
                case (data[`PICORV_STATE_NUM-1:0]) 
                    `PICORV_RUN     : begin
                        state_fifo_in <= data;
                        picorv_state <= `PICORV_RUN;
                    end
                    `PICORV_LOAD    : begin
                        state_fifo_in <= data;
                        picorv_state <= `PICORV_LOAD;
                    end
                    `PICORV_RESET   : begin
                        state_fifo_in <= data;
                        picorv_state <= `PICORV_RESET;
                    end
                    default : begin
                        state_fifo_in <= {{(8-`PICORV_STATE_NUM){1'b0}}, `PICORV_RESET};
                        picorv_state <= `PICORV_RESET;
                    end
                endcase
            end
        end
    end
        
    always @(*) begin
        case (addr) 
            `USB_STATUS_REG     : data_out = usb_status;
            `PICORV_STATE_REG   : data_out = {{(8-`PICORV_STATE_NUM){1'b0}}, picorv_state};
            `PICORV_SERIAL_REG  : data_out = serial_fifo_out[ 7: 0];
            `PICORV_SERIAL_REG+1: data_out = serial_fifo_out[15: 8];
            `PICORV_SERIAL_REG+2: data_out = serial_fifo_out[23:16];
            `PICORV_SERIAL_REG+3: data_out = serial_fifo_out[31:24];
            default: data_out = 0;
        endcase
    end
    
    always @(posedge clk_usb) begin
        serial_fifo_rd_en <= 0;
        
        prev_rd_en <= rd_en;
        
        if (picorv_state == `PICORV_LOAD) begin
            // While loading memory, the serial "connection" to the picorv core is sending the number of bytes written
            // Constantly try to read from the FIFO to make sure the byte num is up-to-date
            if (~serial_fifo_empty && ~serial_fifo_rd_rst_busy) begin
                serial_fifo_rd_en <= 1;
            end   
        end
        
        if (negedge_rd_en) begin
            case (addr) 
                `PICORV_SERIAL_REG  : begin
                    if (~serial_fifo_empty && ~serial_fifo_rd_rst_busy) begin
                        serial_fifo_rd_en <= 1;
                    end                
                end
            endcase
        end
        
//  For some reason, the above code works, but this code doesn't.  As in, serial_fifo_rd_en is non-existant in the 
//  synthesized design if you use the code below.  I have no idea why, but it's probably stupid.
//
//        if (negedge_rd_en && (addr == `PICORV_SERIAL_REG)) begin
//            if (~serial_fifo_empty && ~serial_fifo_rd_rst_busy) begin
//                serial_fifo_rd_en <= 1;
//            end
//        end
    end
    
    assign data = oe ? data_out : 8'hZZ;
    
endmodule

