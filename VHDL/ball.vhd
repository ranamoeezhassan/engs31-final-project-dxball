library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ball is
    Generic ( 
        BALL_SPEED  : integer := 5;
        BALL_RADIUS : integer := 15;
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
        take_sample : in STD_LOGIC;
        ball_pos_x  : out STD_LOGIC_VECTOR(9 downto 0);  -- Ball x position
        ball_pos_y  : out STD_LOGIC_VECTOR(9 downto 0)   -- Ball y position
    );
end ball;

architecture Behavioral of ball is
    constant BALL_STARTING_Y : unsigned := to_unsigned(MAX_Y - PADDLE_HEIGHT - BALL_RADIUS - 1, 10);  -- Center start
    signal ball_x_reg : unsigned(9 downto 0);  -- Initialized in process
    signal ball_y_reg : unsigned(9 downto 0) := BALL_STARTING_Y;  -- Center start

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                ball_x_reg <= paddle_x + to_unsigned(paddle_width/2, 10);
                ball_y_reg <= BALL_STARTING_Y;
            elsif game_over = '0' then  -- Only update if game is not over
                if take_sample = '1' then
                    if ball_moving = '1' then                                            -- Ball moves independently                        
                        if ball_dir_x = '1' and ball_x_reg < MAX_X - BALL_RADIUS then    -- Right trajectory
                            ball_x_reg <= ball_x_reg + BALL_SPEED;
                        elsif ball_dir_x = '0' and ball_x_reg > MIN_X + BALL_RADIUS then -- Left trajectory 
                            ball_x_reg <= ball_x_reg - BALL_SPEED;
                        end if;
                        if ball_dir_y = '1' and ball_y_reg < MAX_Y - BALL_RADIUS then    -- Upper trajectory
                            ball_y_reg <= ball_y_reg + BALL_SPEED;
                        elsif ball_dir_y = '0' and ball_y_reg > MIN_Y + BALL_RADIUS then -- Lower trajectory
                            ball_y_reg <= ball_y_reg - BALL_SPEED;
                        end if;
                    else
                        -- Ball follows paddle when not moving
                        ball_x_reg <= paddle_x + to_unsigned(paddle_width/2, 10);
                        ball_y_reg <= BALL_STARTING_Y;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    ball_pos_x <= std_logic_vector(ball_x_reg);
    ball_pos_y <= std_logic_vector(ball_y_reg);
end Behavioral;