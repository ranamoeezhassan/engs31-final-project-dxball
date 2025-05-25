--=============================================================================
--Library Declarations:
--=============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
library UNISIM;
use UNISIM.VComponents.all;

--=============================================================================
--Entity Declaration:
--=============================================================================
entity vga_toplevel is
    port (
        ext_clk : in std_logic;
        reset : in std_logic;
        hsync : out std_logic;
        vsync : out std_logic;
        rgb : out std_logic_vector(11 downto 0)
    );
end entity;

--=============================================================================
--Architecture
--=============================================================================
architecture testbench of vga_toplevel is

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
	port(row,column			: in std_logic_vector(9 downto 0);
		  color					: out std_logic_vector(11 downto 0));
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

--=============================================================================
--Signals
--=============================================================================
signal system_clk 	: std_logic := '0';
signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
signal video_on 	: std_logic := '0';

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
	
	color => rgb);
	

end testbench;
