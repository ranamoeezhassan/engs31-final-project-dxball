library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity paddle is
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
        paddle_x     : out STD_LOGIC_VECTOR(9 downto 0)  -- Paddle's left x-coordinate
    );
end paddle;

architecture Behavioral of paddle is
    constant PADDLE_MAX_X : integer := MAX_X - PADDLE_WIDTH;  -- Max x to stay in 640-pixel display
    constant FRAME_DIVIDER : integer := 416667;  -- ~60 Hz updates (25 MHz / 416667 ? 60 Hz)
    signal paddle_x_reg : unsigned(9 downto 0) := to_unsigned(280, 10);  -- Start at x=280 (center)
    signal frame_counter : unsigned(18 downto 0) := (others => '0');  -- Counter for 60 Hz updates
begin
    process(clk, reset)
    begin
        if reset = '1' then
            paddle_x_reg <= to_unsigned(280, 10);  -- Center paddle
            frame_counter <= (others => '0');
        elsif rising_edge(clk) then
            if game_over = '0' then  -- Only update if game is not over
                frame_counter <= frame_counter + 1;
                if frame_counter = FRAME_DIVIDER - 1 then
                    frame_counter <= (others => '0');
                    -- Move paddle if button is held and within bounds
                    if btn_left_db = '1' and btn_right_db = '0' and paddle_x_reg > 0 then
                        paddle_x_reg <= paddle_x_reg - 5;  -- Move left by 5 pixels
                    elsif btn_right_db = '1' and btn_left_db = '0' and paddle_x_reg < PADDLE_MAX_X then
                        paddle_x_reg <= paddle_x_reg + 5;  -- Move right by 5 pixels
                    end if;
                end if;
            end if;
        end if;
    end process;

    paddle_x <= std_logic_vector(paddle_x_reg);
end Behavioral;