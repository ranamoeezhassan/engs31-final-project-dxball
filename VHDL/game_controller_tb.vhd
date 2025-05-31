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
            clk         : in std_logic;
            reset       : in std_logic;
            ball_pos_x  : in unsigned(9 downto 0);
            ball_pos_y  : in unsigned(9 downto 0);
            paddle_pos_x : in unsigned(9 downto 0);
            btn_center  : in std_logic;
            brick_grid  : in std_logic_vector(BRICK_ROWS * BRICK_COLS - 1 downto 0);
            hit_brick_index : out integer range 0 to BRICK_ROWS*BRICK_COLS - 1;
            hit_request     : out std_logic;
            ball_dir_x  : out std_logic;
            ball_dir_y  : out std_logic;
            ball_moving : out std_logic;
            game_over   : out std_logic;
            score       : out std_logic_vector(15 downto 0);
            win_signal  : out std_logic
        );
    end component;
  
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
        clk         : in STD_LOGIC;          -- 25 MHz clock
        reset       : in STD_LOGIC;          -- Active-high reset
        ball_dir_x  : in STD_LOGIC;
        ball_dir_y  : in STD_LOGIC;
        paddle_x    : in unsigned(9 downto 0);
        ball_moving : in std_logic;
        game_over   : in STD_LOGIC;          -- Input from game_controller
        take_sample : in STD_LOGIC;
        ball_pos_x  : out STD_LOGIC_VECTOR(9 downto 0);  -- Ball x position
        ball_pos_y  : out STD_LOGIC_VECTOR(9 downto 0)   -- Ball y position
      );
  	end component;
  	
      component paddle is
        Generic (
            PADDLE_WIDTH  : integer := 80;
            MAX_X         : integer := 640
        );
        Port (
            clk          : in STD_LOGIC;          -- 25 MHz clock
            reset        : in STD_LOGIC;          -- Active-high reset
            btn_left_db  : in STD_LOGIC;          -- Debounced left button
            btn_right_db : in STD_LOGIC;          -- Debounced right button
            game_over    : in STD_LOGIC;          -- Input from game_controller
            take_sample : in STD_LOGIC;
            paddle_x     : out STD_LOGIC_VECTOR(9 downto 0)  -- Paddle's left x-coordinate
        );
    	end component;
  
    constant CLK_PERIOD : time := 40 ns; -- 25 MHz clock

    -- Clock + Input Signals
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';
    signal btn_center    : std_logic := '0';
    signal btn_left_db   : std_logic := '0';
    signal btn_right_db  : std_logic := '0';
    signal brick_grid    : std_logic_vector(49 downto 0) := (others => '1');
    signal take_sample   : std_logic;

    -- Shared Game Signals
    signal paddle_pos_x  : std_logic_vector(9 downto 0);
    signal ball_pos_x    : std_logic_vector(9 downto 0);
    signal ball_pos_y    : std_logic_vector(9 downto 0);
    signal ball_dir_x    : std_logic;
    signal ball_dir_y    : std_logic;
    signal ball_moving   : std_logic;
    signal game_over     : std_logic;
    signal score         : std_logic_vector(15 downto 0);
    signal win_signal    : std_logic;
    signal hit_brick_index : integer range 0 to 49;
    signal hit_request     : std_logic;

    -- Converted types
    signal paddle_x_unsigned : unsigned(9 downto 0);

begin
    -- Clock process
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    
        -- Faster take_sample for simulation
    process(clk)
        variable counter : integer := 0;
    begin
        if rising_edge(clk) then
            if counter = 0 then
                take_sample <= '1';
            else
                take_sample <= '0';
            end if;

            if counter < 10 then
                counter := counter + 1;
            else
                counter := 0;
            end if;
        end if;
    end process;


    -- DUT instantiation: Game Controller
    uut: game_controller
        generic map (PADDLE_WIDTH => 640)
        port map (
            clk             => clk,
            reset           => reset,
            ball_pos_x      => unsigned(ball_pos_x),
            ball_pos_y      => unsigned(ball_pos_y),
            paddle_pos_x    => unsigned(paddle_pos_x),
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

    -- Paddle instantiation
    paddle_inst: paddle
        generic map (
            PADDLE_WIDTH => 640,
            MAX_X        => 640
        )
        port map (
            clk          => clk,
            reset        => reset,
            btn_left_db  => btn_left_db,
            btn_right_db => btn_right_db,
            game_over    => game_over,
            take_sample  => take_sample,
            paddle_x     => paddle_pos_x
        );

    -- Ball instantiation
    ball_inst: ball
        generic map (
            BALL_SPEED   => 50,
            BALL_RADIUS  => 15,
            PADDLE_WIDTH => 640,
            PADDLE_HEIGHT => 10,
            MAX_X        => 640,
            MAX_Y        => 380,
            MIN_X        => 0,
            MIN_Y        => 0
        )
        port map (
            clk         => clk,
            reset       => reset,
            ball_dir_x  => ball_dir_x,
            ball_dir_y  => ball_dir_y,
            paddle_x    => unsigned(paddle_pos_x),
            ball_moving => ball_moving,
            game_over   => game_over,
            take_sample => take_sample,
            ball_pos_x  => ball_pos_x,
            ball_pos_y  => ball_pos_y
        );

    -- Test sequence
    stim_proc: process
    begin
        -- Initial Reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- Start the game
        btn_center <= '1';
        wait for 5*CLK_PERIOD;
        btn_center <= '0';

        -- Let simulation run for a while

        wait;
    end process;
end tb;
