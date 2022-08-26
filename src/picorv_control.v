`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/18/2019 09:26:38 AM
// Design Name: 
// Module Name: picorv_control
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

`define PICORV_STATE_NUM    3
`define PICORV_RUN      3'b001
`define PICORV_LOAD     3'b010
`define PICORV_RESET    3'b100
`define MEM_TOP     32'h0000_4000
`define SERIAL_REG  32'hFF00_0000
`define SWITCH_REG  32'hFFF0_0000
`define LED_REG     32'hFFFF_0000
    
module picorv_control(
        input   wire        picorv_clk,
        input   wire [31:0] picorv_mem_addr,
        input   wire [31:0] picorv_mem_wdata,
        input   wire [ 3:0] picorv_mem_wstrb,
        output  wire [31:0] picorv_mem_rdata,
        output  reg         picorv_rst_n,
        output  wire        picorv_mem_ready,
        input   wire        picorv_mem_valid,
        
        output  wire [31:0] mem_addr,
        output  wire [31:0] mem_wdata,
        output  wire [ 3:0] mem_wstrb,
        input   wire [31:0] mem_rdata,        
        
        input   wire        mem_fifo_empty,
        input   wire [ 7:0] mem_fifo_out,
        output  reg         mem_fifo_rd_en,
        input   wire        mem_fifo_rd_rst_busy,
        
        input   wire        state_fifo_empty,
        input   wire [ 7:0] state_fifo_out,
        output  reg         state_fifo_rd_en,
        input   wire        state_fifo_rd_rst_busy,
        
        input   wire        serial_fifo_full,
        output  reg  [31:0] serial_fifo_in,
        output  reg         serial_fifo_wr_en,
        input   wire        serial_fifo_wr_rst_busy,
        
        input   wire        sw1, /* DIP switch J16 */
        input   wire        sw2, /* DIP switch K16 */
        input   wire        sw3, /* DIP switch K15 */
        input   wire        sw4, /* DIP Switch L14 */
        
        input   wire        pushbutton, /* Pushbutton SW4, connected to R1 */
        
        output  reg         led2, /* green LED */
        output  reg         led3, /* blue LED */
        
        input   wire        reset
    );
    
    reg [31:0] temp_read_reg;
    wire [31:0] wstrb;
    assign wstrb = (picorv_mem_addr < `MEM_TOP) ? picorv_mem_wstrb : 0;     // If something is trying to write beyond main memory, disable the write strobe (it's probably just going to mess something up)
     
    reg [1:0] picorv_mem_ready_dly;
    assign picorv_mem_ready = picorv_mem_ready_dly[1];  // The BRAM has a 2 cycle latency, so we have to delay access
    assign picorv_mem_rdata = (picorv_mem_addr < `MEM_TOP) ? mem_rdata : temp_read_reg; // If something is trying to read beyond main memory, provide some other memory instead
    
    reg [`PICORV_STATE_NUM-1:0] picorv_core_state = `PICORV_RESET;
    
	reg  [ 3:0] code_wstrb = 0;	
    reg  [31:0] word_buffer = 0;
    reg  [31:0] byte_index = 0;
    wire [31:0] code_address;
    assign code_address = byte_index - 32'h0000_0004;
    wire at_mem_top;
    assign at_mem_top = (byte_index >= `MEM_TOP);
    
    // Only allow the picorv core access to main memory when in run state, otherwise set things up to load memory
    assign mem_wstrb = (picorv_core_state == `PICORV_RUN) ? wstrb               : code_wstrb; 
    assign mem_addr  = (picorv_core_state == `PICORV_RUN) ? picorv_mem_addr     : code_address; 
    assign mem_wdata = (picorv_core_state == `PICORV_RUN) ? picorv_mem_wdata    : word_buffer; 
        
    // Quasi next state logic (really driven by the USB logic)
    always @ (posedge picorv_clk) begin
        state_fifo_rd_en <= 0;
        picorv_core_state <= picorv_core_state;
        
        if (~state_fifo_empty && ~state_fifo_rd_rst_busy) begin
            state_fifo_rd_en <= 1;
            picorv_core_state <= state_fifo_out[`PICORV_STATE_NUM-1:0];
        end
    end
    
    // State logic
    always @ (negedge picorv_clk) begin
        mem_fifo_rd_en <= 0;
        code_wstrb <= 0;
        
        picorv_mem_ready_dly[0] <= 0;
        picorv_mem_ready_dly[1] <= picorv_mem_ready_dly[0];
        
        serial_fifo_wr_en <= 0;
        
//        if (reset) begin
//            serial_fifo_wr_en <= 0;
//            temp_read_reg <= 0;
//            byte_index <= 0;  
//            picorv_rst_n <= 0;
//            serial_fifo_in <= 0;
//            picorv_mem_ready_dly <= 0;
//        end else begin
            case (picorv_core_state)
                `PICORV_RUN   : begin
                    byte_index <= 0;  
                    picorv_rst_n <= 1;
                    
                    if (picorv_mem_valid && !picorv_mem_ready_dly[0]) begin
                        picorv_mem_ready_dly[0] <= 1;
                        
                        case (picorv_mem_addr) 
                            `SERIAL_REG : begin
                                temp_read_reg <= serial_fifo_in;
                                
                                if (picorv_mem_wstrb[0] && ~serial_fifo_full && ~serial_fifo_wr_rst_busy) begin
                                    serial_fifo_wr_en <= 1;
                                    serial_fifo_in[ 7: 0] <= picorv_mem_wdata[ 7: 0];
                                end 
                                
                                if (picorv_mem_wstrb[1] && ~serial_fifo_full && ~serial_fifo_wr_rst_busy) begin
                                    serial_fifo_wr_en <= 1;
                                    serial_fifo_in[15: 8] <= picorv_mem_wdata[15: 8];
                                end 
                                
                                if (picorv_mem_wstrb[2] && ~serial_fifo_full && ~serial_fifo_wr_rst_busy) begin
                                    serial_fifo_wr_en <= 1;
                                    serial_fifo_in[23:16] <= picorv_mem_wdata[23:16];
                                end 
                                
                                if (picorv_mem_wstrb[3] && ~serial_fifo_full && ~serial_fifo_wr_rst_busy) begin
                                    serial_fifo_wr_en <= 1;
                                    serial_fifo_in[31:24] <= picorv_mem_wdata[31:24];
                                end 
                            end
                            
                            `SWITCH_REG :  temp_read_reg <= {27'b0, pushbutton, sw4, sw3, sw2, sw1};
                            
                            `LED_REG    :  begin                 
                                temp_read_reg <= {30'b0, led3, led2};
                                
                                if (picorv_mem_wstrb[0]) begin
                                    led2 <= picorv_mem_wdata[0];
                                    led3 <= picorv_mem_wdata[1];
                                end
                            end
                            
                            default : temp_read_reg <= 0;
                        endcase
                    end
                end
                
                `PICORV_RESET : begin
                    byte_index <= 0;  
                    picorv_rst_n <= 0;
                    serial_fifo_in <= 0;
                end
                
                `PICORV_LOAD  : begin
                    picorv_rst_n <= 0;
                    
                    if (~mem_fifo_empty && ~mem_fifo_rd_rst_busy) begin
                        mem_fifo_rd_en <= 1;
                        byte_index <= byte_index + 1;
                        serial_fifo_wr_en <= 1;
                        serial_fifo_in <= byte_index + 1;
                       
                        case (byte_index[1:0])
                            2'd0    : word_buffer[ 7: 0] <= mem_fifo_out;
                            2'd1    : word_buffer[15: 8] <= mem_fifo_out;
                            2'd2    : word_buffer[23:16] <= mem_fifo_out;
                            2'd3    : begin
                                word_buffer[31:24] <= mem_fifo_out;
                                if (at_mem_top) 
                                    code_wstrb <= 4'b0000; // Keep reading from the FIFO, but don't write to memory
                                else
                                    code_wstrb <= 4'b1111;
                            end 
                        endcase
                    end      
                end
            endcase
		end
//    end
    
endmodule
