library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IP_UART is
    port 
    (
        clk      : in std_logic;                 
        Rst_n  : in std_logic;               

        Load     : in std_logic;  
        
        Tx_Data    : in std_logic_vector(7 downto 0); 
        Uart_Tx  : out std_logic;                    

        Rx_Data  : out std_logic_vector(7 downto 0);
        Uart_Rx  : in std_logic                    
    );
end entity;

architecture Behavioral of IP_UART is
    -- Signals Rx
    type StateType_RX is (Wait_data, Load_data, Wait_end, Save_byte ); 
    signal State_Rx        : StateType_RX := Wait_data;
    signal bit_Rx   : integer range 0 to 9 := 0;     
    signal byte_Rx   : std_logic_vector(7 downto 0) := (others => '0');

    -- Signals Tx
    type StateType_TX is (Idle, Wait_Release, Load_reg, Send_start, Send_byte, Send_stop);
    signal State_Tx        : StateType_TX := Idle;
    signal bit_Tx   : integer range 0 to 9 := 0; 
    signal byte_Tx   : std_logic_vector(7 downto 0) := (others => '0');
            -- Signal de chargement
    signal byte_to_data     : std_logic_vector(9 downto 0) := (others => '0'); -- 1 bit start, 8 bits data, 1 bit stop
    signal load_r   : std_logic := '0';   

    -- Signal de comptage
    constant FREQ_DIV           : integer := 1; -- 100MHz -> 2, 50MHz -> 1
    constant DIV_FACTOR         : integer := 434 * FREQ_DIV; -- Baudrate 115200
    signal counter              : integer := 0; -- Compteur de temps
    signal Tick                 : std_logic := '0'; -- Signal Tick

begin
    -- Diviseur d horloge pour generer le signal Tick
    process (clk, Rst_n)
    begin
        if Rst_n = '0' then
            counter <= 0;
            Tick <= '0';
        elsif rising_edge(clk) then
            if counter = DIV_FACTOR - 1 then
                counter <= 0;
                Tick <= '1';
            else
                counter <= counter + 1;
                Tick <= '0';
            end if;
        end if;
    end process;

    -- Transmission
    process (clk, Rst_n)
    begin
        if Rst_n = '0' then
            byte_Tx <= (others => '0');
        elsif rising_edge(clk) then
            if Load = '1' then
                byte_Tx <= Tx_Data(7 downto 0);
                load_r <= '1';
            else 
                load_r <= '0';
            end if;
        end if;
    end process;
    
    -- Double FSM pour gerer la transmission UART
    process (clk, Rst_n)
    begin
        if Rst_n = '0' then
            State_Rx <= Wait_data;
            bit_Rx <= 0;
            byte_Rx <= (others => '0');
            Rx_Data <= (others => '0');

            State_Tx <= Idle;
            Uart_Tx <= '1';
            bit_Tx <= 0;
            byte_to_data <= (others => '0');

        elsif rising_edge(clk) then
            if Tick = '1' then
                if load_r = '1' or State_Tx /= Idle then -- Priorite a la transmission
                    case State_Tx is
                        when Idle =>
                            -- Attente le load actif
                            if load_r = '1' then
                                State_Tx <= Load_reg;
                            end if;
                            -- Reset de la lecture
                            State_Rx <= Wait_data;

                        when Load_reg =>
                            -- Charger les donnees et passer a l envoi
                            byte_to_data <= '1' & byte_Tx & '0';
                            bit_Tx <= 0;
                            State_Tx <= Send_start;

                        when Send_start =>
                            -- Envoi du bit de start
                            Uart_Tx <= byte_to_data(bit_Tx);
                            bit_Tx <= bit_Tx + 1;
                            State_Tx <= Send_byte;

                        when Send_byte =>
                            -- Envoi des bits data
                            Uart_Tx <= byte_to_data(bit_Tx);
                            if bit_Tx = 8 then
                                State_Tx <= Send_stop;
                            else
                                bit_Tx <= bit_Tx + 1;
                            end if;

                        when Send_stop =>
                            Uart_Tx <= '1';
                            State_Tx <= Wait_Release;

                        when Wait_Release =>
                            if load_r = '0' then
                                State_Tx <= Idle;
                            end if;

                        when others =>
                            State_Tx <= Idle;
                    end case;
                else 
                    case State_Rx is
                        when Wait_data =>
                            -- Attendre que le bit de start soit detecte
                            if Uart_Rx = '0' then
                                State_Rx <= Load_data;
                                bit_Rx <= 0;
                            end if;
                        
                        when Load_data =>
                            -- Chargement des donnees
                            if bit_Rx = 8 then
                                State_Rx <= Wait_end;
                            else
                                byte_Rx(bit_Rx) <= Uart_Rx;
                                bit_Rx <= bit_Rx + 1;
                            end if;
                        
                        when Wait_end =>
                            -- Attendre que le bit de stop soit detecte
                            if Uart_Rx = '1' then
                                State_Rx <= Save_byte;
                                Rx_Data (7 downto 0) <= byte_Rx; -- Sauvegarde de la donnee
                                byte_Rx <= (others => '0'); -- Reset de la sauvegarde
                            end if;
                            
                        when Save_byte => 
                            State_Rx <= Wait_data;

                        when others =>
                            State_Rx <= Wait_data;
                    end case;
                end if;
            end if;
        end if;
    end process;

end architecture;
