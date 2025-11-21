----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/9/2025 12:50:53 PM
-- Design Name: 
-- Module Name: dual_7seg_countdown - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity dual_7seg_countdown is
    Port ( clk : in STD_LOGIC; 
           reset : in STD_LOGIC; 
          -- ped_req : in STD_LOGIC; -- this should be once the button is pressed by the pedestrian (Not sure if needed here)
           count  : in integer range 0 to 99; -- this should be coming from the countdown file
          -- int_value : in integer range 0 to 99;    --highest and lowest possible integer value that can be displayed on the 7seg disp
           digit_select : out STD_LOGIC_VECTOR (1 downto 0); -- alternates between tens and ones place
           segment_vector : out STD_LOGIC_VECTOR (6 downto 0));
end dual_7seg_countdown;

architecture Behavioral of dual_7seg_countdown is
signal clk_counter : unsigned(5 downto 0) := (others => '0');
signal mux_select : STD_LOGIC;
signal ones_digit : integer range 0 to 9;
signal tens_digit : integer range 0 to 9;
signal digit_value : integer range 0 to 9;


begin

--Clock Cycle Counter 

process (clk)
begin
    if rising_edge (clk) then
        if reset = '1' then
            clk_counter <= (others => '0');
        else
            clk_counter <= clk_counter + 1;
        
        end if;
    end if;
end process;

mux_select <= std_logic(clk_counter(5)); 

-- Single 7 segment display output in decimal

process (digit_value)
begin
    case (digit_value) is 
        when 0 => 
            segment_vector <= "0111111";
        when 1 => 
            segment_vector <= "0000110";
        when 2 => 
            segment_vector <= "1011011";
        when 3 => 
            segment_vector <= "1001111";
        when 4 => 
            segment_vector <= "1100110";
        when 5 => 
            segment_vector <= "1101101";
        when 6 => 
            segment_vector <= "1111101";
        when 7 => 
            segment_vector <= "0000111";
        when 8 => 
            segment_vector <= "1111111";
        when 9 => 
            segment_vector <= "1101111";
        when others =>
            segment_vector <= "0000000";
            
    end case;
end process;

-- Selecting digit on display
process(mux_select, ones_digit, tens_digit)
begin

    if mux_select = '0' then
            digit_select <= "01";
            digit_value <= ones_digit;
    
        else
            digit_select <= "10";
            digit_value <= tens_digit;
    end if;
end process;

-- Calculating tens and ones digit value to display
ones_digit <= count rem 10;
tens_digit <= count / 10;


end Behavioral;
