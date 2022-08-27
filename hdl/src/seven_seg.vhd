--! @title Seven Segment LED driver
--! @author Mallory Sutter (sir.oslay@gmail.com)
--! @date 2015-10-22

library ieee;
use ieee.std_logic_1164.all;

entity seven_seg is 
	port(
        --! 4-bit value to be displayed
		disp_val: in std_logic_vector(3 downto 0);
        --! enable signal (active high)
		en: in std_logic;
        --! output to LEDs (active low)
		seg_out: out std_logic_vector(6 downto 0)
	);
end seven_seg;

architecture rtl of seven_seg is 
begin
	segment_lut: process(en, disp_val)
	begin
		if (en = '0') then
			seg_out <=	"1111111";	-- blank
		else
			case disp_val is
				when "0000" =>
					seg_out <=	"1000000";	-- 0
				when "0001" =>
					seg_out <=	"1111001";	-- 1
				when "0010" =>
					seg_out <=	"0100100";	-- 2
				when "0011" =>
					seg_out <=	"0110000";	-- 3
				when "0100" =>
					seg_out <=	"0011001";	-- 4
				when "0101" =>
					seg_out <=	"0010010";	-- 5
				when "0110" =>
					seg_out <=	"0000010";	-- 6
				when "0111" =>
					seg_out <=	"1111000";	-- 7
				when "1000" =>
					seg_out <=	"0000000";	-- 8
				when "1001" =>
					seg_out <=	"0010000";	-- 9
				when "1010" =>
					seg_out <=	"0001000";	-- A
				when "1011" =>
					seg_out <=	"0000011";	-- b
				when "1100" =>
					seg_out <=	"1000110";	-- C
				when "1101" =>
					seg_out <=	"0100001";	-- d
				when "1110" =>
					seg_out <=	"0000110";	-- E
				when "1111" =>
					seg_out <=	"0001110";	-- F
				when others =>
					seg_out <=	"1111111";	-- blank
			end case;
		end if;
	end process;

end rtl;