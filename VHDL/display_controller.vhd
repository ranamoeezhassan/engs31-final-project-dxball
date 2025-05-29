library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_controller is
    generic (
        BALL_RADIUS    : integer := 15;
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
        color       : out std_logic_vector(11 downto 0) -- RGB output (4 bits per color)
    );
end display_controller;

architecture Behavioral of display_controller is
    constant WHITE : std_logic_vector(11 downto 0) := "111111111111";
    constant BLACK : std_logic_vector(11 downto 0) := "000000000000";
    constant RED   : std_logic_vector(11 downto 0) := "111100000000";
    constant PADDLE_Y : integer := MAX_Y - PADDLE_HEIGHT;  -- Paddle y-position
    constant BALL_RADIUS_SQ : integer := BALL_RADIUS * BALL_RADIUS;
    
    signal row_int, col_int, paddle_x_int, ball_x_int, ball_y_int, dist_sq: integer;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if active = '1' then
                -- Convert inputs to integers
                row_int <= to_integer(unsigned(row));
                col_int <= to_integer(unsigned(column));
                paddle_x_int <= to_integer(unsigned(paddle_x));
                ball_x_int <= to_integer(unsigned(ball_x));
                ball_y_int <= to_integer(unsigned(ball_y));

                -- Default to background
                color <= BLACK; 

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
            else
                color <= BLACK;  -- Blank during non-active periods
            end if;
        end if;
    end process;
end Behavioral;