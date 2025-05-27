library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ball is
    Generic( 
        BALL_SPEED : integer := 5;
        BALL_RADIUS : integer := 15
    );
    Port (
        clk : in STD_LOGIC;          -- 25 MHz clock
        reset : in STD_LOGIC;        -- Active-high reset
        ball_dir_x : in STD_LOGIC;
        ball_dir_y : in STD_LOGIC;
        paddle_x : in unsigned(9 downto 0);
        paddle_width: in integer;
        ball_moving: in std_logic;
        ball_pos_x : out STD_LOGIC_VECTOR(9 downto 0);  -- 
        ball_pos_y : out STD_LOGIC_VECTOR(9 downto 0)
    );
end ball;

architecture Behavioral of ball is
    constant MAX_X : integer := 640;
    constant MAX_Y : integer := 380;
    constant MIN_X : integer := 0;
    constant MIN_Y : integer := 0;
    constant BALL_STARTING_Y : unsigned := to_unsigned(370 - ball_radius - 1, 10);  -- Center start
    constant BALL_STARTING_X : unsigned(9 downto 0) := paddle_x + to_unsigned(paddle_width/2, 10);  -- Center start

    constant FRAME_DIVIDER : integer := 416667;  -- 25MHz / 416667 ~ 60 Hz
    signal frame_counter : unsigned(18 downto 0) := (others => '0');

    signal ball_x_reg : unsigned(9 downto 0) := BALL_STARTING_X;  -- Center start
    signal ball_y_reg : unsigned(9 downto 0) := BALL_STARTING_Y;  -- Center start
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                ball_x_reg <= paddle_x + to_unsigned(paddle_width/2, 10);
                ball_y_reg <= BALL_STARTING_Y;
                frame_counter <= (others => '0');
            else
                frame_counter <= frame_counter + 1;
                if frame_counter = FRAME_DIVIDER - 1 then
                    frame_counter <= (others => '0');
                    if ball_moving = '1' then
                        -- Ball moves independently
                        if ball_dir_x = '1' and ball_x_reg < MAX_X - BALL_RADIUS then
                            ball_x_reg <= ball_x_reg + BALL_SPEED;
                        elsif ball_dir_x = '0' and ball_x_reg > MIN_X + BALL_RADIUS then
                            ball_x_reg <= ball_x_reg - BALL_SPEED;
                        end if;
                        if ball_dir_y = '1' and ball_y_reg < MAX_Y - BALL_RADIUS then
                            ball_y_reg <= ball_y_reg + BALL_SPEED;
                        elsif ball_dir_y = '0' and ball_y_reg > MIN_Y + BALL_RADIUS then
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