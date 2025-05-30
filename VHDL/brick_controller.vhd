library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity brick_controller is
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
        ball_dir_x  : in  std_logic;
        ball_dir_y  : in  std_logic;
        ball_x      : in  std_logic_vector(9 downto 0);
        ball_y      : in  std_logic_vector(9 downto 0);
        game_over   : in  std_logic;
        brick_grid  : out std_logic_vector(BRICK_ROWS * BRICK_COLS - 1 downto 0);
        brick_hit   : out std_logic;
        new_dir_x   : out std_logic;                    -- New x direction
        new_dir_y   : out std_logic;                    -- New y direction
        win_signal  : out std_logic
    );
end brick_controller;

architecture Behavioral of brick_controller is
    signal brick_grid_int : std_logic_vector(BRICK_ROWS * BRICK_COLS - 1 downto 0) := (others => '1');
    signal brick_count    : integer range 0 to BRICK_ROWS * BRICK_COLS := BRICK_ROWS * BRICK_COLS;
    signal brick_hit_int  : std_logic := '0';
    signal prev_hit       : std_logic := '0';
    signal new_dir_x_int, new_dir_y_int : std_logic;
begin

    brick_grid <= brick_grid_int;
    brick_hit <= brick_hit_int;
    new_dir_x <= new_dir_x_int;
    new_dir_y <= new_dir_y_int;
    
    process(clk, reset)
        -- No variables used here
    begin
        if reset = '1' then
            brick_grid_int <= (others => '1');
            brick_count <= BRICK_ROWS * BRICK_COLS;
            brick_hit_int <= '0';
            prev_hit <= '0';
            new_dir_x_int <= '0';
            new_dir_y_int <= '0';

        elsif rising_edge(clk) then
            brick_hit_int <= '0';
            if game_over = '0' then
                for row in 0 to BRICK_ROWS - 1 loop
                    for col in 0 to BRICK_COLS - 1 loop
                        -- Only check if this brick is still active
                        if brick_grid_int(row * BRICK_COLS + col) = '1' and prev_hit = '0' then
                            -- Calculate brick bounds
                            if (to_integer(unsigned(ball_x)) + BALL_RADIUS >= col * BRICK_WIDTH) and
                               (to_integer(unsigned(ball_x)) - BALL_RADIUS <= (col + 1) * BRICK_WIDTH - 1) and
                               (to_integer(unsigned(ball_y)) + BALL_RADIUS >= row * BRICK_HEIGHT) and
                               (to_integer(unsigned(ball_y)) - BALL_RADIUS <= (row + 1) * BRICK_HEIGHT - 1) then

                                -- Hit detected
                                brick_grid_int(row * BRICK_COLS + col) <= '0';
                                brick_count <= brick_count - 1;
                                brick_hit_int <= '1';
                                new_dir_x_int <= not ball_dir_x;  -- Reverse x
                                new_dir_y_int <= not ball_dir_y;  -- Reverse y
                            end if;
                        end if;
                    end loop;
                end loop;

                prev_hit <= brick_hit_int;

            else
                prev_hit <= '0';
            end if;
        end if;
    end process;

    win_signal <= '1' when brick_count = 0 else '0';

end Behavioral;
