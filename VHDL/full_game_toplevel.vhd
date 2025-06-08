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
entity full_game_toplevel is
    port (
        ext_clk : in std_logic;
        reset : in std_logic;        -- Down button
        btn_center : in std_logic;  -- Center button to launch ball
        hsync : out std_logic;
        vsync : out std_logic;
        rgb : out std_logic_vector(11 downto 0);
        seg_ext_port		    : out std_logic_vector(0 to 6);
        dp_ext_port				: out std_logic;
        an_ext_port				: out std_logic_vector(3 downto 0);
        spi_s_data_ext_port : in std_logic;
        spi_cs_ext_port : out std_logic;
        spi_sclk_ext_port : out std_logic;
        spi_trigger_ext_port : out std_logic
    );
end entity;

--=============================================================================
--Architecture
--=============================================================================
architecture testbench of full_game_toplevel is
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
        system_clk_port		: out std_logic;
		fwd_clk_port		: out std_logic);
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Sample Tick Generation for SPI
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component tick_generator is
	generic (
	   FREQUENCY_DIVIDER_RATIO : integer);
	port (
		system_clk_port : in  std_logic;
		tick_port	    : out std_logic);
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Frame Divider for Ball
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
        state       : in std_logic_vector(1 downto 0);
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
--Spi Receiver
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component spi_receiver is
	generic(
		N_SHIFTS			: integer);
	port(
		clk_port			: in  std_logic;	--1 MHz serial clock
    	 
		take_sample_port 	: in  std_logic;	--controller signals
		spi_cs_port		    : out std_logic;

		spi_s_data_port	    : in  std_logic;	--datapath signals
		adc_data_port		: out std_logic_vector(11 downto 0));
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
        MAX_X         : integer := 640;
        ADC_BITS      : integer := 12;
        PADDLE_SPEED  : integer := 5
    );
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        adc_data     : in std_logic_vector(11 downto 0); 
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
        hit_brick_index : in integer range 0 to BRICK_ROWS*BRICK_COLS - 1;
        hit_request     : in std_logic;
        brick_grid  : out std_logic_vector(BRICK_ROWS * BRICK_COLS - 1 downto 0)
    );
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Binary to BCD converter:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component bin2bcd is
    Port (
        bin_in  : in std_logic_vector(15 downto 0); -- Input binary score
        game_state : in std_logic_vector(1 downto 0);    -- Game state input
        y0_display    : out std_logic_vector(4 downto 0); -- Units
        y1_display    : out std_logic_vector(4 downto 0); -- Tens
        y2_display    : out std_logic_vector(4 downto 0); -- Hundreds
        y3_display    : out std_logic_vector(4 downto 0)  -- Thousands
    );
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--7-Segment Display:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component mux7seg is
    Port ( clk_port 	: in  std_logic;						--should get the 1 MHz system clk
         y3_port 		: in  std_logic_vector(4 downto 0);		--left most digit
         y2_port 		: in  std_logic_vector(4 downto 0);		--center left digit
         y1_port 		: in  std_logic_vector(4 downto 0);		--center right digit
         y0_port 		: in  std_logic_vector(4 downto 0);		--right most digit
         dp_set_port 	: in  std_logic_vector(3 downto 0);     --decimal points
         seg_port 	: out  std_logic_vector(0 to 6);		--segments (a...g)
         dp_port 		: out  std_logic;						--decimal point
         an_port 		: out  std_logic_vector (3 downto 0) );	--anodes
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
        win_signal  : out std_logic;
        score       : out std_logic_vector(15 downto 0);
        state_out  : out std_logic_vector(1 downto 0)
    );
end component;

component brick_rom is
  Port (
    clk        : in  std_logic;
    row        : in  std_logic_vector(9 downto 0);
    col        : in  std_logic_vector(9 downto 0);
    color_data : out std_logic_vector(11 downto 0)
  );
end component;


--=============================================================================
--Game Constants
--=============================================================================
constant PADDLE_WIDTH_C   : integer := 80;
constant PADDLE_HEIGHT_C  : integer := 10;
constant PADDLE_Y_C       : integer := 360;
constant PADDLE_SPEED_C   : integer := 5;

constant BALL_RADIUS_C    : integer := 12;
constant BALL_SPEED_C       : integer := 3;

constant BRICK_ROWS_C         : integer := 5;
constant BRICK_COLS_C       : integer := 10;
constant BRICK_WIDTH_C       : integer := 64;
constant BRICK_HEIGHT_C       : integer := 32;


constant SCREEN_MAX_X     : integer := 640;
constant SCREEN_MAX_Y     : integer := 380;
constant SCREEN_MIN_X     : integer := 0;
constant SCREEN_MIN_Y     : integer := 0;

constant ADC_BITS        : integer := 12;

--=============================================================================
--Signals
--=============================================================================
signal system_clk 	: std_logic := '0';
signal pixel_x, pixel_y, paddle_x, ball_pos_x, ball_pos_y : std_logic_vector(9 downto 0);

signal video_on 	: std_logic := '0';
signal btn_left_db, btn_right_db, btn_center_db, reset_db : std_logic;
signal launch_ball : std_logic;

signal hit_request, win_signal : std_logic := '0';
signal hit_brick_index: integer range 0 to (BRICK_ROWS_C*BRICK_COLS_C - 1) := 0 ;
signal brick_grid : std_logic_vector(49 downto 0);

-- Signal for Game Controller outputs
signal ball_start_x_sig : unsigned(9 downto 0);
signal ball_start_y_sig : unsigned(9 downto 0);
signal ball_dir_x, ball_dir_y, new_dir_x, new_dir_y, ball_moving, game_over_sg : std_logic;
signal take_sample : std_logic;
signal score : std_logic_vector(15 downto 0);

-- Signals (add to existing signal declarations)
signal y3_display, y2_display, y1_display, y0_display : std_logic_vector(3 downto 0);
signal dp_set : std_logic_vector(3 downto 0) := "0000";
signal overflow         : std_logic := '0'; --You get this one for free
signal game_state : std_logic_vector(1 downto 0);

signal take_sample_adc : std_logic := '0';
signal adc_data : std_logic_vector(11 downto 0) := (others => '0');
signal spi_clk : std_logic := '0';
signal clk_counter : unsigned(6 downto 0) := (others => '0'); -- Increased to 7 bits

-- Internal signals
signal bcd0, bcd1, bcd2, bcd3 : std_logic_vector(4 downto 0);

--=============================================================================
--Port Mappings
--=============================================================================
begin
-- Clock
clocking: system_clock_generation 
generic map( CLK_DIVIDER_RATIO => 4 )          
port map(
    input_clk_port => ext_clk,
    system_clk_port => system_clk,
    fwd_clk_port => open );

-- Clock for SPI
-- Clock divider process (1 MHz from 100 MHz)
spi_clocking: system_clock_generation 
generic map( CLK_DIVIDER_RATIO => 49 )          
port map(
    input_clk_port => ext_clk,
    system_clk_port => spi_clk,
    fwd_clk_port => open );

-- Tick generator for SPI controlled paddle movement
tick_generation: tick_generator
generic map( FREQUENCY_DIVIDER_RATIO => 25000 )
port map( 
    system_clk_port => spi_clk,
    tick_port => take_sample_adc );
spi_trigger_ext_port <= take_sample_adc;
spi_sclk_ext_port <= spi_clk;

-- Frame divider for Ball movement
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

-- SPI Receiver
receiver: spi_receiver
generic map ( N_SHIFTS => ADC_BITS )
port map (
    clk_port => spi_clk,
    take_sample_port => take_sample_adc,
    spi_cs_port => spi_cs_ext_port,
    spi_s_data_port => spi_s_data_ext_port,
    adc_data_port => adc_data );

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
        state => game_state,
        color    => rgb
    );

-- Paddle controller
paddle_ctrl: paddle
    generic map (
        PADDLE_WIDTH => PADDLE_WIDTH_C,
        PADDLE_SPEED => PADDLE_SPEED_C,
        MAX_X => SCREEN_MAX_X,
        ADC_BITS => ADC_BITS
        )
    port map (
        clk => system_clk,
        reset => reset_db,
        paddle_x => paddle_x,
        game_over => game_over_sg,
        take_sample => take_sample_adc,
        adc_data => adc_data
);

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Wire the 7-segment display into the shell with a port map:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
binary2bcd : bin2bcd port map(
        bin_in  	=> score,
        game_state  => game_state,
        y0_display    	=> bcd0,
        y1_display    	=> bcd1,
        y2_display    	=> bcd2,
        y3_display    	=> bcd3
    );

seven_seg: mux7seg port map(
        clk_port	=> system_clk,		--should get the 1 MHz system clk
        y3_port		=> bcd3,		--left most digit
        y2_port 	=> bcd2,		--center left digit
        y1_port 	=> bcd1,		--center right digit (don't use this one)
        y0_port 	=> bcd0,		--right most digit
        dp_set_port => dp_set,	--you get this one for free too
        seg_port 	=> seg_ext_port,
        dp_port 	=> dp_ext_port,
        an_port 	=> an_ext_port);

-- Game Controller
game_ctrl: game_controller
    generic map (
        PADDLE_WIDTH => PADDLE_WIDTH_C,
        PADDLE_HEIGHT => PADDLE_HEIGHT_C,
        BALL_RADIUS => BALL_RADIUS_C,
        MAX_X => SCREEN_MAX_X,
        MAX_Y => SCREEN_MAX_Y,
        MIN_X => SCREEN_MIN_X,
        MIN_Y => SCREEN_MIN_Y,
        BRICK_ROWS => BRICK_ROWS_C,
        BRICK_COLS => BRICK_COLS_C,
        BRICK_WIDTH => BRICK_WIDTH_C,
        BRICK_HEIGHT => BRICK_HEIGHT_C
    )
    port map (
        clk => system_clk,
        reset => reset_db,
        ball_pos_x  => unsigned(ball_pos_x),
        ball_pos_y => unsigned(ball_pos_y),
        paddle_pos_x => unsigned(paddle_x), 
        btn_center  => btn_center_db,
        brick_grid  => brick_grid,
        hit_brick_index => hit_brick_index,
        hit_request => hit_request,
        win_signal => win_signal,
        ball_dir_x => ball_dir_x,
        ball_dir_y => ball_dir_y,
        ball_moving => ball_moving,
        game_over => game_over_sg,
        score => score,
        state_out => game_state
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
        BRICK_ROWS  => BRICK_ROWS_C,
        BRICK_COLS  => BRICK_COLS_C,
        BRICK_WIDTH => BRICK_WIDTH_C,
        BRICK_HEIGHT => BRICK_HEIGHT_C,
        BALL_RADIUS => 10
    )
    port map (
        clk         => system_clk,
        reset       => reset_db,    
        hit_brick_index => hit_brick_index,
        hit_request => hit_request,
        brick_grid => brick_grid
    );  
  
end testbench;