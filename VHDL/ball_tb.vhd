library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ball_tb is
end ball_tb;

architecture testbench of ball_tb is

component ball is
    Generic ( 
        BALL_SPEED  : integer := 5;
        BALL_RADIUS : integer := 15;
        PADDLE_WIDTH : integer := 80;
        PADDLE_HEIGHT : integer := 10;
        MAX_X : integer := 640;
        MAX_Y : integer := 380;
        MIN_X : integer := 0;
        MIN_Y : integer := 0
    );
    Port (
        clk         : in STD_LOGIC;
        reset       : in STD_LOGIC;
        ball_dir_x  : in STD_LOGIC;
        ball_dir_y  : in STD_LOGIC;
        paddle_x    : in unsigned(9 downto 0);
        ball_moving : in std_logic;
        game_over   : in STD_LOGIC;
        take_sample : in STD_LOGIC;
        ball_pos_x  : out STD_LOGIC_VECTOR(9 downto 0);
        ball_pos_y  : out STD_LOGIC_VECTOR(9 downto 0)
    );
end component;

constant CLK_PERIOD : time := 40 ns; -- 25 MHz clock

-- Signals
signal clk         : std_logic := '0';
signal reset       : std_logic := '0';
signal ball_dir_x  : std_logic := '0';
signal ball_dir_y  : std_logic := '0';
signal paddle_x    : unsigned(9 downto 0) := to_unsigned(280, 10); -- Start at center
signal ball_moving : std_logic := '0';
signal game_over   : std_logic := '0';
signal take_sample : std_logic := '0';
signal ball_pos_x  : std_logic_vector(9 downto 0);
signal ball_pos_y  : std_logic_vector(9 downto 0);

begin

-- Instantiate the Unit Under Test (UUT)
uut: ball
    generic map (
        BALL_SPEED  => 5,
        BALL_RADIUS => 15,
        PADDLE_WIDTH => 80,
        PADDLE_HEIGHT => 10,
        MAX_X => 640,
        MAX_Y => 380,
        MIN_X => 0,
        MIN_Y => 0
    )
    port map (
        clk         => clk,
        reset       => reset,
        ball_dir_x  => ball_dir_x,
        ball_dir_y  => ball_dir_y,
        paddle_x    => paddle_x,
        ball_moving => ball_moving,
        game_over   => game_over,
        take_sample => take_sample,
        ball_pos_x  => ball_pos_x,
        ball_pos_y  => ball_pos_y
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
    paddle_x <= to_unsigned(280, 10); -- Center paddle
    reset <= '1';
    wait for CLK_PERIOD*2;
    reset <= '0';
    wait for CLK_PERIOD*2;
    
    -- Test 2: Ball follows paddle when not moving
    ball_moving <= '0';
    paddle_x <= to_unsigned(300, 10);
    wait for CLK_PERIOD*5;
    paddle_x <= to_unsigned(320, 10);
    wait for CLK_PERIOD*5;
    
    -- Test 3: Ball movement right and up
    ball_moving <= '1';
    ball_dir_x <= '1'; -- Right
    ball_dir_y <= '1'; -- Up
    wait for CLK_PERIOD*10;
    
    -- Test 4: Ball movement left and down
    ball_dir_x <= '0'; -- Left
    ball_dir_y <= '0'; -- Down
    wait for CLK_PERIOD*10;
    
    -- Test 5: Game over prevents movement
    game_over <= '1';
    ball_dir_x <= '1'; -- Try to move right
    ball_dir_y <= '1'; -- Try to move up
    wait for CLK_PERIOD*10;
    
    -- Test 6: Test boundary conditions
    game_over <= '0';
    reset <= '1';
    wait for CLK_PERIOD*1;
    reset <= '0';
    ball_dir_x <= '1'; -- Move right
    ball_dir_y <= '0'; -- Move up
    wait for CLK_PERIOD*100; -- Long enough to hit MAX_X or MAX_Y
    
    wait;
end process;

end testbench;