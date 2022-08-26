/* 
ChipWhisperer Artix Target - Example of connections between example registers
and rest of system.

Copyright (c) 2016, NewAE Technology Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted without restriction. Note that modules within
the project may have additional restrictions, please carefully inspect
additional licenses.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of NewAE Technology Inc.
*/

`timescale 1ns / 1ps
`default_nettype none 

`include "board.v"

module cw305_top(
    
    /****** USB Interface ******/
    input wire        usb_clk, /* Clock */
    inout wire [7:0]  usb_data,/* Data for write/read */
    input wire [20:0] usb_addr,/* Address data */
    input wire        usb_rdn, /* !RD, low when addr valid for read */
    input wire        usb_wrn, /* !WR, low when data+addr valid for write */
    input wire        usb_cen, /* !CE not used */
    input wire        usb_trigger, /* High when trigger requested */
    
    /****** Buttons/LEDs on Board ******/
    input wire sw1, /* DIP switch J16 */
    input wire sw2, /* DIP switch K16 */
    input wire sw3, /* DIP switch K15 */
    input wire sw4, /* DIP Switch L14 */
    
    input wire pushbutton, /* Pushbutton SW4, connected to R1 */
    
    output wire led1, /* red LED */
    output wire led2, /* green LED */
    output wire led3,  /* blue LED */
    
    /****** PLL ******/
    input wire pll_clk1 //PLL Clock Channel #1
    
    );
    
    reg reset_usb;
    reg reset_pll;
    wire reset;
    assign reset = reset_usb || reset_pll;
    reg [7:0] reset_usb_dly_count = 0;
    reg [7:0] reset_pll_dly_count = 0;
    
    `define RESET_CYCLES 8'h08
    
    always @(posedge usb_clk) begin
        if (reset_usb_dly_count < `RESET_CYCLES) begin
            reset_usb_dly_count <= reset_usb_dly_count + 1;
            reset_usb <= 1; 
        end else
            reset_usb <= 0; 
    end
    
    always @(posedge pll_clk1) begin
        if (reset_pll_dly_count < `RESET_CYCLES) begin
            reset_pll_dly_count <= reset_pll_dly_count + 1;
            reset_pll <= 1; 
        end else
            reset_pll <= 0; 
    end
    
    usb_control usb_ctl(
        .clk_usb                (usb_clk                ),
        .data                   (usb_data               ),
        .addr                   (usb_addr               ),
        .rd_en                  (usb_rdn                ),
        .wr_en                  (usb_wrn                ),
        .cen                    (usb_cen                ),
        .trigger                (usb_trigger            ),
        .usb_heartbeat          (led1                   ),    
        
        .mem_fifo_full          (mem_fifo_full          ),
        .mem_fifo_in            (mem_fifo_in            ),
        .mem_fifo_wr_en         (mem_fifo_wr_en         ),
        .mem_fifo_wr_rst_busy   (mem_fifo_wr_rst_busy   ),
        
        .state_fifo_full        (state_fifo_full        ),
        .state_fifo_in          (state_fifo_in          ),
        .state_fifo_wr_en       (state_fifo_wr_en       ),
        .state_fifo_wr_rst_busy (state_fifo_wr_rst_busy ),
        
        .serial_fifo_empty       (serial_fifo_empty       ),
        .serial_fifo_out         (serial_fifo_out         ),
        .serial_fifo_rd_en       (serial_fifo_rd_en       ),
        .serial_fifo_rd_rst_busy (serial_fifo_rd_rst_busy ),
        
        .reset                  (reset                  )
    );   
    
	wire [7:0] mem_fifo_in;
	wire [7:0] mem_fifo_out;
	wire mem_fifo_full;
	wire mem_fifo_wr_en;
	wire mem_fifo_empty;
	wire mem_fifo_rd_en;
	wire mem_fifo_rd_rst_busy;
	wire mem_fifo_wr_rst_busy;
	wire mem_fifo_rst;
   
    fifo_generator_0 code_buffer (
        .full           (mem_fifo_full          ),
        .din            (mem_fifo_in            ),
        .wr_en          (mem_fifo_wr_en         ),
        .wr_clk         (usb_clk                ),
        
        .empty          (mem_fifo_empty         ),
        .dout           (mem_fifo_out           ),
        .rd_en          (mem_fifo_rd_en         ),
        .rd_clk         (pll_clk1               ),
        
        .rst            (reset           ),
        .rd_rst_busy    (mem_fifo_rd_rst_busy   ),
        .wr_rst_busy    (mem_fifo_wr_rst_busy   )
    );
    
	wire [7:0] state_fifo_in;
	wire [7:0] state_fifo_out;
	wire state_fifo_full;
	wire state_fifo_wr_en;
	wire state_fifo_empty;
	wire state_fifo_rd_en;
	wire state_fifo_rd_rst_busy;
	wire state_fifo_wr_rst_busy;
	wire state_fifo_rst;
	
    fifo_generator_1 state_buffer (
        .full           (state_fifo_full        ),
        .din            (state_fifo_in          ),
        .wr_en          (state_fifo_wr_en       ),
        .wr_clk         (usb_clk                ),
        
        .empty          (state_fifo_empty       ),
        .dout           (state_fifo_out         ),
        .rd_en          (state_fifo_rd_en       ),
        .rd_clk         (pll_clk1               ),
        
        .rst            (reset         ),
        .rd_rst_busy    (state_fifo_rd_rst_busy ),
        .wr_rst_busy    (state_fifo_wr_rst_busy )
    );
    
	wire [31:0] serial_fifo_in;
	wire [31:0] serial_fifo_out;
	wire serial_fifo_full;
	wire serial_fifo_wr_en;
	wire serial_fifo_empty;
	wire serial_fifo_rd_en;
	wire serial_fifo_rd_rst_busy;
	wire serial_fifo_wr_rst_busy;
	wire serial_fifo_rst;
	
    fifo_generator_2 serial_buffer (
        .full           (serial_fifo_full       ),
        .din            (serial_fifo_in         ),
        .wr_en          (serial_fifo_wr_en      ),
        .wr_clk         (pll_clk1               ),
        
        .empty          (serial_fifo_empty      ),
        .dout           (serial_fifo_out        ),
        .rd_en          (serial_fifo_rd_en      ),
        .rd_clk         (~usb_clk                ),
        
        .rst            (reset        ),
        .rd_rst_busy    (serial_fifo_rd_rst_busy),
        .wr_rst_busy    (serial_fifo_wr_rst_busy)
    );
    
    wire [31:0] rv_mem_addr;
	wire [31:0] rv_mem_wdata;
	wire [ 3:0] rv_mem_wstrb;
	wire [31:0] rv_mem_rdata;
    wire rv_mem_valid;
    wire rv_mem_instr;
    wire rv_mem_ready;
    wire rv_trap;
    wire rv_rst_n;
    
    picorv32 #(
        .STACKADDR(32'h 0000_3FF0)
	) rv_core (
		.clk         (pll_clk1        ),
		.resetn      (rv_rst_n        ),
		.trap        (rv_trap         ),
		.mem_valid   (rv_mem_valid    ),
		.mem_instr   (rv_mem_instr    ),
		.mem_ready   (rv_mem_ready    ),
		.mem_addr    (rv_mem_addr     ),
		.mem_wdata   (rv_mem_wdata    ),
		.mem_wstrb   (rv_mem_wstrb    ),
		.mem_rdata   (rv_mem_rdata    )
	);
    
    wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [ 3:0] mem_wstrb;
	wire [31:0] mem_rdata;   
    
    blk_mem_gen_0 main_memory (
        .clka   (~pll_clk1   ),
        .ena    (1'b1       ),
        .wea    (mem_wstrb  ),
        .addra  (mem_addr   ),
        .dina   (mem_wdata  ),
        .douta  (mem_rdata  )
    );
    
    picorv_control rv_control (
        .picorv_clk             (pll_clk1               ),
        .picorv_mem_addr        (rv_mem_addr            ),
        .picorv_mem_wdata       (rv_mem_wdata           ),
        .picorv_mem_wstrb       (rv_mem_wstrb           ),
        .picorv_mem_rdata       (rv_mem_rdata           ),
        .picorv_rst_n           (rv_rst_n               ),
        .picorv_mem_ready       (rv_mem_ready           ),
        .picorv_mem_valid       (rv_mem_valid           ),
        
        .mem_addr               (mem_addr               ),
        .mem_wdata              (mem_wdata              ),
        .mem_wstrb              (mem_wstrb              ),
        .mem_rdata              (mem_rdata              ),        
        
        .mem_fifo_empty         (mem_fifo_empty         ),
        .mem_fifo_out           (mem_fifo_out           ),
        .mem_fifo_rd_en         (mem_fifo_rd_en         ),
        .mem_fifo_rd_rst_busy   (mem_fifo_rd_rst_busy   ),
        
        .state_fifo_empty       (state_fifo_empty       ),
        .state_fifo_out         (state_fifo_out         ),
        .state_fifo_rd_en       (state_fifo_rd_en       ),
        .state_fifo_rd_rst_busy (state_fifo_rd_rst_busy ),
        
        .serial_fifo_full        (serial_fifo_full       ),
        .serial_fifo_in          (serial_fifo_in         ),
        .serial_fifo_wr_en       (serial_fifo_wr_en      ),
        .serial_fifo_wr_rst_busy (serial_fifo_wr_rst_busy),
        
        .sw1                    (sw1                    ),
        .sw2                    (sw2                    ),
        .sw3                    (sw3                    ),
        .sw4                    (sw4                    ),
        
        .pushbutton             (pushbutton             ),
        
        .led2                   (led2                   ),
        .led3                   (led3                   ),
        .reset                  (reset                  )
    );
    
endmodule
