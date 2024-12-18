library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_Telemetre_Avalon_DUT is
    -- Pas de ports pour un testbench
end TB_Telemetre_Avalon_DUT;

architecture Behavioral of TB_Telemetre_Avalon_DUT is
    -- Déclarations des signaux pour connecter au DUT (Device Under Test)
    signal clk     : std_logic := '0';
    signal rst     : std_logic := '0';
    signal trig    : std_logic;
    signal echo    : std_logic := '0';
    signal dist    : std_logic_vector(9 downto 0);

    -- Constantes pour la simulation
    constant CLK_PERIOD : time := 20 NS; -- Période d'horloge de 20 ns

begin
    -- Instanciation de l'IP_Telemetre
	 DUT: entity work.IP_Telemetre
        port map (
            clk     => clk,
            rst_n     => rst,
            trig    => trig,
            echo    => echo,
            Dist_cm => dist
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
	 
	 rst <= '0', '1' after CLK_PERIOD / 2;
    -- Processus de simulation
    stim_process : process
    begin

		  wait until  trig = '1';
		  wait until  trig = '0';
		  wait for 5 * CLK_PERIOD;

        echo <= '1';           -- Début du signal echo
		  wait for 2ms;
        echo <= '0';           -- Fin du signal echo
		  
		  wait until  trig = '1';
		  wait until  trig = '0';
		  wait for 5 * CLK_PERIOD;
		  
		  echo <= '1';           -- Début du signal echo
		  wait for 5ms;
        echo <= '0';           -- Fin du signal echo
		  
		  wait until  trig = '1';
		  wait until  trig = '0';
		  wait for 5 * CLK_PERIOD;
		  
		  echo <= '1';           -- Début du signal echo
		  wait for 10ms;
        echo <= '0';           -- Fin du signal echo

        -- Fin de la simulation
        wait;
    end process;

end Behavioral;
