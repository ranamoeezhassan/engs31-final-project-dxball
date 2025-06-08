library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity brick_controller_tb is
end brick_controller_tb;

architecture Behavioral of brick_controller_tb is

    constant BRICK_ROWS   : integer := 5;
    constant BRICK_COLS   : integer := 10;
    constant BRICK_COUNT  : integer := BRICK_ROWS * BRICK_COLS;

    signal clk         : std_logic := '0';
    signal reset       : std_logic := '0';
    signal hit_brick_index : integer range 0 to BRICK_COUNT - 1 := 0;
    signal hit_request     : std_logic := '0';
    signal brick_grid  : std_logic_vector(BRICK_COUNT - 1 downto 0);

    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.brick_controller
        generic map (
            BRICK_ROWS => BRICK_ROWS,
            BRICK_COLS => BRICK_COLS
        )
        port map (
            clk => clk,
            reset => reset,
            hit_brick_index => hit_brick_index,
            hit_request => hit_request,
            brick_grid => brick_grid
        );

    -- Clock generation
    clk_process : process
    begin
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
	  wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus process
    stim_proc : process
    begin
        -- Initial reset
        reset <= '1';
        wait for CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;

        -- Simulate hit on brick index 12
        hit_brick_index <= 12;
        hit_request <= '1';
        wait for CLK_PERIOD;
        hit_request <= '0';
        wait for CLK_PERIOD;

        -- Try hitting the same brick again (should stay '0')
        hit_brick_index <= 12;
        hit_request <= '1';
        wait for CLK_PERIOD;
        hit_request <= '0';
        wait for CLK_PERIOD;

        -- Hit another brick (index 0)
        hit_brick_index <= 0;
        hit_request <= '1';
        wait for CLK_PERIOD;
        hit_request <= '0';
        wait for CLK_PERIOD;

        -- Done
        wait;
    end process;

end Behavioral;
