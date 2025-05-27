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
    generic (
        BALL_RADIUS : integer;
        BALL_SPEED : integer;
        PADDLE_Y : integer;
        PADDLE_WIDTH : integer
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        launch : in std_logic;
        ball_start_x : in unsigned(9 downto 0);
        ball_start_y : in unsigned(9 downto 0);
        paddle_x : in unsigned(9 downto 0);
        ball_pos_x : out std_logic_vector(9 downto 0);
        ball_pos_y : out std_logic_vector(9 downto 0)
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
        paddle_x : out STD_LOGIC_VECTOR(9 downto 0)
    );
end component;

component game_controller
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        btn_center  : in std_logic;
        paddle_x    : in unsigned(9 downto 0);
        paddle_width: in integer;
        ball_radius : in integer;
        ball_start_x: out unsigned(9 downto 0);
        ball_start_y: out unsigned(9 downto 0);
        launch_ball : out std_logic
    );
end component;
--=============================================================================
--Signals
--=============================================================================
signal system_clk 	: std_logic := '0';
signal pixel_x, pixel_y, paddle_x, ball_pos_x, ball_pos_y : std_logic_vector(9 downto 0);

signal video_on 	: std_logic := '0';
signal btn_left_db, btn_right_db, btn_center_db : std_logic;
signal launch_ball : std_logic;

-- Signal for Game Controller outputs
signal ball_start_x_sig : unsigned(9 downto 0);
signal ball_start_y_sig : unsigned(9 downto 0);

constant PADDLE_WIDTH_C : integer := 80;
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
	reset => reset,
	
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
        reset => reset,
        btn_left_db => btn_left_db,
        btn_right_db => btn_right_db,
        paddle_x => paddle_x
);

game_ctrl : game_controller
    port map (
        clk => system_clk,
        reset => reset,
        btn_center => btn_center_db,
        paddle_x => unsigned(paddle_x),
        paddle_width => PADDLE_WIDTH_C,
        ball_radius => BALL_RADIUS_C,
        ball_start_x => ball_start_x_sig,
        ball_start_y => ball_start_y_sig,
        launch_ball => launch_ball
    );

-- Ball controller (no paddle collision here)
ball_ctrl : ball
    generic map (
        BALL_SPEED => 5,
        BALL_RADIUS => BALL_RADIUS_C,
        PADDLE_WIDTH => PADDLE_WIDTH_C,
        PADDLE_Y => PADDLE_Y_C
    )
    port map (
        clk => system_clk,
        reset => reset,
        launch => launch_ball,
        ball_start_x => ball_start_x_sig,
        ball_start_y => ball_start_y_sig,
        paddle_x => unsigned(paddle_x),
        ball_pos_x => ball_pos_x,
        ball_pos_y => ball_pos_y
    );
    
-- Game controller

end testbench;
