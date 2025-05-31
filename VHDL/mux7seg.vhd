library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity mux7seg is
    Port ( 
        clk_port    : in  std_logic;                        -- 100 MHz clock
        y3_port     : in  std_logic_vector(4 downto 0);     -- Digits (5 bits)
        y2_port     : in  std_logic_vector(4 downto 0);     -- Digits
        y1_port     : in  std_logic_vector(4 downto 0);     -- Digits
        y0_port     : in  std_logic_vector(4 downto 0);     -- Digits
        dp_set_port : in  std_logic_vector(3 downto 0);     -- Decimal points
        seg_port    : out std_logic_vector(0 to 6);         -- Segments (a...g)
        dp_port     : out std_logic;                        -- Decimal point
        an_port     : out std_logic_vector(3 downto 0)      -- Anodes
    );
end mux7seg;

architecture Behavioral of mux7seg is
    constant NCLKDIV: integer := 11;                     -- 100 MHz / 2^18 ? 381 Hz
    constant MAXCLKDIV: integer := 2**NCLKDIV-1;         -- Max count
    signal cdcount: unsigned(NCLKDIV-1 downto 0);        -- Clock divider counter
    signal CE : std_logic;                              -- Clock enable
    signal adcount : unsigned(1 downto 0) := "00";       -- Anode counter
    signal anb: std_logic_vector(3 downto 0);
    signal muxy : std_logic_vector(4 downto 0);          -- Mux output (5 bits)
    signal segh : std_logic_vector(0 to 6);             -- Segments (high true)

begin
    ClockDivider:
    process(clk_port)
    begin
        if rising_edge(clk_port) then
            if cdcount < MAXCLKDIV then
                CE <= '0';
                cdcount <= cdcount + 1;
            else 
                CE <= '1';
                cdcount <= (others => '0');
            end if;
        end if;
    end process;

    AnodeDriver:
    process(clk_port)
    begin
        if rising_edge(clk_port) then
            if CE = '1' then
                adcount <= adcount + 1;
            end if;
        end if;
    end process;

    with adcount select anb <=
        "1110" when "00",
        "1101" when "01",
        "1011" when "10",
        "0111" when "11",
        "1111" when others;

    an_port <= anb; -- Enable all digits

    Multiplexer:
    process(adcount, y0_port, y1_port, y2_port, y3_port, dp_set_port)
    begin
        case adcount is
            when "00" => muxy <= y0_port; dp_port <= not(dp_set_port(0));
            when "01" => muxy <= y1_port; dp_port <= not(dp_set_port(1));
            when "10" => muxy <= y2_port; dp_port <= not(dp_set_port(2));
            when "11" => muxy <= y3_port; dp_port <= not(dp_set_port(3));
            when others => muxy <= "00000"; dp_port <= '1';
        end case;
    end process;

    with muxy select segh <=
        "0001110" when "00000", -- L
        "1110111" when "00001", -- A
        "0111011" when "00010", -- Y
        "1111110" when "00011", -- O
        "1011011" when "00100", -- S
        "0000000" when "00101", -- Space
        "1001111" when "00110", -- E
        "1110110" when "00111", -- N
        "1101111" when "01000", -- D
        "1100111" when "01001", -- P
        "0000110" when "01010", -- I
        "1011100" when "01011", -- W (U-like)
        "1111110" when "01100", -- 0
        "0110000" when "01101", -- 1
        "1101101" when "01110", -- 2
        "1111001" when "01111", -- 3
        "0110011" when "10000", -- 4
        "1011011" when "10001", -- 5
        "1011111" when "10010", -- 6
        "1110000" when "10011", -- 7
        "1111111" when "10100", -- 8
        "1111011" when "10101", -- 9
        "0000000" when others;  -- Blank

    seg_port <= not(segh); -- Active-low
end Behavioral;