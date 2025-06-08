library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_controller_tb is
end game_controller_tb;

architecture tb of game_controller_tb is

    component game_controller is
        generic (
            PADDLE_WIDTH : integer := 80;
            PADDLE_HEIGHT : integer := 10;
            BALL_RADIUS : integer := 10;
            MAX_X : integer := 640;
            MAX_Y : integer := 380;
            MIN_X : integer := 0;
            MIN_Y : integer := 0;
            BRICK_ROWS : integer := 5;
            BRICK_COLS : integer := 10;
            BRICK_WIDTH : integer := 64;
            BRICK_HEIGHT : integer := 32
        );
        port (
            clk             : in std_logic;
            reset           : in std_logic;
            ball_pos_x      : in unsigned(9 downto 0);
            ball_pos_y      : in unsigned(9 downto 0);
            paddle_pos_x    : in unsigned(9 downto 0);
            btn_center      : in std_logic;
            brick_grid      : in std_logic_vector(49 downto 0);
            hit_brick_index : out integer range 0 to 49;
            hit_request     : out std_logic;
            ball_dir_x      : out std_logic;
            ball_dir_y      : out std_logic;
            ball_moving     : out std_logic;
            game_over       : out std_logic;
            score           : out std_logic_vector(15 downto 0);
            win_signal      : out std_logic
        );
    end component;

    -- Signals
    signal clk, reset, btn_center : std_logic := '0';
    signal paddle_pos_x : unsigned(9 downto 0) := to_unsigned(128, 10);
    signal ball_pos_x : unsigned(9 downto 0) := to_unsigned(128, 10);
    signal ball_pos_y : unsigned(9 downto 0) := to_unsigned(300, 10);
    
    signal brick_grid : std_logic_vector(49 downto 0) := (others => '1');
    signal hit_brick_index : integer range 0 to 49;
    signal hit_request, ball_dir_x, ball_dir_y, ball_moving, game_over, win_signal : std_logic := '0';
    signal score : std_logic_vector(15 downto 0);

    constant CLK_PERIOD : time := 40 ns;

begin

    -- Clock Generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- DUT
    uut: game_controller
        port map (
            clk             => clk,
            reset           => reset,
            ball_pos_x      => ball_pos_x,
            ball_pos_y      => ball_pos_y,
            paddle_pos_x    => paddle_pos_x,
            btn_center      => btn_center,
            brick_grid      => brick_grid,
            hit_brick_index => hit_brick_index,
            hit_request     => hit_request,
            ball_dir_x      => ball_dir_x,
            ball_dir_y      => ball_dir_y,
            ball_moving     => ball_moving,
            game_over       => game_over,
            score           => score,
            win_signal      => win_signal
        );

    -- Stimulus Process
    stim_proc : process
    begin
        ------------------------------------------------------------
        -- Start Game
        ------------------------------------------------------------

        btn_center <= '1';  -- Launch the ball
        wait for CLK_PERIOD;
        btn_center <= '0';
        wait for 100 ns;

        -- Test Case 1: Single Brick Hit at (col=2, row=2), index=22
        ball_pos_x <= to_unsigned(128, 10); -- 128/64 = col 2
        ball_pos_y <= to_unsigned(64, 10);  -- 64/32 = row 2, index = 22
        wait for 200 ns;

        -- Test Case 2: Another Brick Hit at (col=3, row=1), index=13
        ball_pos_x <= to_unsigned(192, 10); -- col 3
        ball_pos_y <= to_unsigned(32, 10);  -- row 1, index = 13
        wait for 200 ns;

        -- Test Case 3: Ball outside brick region (no hit)
        ball_pos_x <= to_unsigned(400, 10); -- col 6
        ball_pos_y <= to_unsigned(200, 10); -- below brick rows
        wait for 200 ns;

        -- Test Case 4: Win Condition → All bricks = '0' except one
        brick_grid <= (others => '0');
        brick_grid(25) <= '1';  -- One brick left
        ball_pos_x <= to_unsigned(320, 10); -- col 5
        ball_pos_y <= to_unsigned(64, 10);  -- row 2 → index = 25
        wait for 200 ns;
        brick_grid(25) <= '0';  -- Now hit → win_signal should go high
        wait for 400 ns;

        -- Test Case 5: Game Over Trigger → Ball drops below paddle
        reset <= '1'; wait for CLK_PERIOD; reset <= '0';
        btn_center <= '1'; wait for CLK_PERIOD; btn_center <= '0';

        ball_pos_y <= to_unsigned(400, 10); -- beyond MAX_Y
        wait for 200 ns;

        wait;
    end process;

end tb;
