library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bin2bcd_tb is
end bin2bcd_tb;

architecture tb of bin2bcd_tb is

    component bin2bcd is
        Port (
            bin_in     : in std_logic_vector(15 downto 0);
            game_state : in std_logic_vector(1 downto 0);
            y3_display : out std_logic_vector(4 downto 0);
            y2_display : out std_logic_vector(4 downto 0);
            y1_display : out std_logic_vector(4 downto 0);
            y0_display : out std_logic_vector(4 downto 0)
        );
    end component;

    -- Testbench signals
    signal bin_in     : std_logic_vector(15 downto 0);
    signal game_state : std_logic_vector(1 downto 0);
    signal y3_display, y2_display, y1_display, y0_display : std_logic_vector(4 downto 0);

begin

    uut: bin2bcd
        port map (
            bin_in     => bin_in,
            game_state => game_state,
            y3_display => y3_display,
            y2_display => y2_display,
            y1_display => y1_display,
            y0_display => y0_display
        );

    stim_proc: process
    begin
        -- Test: Game State 00 - Idle (Should say PLAY)
        bin_in <= x"0000";
        game_state <= "00";
        wait for 100 ns;

        -- Test: Game State 01 - Playing with score = 1234 (BCD = 0001 0010 0011 0100)
        bin_in <= std_logic_vector(to_unsigned(1234, 16));
        game_state <= "01";
        wait for 100 ns;

        -- Test: Game State 10 - Lose with score = 9999
        bin_in <= std_logic_vector(to_unsigned(9999, 16));
        game_state <= "10";
        wait for 100 ns;

        -- Test: Game State 11 - Win (Should say YAY(space))
        bin_in <= x"0000";
        game_state <= "11";
        wait for 100 ns;

        -- Test: Edge case - Score = 0
        bin_in <= x"0000";
        game_state <= "01";
        wait for 100 ns;

        wait;
    end process;

end tb;
