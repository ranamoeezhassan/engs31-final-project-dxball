library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_controller is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        ball_pos_x  : in unsigned(9 downto 0);
        ball_pos_y  : in unsigned(9 downto 0);
        paddle_pos_x : in unsigned(9 downto 0);
        btn_center  : in std_logic;
        paddle_width: in integer;
        paddle_height: in integer;
        ball_radius : in integer;
        ball_dir_x : out std_logic;
        ball_dir_y: out std_logic;
        ball_moving: out std_logic
    );
end game_controller;

architecture Behavioral of game_controller is
    constant MAX_X : integer := 640;
    constant MAX_Y : integer := 380;
    constant MIN_X : integer := 0;
    constant MIN_Y : integer := 0;

    type state_type is (Idle, Playing, LOSE, WIN);
    signal current_state, next_state : state_type := Idle;

    -- Registered direction and moving signals
    signal ball_dir_x_reg, ball_dir_y_reg : std_logic := '0';
    signal ball_moving_reg : std_logic := '0';

    -- Signals used only inside combinational output logic (next direction)
    signal ball_dir_x_next, ball_dir_y_next : std_logic;
    signal ball_moving_next : std_logic;

    signal ball_x_int, ball_y_int : integer := 0;
    signal paddle_x_int : integer := 0;
    signal paddle_left, paddle_right : integer := 0;

begin
    -- Datapath
    process(clk)
    begin
        if rising_edge(clk) then
            ball_x_int   <= to_integer(ball_pos_x);
            ball_y_int   <= to_integer(ball_pos_y);
            paddle_x_int <= to_integer(paddle_pos_x);
            paddle_left <= paddle_x_int;
            paddle_right <= paddle_x_int + paddle_width;
            
            if reset = '1' then
                ball_dir_x_reg <= '0'; -- initial direction left
                ball_dir_y_reg <= '0'; -- initial direction up
                ball_moving_reg <= '0';
            else
                -- Update registered directions and moving with next computed values
                ball_dir_x_reg <= ball_dir_x_next;
                ball_dir_y_reg <= ball_dir_y_next;
                ball_moving_reg <= ball_moving_next;
            end if;
        end if;
    end process;
    
    -- Output ports
    ball_dir_x <= ball_dir_x_reg;
    ball_dir_y <= ball_dir_y_reg;
    ball_moving <= ball_moving_reg;
    
    ------- FSM --------
    -- State register
    process(clk)
    begin
        if rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Next state logic (unchanged)
    process(current_state, btn_center, reset, ball_y_int)
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
                elsif ball_y_int > MAX_Y then
                    next_state <= LOSE;
                end if;
            when WIN =>
                null;
            when LOSE =>
                null;
        end case;
    end process;

    -- State output and ball direction/moving next value logic (combinational)
    process(current_state, ball_x_int, ball_y_int, paddle_left, paddle_right,
            ball_dir_x_reg, ball_dir_y_reg)
    begin
        -- Default output assignments = hold current
        ball_dir_x_next <= ball_dir_x_reg;
        ball_dir_y_next <= ball_dir_y_reg;
        ball_moving_next <= '0';

        case current_state is
            when Idle =>
                ball_moving_next <= '0';

                ball_dir_x_next <= '0';
                ball_dir_y_next <= '0';

            when Playing =>
                ball_moving_next <= '1';

                -- Check collision with left wall
                if (ball_x_int - ball_radius) <= MIN_X then
                    ball_dir_x_next <= '1'; -- move right
                -- Check collision with right wall
                elsif (ball_x_int + ball_radius) >= MAX_X then
                    ball_dir_x_next <= '0'; -- move left
                end if;

                -- Check collision with top wall
                if (ball_y_int - ball_radius) <= MIN_Y then
                    ball_dir_y_next <= '1'; -- move down
                end if;

                -- Check paddle collision (near bottom)
                if (ball_dir_y_reg = '1') and                             -- ball moving down
                   (ball_y_int + ball_radius) >= (MAX_Y - paddle_height) and  -- ball bottom hits top of paddle
                   (ball_y_int + ball_radius) <= MAX_Y and                 -- ball still above the bottom
                   (ball_x_int >= paddle_left) and (ball_x_int <= paddle_right) then
                    ball_dir_y_next <= '0'; -- bounce up
                end if;

            when WIN =>
                ball_moving_next <= '0';

            when LOSE =>
                ball_moving_next <= '0';

        end case;
    end process;

end Behavioral;
