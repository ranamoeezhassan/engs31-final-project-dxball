library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity paddle_tb is
end paddle_tb;

architecture testbench of paddle_tb is

component paddle is
    generic (
        PADDLE_WIDTH  : integer := 80;
        MAX_X         : integer := 640;
        ADC_BITS      : integer := 12;
        PADDLE_SPEED_FRACTIONAL : integer := 6
    );
    port (
        clk           : in std_logic;
        reset         : in std_logic;
        adc_data      : in std_logic_vector(ADC_BITS-1 downto 0);
        take_sample   : in std_logic;
        game_over     : in std_logic;
        paddle_x      : out std_logic_vector(9 downto 0)
    );
end component;

constant CLK_PERIOD : time := 10 ns;

-- Signals
signal clk          : std_logic := '0';
signal reset        : std_logic := '0';
signal adc_data     : std_logic_vector(11 downto 0) := (others => '0');
signal take_sample  : std_logic := '0';
signal game_over    : std_logic := '0';
signal paddle_x     : std_logic_vector(9 downto 0);

begin

-- Instantiate the Unit Under Test (UUT)
uut: paddle
    generic map (
        PADDLE_WIDTH  => 80,
        MAX_X         => 640,
        ADC_BITS      => 12,
        PADDLE_SPEED_FRACTIONAL => 6
    )
    port map (
        clk        => clk,
        reset      => reset,
        adc_data   => adc_data,
        take_sample => take_sample,
        game_over  => game_over,
        paddle_x   => paddle_x
    );

-- Clock process
clk_proc: process
begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
end process;


take_sample_proc: process
begin
    take_sample <= '0';
    wait for 5*CLK_PERIOD;
    take_sample <= '1';
    wait for 5*CLK_PERIOD;
end process;


-- Stimulus process
stim_proc: process
begin
    -- Initialize signals
    wait for CLK_PERIOD*2;
    
    -- Test 1: Reset functionality
    reset <= '1';
    wait for CLK_PERIOD*2;
    reset <= '0';
    wait for CLK_PERIOD*2;
    
    -- Test 2: Move left with take_sample and game_over = '0'
    game_over <= '0';
    adc_data <= std_logic_vector(to_unsigned(100, 12)); -- Below LEFT_THRESH (112)
    wait for CLK_PERIOD*10;
    
    -- Test 3: No movement in dead zone
    adc_data <= std_logic_vector(to_unsigned(140, 12)); 
    wait for CLK_PERIOD*10;
    
    -- Test 4: Move right with take_sample and game_over = '0'
    adc_data <= std_logic_vector(to_unsigned(950, 12)); -- Above RIGHT_THRESH (900)
    wait for CLK_PERIOD*10;
    
    -- Test 5: Game over prevents movement
    game_over <= '1';
    adc_data <= std_logic_vector(to_unsigned(950, 12)); -- Try to move right
    wait for CLK_PERIOD*10;
    
    -- Test 6: Reset functionality
    reset <= '1';
    wait for CLK_PERIOD*2;
    reset <= '0';
    wait for CLK_PERIOD*2;
    
    report "Testbench completed";
    wait;
end process;

end testbench;