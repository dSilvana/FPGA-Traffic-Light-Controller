library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;


entity traffic_light_top is
  Port (clk      : in  std_logic;
        reset    : in  std_logic;

        -- Traffic light outputs
        NS_red    : out std_logic;
        NS_yellow : out std_logic;
        NS_green  : out std_logic;

        EW_red    : out std_logic;
        EW_yellow : out std_logic;
        EW_green  : out std_logic;

        -- 7-seg display (Pmod SSD)
        seg    : out std_logic_vector(6 downto 0); -- segments a–g
        an     : out std_logic_vector(1 downto 0)  -- digit enable (2 digits)
    );
end traffic_light_top;

architecture Behavioral of traffic_light_top is
    -- All states the traffic light can take
    type state_type is (S_Init, S_NS_GREEN, S_NS_YELLOW, S_NS_red, S_EW_GREEN, S_EW_YELLOW, S_EW_red, S_PED);

    -- Constants for clock frequency
    constant CLK_FREQ : integer := 125_000_000; -- Zybo Z7 clock (external 125 MHz reference clock)
    constant ONE_SEC  : integer := CLK_FREQ - 1;

    -- Duration for each state
    constant T_GREEN  : integer := 5; -- 5 secs for green
    constant T_RED  : integer := 5; -- 5 secs for red
    constant T_YELLOW : integer := 2; -- 2 secs for yellow

    -- Signals
    signal clk_1hz_en : std_logic := '0'; -- 1 Hz tick enable
    signal div_count  : integer := 0; -- clock divider counter

    signal current_state, next_state : state_type;
    signal timer_value : integer := 0; -- countdown value

    -- 7-seg display
    signal digit0 : integer range 0 to 9 := 0; -- ones place (right 7 seg)
    signal digit1 : integer range 0 to 9 := 0; -- tens place (left 7 seg)

    signal mux_sel : std_logic := '0'; -- toggles between digits
    
    -- Pedestrian request
    constant ped_req : integer := 1;

begin
    -- Clock Divider (generates 1 Hz pulse)
    -- ticks once per second
    clock_divider : process(clk)
    begin
        if rising_edge(clk) then
            if div_count = ONE_SEC then
                div_count <= 0;
                clk_1hz_en <= '1';
         else
            div_count <= div_count + 1;
            clk_1hz_en <= '0';
         end if;
    end if;
end process;

    -- State Register
    -- Stores the current FSM state
    -- Basically remembers what CURRENT state we are in
    state_register : process(clk, reset)
    begin
        if reset = '1' then
            current_state <= S_NS_GREEN;
            timer_value   <= T_GREEN;
        elsif rising_edge(clk) then
            if clk_1hz_en = '1' then
                current_state <= next_state;
            end if;
        end if;
    end process;
    
    -- Next State Logic
    -- Determines rules needed for behavior/ transition
        next_state_logic : process(current_state, timer_value)
    begin
        next_state <= current_state;  -- default

        case current_state is

            when S_NS_GREEN =>
                if timer_value = 0 then
                    next_state <= S_NS_YELLOW;
                end if;

            when S_NS_YELLOW =>
                if timer_value = 0 then
                    next_state <= S_NS_red;
                end if;
                
                when S_NS_red =>
                if timer_value = 0 and ped_req = 1 then
                    next_state <= S_PED;
                else
                next_state <= S_EW_GREEN;
                end if;

            when S_EW_GREEN =>
                if timer_value = 0 then
                    next_state <= S_EW_YELLOW;
                end if;

            when S_EW_YELLOW =>
                if timer_value = 0 then
                    next_state <= S_NS_GREEN;
                end if;
                
             when S_EW_red =>
                if timer_value = 0 and ped_req = 1 then
                    next_state <= S_PED;
                else
                next_state <= S_Init;
                end if;

        end case;
    end process;


    --  Timer Process
    -- Makes the light duration in real-time
    timer_process : process(clk, reset)
    begin
        if reset = '1' then
            timer_value <= T_GREEN;
    
        elsif rising_edge(clk) then
            if clk_1hz_en = '1' then
    
                if timer_value = 0 then
                    -- Load new duration based on next state
                    case next_state is
                        when S_NS_GREEN  => timer_value <= T_GREEN;
                        when S_NS_YELLOW => timer_value <= T_YELLOW;
                        when S_NS_red => timer_value <= T_RED;
                        when S_EW_GREEN  => timer_value <= T_GREEN;
                        when S_EW_YELLOW => timer_value <= T_YELLOW;
                        when S_EW_red => timer_value <= T_RED;
                    end case;
    
                else
                    timer_value <= timer_value - 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Traffic Light Output Logic
    -- Sets LEDs based on the current state
    light_output : process(current_state)
    begin
        --NS_red <= '1';  NS_yellow <= '0'; NS_green <= '0';
        --EW_red <= '1';  EW_yellow <= '0'; EW_green <= '0';

        case current_state is

            when S_Init =>
                NS_red <= '1';  NS_yellow <= '0'; NS_green <= '0';
                EW_red <= '1';  EW_yellow <= '0'; EW_green <= '0';
            
            when S_NS_GREEN =>
                NS_red <= '0'; NS_yellow <= '0'; NS_green <= '1'; 
                EW_red <= '1'; EW_yellow <= '0'; EW_green <= '0';

            when S_NS_YELLOW =>
                NS_red <= '0'; NS_yellow <= '1'; NS_green <= '0';
                EW_red <= '1'; EW_yellow <= '0'; EW_green <= '0';
                
            when S_NS_red =>
                NS_red <= '1'; NS_yellow <= '0'; NS_green <= '0';
                EW_red <= '1'; EW_yellow <= '0'; EW_green <= '0';

            when S_EW_GREEN =>
                NS_red <= '1'; NS_yellow <= '0'; NS_green <= '0';
                EW_red <= '0'; EW_yellow <= '0'; EW_green <= '1'; 

            when S_EW_YELLOW =>
                NS_red <= '1'; NS_yellow <= '0'; NS_green <= '0';
                EW_red <= '0'; EW_yellow <= '1'; EW_green <= '0';
                
            when S_EW_red =>
                NS_red <= '1'; NS_yellow <= '0'; NS_green <= '0';
                EW_red <= '1'; EW_yellow <= '0'; EW_green <= '0';
              
            when S_PED =>
                NS_red <= '1';  NS_yellow <= '0'; NS_green <= '0';
                EW_red <= '1';  EW_yellow <= '0'; EW_green <= '0';

        end case;
    end process;

    -- Split Timer Into Two Digits
    -- Converts timer value into two digits as Pmod 
    -- has 2 displays (each shows a digit)
    digit1 <= timer_value / 10; -- tens place
    digit0 <= timer_value mod 10; -- ones place

    -- Display Multiplexing Process
    -- Switches rapidly between the left and right digit
    multiplex : process(clk)
    begin
        if rising_edge(clk) then
            mux_sel <= not mux_sel;
        end if;
    end process;

    -- 7 segment decoder
    -- Turns the numbers into segment patterns
    seven_seg_decoder : process(mux_sel, digit0, digit1)
    begin
        if mux_sel = '0' then
            an <= "10";           -- enable right digit
            case digit0 is
                when 0 => seg <= "0111111";
                when 1 => seg <= "0000110";
                when 2 => seg <= "1011011";
                when 3 => seg <= "1001111";
                when 4 => seg <= "1100110";
                when 5 => seg <= "1101101";
                when 6 => seg <= "1111101";
                when 7 => seg <= "0000111";
                when 8 => seg <= "1111111";
                when 9 => seg <= "1101111";
                when others => seg <= "0000000";
            end case;
        else
            an <= "01";           -- enable left digit
            case digit1 is
                when 0 => seg <= "0111111";
                when 1 => seg <= "0000110";
                when 2 => seg <= "1011011";
                when 3 => seg <= "1001111";
                when 4 => seg <= "1100110";
                when 5 => seg <= "1101101";
                when 6 => seg <= "1111101";
                when 7 => seg <= "0000111";
                when 8 => seg <= "1111111";
                when 9 => seg <= "1101111";
                when others => seg <= "0000000";
            end case;
        end if;
    end process;

end Behavioral;
