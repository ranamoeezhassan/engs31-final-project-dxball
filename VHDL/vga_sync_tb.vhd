library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync_tb is
end entity;

architecture sim of vga_sync_tb is

    -- DUT signals
    signal game_clk  : std_logic := '0';
    signal reset     : std_logic := '1';
    signal hsync     : std_logic;
    signal vsync     : std_logic;
    signal video_on  : std_logic;
    signal pixel_x   : std_logic_vector(9 downto 0);
    signal pixel_y   : std_logic_vector(9 downto 0);

    -- Clock period constant (25 MHz)
    constant CLK_PERIOD : time := 10 ns;
    
    component vga_sync is
    port (
        game_clk : in  std_logic; -- 100 MHz game clock
        reset    : in  std_logic;

        hsync    : out std_logic;
        vsync    : out std_logic;
        video_on : out std_logic;

        pixel_x  : out std_logic_vector(9 downto 0);
        pixel_y  : out std_logic_vector(9 downto 0)
    );
	end component;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: vga_sync
        port map (
            game_clk => game_clk,
            reset    => reset,
            hsync    => hsync,
            vsync    => vsync,
            video_on => video_on,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y
        );

    -- Clock process
    clk_process : process
    begin
      game_clk <= '0';
      wait for CLK_PERIOD / 2;
      game_clk <= '1';
	  wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Initial reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';

        -- Allow simulation to run
        wait for 15 ms;
        
    end process;

end architecture;
