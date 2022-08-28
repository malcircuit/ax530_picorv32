set_global_assignment -name SDC_FILE ../../../Top/ax530/usb_test/usb_test.sdc

set_location_assignment PIN_T21 -to clk
set_location_assignment PIN_B19 -to reset_n
set_location_assignment PIN_H16 -to usb_ifclk
set_location_assignment PIN_L21 -to usb_fd[15]
set_location_assignment PIN_L22 -to usb_fd[14]
set_location_assignment PIN_K19 -to usb_fd[13]
set_location_assignment PIN_K21 -to usb_fd[12]
set_location_assignment PIN_K22 -to usb_fd[11]
set_location_assignment PIN_J18 -to usb_fd[10]
set_location_assignment PIN_J21 -to usb_fd[9]
set_location_assignment PIN_J22 -to usb_fd[8]
set_location_assignment PIN_F20 -to usb_fd[7]
set_location_assignment PIN_F19 -to usb_fd[6]
set_location_assignment PIN_E22 -to usb_fd[5]
set_location_assignment PIN_E21 -to usb_fd[4]
set_location_assignment PIN_D22 -to usb_fd[3]
set_location_assignment PIN_D21 -to usb_fd[2]
set_location_assignment PIN_H17 -to usb_fd[1]
set_location_assignment PIN_C22 -to usb_fd[0]
set_location_assignment PIN_H22 -to usb_fifoaddr[1]
set_location_assignment PIN_H19 -to usb_fifoaddr[0]
set_location_assignment PIN_F22 -to usb_flaga
set_location_assignment PIN_F21 -to usb_flagb
set_location_assignment PIN_G18 -to usb_flagc
set_location_assignment PIN_H20 -to usb_flagd
set_location_assignment PIN_H18 -to usb_sloe
set_location_assignment PIN_J17 -to usb_slrd
set_location_assignment PIN_K17 -to usb_slwr
set_location_assignment PIN_H21 -to usb_pktend
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to reset_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_ifclk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[15]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[14]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[13]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fifoaddr[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fifoaddr[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_flaga
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_flagb
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_flagc
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_flagd
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_sloe
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_slrd
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_slwr
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_pktend

set_location_assignment PIN_Y2 -to usb_ifclk_dup
set_location_assignment PIN_V4 -to usb_flaga_dup
set_location_assignment PIN_R6 -to usb_flagb_dup
set_location_assignment PIN_V2 -to usb_flagc_dup
set_location_assignment PIN_V1 -to usb_flagd_dup
set_location_assignment PIN_U2 -to usb_slwr_dup
set_location_assignment PIN_T3 -to usb_slrd_dup
set_location_assignment PIN_P5 -to usb_sloe_dup
set_location_assignment PIN_R2 -to usb_pktend_dup
set_location_assignment PIN_P3 -to usb_fifoaddr_dup[0]
set_location_assignment PIN_P1 -to usb_fifoaddr_dup[1]

set_location_assignment PIN_AA1 -to usb_fd_dup[0]
set_location_assignment PIN_V3 -to usb_fd_dup[1]
set_location_assignment PIN_W2 -to usb_fd_dup[2]
set_location_assignment PIN_W1 -to usb_fd_dup[3]
set_location_assignment PIN_T5 -to usb_fd_dup[4]
set_location_assignment PIN_T4 -to usb_fd_dup[5]
set_location_assignment PIN_U1 -to usb_fd_dup[6]
set_location_assignment PIN_R5 -to usb_fd_dup[7]
set_location_assignment PIN_P4 -to usb_fd_dup[8]
set_location_assignment PIN_R1 -to usb_fd_dup[9]
set_location_assignment PIN_P2 -to usb_fd_dup[10]
set_location_assignment PIN_T7 -to usb_fd_dup[11]
set_location_assignment PIN_N5 -to usb_fd_dup[12]
set_location_assignment PIN_M5 -to usb_fd_dup[13]
set_location_assignment PIN_P7 -to usb_fd_dup[14]
set_location_assignment PIN_M7 -to usb_fd_dup[15]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_ifclk_dup
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_slwr_dup
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_slrd_dup
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_sloe_dup
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_flaga_dup
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_flagb_dup
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_flagc_dup
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_flagd_dup
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_pktend_dup
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fifoaddr_dup[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fifoaddr_dup[0]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[13]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[14]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_fd_dup[15]

set_location_assignment PIN_M16 -to SMG_Data[7]
set_location_assignment PIN_N22 -to SMG_Data[6]
set_location_assignment PIN_N21 -to SMG_Data[5]
set_location_assignment PIN_M19 -to SMG_Data[4]
set_location_assignment PIN_N16 -to SMG_Data[3]
set_location_assignment PIN_M20 -to SMG_Data[2]
set_location_assignment PIN_M22 -to SMG_Data[1]
set_location_assignment PIN_W20 -to SMG_Data[0]
set_location_assignment PIN_W19 -to Scan_Sig[5]
set_location_assignment PIN_AA21 -to Scan_Sig[4]
set_location_assignment PIN_T18 -to Scan_Sig[3]
set_location_assignment PIN_T17 -to Scan_Sig[2]
set_location_assignment PIN_G17 -to Scan_Sig[1]
set_location_assignment PIN_M21 -to Scan_Sig[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SMG_Data[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SMG_Data[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SMG_Data[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SMG_Data[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SMG_Data[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SMG_Data[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SMG_Data[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SMG_Data[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to Scan_Sig[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to Scan_Sig[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to Scan_Sig[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to Scan_Sig[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to Scan_Sig[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to Scan_Sig[0]