library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_controller is
    generic (
        BALL_RADIUS    : integer := 10;
        PADDLE_WIDTH   : integer := 80;
        PADDLE_HEIGHT  : integer := 10;
        MAX_Y          : integer := 380
    );
    port (
        clk         : in  std_logic;                     -- 25.175 MHz pixel clock
        row         : in  std_logic_vector(9 downto 0); -- Vertical position (0-479)
        column      : in  std_logic_vector(9 downto 0); -- Horizontal position (0-639)
        paddle_x    : in  std_logic_vector(9 downto 0); -- Paddle X position
        ball_x      : in  std_logic_vector(9 downto 0); -- Ball X position
        ball_y      : in  std_logic_vector(9 downto 0); -- Ball Y position
        active      : in  std_logic;                    -- Active display signal
        brick_grid  : in  std_logic_vector(49 downto 0);
        state       : in std_logic_vector(1 downto 0);
        brick_rom_color : in std_logic_vector(11 downto 0);
        color       : out std_logic_vector(11 downto 0) -- RGB output (4 bits per color)
    );
end display_controller;

architecture Behavioral of display_controller is
    constant WHITE : std_logic_vector(11 downto 0) := "111111111111";
    constant BLACK : std_logic_vector(11 downto 0) := "000000000000";
    constant RED   : std_logic_vector(11 downto 0) := "111100000000";
    constant BLUE  : std_logic_vector(11 downto 0) := "000000001111"; -- Bricks
    constant PADDLE_Y : integer := MAX_Y - PADDLE_HEIGHT;  -- Paddle y-position
    constant BALL_RADIUS_SQ : integer := BALL_RADIUS * BALL_RADIUS;
    constant BRICK_ROWS : integer := 5;
    constant BRICK_COLS : integer := 10;
    constant BRICK_WIDTH : integer := 64;
    constant BRICK_HEIGHT : integer := 32;  
    
    constant GAME_OVER_IMAGE_WIDTH  : integer := 83;
    constant GAME_OVER_IMAGE_HEIGHT : integer := 127;
    constant GAME_OVER_IMAGE_TOP    : integer := (480 - GAME_OVER_IMAGE_HEIGHT) / 2;
    constant GAME_OVER_IMAGE_LEFT   : integer := (640 - GAME_OVER_IMAGE_WIDTH) / 2;

    signal row_int, col_int, paddle_x_int, ball_x_int, ball_y_int, dist_sq: integer;
    
    signal brick_row, brick_col : integer;
    signal paddle_on, ball_on : std_logic;
    
    signal game_over_row : std_logic_vector(6 downto 0);
    signal game_over_col : std_logic_vector(6 downto 0);
    signal game_over_color: std_logic_vector(11 downto 0);
    
    signal display_game_over_pixel : std_logic := '0';
    signal display_game_over_pixel_d : std_logic := '0'; -- 1-cycle delayed signal

    
    component game_over_rom is
      Port (
        clk        : in  std_logic;
        row        : in  std_logic_vector(6 downto 0);
        col        : in  std_logic_vector(6 downto 0);
        color_data : out std_logic_vector(11 downto 0)
      );
    end component;
   

begin
    game_over_rom_data: game_over_rom port map (
    clk => clk,
    row => game_over_row,
    col => game_over_col,
    color_data => game_over_color
    );
    
    process(clk)
    begin
        if rising_edge(clk) then
            -- Convert inputs to integers (always needed)
            row_int <= to_integer(unsigned(row));
            col_int <= to_integer(unsigned(column));
            paddle_x_int <= to_integer(unsigned(paddle_x));
            ball_x_int <= to_integer(unsigned(ball_x));
            ball_y_int <= to_integer(unsigned(ball_y));
    
            -- Default to background
            color <= BLACK;
    
            -- GAME OVER LOGIC
            if state = "10" or state = "11" then
                if row_int >= GAME_OVER_IMAGE_TOP and row_int < GAME_OVER_IMAGE_TOP + GAME_OVER_IMAGE_HEIGHT and
                   col_int >= GAME_OVER_IMAGE_LEFT and col_int < GAME_OVER_IMAGE_LEFT + GAME_OVER_IMAGE_WIDTH then
    
                    game_over_row <= std_logic_vector(to_unsigned(row_int - GAME_OVER_IMAGE_TOP, 7));
                    game_over_col <= std_logic_vector(to_unsigned(col_int - GAME_OVER_IMAGE_LEFT, 7));
                    display_game_over_pixel <= '1';
                else
                    display_game_over_pixel <= '0';
                end if;
    
                -- One-cycle delay to let ROM output valid color
                display_game_over_pixel_d <= display_game_over_pixel;
    
                if display_game_over_pixel_d = '1' then
                    color <= game_over_color;
                end if;
    
            elsif active = '1' then
                -- Draw paddle
                if row_int >= PADDLE_Y and row_int < PADDLE_Y + PADDLE_HEIGHT and
                   col_int >= paddle_x_int and col_int < paddle_x_int + PADDLE_WIDTH then
                    color <= WHITE;
                end if;
    
                -- Draw ball (circular)
                dist_sq <= (row_int - ball_y_int) * (row_int - ball_y_int) + 
                           (col_int - ball_x_int) * (col_int - ball_x_int);
    
                if dist_sq <= BALL_RADIUS_SQ then
                    color <= RED;
                end if;
    
                -- Draw bricks
                brick_row <= row_int / BRICK_HEIGHT;
                brick_col <= col_int / BRICK_WIDTH;
                if brick_row < BRICK_ROWS and brick_col < BRICK_COLS then
                    if brick_grid(brick_row * BRICK_COLS + brick_col) = '1' then
                        color <= brick_rom_color;
                    end if;
                end if;
            else
                color <= BLACK;
            end if;
        end if;
    end process;

end Behavioral;