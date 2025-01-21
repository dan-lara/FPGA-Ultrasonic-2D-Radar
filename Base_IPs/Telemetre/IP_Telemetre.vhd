library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IP_Telemetre is
    Port (
        clk     : in  std_logic;          -- Horloge 
        Rst_n     : in  std_logic;          -- Reset actif bas
        trig    : out std_logic;          -- Signal de déclenchement
        echo    : in  std_logic;          -- Signal de retour
        Dist_cm : out std_logic_vector(9 downto 0) -- Distance en cm
    );
end IP_Telemetre;

architecture Behavioral of IP_Telemetre is
    -- Déclaration des signaux internes
    signal counter      	: integer;                  
    type StateType is (Idle, S1, S2, S3, S4);                     
    signal state        	: StateType := Idle; 
	signal echo_r, echo_rr : std_logic;
begin

    process(clk, Rst_n)
    begin
        if Rst_n = '0' then
            trig <= '0';
            counter <= 0;
				Dist_cm <= "0000000000";
            state <= Idle;					
        elsif rising_edge(clk) then
				echo_r <= echo;
				echo_rr <= echo_r;
				
            case state is
                when Idle =>
                    trig <= '0';
                    counter <= 0;
						  State <= S1;

                when S1 =>
                    if counter < 600 then
                        trig <= '1';
                        counter <= counter + 1;
                    else
                        trig <= '0';
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
                        Dist_cm <= std_logic_vector(to_unsigned(counter / 2941, 10));
                        state <= S4;
                    end if;
						  
                when S4 => 
                    if counter < 3_000_000 then
                        counter <= counter + 1;
                    else
                        state <= Idle;
                    end if;
                when others =>
                    state <= Idle;
            end case;
        end if;
    end process;

end Behavioral;
