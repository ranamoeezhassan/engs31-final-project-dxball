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
    
    constant GAME_WIN_IMAGE_WIDTH  : integer := 100;
    constant GAME_WIN_IMAGE_HEIGHT : integer := 149;
    constant GAME_WIN_IMAGE_TOP    : integer := (480 - GAME_WIN_IMAGE_HEIGHT) / 2;
    constant GAME_WIN_IMAGE_LEFT   : integer := (640 - GAME_WIN_IMAGE_WIDTH) / 2;

    signal row_int, col_int, paddle_x_int, ball_x_int, ball_y_int, dist_sq: integer;
    
    signal ball_on_d : std_logic := '0'; 
    
    signal brick_row, brick_col : integer;
    signal paddle_on, ball_on : std_logic;
    
    signal game_over_row : std_logic_vector(6 downto 0);
    signal game_over_col : std_logic_vector(6 downto 0);
    signal game_over_color: std_logic_vector(11 downto 0);
    signal display_game_over_pixel : std_logic := '0';
    signal display_game_over_pixel_d : std_logic := '0'; -- 1-cycle delayed signal
    
    signal brick_pixel_row  : std_logic_vector(4 downto 0); -- 0 to 31 (since brick height is 32)
    signal brick_pixel_col  : std_logic_vector(5 downto 0); -- 0 to 63 (since brick width is 64)
    signal brick_color      : std_logic_vector(11 downto 0);
    signal display_brick_pixel     : std_logic := '0';
    signal display_brick_pixel_d   : std_logic := '0'; -- one-cycle delay for color
    
    
    signal game_win_row  : std_logic_vector(7 downto 0);
    signal game_win_col  : std_logic_vector(6 downto 0); 
    signal game_win_color     : std_logic_vector(11 downto 0);
    signal game_win_pixel     : std_logic := '0';
    signal game_win_pixel_d   : std_logic := '0'; -- one-cycle delay for color
    
    signal ball_pixel_row: std_logic_vector(4 downto 0);
    signal ball_pixel_col: std_logic_vector(4 downto 0);
    signal ball_color : std_logic_vector(11 downto 0);
    
    signal paddle_pixel_row : std_logic_vector(3 downto 0); -- 0 to 9
    signal paddle_pixel_col : std_logic_vector(6 downto 0); -- 0 to 79
    signal paddle_color     : std_logic_vector(11 downto 0);
    signal paddle_on_d      : std_logic := '0'; -- one-cycle delay



    
    component game_over_rom is
      Port (
        clk        : in  std_logic;
        row        : in  std_logic_vector(6 downto 0);
        col        : in  std_logic_vector(6 downto 0);
        color_data : out std_logic_vector(11 downto 0)
      );
    end component;
    
    component game_win_rom is
      Port (
        clk        : in  std_logic;
        row        : in  std_logic_vector(7 downto 0);
        col        : in  std_logic_vector(6 downto 0);
        color_data : out std_logic_vector(11 downto 0)
      );
    end component;

    component brick_rom is
      Port (
        clk        : in  std_logic;
        row        : in  std_logic_vector(4 downto 0);
        col        : in  std_logic_vector(5 downto 0);
        color_data : out std_logic_vector(11 downto 0)
      );
    end component;
    
    component ball_rom is
      Port (
        clk        : in  std_logic;
        row        : in  std_logic_vector(4 downto 0);
        col        : in  std_logic_vector(4 downto 0);
        color_data : out std_logic_vector(11 downto 0)
      );
    end component;
    
    component paddle_rom is
      Port (
        clk        : in  std_logic;
        row        : in  std_logic_vector(3 downto 0);
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
    
    game_win_rom_data: game_win_rom port map (
        clk => clk,
        row => game_win_row,
        col => game_win_col,
        color_data => game_win_color
   );
        
    
    brick_rom_data: brick_rom port map(
        clk => clk,
        row => brick_pixel_row,
        col => brick_pixel_col,
        color_data => brick_color
    );
    
    ball_rom_data: ball_rom port map (
        clk => clk,
        row => ball_pixel_row,
        col => ball_pixel_col,
        color_data => ball_color
    );
    
    paddle_rom_data: paddle_rom port map (
        clk => clk,
        row => paddle_pixel_row,
        col => paddle_pixel_col,
        color_data => paddle_color
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
            if state = "10" then
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
    
            elsif state = "11" then
                if row_int >= GAME_WIN_IMAGE_TOP and row_int < GAME_WIN_IMAGE_TOP + GAME_WIN_IMAGE_HEIGHT and
                   col_int >= GAME_WIN_IMAGE_LEFT and col_int < GAME_WIN_IMAGE_LEFT + GAME_WIN_IMAGE_WIDTH then
            
                    game_win_row <= std_logic_vector(to_unsigned(row_int - GAME_WIN_IMAGE_TOP, 8));
                    game_win_col <= std_logic_vector(to_unsigned(col_int - GAME_WIN_IMAGE_LEFT, 7));
                    game_win_pixel <= '1';
                else
                    game_win_pixel <= '0';
                end if;
            
                -- One-cycle delay for ROM output
                game_win_pixel_d <= game_win_pixel;
            
                if game_win_pixel_d = '1' then
                    color <= game_win_color;
                end if;

            else
                -- Draw paddle
                if row_int >= PADDLE_Y and row_int < PADDLE_Y + PADDLE_HEIGHT and
                   col_int >= paddle_x_int and col_int < paddle_x_int + PADDLE_WIDTH then
                
                    paddle_pixel_row <= std_logic_vector(to_unsigned(row_int - PADDLE_Y, 4));
                    paddle_pixel_col <= std_logic_vector(to_unsigned(col_int - paddle_x_int, 7));
                    paddle_on <= '1';
                else
                    paddle_on <= '0';
                end if;
                
                paddle_on_d <= paddle_on;
                
                if paddle_on_d = '1' then
                    color <= paddle_color;
                end if;

    
                -- Draw ball (circular)
                dist_sq <= (row_int - ball_y_int) * (row_int - ball_y_int) + 
                           (col_int - ball_x_int) * (col_int - ball_x_int);

                
                if dist_sq <= BALL_RADIUS_SQ then
                    ball_pixel_row <= std_logic_vector(to_unsigned(row_int - (ball_y_int - BALL_RADIUS), 5));
                    ball_pixel_col <= std_logic_vector(to_unsigned(col_int - (ball_x_int - BALL_RADIUS), 5));
                    ball_on <= '1';
                else
                    ball_on <= '0';
                end if;
                
                ball_on_d <= ball_on;
                    
                if ball_on_d = '1' then
                    color <= ball_color;
                end if;
    
                
                -- Draw bricks (pixel-based within each brick)
                brick_row <= row_int / BRICK_HEIGHT;
                brick_col <= col_int / BRICK_WIDTH;
                
                if brick_row < BRICK_ROWS and brick_col < BRICK_COLS then
                    if brick_grid(brick_row * BRICK_COLS + brick_col) = '1' then
                        -- Use pixel offset within the brick to access brick ROM
                        brick_pixel_row <= std_logic_vector(to_unsigned(row_int mod BRICK_HEIGHT, 5));
                        brick_pixel_col <= std_logic_vector(to_unsigned(col_int mod BRICK_WIDTH, 6));
                        display_brick_pixel <= '1';
                    else
                        display_brick_pixel <= '0';
                    end if;
                else
                    display_brick_pixel <= '0';
                end if;
                
                -- Pipeline delay
                display_brick_pixel_d <= display_brick_pixel;
                
                -- Apply brick color from ROM
                if display_brick_pixel_d = '1' then
                    color <= brick_color;
                end if;

            end if;
        end if;
    end process;

end Behavioral;