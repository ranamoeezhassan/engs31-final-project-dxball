----------------------------------------------------------------------------------
-- Engineer:		J. Graham Keggi
-- 
-- Create Date:	15:10:36 07/12/2010 
-- Module Name:	vga_test_pattern
-- Target Device:	Basys3
--
-- Description:	Draws components in the VGA
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ball_test is
    generic (BALL_RADIUS : integer := 15);
    port (
        clk     : in std_logic;
        row, column : in std_logic_vector(9 downto 0);
        ball_x : in std_logic_vector(9 downto 0);
        ball_y : in std_logic_vector(9 downto 0);
        color : out std_logic_vector(11 downto 0)
    );
end ball_test;

architecture Behavioral of ball_test is
    constant WHITE : std_logic_vector(11 downto 0) := (others => '1');
    constant BLACK : std_logic_vector(11 downto 0) := (others => '0');
    signal row_int, col_int, ball_x_int, ball_y_int : integer := 0;
    signal dist_sq : integer := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            row_int <= to_integer(unsigned(row));
            col_int <= to_integer(unsigned(column));
            ball_x_int <= to_integer(unsigned(ball_x));
            ball_y_int <= to_integer(unsigned(ball_y));

            dist_sq <= ((row_int - ball_y_int)*(row_int - ball_y_int)) + ((col_int - ball_x_int)*(col_int - ball_x_int));

            if dist_sq <= BALL_RADIUS*BALL_RADIUS then
                color <= WHITE;  -- pixel inside the ball
            else
                color <= BLACK;  -- background pixel
            end if;
        end if;
    end process;
end Behavioral;