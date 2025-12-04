library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic_light_top is
  Port (
    clk        : in  std_logic;
    reset      : in  std_logic;
    ped_button : in  std_logic;  -- pedestrian pushbutton input (active high)

    -- Traffic light outputs
    NS_red    : out std_logic;
    NS_yellow : out std_logic;
    NS_green  : out std_logic;

    EW_red    : out std_logic;
    EW_yellow : out std_logic;
    EW_green  : out std_logic;

    -- 7-seg display (Pmod SSD)
    seg    : out std_logic_vector(6 downto 0); -- segments a-g
    an     : out std_logic_vector(1 downto 0)  -- digit enable (2 digits)
  );
end traffic_light_top;

architecture Behavioral of traffic_light_top is

  ----------------------------------------------------------------
  -- State type
  ----------------------------------------------------------------
  type state_type is (
    S_Init,
    S_NS_GREEN,
    S_NS_YELLOW,
    S_NS_RED,
    S_EW_GREEN,
    S_EW_YELLOW,
    S_EW_RED,
    S_PED
  );

  ----------------------------------------------------------------
  -- Clock / timing parameters (adjust if needed)
  ----------------------------------------------------------------
  constant CLK_FREQ : integer := 125_000_000; -- Zybo Z7 125 MHz
  constant ONE_SEC  : integer := CLK_FREQ - 1;

  -- Multiplex divisor for 7-seg (adjust for reasonable refresh)
  constant MUX_DIV : integer := 100000; -- ~1250 Hz toggle

  ----------------------------------------------------------------
  -- Per-state durations (seconds)
  ----------------------------------------------------------------
  constant T_GREEN  : integer := 5;
  constant T_YELLOW : integer := 2;
  constant T_RED    : integer := 5;
  constant T_PED    : integer := 6;

  ----------------------------------------------------------------
  -- Signals
  ----------------------------------------------------------------
  signal div_count      : integer range 0 to ONE_SEC := 0;
  signal clk_1hz_en     : std_logic := '0';

  signal mux_div_count  : integer range 0 to MUX_DIV := 0;
  signal mux_sel        : std_logic := '0';

  signal current_state  : state_type := S_NS_GREEN;
  signal next_state     : state_type := S_NS_GREEN;

  -- timer_value is single-driven by timer_state_process
  signal timer_value    : integer range 0 to 99 := 0;

  signal digit0         : integer range 0 to 9 := 0;
  signal digit1         : integer range 0 to 9 := 0;

  -- ped_req is single-driven by ped_process
  signal ped_button_sync0, ped_button_sync1 : std_logic := '0';
  signal ped_req        : std_logic := '0';

  -- ped_next_dir is single-driven by timer_state_process
  signal ped_next_dir   : state_type := S_EW_GREEN;

begin

  ----------------------------------------------------------------
  -- 1) Clock Divider: generate 1Hz tick and mux toggle
  ----------------------------------------------------------------
  clock_divider : process(clk, reset)
  begin
    if reset = '1' then
      div_count <= 0;
      clk_1hz_en <= '0';
      mux_div_count <= 0;
      mux_sel <= '0';
    elsif rising_edge(clk) then
      -- 1 Hz tick
      if div_count = ONE_SEC then
        div_count <= 0;
        clk_1hz_en <= '1';
      else
        div_count <= div_count + 1;
        clk_1hz_en <= '0';
      end if;

      -- Fast mux toggle
      if mux_div_count = MUX_DIV then
        mux_div_count <= 0;
        mux_sel <= not mux_sel;
      else
        mux_div_count <= mux_div_count + 1;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- 2) Pedestrian process (single driver for ped_req)
  --    - synchronizes button into clk domain
  --    - latches request on rising edge of sync'd button
  --    - clears ped_req when pedestrian service finishes (current_state=S_PED and timer_value=0)
  ----------------------------------------------------------------
  ped_process : process(clk, reset)
  begin
    if reset = '1' then
      ped_button_sync0 <= '0';
      ped_button_sync1 <= '0';
      ped_req <= '0';
    elsif rising_edge(clk) then
      -- sync
      ped_button_sync0 <= ped_button;
      ped_button_sync1 <= ped_button_sync0;

      -- edge detection: press -> latch
      if (ped_button_sync0 = '1' and ped_button_sync1 = '0') then
        ped_req <= '1';
      end if;

      -- clear when pedestrian service completes
      if (current_state = S_PED) and (timer_value = 0) then
        ped_req <= '0';
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- 3) State register: update current_state on 1Hz tick
  ----------------------------------------------------------------
  state_register : process(clk, reset)
  begin
    if reset = '1' then
      current_state <= S_NS_GREEN;
    elsif rising_edge(clk) then
      if clk_1hz_en = '1' then
        current_state <= next_state;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- 4) Next-state combinational logic (Moore-like)
  ----------------------------------------------------------------
  next_state_logic : process(current_state, timer_value, ped_req)
  begin
    next_state <= current_state;
    case current_state is
      when S_Init =>
        next_state <= S_NS_GREEN;

      when S_NS_GREEN =>
        if timer_value = 0 then
          next_state <= S_NS_YELLOW;
        end if;

      when S_NS_YELLOW =>
        if timer_value = 0 then
          next_state <= S_NS_RED;
        end if;

      when S_NS_RED =>
        if timer_value = 0 then
          if ped_req = '1' then
            next_state <= S_PED;
          else
            next_state <= S_EW_GREEN;
          end if;
        end if;

      when S_EW_GREEN =>
        if timer_value = 0 then
          next_state <= S_EW_YELLOW;
        end if;

      when S_EW_YELLOW =>
        if timer_value = 0 then
          next_state <= S_EW_RED;
        end if;

      when S_EW_RED =>
        if timer_value = 0 then
          if ped_req = '1' then
            next_state <= S_PED;
          else
            next_state <= S_NS_GREEN;
          end if;
        end if;

      when S_PED =>
        if timer_value = 0 then
          next_state <= ped_next_dir;
        end if;

    end case;
  end process;

  ----------------------------------------------------------------
  -- 5) Timer & ped_next_dir process (single driver for timer_value & ped_next_dir)
  --    Behavior: on a 1Hz tick, if a state change is occurring (next_state /= current_state),
  --    load the timer for the next state; otherwise decrement timer.
  ----------------------------------------------------------------
timer_state_process : process(clk, reset)
begin
  if reset = '1' then
    ped_next_dir <= S_EW_GREEN;
  elsif rising_edge(clk) then
    if clk_1hz_en = '1' then
      if next_state /= current_state then
        case next_state is
          when S_NS_RED =>
            ped_next_dir <= S_EW_GREEN;

          when S_EW_RED =>
            ped_next_dir <= S_NS_GREEN;

          when others =>
            null;
        end case;
      end if;
    end if;
  end if;
end process;


  ----------------------------------------------------------------
  -- 6) Output logic (Moore outputs depend only on current_state)
  ----------------------------------------------------------------
  light_output : process(current_state)
  begin
    -- default all off (active-high outputs assumed)
    NS_red    <= '0';
    NS_yellow <= '0';
    NS_green  <= '0';
    EW_red    <= '0';
    EW_yellow <= '0';
    EW_green  <= '0';

    case current_state is
      when S_Init =>
        NS_red <= '1';
        EW_red <= '1';

      when S_NS_GREEN =>
        NS_green <= '1';
        EW_red <= '1';

      when S_NS_YELLOW =>
        NS_yellow <= '1';
        EW_red <= '1';

      when S_NS_RED =>
        NS_red <= '1';
        EW_red <= '1';

      when S_EW_GREEN =>
        EW_green <= '1';
        NS_red <= '1';

      when S_EW_YELLOW =>
        EW_yellow <= '1';
        NS_red <= '1';

      when S_EW_RED =>
        NS_red <= '1';
        EW_red <= '1';

      when S_PED =>
        NS_red <= '1';
        EW_red <= '1';
    end case;
  end process;

  ----------------------------------------------------------------
  -- 7) 7-seg: split timer into digits and decode (multiplexed)
  ----------------------------------------------------------------
  digit1 <= timer_value / 10; -- tens
  digit0 <= timer_value mod 10; -- ones

  seven_seg_decoder : process(mux_sel, digit0, digit1)
  begin
    if mux_sel = '0' then
      an <= "10"; -- enable ones (right)
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
      an <= "01"; -- enable tens (left)
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
