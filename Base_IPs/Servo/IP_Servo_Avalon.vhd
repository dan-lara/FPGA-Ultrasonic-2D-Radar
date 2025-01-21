library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IP_Servo_Avalon is
    Port (
        clk        : in  std_logic;                      -- Horloge à 50 MHz
        reset_n    : in  std_logic;                      -- Reset actif bas
        chipselect : in  std_logic;                      -- Sélection de l'IP
        write_n    : in  std_logic;                      -- Autorisation d'écriture (actif bas)
        WriteData  : in  std_logic_vector(31 downto 0);  -- Données écrites (32 bits)
        commande   : out std_logic                       -- Signal PWM vers servomoteur
    );
end IP_Servo_Avalon;

architecture Behavior of IP_Servo_Avalon is

    -- Constantes pour le calcul de la PWM
    constant FREQ_DIV   : integer := 2; -- 100MHz -> 2, 50MHz -> 1
    constant PULSE_MIN  : integer := 40_000 * FREQ_DIV; -- 0.8 ms
    constant PULSE_MAX  : integer := 130_000 * FREQ_DIV; -- 2.6 ms
    constant PERIOD     : integer := 1_000_000 * FREQ_DIV;  -- Période de 20 ms (2,000,000 cycles)

    -- Signaux internes
    signal counter      : integer range 0 to PERIOD := 0; -- Compteur pour générer le PWM
    signal pulse_width  : integer := PULSE_MIN;           -- Largeur de l'impulsion PWM
    signal position_reg : std_logic_vector(31 downto 0) := (others => '0'); -- Registre de position

begin

    -- Gestion de l'écriture dans le registre
    process(clk, reset_n, chipselect)
    begin
        if reset_n = '0' then
            position_reg <= (others => '0');
        elsif rising_edge(clk) then
            if chipselect = '1' and write_n = '0' then
                position_reg <= WriteData;   -- Écriture dans le registre
            end if;
        end if;
    end process;
    
    -- Génération du signal PWM et conversion de la position en largeur d'impulsion
    process(clk, reset_n)
begin
    if reset_n = '0'  Then
      counter  <=  0 ;
      commande <= '0';

    elsif rising_edge( clk ) Then
      if ( counter < PERIOD ) Then 
          counter <= counter + 1;

          if ( to_integer (unsigned(position_reg)) > 1800 ) Then --precision 0.1º
            if counter < PULSE_MAX Then 
					commande <= '1';
            else
					commande <= '0';
            end if;
          else 
            if ( counter < (PULSE_MIN + (to_integer (unsigned(position_reg))) * 98 * FREQ_DIV) ) Then
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

end Behavior;