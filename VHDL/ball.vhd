library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ball is
    Generic( 
        BALL_SPEED : integer := 5;
        BALL_RADIUS : integer := 15;
        PADDLE_WIDTH : integer := 80;
        PADDLE_Y : integer := 10
    );
    Port (
        clk : in STD_LOGIC;          -- 25 MHz clock
        reset : in STD_LOGIC;        -- Active-high reset
        launch : in STD_LOGIC;
        ball_start_x : in unsigned(9 downto 0);  -- Starting position from controller
        ball_start_y : in unsigned(9 downto 0);
        paddle_x     : in unsigned(9 downto 0);
        ball_pos_x : out STD_LOGIC_VECTOR(9 downto 0);  -- 
        ball_pos_y : out STD_LOGIC_VECTOR(9 downto 0)
    );
end ball;

architecture Behavioral of ball is
    constant MAX_X : integer := 640;
    constant MAX_Y : integer := 380;
    constant MIN_X : integer := 0;
    constant MIN_Y : integer := 0;

    constant FRAME_DIVIDER : integer := 416667;  -- 25MHz / 416667 ~ 60 Hz
    signal frame_counter : unsigned(18 downto 0) := (others => '0');

    signal ball_x_reg : unsigned(9 downto 0) := to_unsigned(320, 10);  -- Center start
    signal ball_y_reg : unsigned(9 downto 0) := to_unsigned(240, 10);  -- Center start
    
    -- direction: 1 = right/down, 0 = left/up
    signal dir_x : std_logic := '1';  -- start moving right
    signal dir_y : std_logic := '0';  -- start moving up

    signal ball_active : std_logic := '0';
    
begin
    process(clk, reset)
    begin       
        if rising_edge(clk) then
            if reset = '1' then
                frame_counter <= (others => '0');
                ball_x_reg <= ball_start_x;
                ball_y_reg <= ball_start_y;
                
                dir_x <= '1';
                dir_y <= '0';
                
                ball_active <= '0';
            else
                frame_counter <= frame_counter + 1;
                
                if launch = '1' then
                    ball_active <= '1';
                end if;
                
                if ball_active = '0' then
                    ball_x_reg <= ball_start_x;
                    ball_y_reg <= ball_start_y;
                    dir_x <= '1';
                    dir_y <= '0';
                else
                    if frame_counter = FRAME_DIVIDER - 1 then
                        frame_counter <= (others => '0');
                        
                        -- Move X
                        if dir_x = '1' then
                            if to_integer(ball_x_reg) + BALL_SPEED >= (MAX_X - BALL_RADIUS) then
                                dir_x <= '0';
                            else
                                ball_x_reg <= ball_x_reg + BALL_SPEED;
                            end if;
                        else
                            if to_integer(ball_x_reg) < (MIN_X + BALL_RADIUS + BALL_SPEED) then
                                dir_x <= '1';
                            else
                                ball_x_reg <= ball_x_reg - BALL_SPEED;
                            end if;
                        end if;
                        
                        -- Move Y
                        if dir_y = '1' then
                            if to_integer(ball_y_reg) + BALL_SPEED >= (MAX_Y - BALL_RADIUS) then
                                dir_y <= '0';
                            else
                                ball_y_reg <= ball_y_reg + BALL_SPEED;
                            end if;
                        else
                            if to_integer(ball_y_reg) < (MIN_Y + BALL_RADIUS + BALL_SPEED) then
                                dir_y <= '1';
                            else
                                ball_y_reg <= ball_y_reg - BALL_SPEED;
                            end if;
                        end if;
                        
                        -- Paddle collision (for Rana)
                                            
                    end if;
                end if;
              end if;
        end if;
    end process;

    ball_pos_x <= std_logic_vector(ball_x_reg);
    ball_pos_y <= std_logic_vector(ball_y_reg);
end Behavioral;