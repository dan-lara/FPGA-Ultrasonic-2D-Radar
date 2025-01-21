library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_Servo_Avalon_DUT is
-- Pas de ports dans le banc de test
end TB_Servo_Avalon_DUT;

architecture testbench of TB_Servo_Avalon_DUT is

    -- Déclaration du composant pour l'IP_Servo_Avalon
    component IP_Servo_Avalon
        Port (
            clk        : in  std_logic;
            reset_n    : in  std_logic;
            chipselect : in  std_logic;
            write_n    : in  std_logic;
            WriteData  : in  std_logic_vector(31 downto 0);
            commande   : out std_logic
        );
    end component;

    -- Signaux pour la connexion à l'IP
    signal clk        : std_logic := '0';
    signal reset_n    : std_logic := '1';
    signal chipselect : std_logic := '0';
    signal write_n    : std_logic := '1';
    signal WriteData  : std_logic_vector(31 downto 0) := (others => '0');
    signal commande   : std_logic;

    -- Définition de la période d'horloge
    constant CLK_PERIOD : time := 10 ns; -- Horloge de 100 MHz

begin

    -- Instanciation de l'IP_Servo_Avalon
    DUT: IP_Servo_Avalon
        port map (
            clk        => clk,
            reset_n    => reset_n,
            chipselect => chipselect,
            write_n    => write_n,
            WriteData  => WriteData,
            commande   => commande
        );

    -- Processus d'horloge
    clk_process : process
    begin
        while  now < 50 ms loop
            clk <= not clk;
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Processus de stimulus
    stimulus_process : process
    begin
        -- Conditions initiales
        -- report "Début de la simulation...";
        reset_n <= '0'; -- Appliquer le reset
        chipselect <= '0';
        write_n <= '1';
        WriteData <= (others => '0');
        wait for 1 us;

        reset_n <= '1'; -- Désactiver le reset
        wait for 50 ns;

        -- Écrire une valeur pour définir la largeur de l'impulsion (par exemple, 300)
        -- report "Écriture de la valeur 300 dans WriteData...";
        chipselect <= '1';
        write_n <= '0';
        WriteData <= std_logic_vector(to_unsigned(600, 32));
        wait for 10 ns;

        write_n <= '1'; -- Fin de l'opération d'écriture
        chipselect <= '0';
        wait for 15 ms; -- Attendre quelques périodes PWM

        -- Écrire une nouvelle valeur (par exemple, 700)
        -- report "Écriture de la valeur 700 dans WriteData...";
        chipselect <= '1';
        write_n <= '0';
        WriteData <= std_logic_vector(to_unsigned(900, 32));
        wait for 10 ns;

        write_n <= '1';
        chipselect <= '0';
        wait for 15 ms;

        -- Écrire une valeur hors plage (par exemple, 1000)
        -- report "Écriture de la valeur invalide 1000 dans WriteData...";
        chipselect <= '1';
        write_n <= '0';
        WriteData <= std_logic_vector(to_unsigned(1800, 32));
        wait for 10 ns;

        write_n <= '1';
        chipselect <= '0';
        wait for 15 ms;
		  
		  chipselect <= '1';
        write_n <= '0';
        WriteData <= std_logic_vector(to_unsigned(2000, 32));
        wait for 10 ns;

        write_n <= '1';
        chipselect <= '0';
        wait for 15 ms;

        -- Fin de la simulation
        -- report "Simulation terminée.";
        wait;
    end process;

end testbench;