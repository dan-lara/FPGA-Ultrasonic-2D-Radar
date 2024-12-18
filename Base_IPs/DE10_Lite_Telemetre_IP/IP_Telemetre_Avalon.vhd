library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IP_Telemetre_Avalon is
    Port (
        clk         : in  std_logic;          -- Horloge système
        Rst_n       : in  std_logic;          -- Reset actif bas
        chipselect  : in  std_logic;          -- Sélection du périphérique Avalon
        Read_n      : in  std_logic;          -- Lecture active basse
        echo        : in  std_logic;          -- Signal de retour du capteur
        
        trig        : out std_logic;          -- Signal de déclenchement
        Dist_cm     : out std_logic_vector(9 downto 0); -- Distance en cm (signal externe)
        readdata    : out std_logic_vector(31 downto 0) -- Données envoyées via Avalon
    );
end IP_Telemetre_Avalon;

architecture Behavioral of IP_Telemetre_Avalon is
    -- Déclaration des signaux internes
    signal counter      : integer;                
    type StateType is (Idle, S1, S2, S3, S4);                     
    signal state        : StateType := Idle; 
    signal echo_r, echo_rr : std_logic;
	 
	 signal data_reg_cont : integer;
	 signal data_reg : std_logic_vector(9 downto 0);
	 constant FREQ_DIV : integer := 2; -- 100MHz -> 2, 50MHz -> 1
        
begin
    process(clk, Rst_n)
    begin
        if Rst_n = '0' then
            Trig <= '0';
            counter <= 0;
            
            state <= Idle;
            data_reg <= (others => '0');
				data_reg_cont <= 0;
        elsif rising_edge(clk) then
            echo_r <= echo;
            echo_rr <= echo_r;
            
            -- Gestion de la machine à états pour la mesure de distance
            case state is
                when Idle =>
                    Trig <= '0';
                    counter <= 0;
                    state <= S1;

                when S1 =>
                    if counter < 600 * FREQ_DIV then
                        Trig <= '1';
                        counter <= counter + 1;
                    else
                        Trig <= '0';
                        counter <= 0;
                        state <= S2; 
                    end if;						
						
                when S2 =>
                    if echo_rr = '1' then
                        counter <= counter + 1; 
                        state <= S3;
                    end if;
					 
                when S3 =>
                    if echo_rr = '1' then
                        counter <= counter + 1; 
                    elsif echo_rr = '0' then
								--data_reg_cont <= counter;
								data_reg <= std_logic_vector(to_unsigned((counter / 2941) / FREQ_DIV, 10));
								Dist_cm <= data_reg;
                        state <= S4;
                    end if;
						  
                when S4 => 
                    if counter < 3_000_000 * FREQ_DIV then
                        counter <= counter + 1;
                    else
                        state <= Idle;
                    end if;
                when others =>
                    state <= Idle;
            end case;
            
            -- Gestion de la lecture Avalon
            --if chipselect = '1' and Read_n = '0' then
				--	 readdata <= (others => '0');
            --    readdata(9 downto 0) <= data_reg;                
            --end if;
        end if;
    end process;
	 process(clk, Rst_n)
    begin
        if chipselect = '1' and Read_n = '0' then
				readdata <= "00000000000000000000000000000000";
            readdata(9 downto 0) <= data_reg;
        end if;
    end process;
	 
end Behavioral;