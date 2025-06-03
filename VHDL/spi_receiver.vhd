--=============================================================
--Ben Dobbins
--ES31/CS56
--This script is the SPI Receiver code for Lab 6, the voltmeter.
--Azizul Hakim
--=============================================================

--=============================================================
--Library Declarations
--=============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;			-- needed for arithmetic
use ieee.math_real.all;				-- needed for automatic register sizing
library UNISIM;						-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

--=============================================================
--Entitity Declarations
--=============================================================
entity spi_receiver is
	generic(
		N_SHIFTS 				: integer);
	port(
	    --1 MHz serial clock
		clk_port				: in  std_logic;	
    	
    	--controller signals
		take_sample_port 		: in  std_logic;	
		spi_cs_port			    : out std_logic;
        
        --datapath signals
		spi_s_data_port		    : in  std_logic;	
		adc_data_port			: out std_logic_vector(11 downto 0));
end spi_receiver; 

--=============================================================
--Architecture + Component Declarations
--=============================================================
architecture Behavioral of spi_receiver is
--=============================================================
--Local Signal Declaration
--=============================================================
type state_type is (IDLE, CONVERSION_START, SHIFT, LOAD, CONVERSION_STOP);
signal current_state, next_state : state_type := IDLE;
signal shift_enable		: std_logic := '0';
signal load_enable		: std_logic := '0';
signal shift_reg	    : std_logic_vector(11 downto 0) := (others => '0');
signal shift_counter : unsigned(3 downto 0) := (others => '0');

begin
--=============================================================
--Controller:
--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--State Update:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++	
state_update: process(clk_port)
begin
  if rising_edge(clk_port) then
    current_state <= next_state;
  end if;
end process;


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Next State Logic:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
next_state_logic : process(current_state, take_sample_port, shift_counter)
begin
  case current_state is
    when IDLE =>
    	if (take_sample_port = '1') then
          next_state <= CONVERSION_START;
    	else
          next_state <= IDLE;
    	end if; 
    when CONVERSION_START =>
    	next_state <= SHIFT;
    
    when SHIFT =>
    if (shift_counter = N_SHIFTS - 1) then
      next_state <= LOAD;
    else
      next_state <= SHIFT;
    end if;
    
    when LOAD =>
      next_state <= CONVERSION_STOP;
    
    when CONVERSION_STOP =>
      next_state <= IDLE;

    when others =>
      next_state <= IDLE;    
  end case;
end process;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Output Logic:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  output_logic : process(current_state)
  begin
    spi_cs_port <= '1';
    shift_enable <= '0';
    load_enable <= '0';
    
    case current_state is
    when IDLE =>
      
    when CONVERSION_START =>
    	spi_cs_port <= '0';
    
    when SHIFT =>
    	spi_cs_port <= '0';
    	shift_enable <= '1';

    when LOAD =>
    	spi_cs_port <= '0';
		load_enable <= '1';
    
    when CONVERSION_STOP =>
    	null;
      
    when others =>
      	null;
  	end case;
  end process;
  
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Timer Sub-routine:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  shift_counter_proc : process(clk_port)
  begin
    if rising_edge(clk_port) then
      if current_state = IDLE or current_state = CONVERSION_STOP then
        shift_counter <= (others => '0');
      elsif current_state = SHIFT then
    	shift_counter <= shift_counter + 1;
      end if;
    end if;
  end process;

--=============================================================
--Datapath:
--=============================================================
shift_register: process(clk_port) 
begin
	if rising_edge(clk_port) then
		if shift_enable = '1' then shift_reg <= shift_reg(10 downto 0) & spi_s_data_port;
		end if;
		
		if load_enable = '1' then adc_data_port <= shift_reg;
		end if;
    end if;
end process;
end Behavioral; 