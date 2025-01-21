library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_UART_DUT is
end entity;

architecture Behavioral of TB_UART_DUT is

    -- Signal
    signal clk        : std_logic := '0';
    signal Rst_n      : std_logic := '1';
    signal load       : std_logic := '0';

    signal Tx_Data      : std_logic_vector(7 downto 0) := (others => '0');
    signal Uart_Tx      : std_logic;

    signal Rx_Data      : std_logic_vector(7 downto 0);
    signal Uart_Rx            : std_logic := '1';
    

    -- Constants for clock generation
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz clock

    -- Content
begin

    -- Instance of the entity under test
    DUT: entity work.IP_UART
        port map (
            clk      => clk,
            Rst_n  => Rst_n,
            Load     => load,

            Uart_Tx  => Uart_Tx,
            Tx_Data  => Tx_Data,
        
            Uart_Rx  => Uart_Rx,
            Rx_Data  => Rx_Data
        );

    -- Clock generation
    process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Test process
    process
    begin
        -- Initial reset
        Rst_n <= '0';
        wait for 50 ns;
        Rst_n <= '1';
        wait for 50 ns;
    
    -- Test Transmit
        -- D
        Tx_Data <= "01000100";
        load <= '1';
        wait for 500*CLK_PERIOD;
        load <= '0';
        wait for 150 us;

        -- a
        Tx_Data <= "01100001";
        load <= '1';
        wait for 500*CLK_PERIOD;
        load <= '0';
        wait for 150 us;
        
        --n
        Tx_Data <= "01101110";
        load <= '1';
        wait for 500*CLK_PERIOD;
        load <= '0';
        wait for 150 us;
        
        --" "
        Tx_Data <= "00100000";
        load <= '1';
        wait for 500*CLK_PERIOD;
        load <= '0';
        wait for 150 us;

        --L
        Tx_Data <= "01001100";
        load <= '1';
        wait for 500*CLK_PERIOD;
        load <= '0';
        wait for 150 us;

        --"\n"
        Tx_Data <= "00001010";
        load <= '1';
        wait for 500*CLK_PERIOD;
        load <= '0';
        wait for 150 us;

        -- Reseting
        Rst_n <= '0';
        wait for 70 us;

        load <= '1';
        wait for 70 us;

        Rst_n <= '1';

    -- Test Read
        wait for 160 us;
        load <= '0';
        wait for 10 us;

        -- Test case 0 : Read random data (ASCII '?')
        Uart_Rx <= '0';
        wait for 434*4*CLK_PERIOD;
        Uart_Rx <= '1';
        wait for 70 us;

        -- STOP_1 01001100 START_0
        Uart_Rx <= '0';
        wait for 434*CLK_PERIOD;
        wait for 434*CLK_PERIOD;
        wait for 434*CLK_PERIOD;
        Uart_Rx <= '1';
        wait for 434*CLK_PERIOD;
        wait for 434*CLK_PERIOD;
        Uart_Rx <= '0';
        wait for 434*CLK_PERIOD;
        wait for 434*CLK_PERIOD;
        Uart_Rx <= '1';
        wait for 434*CLK_PERIOD;
        Uart_Rx <= '0';
        wait for 434*CLK_PERIOD;
        Uart_Rx <= '1';
        wait for 30 us;


        -- End simulation
        wait;
    end process;

end architecture;