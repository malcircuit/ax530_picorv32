import clr
clr.AddReference("CyUSB")    
from CyUSB import *

CMD_FIFO_LEN  = 512
BULK_FIFO_LEN = 1024

usb_devices = USBDeviceList(CyConst.DEVICES_CYUSB)
bulk_xfer_device = usb_devices[0x4b4, 0x1004]

bulk_rx_endpoint = bulk_xfer_device.USBCfgs[0].Interfaces[0].EndPoints[1]   # To FPGA
cmd_rx_endpoint  = bulk_xfer_device.USBCfgs[0].Interfaces[0].EndPoints[2]   # To FPGA
bulk_tx_endpoint = bulk_xfer_device.USBCfgs[0].Interfaces[0].EndPoints[3]   # From FPGA
cmd_tx_endpoint  = bulk_xfer_device.USBCfgs[0].Interfaces[0].EndPoints[4]   # From FPGA

cmd_rx_buffer = b'\x01\x02\x03\x04'
send_len = len(cmd_rx_buffer)

cmd_rx_endpoint.XferData(cmd_rx_buffer, send_len)

print("sent {} bytes\n".format(send_len))

