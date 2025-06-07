library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity frame_divider_tb is
end frame_divider_tb;

architecture sim of frame_divider_tb is

    -- Component signals
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';
    signal take_sample : std_logic;

    -- Test clock period
    constant CLK_PERIOD : time := 10 ns;

    component frame_divider is
        generic (
            DIVIDE_BY : integer := 416667  -- Number of clock cycles between pulses
        );
        port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            take_sample : out STD_LOGIC  -- Pulse output, one clk wide
        );
    end component;

begin

    -- Instantiate Unit Under Test (UUT)
    uut: frame_divider
        generic map (
            DIVIDE_BY => 10  -- For simulation purposes
        )
        port map (
            clk         => clk,
            reset       => reset,
            take_sample => take_sample
        );

    -- Clock process
    clk_process : process
    begin
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus and observation process
    stim_proc : process
    begin
        -- Apply reset
        reset <= '1';
        wait for 30 ns;
        reset <= '0';

        -- Observe pulses
        wait for 500 ns;

    end process;

end architecture;
