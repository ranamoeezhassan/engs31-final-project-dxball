library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity brick_controller is
    generic (
        BRICK_ROWS   : integer := 5;
        BRICK_COLS   : integer := 10;
        BRICK_WIDTH  : integer := 64;
        BRICK_HEIGHT : integer := 32;
        BALL_RADIUS  : integer := 10
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        hit_brick_index : in integer range 0 to BRICK_ROWS*BRICK_COLS - 1;
        hit_request     : in std_logic;
        brick_grid  : out std_logic_vector(BRICK_ROWS * BRICK_COLS - 1 downto 0)
    );
end brick_controller;

architecture Behavioral of brick_controller is
    signal brick_grid_reg : std_logic_vector(BRICK_ROWS * BRICK_COLS - 1 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Initialize all bricks as active
                brick_grid_reg <= (others => '1');
            else
                -- Detect rising edge of hit_request (new hit)
                if hit_request = '1' then
                    -- Only update if the brick is still active
                    if brick_grid_reg(hit_brick_index) = '1' then
                        brick_grid_reg(hit_brick_index ) <= '0';  -- Mark brick as hit
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- Output the registered brick grid
    brick_grid <= brick_grid_reg;
end Behavioral;