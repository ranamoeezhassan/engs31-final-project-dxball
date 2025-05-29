--=============================================================================
--Library Declarations:
--=============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity frame_divider is
    generic (
        DIVIDE_BY : integer := 416667  -- Number of clock cycles between pulses
    );
    port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        take_sample : out STD_LOGIC  -- Pulse output, one clk wide
    );
end frame_divider;

architecture Behavioral of frame_divider is
    -- Width of counter must be big enough to hold DIVIDE_BY
    constant CNT_WIDTH : integer := integer(ceil(log2(real(DIVIDE_BY))));
    signal counter : unsigned(CNT_WIDTH-1 downto 0) := (others => '0');
    
begin
    process(clk)
    begin    
        if rising_edge(clk) then
            if reset = '1' then
                counter     <= (others => '0');
                take_sample <= '0';
            else
                if counter = DIVIDE_BY - 1 then
                    counter     <= (others => '0');
                    take_sample <= '1';
                else
                    counter     <= counter + 1;
                    take_sample <= '0';
                end if;
            end if;
        end if;
    end process;
end Behavioral;