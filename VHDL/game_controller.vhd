library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_controller is
    generic (
        PADDLE_WIDTH : integer := 80;
        PADDLE_HEIGHT : integer := 10;
        BALL_RADIUS : integer := 10;
        MAX_X : integer := 640;
        MAX_Y : integer := 380;
        MIN_X : integer := 0;
        MIN_Y : integer := 0;
        BRICK_ROWS : integer := 5;
        BRICK_COLS : integer := 10;
        BRICK_WIDTH : integer := 64;
        BRICK_HEIGHT : integer := 32
    );
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        ball_pos_x  : in unsigned(9 downto 0);
        ball_pos_y  : in unsigned(9 downto 0);
        paddle_pos_x : in unsigned(9 downto 0);
        btn_center  : in std_logic;
        brick_grid  : in std_logic_vector(BRICK_ROWS * BRICK_COLS - 1 downto 0);
        hit_brick_index : out integer range 0 to BRICK_ROWS*BRICK_COLS - 1;
        hit_request     : out std_logic;
        ball_dir_x  : out std_logic;
        ball_dir_y  : out std_logic;
        ball_moving : out std_logic;
        game_over   : out std_logic;
        score       : out std_logic_vector(15 downto 0);
        win_signal  : out std_logic
    );
end game_controller;

architecture Behavioral of game_controller is
    type state_type is (Idle, Playing, LOSE, WIN);
    signal current_state, next_state : state_type := Idle;

    signal ball_dir_x_reg, ball_dir_y_reg : std_logic := '0';
    signal ball_moving_reg : std_logic := '0';

    signal ball_dir_x_next, ball_dir_y_next : std_logic;
    signal ball_moving_next : std_logic;

    signal ball_x_int, ball_y_int : integer := 0;
    signal paddle_x_int : integer := 0;
    signal paddle_left, paddle_right : integer := 0;
    signal score_int : unsigned(15 downto 0) := (others => '0');

    signal hit_request_reg : std_logic := '0';
    signal hit_brick_index_reg : integer range 0 to BRICK_ROWS*BRICK_COLS - 1 := 0;

    signal brick_row, brick_col, brick_index : integer := 0;
    signal brick_left, brick_right, brick_top, brick_bottom : integer := 0;

    signal prev_ball_x, prev_ball_y : integer := 0;
    signal brick_hit : std_logic := '0';
    signal recent_brick_hit : std_logic := '0';
begin

	-- Calculate brick_row, brick_col, and brick_index asynchronously
    process(ball_pos_x, ball_pos_y)
    begin
        brick_row <= to_integer(ball_pos_y) / BRICK_HEIGHT;
        brick_col <= to_integer(ball_pos_x) / BRICK_WIDTH;
        brick_index <= brick_row * BRICK_COLS + brick_col;
    end process;


    process(clk)
    begin
        if rising_edge(clk) then
            -- Store previous position BEFORE updating
            prev_ball_x <= ball_x_int;
            prev_ball_y <= ball_y_int;

            ball_x_int   <= to_integer(ball_pos_x);
            ball_y_int   <= to_integer(ball_pos_y);
            paddle_x_int <= to_integer(paddle_pos_x);
            paddle_left  <= paddle_x_int;
            paddle_right <= paddle_x_int + PADDLE_WIDTH;

            brick_left   <= brick_col * BRICK_WIDTH;
            brick_right  <= brick_left + BRICK_WIDTH;
            brick_top    <= brick_row * BRICK_HEIGHT;
            brick_bottom <= brick_top + BRICK_HEIGHT;

            if reset = '1' then
                ball_dir_x_reg  <= '0';
                ball_dir_y_reg  <= '0';
                ball_moving_reg <= '0';
                score_int <= (others => '0');
                hit_request_reg <= '0';
                hit_brick_index_reg <= 0;
                recent_brick_hit <= '0';
            else
                ball_dir_x_reg  <= ball_dir_x_next;
                ball_dir_y_reg  <= ball_dir_y_next;
                ball_moving_reg <= ball_moving_next;
                
                -- Only register brick hit once per contact
                if brick_hit = '1' and recent_brick_hit = '0' then
                    score_int <= score_int + 1;
                    hit_request_reg <= '1';
                    hit_brick_index_reg <= brick_index;
                    recent_brick_hit <= '1';
                elsif brick_hit = '0' then
                    recent_brick_hit <= '0';
                    hit_request_reg <= '0';
                end if;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    process(current_state, btn_center, reset, ball_y_int, brick_grid)
    begin
        next_state <= current_state;
        case current_state is
            when Idle =>
                if btn_center = '1' then
                    next_state <= Playing;
                end if;
            when Playing =>
                if reset = '1' then
                    next_state <= Idle;
                elsif ball_y_int + BALL_RADIUS >= MAX_Y then
                    next_state <= LOSE;
                elsif brick_grid = (brick_grid'range => '0') then
                    next_state <= WIN;
                end if;
            when WIN | LOSE =>
                if reset = '1' then
                    next_state <= Idle;
                end if;
        end case;
    end process;

    process(current_state, ball_x_int, ball_y_int, paddle_left, paddle_right,
            ball_dir_x_reg, ball_dir_y_reg, brick_grid, brick_row, brick_col, brick_index,
            brick_left, brick_right, brick_top, brick_bottom, prev_ball_x, prev_ball_y,
            recent_brick_hit)
    begin
        ball_dir_x_next  <= ball_dir_x_reg;
        ball_dir_y_next  <= ball_dir_y_reg;
        ball_moving_next <= '0';
        game_over        <= '0';
        win_signal       <= '0';
        brick_hit        <= '0';

        case current_state is
            when Idle =>
                ball_moving_next <= '0';
                ball_dir_x_next  <= '0';
                ball_dir_y_next  <= '0';

            when Playing =>
                ball_moving_next <= '1';

                if (ball_x_int - BALL_RADIUS) <= MIN_X then
                    ball_dir_x_next <= '1';
                elsif (ball_x_int + BALL_RADIUS) >= MAX_X then
                    ball_dir_x_next <= '0';
                end if;

                if (ball_y_int - BALL_RADIUS) <= MIN_Y then
                    ball_dir_y_next <= '1';
                end if;

                if (ball_dir_y_reg = '1') and
                   (ball_y_int + BALL_RADIUS) >= (MAX_Y - PADDLE_HEIGHT) and
                   (ball_y_int + BALL_RADIUS) < MAX_Y and
                   (ball_x_int >= paddle_left) and (ball_x_int <= paddle_right) then
                    ball_dir_y_next <= '0';
                end if;
                
                if brick_row >= 0 and brick_row < BRICK_ROWS and
                   brick_col >= 0 and brick_col < BRICK_COLS then

                    -- Only access brick_grid if brick_index is in range
                    if brick_index >= 0 and brick_index < BRICK_ROWS * BRICK_COLS then
                        if brick_grid(brick_index) = '1' then
                             if (ball_x_int + BALL_RADIUS >= brick_left) and
                             (ball_x_int - BALL_RADIUS <= brick_right) and
                             (ball_y_int + BALL_RADIUS >= brick_top) and
                             (ball_y_int - BALL_RADIUS <= brick_bottom) then
                                brick_hit <= '1';
                                
                                if recent_brick_hit = '0' then
                                    if (prev_ball_x + BALL_RADIUS <= brick_left) or
                                       (prev_ball_x - BALL_RADIUS >= brick_right) then
                                        ball_dir_x_next <= not ball_dir_x_reg;
                                    elsif (prev_ball_y + BALL_RADIUS <= brick_top) or
                                          (prev_ball_y - BALL_RADIUS >= brick_bottom) then
                                        ball_dir_y_next <= not ball_dir_y_reg;
                                    else
                                        ball_dir_y_next <= not ball_dir_y_reg;
                                    end if;
                                end if;

                                
                          	end if;
                        end if;
                    end if;
                end if;

            when WIN =>
                ball_moving_next <= '0';
                ball_dir_x_next  <= '0';
                ball_dir_y_next  <= '0';
                win_signal       <= '1';

            when LOSE =>
                ball_moving_next <= '0';
                ball_dir_x_next  <= '0';
                ball_dir_y_next  <= '0';
                game_over        <= '1';
        end case;
    end process;

	ball_dir_x <= ball_dir_x_reg;
    ball_dir_y <= ball_dir_y_reg;
    ball_moving <= ball_moving_reg;
    hit_request <= hit_request_reg;
    hit_brick_index <= hit_brick_index_reg;
    score <= std_logic_vector(score_int);

end Behavioral;
