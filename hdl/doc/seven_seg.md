# Seven Segment LED driver

- **File**: seven_seg.vhd
- **Author:** Mallory Sutter (sir.oslay@gmail.com)
- **Date:** 2015-10-22
## Diagram

![Diagram](seven_seg.svg "Diagram")
## Ports

| Port name | Direction | Type                         | Description                 |
| --------- | --------- | ---------------------------- | --------------------------- |
| disp_val  | in        | std_logic_vector(3 downto 0) | 4-bit value to be displayed |
| en        | in        | std_logic                    | enable signal (active high) |
| seg_out   | out       | std_logic_vector(6 downto 0) | output to LEDs (active low) |
## Processes
- segment_lut: ( en, disp_val )
