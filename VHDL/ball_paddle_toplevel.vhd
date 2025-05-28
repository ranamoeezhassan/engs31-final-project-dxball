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
component system_clock_generation is
    Generic( CLK_DIVIDER_RATIO : integer := 25  );
    Port (
        --External Clock:
        input_clk_port		: in std_logic;
        --System Clock:
        system_clk_port		: out std_logic);
end component;

component display_controller
    generic (
        BALL_RADIUS : integer := 10
    );
    port (
        clk         : in  std_logic;
        row         : in  std_logic_vector(9 downto 0);
        column      : in  std_logic_vector(9 downto 0);
        paddle_x    : in  std_logic_vector(9 downto 0);
        ball_x      : in  std_logic_vector(9 downto 0);
        ball_y      : in  std_logic_vector(9 downto 0);
        active      : in  std_logic;
        color       : out std_logic_vector(11 downto 0)
    );
end component;

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
--Input Conditioning:
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
    Generic( 
        BALL_SPEED : integer := 5;
        BALL_RADIUS : integer := 15
    );
    Port (
        clk : in STD_LOGIC;          -- 25 MHz clock
        reset : in STD_LOGIC;        -- Active-high reset
        ball_dir_x : in STD_LOGIC;
        ball_dir_y : in STD_LOGIC;
        ball_moving: in std_logic;
        paddle_x : in unsigned(9 downto 0);
        paddle_width: in integer;
        game_over : in STD_LOGIC;
        ball_pos_x : out STD_LOGIC_VECTOR(9 downto 0);  -- 
        ball_pos_y : out STD_LOGIC_VECTOR(9 downto 0)
    );
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Paddle Controller:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component paddle
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        btn_left_db : in STD_LOGIC;
        btn_right_db : in STD_LOGIC;
        game_over : in STD_LOGIC;
        paddle_x : out STD_LOGIC_VECTOR(9 downto 0)
    );
end component;

component game_controller is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        ball_pos_x  : in unsigned(9 downto 0);
        ball_pos_y  : in unsigned(9 downto 0);
        paddle_pos_x : in unsigned(9 downto 0);   
        btn_center  : in std_logic;
        paddle_width: in integer;
        paddle_height: in integer;
        ball_radius : in integer;
        ball_dir_x : out std_logic;
        ball_dir_y: out std_logic;
        ball_moving: out std_logic;
        game_over : out std_logic
    );
end component;
--=============================================================================
--Signals
--=============================================================================
signal system_clk 	: std_logic := '0';
signal pixel_x, pixel_y, paddle_x, ball_pos_x, ball_pos_y : std_logic_vector(9 downto 0);

signal video_on 	: std_logic := '0';
signal btn_left_db, btn_right_db, btn_center_db, reset_db : std_logic;
signal launch_ball : std_logic;

-- Signal for Game Controller outputs
signal ball_start_x_sig : unsigned(9 downto 0);
signal ball_start_y_sig : unsigned(9 downto 0);
signal ball_dir_x, ball_dir_y, ball_moving, game_over_sg : std_logic;

constant PADDLE_WIDTH_C : integer := 80;
constant PADDLE_HEIGHT_C : integer := 10;
constant PADDLE_Y_C     : integer := 360;
constant BALL_RADIUS_C  : integer := 10;
--=============================================================================
--Port Map
--=============================================================================
begin

-- Clock
clocking: system_clock_generation 
generic map(
	CLK_DIVIDER_RATIO => 4)          
port map(
	input_clk_port 		=> ext_clk,
	system_clk_port 	=> system_clk);
	
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


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Wire the input conditioning block into the shell with a port map:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Wiring the port map in twice generates two separate instances of one component
left_button_debouncer: button_interface
    generic map ( STABLE_TIME => 100 )
    port map (
        clk_port => system_clk,
        button_port => btn_left,
        button_db_port => btn_left_db,
        button_mp_port => open
    );

right_button_debouncer: button_interface
    generic map ( STABLE_TIME => 100 )
    port map (
        clk_port => system_clk,
        button_port => btn_right,
        button_db_port => btn_right_db,
        button_mp_port => open
    );

center_button_debouncer: button_interface
    generic map ( STABLE_TIME => 100 )
    port map (
        clk_port => system_clk,
        button_port => btn_center,
        button_db_port => btn_center_db,
        button_mp_port => open
    ); 

reset_button_debouncer: button_interface
    generic map ( STABLE_TIME => 100 )
    port map (
        clk_port => system_clk,
        button_port => reset,
        button_db_port => reset_db,
        button_mp_port => open
    ); 
-- VGA Display Driver
disp_ctrl: display_controller
    port map (
        clk      => system_clk,
        row      => pixel_y,
        column   => pixel_x,
        paddle_x => paddle_x,
        ball_x   => ball_pos_x,
        ball_y   => ball_pos_y,
        active   => video_on,
        color    => rgb
    );

-- Paddle controller
paddle_ctrl: paddle
    port map (
        clk => system_clk,
        reset => reset_db,
        btn_left_db => btn_left_db,
        btn_right_db => btn_right_db,
        paddle_x => paddle_x,
        game_over => game_over_sg
);
    
game_ctrl: game_controller
    port map (
        clk => system_clk,
        reset => reset_db,
        ball_pos_x  => unsigned(ball_pos_x),
        ball_pos_y => unsigned(ball_pos_y),
        paddle_pos_x => unsigned(paddle_x), 
        btn_center  => btn_center_db,
        paddle_width => PADDLE_WIDTH_C,
        paddle_height => PADDLE_HEIGHT_C,
        ball_radius => BALL_RADIUS_C,
        ball_dir_x => ball_dir_x,
        ball_dir_y => ball_dir_y,
        ball_moving => ball_moving,
        game_over => game_over_sg
    );

-- Ball controller (no paddle collision here)
ball_ctrl : ball
    generic map (
        BALL_SPEED => 5,
        BALL_RADIUS => BALL_RADIUS_C
    )
    port map (
        clk => system_clk,
        reset => reset_db,
        ball_pos_x => ball_pos_x,
        ball_pos_y => ball_pos_y,
        ball_dir_x => ball_dir_x,
        ball_dir_y => ball_dir_y,
        paddle_x => unsigned(paddle_x),
        paddle_width => PADDLE_WIDTH_C,
        ball_moving => ball_moving,
        game_over => game_over_sg
    );
   

end testbench;
