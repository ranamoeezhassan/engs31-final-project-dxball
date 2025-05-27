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

entity paddle_test is
    port (
        clk : in std_logic;
        row, column : in std_logic_vector(9 downto 0);
        paddle_x : in std_logic_vector(9 downto 0);
        color : out std_logic_vector(11 downto 0)
    );
end paddle_test;

architecture Behavioral of paddle_test is
    constant WHITE : std_logic_vector(11 downto 0) := "111111111111";
    constant BLACK : std_logic_vector(11 downto 0) := "000000000000";
    constant PADDLE_Y : integer := 350;  -- Paddle y-position
    constant PADDLE_WIDTH : integer := 80;
    constant PADDLE_HEIGHT : integer := 10;
begin
    process(clk)
        variable row_int, col_int, paddle_x_int : integer;
    begin
        if rising_edge(clk) then
            row_int := to_integer(unsigned(row));
            col_int := to_integer(unsigned(column));
            paddle_x_int := to_integer(unsigned(paddle_x));
    
            -- Draw paddle (white)
            if row_int >= PADDLE_Y and row_int < PADDLE_Y + PADDLE_HEIGHT and
               col_int >= paddle_x_int and col_int < paddle_x_int + PADDLE_WIDTH then
                color <= WHITE;
            else
                color <= BLACK;  -- Black background for testing
            end if;
        end if;
    end process;
end Behavioral;
