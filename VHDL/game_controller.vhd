library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_controller is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        btn_center  : in std_logic;
        paddle_x    : in unsigned(9 downto 0);
        paddle_width: in integer;
        ball_radius : in integer;
        ball_start_x: out unsigned(9 downto 0);
        ball_start_y: out unsigned(9 downto 0);
        launch_ball : out std_logic
    );
end game_controller;

architecture Behavioral of game_controller is
    type state_type is (BALL_ON_PADDLE, BALL_IN_MOTION, LOSE, WIN);
    signal state : state_type := BALL_ON_PADDLE;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            state <= BALL_ON_PADDLE;
        elsif rising_edge(clk) then
            case state is
                when BALL_ON_PADDLE =>
                    if btn_center = '1' then
                        state <= BALL_IN_MOTION;
                    end if;
                when BALL_IN_MOTION =>
                    -- Could add restart logic if ball lost etc.
                    null;
                when WIN =>
                    null;
                when LOSE =>
                    null;
            end case;
        end if;
    end process;

    ball_start_x <= paddle_x + to_unsigned(paddle_width/2, 10);
    ball_start_y <= to_unsigned(360 - ball_radius - 1, 10); -- fixed paddle y position - ball radius offset

    launch_ball <= '1' when state = BALL_IN_MOTION else '0';

end Behavioral;
