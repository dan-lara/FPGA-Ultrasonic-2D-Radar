library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IP_Servo is
    Port (
        clk  	   : in  std_logic;          -- Horloge 
        Rst_n		: in  std_logic;          -- Reset actif bas
        position 	: in std_logic_vector(9 downto 0); -- Distance en cm
		  commande  : Out   std_logic                        -- Commande du Servo
    );
end IP_Servo;

Architecture Behavior of IP_Servo Is

signal counter    : integer := 0; -- Clock Counter jusqu'a 20ms
constant FREQ_DIV : integer := 1; -- 100MHz -> 2, 50MHz -> 1
constant PULSE_MIN : integer := 40_000 * FREQ_DIV; -- 0.9 ms
constant PULSE_MAX : integer := 130_000 * FREQ_DIV; -- 2.6 ms
constant PERIOD    : integer := 1_000_000 * FREQ_DIV;  -- 20 ms period (1,000,000 cycles)
Begin

process( Rst_n, clk )
begin
    if Rst_n = '0'  Then
      counter  <=  0 ;
      commande <= '0';

    elsif rising_edge( clk ) Then
      if ( counter < PERIOD ) Then 
          counter <= counter + 1;

          if ( to_integer (unsigned(position)) > 900 ) Then -- Limité a 900, a cause de les 10 bits de la position
            if counter < PULSE_MAX Then 
					commande <= '1';
            else
					commande <= '0';
            end if;
				
          else
			 
            if ( counter < (PULSE_MIN +(to_integer (unsigned(position)))*100) * FREQ_DIV) Then
					-- ((130_000 - 40_000) * position (max 900) / 180); Donc 
					commande <= '1';
            else
					commande <= '0';
				end if;
          end if;
      else
			counter <= 0;
      end if;
    end if;
  end process;
End Architecture;