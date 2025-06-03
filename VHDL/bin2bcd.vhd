library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bin2bcd is
    Port (
        bin_in     : in std_logic_vector(15 downto 0);
        game_state : in std_logic_vector(1 downto 0);
        y3_display : out std_logic_vector(4 downto 0); -- 5 bits
        y2_display : out std_logic_vector(4 downto 0);
        y1_display : out std_logic_vector(4 downto 0);
        y0_display : out std_logic_vector(4 downto 0)
    );
end bin2bcd;

architecture Behavioral of bin2bcd is
    signal bcd : unsigned(15 downto 0) := (others => '0');
    signal bcd0, bcd1, bcd2, bcd3 : std_logic_vector(3 downto 0);
begin
    process(bin_in, game_state, bcd0, bcd1, bcd2, bcd3 )
        variable bin : unsigned(15 downto 0);
        variable bcd_var : unsigned(15 downto 0) := (others => '0');
    begin
        bin := unsigned(bin_in);
        bcd_var := (others => '0');

        for i in 0 to 15 loop
            if bcd_var(3 downto 0) >= 5 then
                bcd_var(3 downto 0) := bcd_var(3 downto 0) + 3;
            end if;
            if bcd_var(7 downto 4) >= 5 then
                bcd_var(7 downto 4) := bcd_var(7 downto 4) + 3;
            end if;
            if bcd_var(11 downto 8) >= 5 then
                bcd_var(11 downto 8) := bcd_var(11 downto 8) + 3;
            end if;
            if bcd_var(15 downto 12) >= 5 then
                bcd_var(15 downto 12) := bcd_var(15 downto 12) + 3;
            end if;
            bcd_var := bcd_var sll 1;
            bcd_var(0) := bin(15);
            bin := bin sll 1;
        end loop;

        bcd0 <= std_logic_vector(bcd_var(3 downto 0));
        bcd1 <= std_logic_vector(bcd_var(7 downto 4));
        bcd2 <= std_logic_vector(bcd_var(11 downto 8));
        bcd3 <= std_logic_vector(bcd_var(15 downto 12));

        case game_state is
            when "00" => -- Idle: "PLAY"
                y3_display <= "01001"; -- P
                y2_display <= "00000"; -- L
                y1_display <= "00001"; -- A
                y0_display <= "00010"; -- Y
            when "01" => -- Playing: score
                y3_display <= std_logic_vector("0" & unsigned(bcd3) + 12); -- x"0C" to x"15"
                y2_display <= std_logic_vector("0" & unsigned(bcd2) + 12);
                y1_display <= std_logic_vector("0" & unsigned(bcd1) + 12);
                y0_display <= std_logic_vector("0" & unsigned(bcd0) + 12);
            when "10" => -- LOSE: "LOSE"
                y3_display <= "00000"; -- L
                y2_display <= "00011"; -- O
                y1_display <= "00100"; -- S
                y0_display <= "00110"; -- E
            when "11" => -- WIN: "WIN "
                y3_display <= "01011"; -- W
                y2_display <= "01010"; -- I
                y1_display <= "00111"; -- N
                y0_display <= "00101"; -- Space
            when others =>
                y3_display <= "00000";
                y2_display <= "00000";
                y1_display <= "00000";
                y0_display <= "00000";
        end case;
    end process;
end Behavioral;