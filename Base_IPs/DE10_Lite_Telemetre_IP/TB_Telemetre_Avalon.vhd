library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_Telemetre_DUT is
    -- Pas de ports pour un testbench
end TB_Telemetre_DUT;

architecture Behavioral of TB_Telemetre_DUT is
    -- Déclarations des signaux pour connecter au DUT (Device Under Test)
    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    signal chipselect  : std_logic := '0';
    signal read_n      : std_logic := '1';
    signal trig        : std_logic;
    signal echo        : std_logic := '0';
    signal dist        : std_logic_vector(9 downto 0);
    signal readdata    : std_logic_vector(31 downto 0);

    -- Constantes pour la simulation
    constant CLK_PERIOD : time := 10 NS; -- Période d'horloge de 20 ns -> Avalon 100MHz

begin
    -- Instanciation de l'IP_Telemetre_Avalon
    DUT: entity work.IP_Telemetre_Avalon
        port map (
            clk         => clk,
            Rst_n       => rst_n,
            chipselect  => chipselect,
            Read_n      => read_n,
            trig        => trig,
            echo        => echo,
            Dist_cm     => dist,
            readdata    => readdata
        );

    -- Processus d'horloge
    clk_process : process
    begin
        while now <= 200 ms loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;
	 
    -- Séquence de reset
    rst_process : process
    begin
        rst_n <= '0';
        wait for CLK_PERIOD / 2;
        rst_n <= '1';
        wait;
    end process;

    -- Processus de simulation
    stim_process : process
    begin
        -- Attendre que le reset soit relâché
        wait until rst_n = '1';

        -- Première mesure de distance (2 ms = environ 34 cm)
        wait until trig = '1';
        wait until trig = '0';

        echo <= '1';           -- Début du signal echo
        wait for 2 ms;
        echo <= '0';           -- Fin du signal echo
		
		  wait for 10 * CLK_PERIOD;
        chipselect <= '1';
        read_n <= '0';
        wait for CLK_PERIOD;
        chipselect <= '0';
        read_n <= '1';
			
		
        -- Deuxième mesure de distance (5 ms = environ 85 cm)
        wait until trig = '1';
        wait until trig = '0';
        wait for 5 * CLK_PERIOD;
		  
        echo <= '1';           -- Début du signal echo
        wait for 5 ms;
        echo <= '0';           -- Fin du signal echo

        -- Lecture des données via Avalon
        wait for 10 * CLK_PERIOD;
        chipselect <= '1';
        read_n <= '0';
        wait for CLK_PERIOD;
        chipselect <= '0';
        read_n <= '1';

        -- Troisième mesure de distance (10 ms = environ 170 cm)
        wait until trig = '1';
        wait until trig = '0';
        wait for 5 * CLK_PERIOD;
		  
        echo <= '1';           -- Début du signal echo
        wait for 10 ms;
        echo <= '0';           -- Fin du signal echo

        -- Lecture finale des données via Avalon
        wait for 10 * CLK_PERIOD;
        chipselect <= '1';
        read_n <= '0';
        wait for CLK_PERIOD;
        chipselect <= '0';
        read_n <= '1';

        -- Fin de la simulation
        wait;
    end process;

end Behavioral;