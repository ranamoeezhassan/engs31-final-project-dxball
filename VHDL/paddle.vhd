library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity paddle is
    generic (
        PADDLE_WIDTH  : integer := 80;
        MAX_X         : integer := 640;
        ADC_BITS      : integer := 12;
        PADDLE_SPEED_FRACTIONAL : integer := 6  -- 0.375 pixels (6/16 with 4-bit fraction)
    );
    port (
        clk           : in std_logic;
        reset         : in std_logic;
        adc_data      : in std_logic_vector(ADC_BITS-1 downto 0);
        take_sample   : in std_logic;
        game_over     : in std_logic;
        paddle_x      : out std_logic_vector(9 downto 0)
    );
end paddle;

architecture Behavioral of paddle is
    constant PADDLE_MAX_X : integer := MAX_X - PADDLE_WIDTH;  -- Max x = 560
    signal paddle_x_acc   : unsigned(13 downto 0) := to_unsigned(280 * 16, 14);  -- 10-bit integer, 4-bit fraction, start at x=280
    signal paddle_x_reg   : unsigned(9 downto 0);  -- Integer part for output
    
    -- ADC thresholds for high dead zone (12-bit ADC, observed range 0 to 1023)
    constant ADC_MAX      : unsigned(ADC_BITS-1 downto 0) := to_unsigned(1023, ADC_BITS);  -- Observed max
    constant ADC_MID      : unsigned(ADC_BITS-1 downto 0) := to_unsigned(512, ADC_BITS);   -- Midpoint of 0-1023
    constant DEAD_ZONE    : integer := 400;  -- Adjusted for 0-1023 range
    constant LEFT_THRESH  : unsigned(ADC_BITS-1 downto 0) := to_unsigned(512 - DEAD_ZONE, ADC_BITS);  -- ~112
    constant RIGHT_THRESH : unsigned(ADC_BITS-1 downto 0) := to_unsigned(900, ADC_BITS);   -- ~900

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                paddle_x_acc <= to_unsigned(280 * 16, 14);  -- Center paddle (280.0)
            elsif game_over = '0' then  -- Only update if game is not over
                if take_sample = '1' then
                    -- Update accumulator based on ADC input
                    if unsigned(adc_data) < LEFT_THRESH and paddle_x_reg > 0 then
                        paddle_x_acc <= paddle_x_acc - PADDLE_SPEED_FRACTIONAL;  -- Move left 0.375 pixels
                    elsif unsigned(adc_data) > RIGHT_THRESH and paddle_x_reg < to_unsigned(PADDLE_MAX_X, 10) then
                        paddle_x_acc <= paddle_x_acc + PADDLE_SPEED_FRACTIONAL;  -- Move right 0.375 pixels
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Extract integer part for output
    paddle_x_reg <= paddle_x_acc(13 downto 4);  -- 10-bit integer part
    paddle_x <= std_logic_vector(paddle_x_reg);
end Behavioral;