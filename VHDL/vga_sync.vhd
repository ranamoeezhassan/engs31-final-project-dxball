-- Rana Moeez Hassan
-- ENGS31 Final Project
-- VGA Screen Synchronizer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
    port (
        game_clk : in  std_logic; -- 25 MHz game clock
        reset    : in  std_logic;

        hsync    : out std_logic;
        vsync    : out std_logic;
        video_on : out std_logic;

        pixel_x  : out std_logic_vector(9 downto 0);
        pixel_y  : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of vga_sync is

    -- VGA 640x480 @ 60Hz Timing Constants
    constant H_DISPLAY       : integer := 640;
    constant H_L_BORDER      : integer := 48;
    constant H_R_BORDER      : integer := 16;
    constant H_RETRACE       : integer := 96;
    constant H_MAX           : integer := H_DISPLAY + H_L_BORDER + H_R_BORDER + H_RETRACE - 1;
    constant START_H_RETRACE : integer := H_DISPLAY + H_R_BORDER;
    constant END_H_RETRACE   : integer := START_H_RETRACE + H_RETRACE - 1;

    constant V_DISPLAY       : integer := 380;
    constant V_T_BORDER      : integer := 10;
    constant V_B_BORDER      : integer := 33;
    constant V_RETRACE       : integer := 2;
    constant V_MAX           : integer := V_DISPLAY + V_T_BORDER + V_B_BORDER + V_RETRACE - 1 - 4; -- -4 for our 25 MHz clock
    constant START_V_RETRACE : integer := V_DISPLAY + V_B_BORDER;
    constant END_V_RETRACE   : integer := START_V_RETRACE + V_RETRACE - 1;

    -- Position counters
    signal h_count : unsigned(9 downto 0) := (others => '0');
    signal v_count : unsigned(9 downto 0) := (others => '0');

begin

    -- VGA Counter Process
    process(game_clk)
    begin
        if rising_edge(game_clk) then
            if reset = '1' then
                h_count <= (others => '0');
                v_count <= (others => '0');
            else
                if h_count = to_unsigned(H_MAX, 10) then
                    h_count <= (others => '0');
                    if v_count = to_unsigned(V_MAX, 10) then
                        v_count <= (others => '0');
                    else
                        v_count <= v_count + 1;
                    end if;
                else
                    h_count <= h_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- Sync signals (active low)
    hsync <= '0' when (to_integer(h_count) >= START_H_RETRACE and to_integer(h_count) <= END_H_RETRACE) else '1';
    vsync <= '0' when (to_integer(v_count) >= START_V_RETRACE and to_integer(v_count) <= END_V_RETRACE) else '1';

    -- Display enable (only true inside visible region)
    video_on <= '1' when (to_integer(h_count) < H_DISPLAY and to_integer(v_count) < V_DISPLAY) else '0';

    -- Output pixel coordinates
    pixel_x <= std_logic_vector(h_count);
    pixel_y <= std_logic_vector(v_count);

end architecture;
