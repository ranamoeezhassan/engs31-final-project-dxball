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
    type state_type is (Idle, Playing, LOSE, WIN);
    signal current_state, next_state : state_type := Idle;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    process(current_state, btn_center, reset)
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
                end if;
                
            when WIN =>
                null;
            when LOSE =>
                null;
        end case;
    end process;

    ball_start_x <= paddle_x + to_unsigned(paddle_width/2, 10);
    ball_start_y <= to_unsigned(360 - ball_radius - 1, 10); -- fixed paddle y position - ball radius offset

    launch_ball <= '1' when current_state = Playing else '0';

end Behavioral;
