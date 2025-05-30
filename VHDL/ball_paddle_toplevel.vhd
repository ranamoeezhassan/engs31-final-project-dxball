--=============================================================================
--Library Declarations:
--=============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;


--=============================================================================
--Entity Declaration:
--=============================================================================
entity ball_paddle_toplevel is
    port (
        ext_clk : in std_logic;
        btn_left : in std_logic;     -- Left button (e.g., btnL)
        btn_right : in std_logic;    -- Right button (e.g., btnR)
        reset : in std_logic;        -- Down button
        btn_center : in std_logic;  -- Center button to launch ball
        hsync : out std_logic;
        vsync : out std_logic;
        rgb : out std_logic_vector(11 downto 0)
    );
end entity;

--=============================================================================
--Architecture
--=============================================================================
architecture testbench of ball_paddle_toplevel is
--=============================================================================
--Component Declaration
--=============================================================================

--=============================================================================
--System Clock Generation
--=============================================================================
component system_clock_generation is
    Generic( CLK_DIVIDER_RATIO : integer := 25  );
    Port (
        --External Clock:
        input_clk_port		: in std_logic;
        --System Clock:
        system_clk_port		: out std_logic);
end component;

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

--=============================================================================
--Display Controller
--=============================================================================
component display_controller
    generic (
        BALL_RADIUS    : integer := 15;
        PADDLE_WIDTH   : integer := 80;
        PADDLE_HEIGHT  : integer := 10;
        MAX_Y          : integer := 380
    );
    port (
        clk         : in  std_logic;
        row         : in  std_logic_vector(9 downto 0);
        column      : in  std_logic_vector(9 downto 0);
        paddle_x    : in  std_logic_vector(9 downto 0);
        ball_x      : in  std_logic_vector(9 downto 0);
        ball_y      : in  std_logic_vector(9 downto 0);
        active      : in  std_logic;
        brick_grid  : in  std_logic_vector(49 downto 0);
        color       : out std_logic_vector(11 downto 0)
    );
end component;

--=============================================================================
--VGA Controller
--=============================================================================
component vga_sync is
    port (
        game_clk : in  std_logic; -- 25 MHz game clock
        reset    : in  std_logic;

        hsync    : out std_logic;
        vsync    : out std_logic;
		
        video_on : out std_logic;
        pixel_x  : out std_logic_vector(9 downto 0);
        pixel_y  : out std_logic_vector(9 downto 0)
    );
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Button Input Conditioning
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component button_interface is
    Generic(
        STABLE_TIME : integer );
    Port( clk_port           : in  std_logic;
         button_port         : in  std_logic;
         button_db_port      : out std_logic;
         button_mp_port      : out std_logic);
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Ball Controller:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component ball is
    Generic ( 
        BALL_SPEED  : integer := 5;
        BALL_RADIUS : integer := 10;
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
        take_sample : in std_logic;
        ball_pos_x  : out STD_LOGIC_VECTOR(9 downto 0);  -- Ball x position
        ball_pos_y  : out STD_LOGIC_VECTOR(9 downto 0)   -- Ball y position
    );
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Paddle Controller:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component paddle
    Generic (
        PADDLE_WIDTH  : integer := 80;
        MAX_X         : integer := 640
    );
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        btn_left_db : in STD_LOGIC;
        btn_right_db : in STD_LOGIC;
        game_over : in STD_LOGIC;
        take_sample : in STD_LOGIC;
        paddle_x : out STD_LOGIC_VECTOR(9 downto 0)
    );
end component;

--=============================================================================
--Brick Controller
--=============================================================================
component brick_controller is
    generic (
        BRICK_ROWS   : integer := 5;
        BRICK_COLS   : integer := 10;
        BRICK_WIDTH  : integer := 64;
        BRICK_HEIGHT : integer := 32;
        BALL_RADIUS  : integer := 10
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        ball_x      : in  std_logic_vector(9 downto 0);
        ball_y      : in  std_logic_vector(9 downto 0);
        ball_dir_x  : in  std_logic;
        ball_dir_y  : in  std_logic;
        game_over   : in  std_logic;
        brick_grid  : out std_logic_vector(BRICK_ROWS * BRICK_COLS - 1 downto 0);
        brick_hit   : out std_logic;
        new_dir_x   : out std_logic;                    -- New x direction
        new_dir_y   : out std_logic;                    -- New y direction
        win_signal  : out std_logic
    );
end component;

--=============================================================================
--Game Controller
--=============================================================================
component game_controller is
    generic (
        PADDLE_WIDTH : integer := 80;
        PADDLE_HEIGHT : integer := 10;
        BALL_RADIUS : integer := 10;
        MAX_X : integer := 640;
        MAX_Y : integer := 380;
        MIN_X : integer := 0;
        MIN_Y : integer := 0
    );
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        ball_pos_x  : in unsigned(9 downto 0);
        ball_pos_y  : in unsigned(9 downto 0);
        paddle_pos_x : in unsigned(9 downto 0);
        brick_hit   : in std_logic;
        new_dir_x   : in std_logic;
        new_dir_y   : in std_logic;
        win_signal  : in std_logic;
        btn_center  : in std_logic;
        ball_dir_x  : out std_logic;
        ball_dir_y  : out std_logic;
        ball_moving : out std_logic;
        game_over   : out std_logic; -- New output to signal LOSE state
        score       : out std_logic_vector(15 downto 0)
    );
end component;

--=============================================================================
--Game Constants
--=============================================================================
constant PADDLE_WIDTH_C   : integer := 80;
constant PADDLE_HEIGHT_C  : integer := 10;
constant PADDLE_Y_C       : integer := 360;
constant BALL_RADIUS_C    : integer := 10;
constant BALL_SPEED_C       : integer := 5;
constant SCREEN_MAX_X     : integer := 640;
constant SCREEN_MAX_Y     : integer := 380;
constant SCREEN_MIN_X     : integer := 0;
constant SCREEN_MIN_Y     : integer := 0;

--=============================================================================
--Signals
--=============================================================================
signal system_clk 	: std_logic := '0';
signal pixel_x, pixel_y, paddle_x, ball_pos_x, ball_pos_y : std_logic_vector(9 downto 0);

signal video_on 	: std_logic := '0';
signal btn_left_db, btn_right_db, btn_center_db, reset_db : std_logic;
signal launch_ball : std_logic;

signal brick_hit, win_signal : std_logic := '0';
signal brick_grid : std_logic_vector(49 downto 0);

-- Signal for Game Controller outputs
signal ball_start_x_sig : unsigned(9 downto 0);
signal ball_start_y_sig : unsigned(9 downto 0);
signal ball_dir_x, ball_dir_y, new_dir_x, new_dir_y, ball_moving, game_over_sg : std_logic;
signal take_sample : std_logic;

--=============================================================================
--Port Mappings
--=============================================================================
begin

-- Clock
clocking: system_clock_generation 
generic map(
	CLK_DIVIDER_RATIO => 4)          
port map(
	input_clk_port 		=> ext_clk,
	system_clk_port 	=> system_clk);
	

frame_dividing: frame_divider 
generic map ( DIVIDE_BY => 416667)
port map (
    clk => system_clk,
    reset => reset_db,
    take_sample => take_sample
);

	
-- VGA Controller
vga_synchronizer: vga_sync
port map (
	game_clk => system_clk,
	reset => reset_db,
	
	hsync => hsync,
	vsync => vsync,
	
	video_on => video_on,
	pixel_x => pixel_x,
	pixel_y => pixel_y);


-- Left Button
left_button_debouncer: button_interface
    generic map ( STABLE_TIME => 100 )
    port map (
        clk_port => system_clk,
        button_port => btn_left,
        button_db_port => btn_left_db,
        button_mp_port => open
    );

-- Right Button
right_button_debouncer: button_interface
    generic map ( STABLE_TIME => 100 )
    port map (
        clk_port => system_clk,
        button_port => btn_right,
        button_db_port => btn_right_db,
        button_mp_port => open
    );

-- Center Button
center_button_debouncer: button_interface
    generic map ( STABLE_TIME => 100 )
    port map (
        clk_port => system_clk,
        button_port => btn_center,
        button_db_port => btn_center_db,
        button_mp_port => open
    ); 

-- Reset Button
reset_button_debouncer: button_interface
    generic map ( STABLE_TIME => 100 )
    port map (
        clk_port => system_clk,
        button_port => reset,
        button_db_port => reset_db,
        button_mp_port => open
    ); 
    
-- Display Controller
disp_ctrl: display_controller
    generic map (
        BALL_RADIUS =>  BALL_RADIUS_C,
        PADDLE_WIDTH =>  PADDLE_WIDTH_C,
        PADDLE_HEIGHT => PADDLE_HEIGHT_C,
        MAX_Y => SCREEN_MAX_Y
    )
    port map (
        clk      => system_clk,
        row      => pixel_y,
        column   => pixel_x,
        paddle_x => paddle_x,
        ball_x   => ball_pos_x,
        ball_y   => ball_pos_y,
        active   => video_on,
        brick_grid => brick_grid,
        color    => rgb
    );

-- Paddle controller
paddle_ctrl: paddle
    generic map (
        PADDLE_WIDTH => PADDLE_WIDTH_C,
        MAX_X => SCREEN_MAX_X
        )
    port map (
        clk => system_clk,
        reset => reset_db,
        btn_left_db => btn_left_db,
        btn_right_db => btn_right_db,
        paddle_x => paddle_x,
        game_over => game_over_sg,
        take_sample => take_sample
);

-- Game Controller
game_ctrl: game_controller
    generic map (
        PADDLE_WIDTH => PADDLE_WIDTH_C,
        PADDLE_HEIGHT => PADDLE_HEIGHT_C,
        BALL_RADIUS => BALL_RADIUS_C,
        MAX_X => SCREEN_MAX_X,
        MAX_Y => SCREEN_MAX_Y,
        MIN_X => SCREEN_MIN_X,
        MIN_Y => SCREEN_MIN_Y
    )
    port map (
        clk => system_clk,
        reset => reset_db,
        ball_pos_x  => unsigned(ball_pos_x),
        ball_pos_y => unsigned(ball_pos_y),
        paddle_pos_x => unsigned(paddle_x), 
        btn_center  => btn_center_db,
        brick_hit  => brick_hit,
        new_dir_x  => new_dir_x,
        new_dir_y  => new_dir_y,
        win_signal => win_signal,
        ball_dir_x => ball_dir_x,
        ball_dir_y => ball_dir_y,
        ball_moving => ball_moving,
        game_over => game_over_sg
    );
    
-- Ball controller 
ball_ctrl : ball
    generic map (
        BALL_SPEED => BALL_SPEED_C,
        BALL_RADIUS => BALL_RADIUS_C,
        PADDLE_WIDTH => PADDLE_WIDTH_C,
        PADDLE_HEIGHT => PADDLE_HEIGHT_C,
        MAX_X => SCREEN_MAX_X,
        MAX_Y => SCREEN_MAX_Y,
        MIN_X => SCREEN_MIN_X,
        MIN_Y => SCREEN_MIN_Y
    )
    port map (
        clk => system_clk,
        reset => reset_db,
        ball_pos_x => ball_pos_x,
        ball_pos_y => ball_pos_y,
        ball_dir_x => ball_dir_x,
        ball_dir_y => ball_dir_y,
        paddle_x => unsigned(paddle_x),
        ball_moving => ball_moving,
        game_over => game_over_sg,
        take_sample => take_sample
    );
    
-- Brick controller 
brick_ctrl : brick_controller
    generic map (
        BRICK_ROWS  => 5,
        BRICK_COLS  => 10,
        BRICK_WIDTH => 64,
        BRICK_HEIGHT => 32,
        BALL_RADIUS => 10
    )
    port map (
        clk         => system_clk,
        reset       => reset_db,
        ball_x      => ball_pos_x,
        ball_y      => ball_pos_y,
        ball_dir_x  => ball_dir_x,
        ball_dir_y  => ball_dir_y,
        game_over   => game_over_sg,
        brick_grid  => brick_grid,
        brick_hit   => brick_hit,
        new_dir_x   => new_dir_x,                    -- New x direction
        new_dir_y   => new_dir_y,                    -- New y direction
        win_signal  => win_signal
    );
end testbench;
