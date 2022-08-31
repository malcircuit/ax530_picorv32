//! @title AX530 scanning seven segment driver
//! @author Mallory Sutter (sir.oslay@gmail.com)
//! @date 2022-08-26
//! @brief The seven segment LED display on the AX530 can have only one segment active at a time, so displaying unique values requires scanning through each segment

module seven_seg_scan
    (
        input  wire       clk,          //! clock (50 MHz)
        input  wire       reset_n,      //! active low reset
        input  wire       en,           //! active high enable

        output wire [7:0] SMG_Data,     //! Seven segment LED signals (active low)
        output wire [5:0] Scan_Sig,     //! Determines which segment is active (active low)

        input  wire [3:0] seg_0_val,    //! Value to display on segment 0 (right-most)
        input  wire [3:0] seg_1_val,    //! Value to display on segment 1
        input  wire [3:0] seg_2_val,    //! Value to display on segment 2
        input  wire [3:0] seg_3_val,    //! Value to display on segment 3
        input  wire [3:0] seg_4_val,    //! Value to display on segment 4
        input  wire [3:0] seg_5_val     //! Value to display on segment 5 (left-most)
    );

    localparam count_limit = 16'd49999; //! This sets each segment to have a 1 ms on-time (1 ms x 6 segments = 167 Hz refresh rate)
    reg [15:0] count;                   //! Timer count 
    reg [5:0] shift_reg = 6'b000001;    //! Shift register that determines which segment is active
    reg [3:0] seg_val;                  //! The value of the active segment

    assign SMG_Data[7] = 1'b1;      // Disable decimal point
    assign Scan_Sig = ~shift_reg;
    
    seven_seg seg_inst (
        .disp_val (       seg_val),
        .en       (            en),
        .seg_out  ( SMG_Data[6:0])
    );

    always @* begin : segment_value_mux
        case (shift_reg)
            6'b000001: seg_val = seg_0_val;
            6'b000010: seg_val = seg_1_val;
            6'b000100: seg_val = seg_2_val;
            6'b001000: seg_val = seg_3_val;
            6'b010000: seg_val = seg_4_val;
            6'b100000: seg_val = seg_5_val;
            default:   seg_val = 4'b0000;
        endcase
    end

    always @ (posedge clk) begin : shift_reg_on_slow_clk
        if(~reset_n) begin
            count <= 16'd0;
            shift_reg <= 6'b000001;
        end else if(count == count_limit) begin
            count <= 16'd0;
            shift_reg <= {shift_reg[4:0], shift_reg[5]};
        end else
            count <= count + 1'b1;
    end

endmodule
