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
entity dxball_toplevel is
    port (
        ext_clk : in std_logic;
        btn_left : in std_logic;     -- Left button (e.g., btnL)
        btn_right : in std_logic;    -- Right button (e.g., btnR)
        reset : in std_logic;        -- Down burron
        hsync : out std_logic;
        vsync : out std_logic;
        rgb : out std_logic_vector(11 downto 0)
    );
end entity;

--=============================================================================
--Architecture
--=============================================================================
architecture testbench of dxball_toplevel is

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

component vga_test_pattern is
    port (
        row, column : in std_logic_vector(9 downto 0);
        paddle_x : in std_logic_vector(9 downto 0);
        color : out std_logic_vector(11 downto 0)
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
--Paddle Controller:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component paddle_controller
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        btn_left_db : in STD_LOGIC;
        btn_right_db : in STD_LOGIC;
        paddle_x : out STD_LOGIC_VECTOR(9 downto 0)
    );
end component;
--=============================================================================
--Signals
--=============================================================================
signal system_clk 	: std_logic := '0';
signal pixel_x, pixel_y, paddle_x, ball_x, ball_y : std_logic_vector(9 downto 0);

signal video_on 	: std_logic := '0';
signal btn_left_db, btn_right_db : std_logic;

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

-- VGA Display Driver
vga_pattern_maker: vga_test_pattern
port map (
	row => pixel_y,
	column => pixel_x,
    paddle_x => paddle_x,
	
	color => rgb);

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

-- Paddle controller
paddle_ctrl: paddle_controller
    port map (
        clk => system_clk,
        reset => reset,
        btn_left_db => btn_left_db,
        btn_right_db => btn_right_db,
        paddle_x => paddle_x
);
end testbench;
