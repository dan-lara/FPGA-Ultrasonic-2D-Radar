library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_Servo_DUT is
end TB_Servo_DUT;

architecture Testbench of TB_Servo_DUT is
    -- Signals for connecting to DUT
    signal clk       : std_logic := '0';
    signal Rst_n     : std_logic := '0';
    signal position  : std_logic_vector(9 downto 0);
    signal commande  : std_logic;

    -- Constants
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz clock

begin
    -- Instantiate the DUT
    DUT: entity work.IP_Servo
        port map (
            clk       => clk,
            Rst_n     => Rst_n,
            position  => position,
            commande  => commande
        );

    -- Clock generation
    clk_process : process
    begin
        while now < 150 ms loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stim_process : process
    begin
        -- Reset
        Rst_n <= '0';
        wait for 1 us;
        Rst_n <= '1';

        -- Test position = 0 (1 ms pulse)
        position <= std_logic_vector(to_unsigned(0, 10));
        wait for 25 ms;

        -- Test position = 450 (1.5 ms pulse)
        position <= std_logic_vector(to_unsigned(450, 10));
        wait for 25 ms;

        -- Test position = 900 (2 ms pulse)
        position <= std_logic_vector(to_unsigned(900, 10));
        wait for 25 ms;

        -- Test invalid position > 900
        position <= std_logic_vector(to_unsigned(1000, 10));
        wait for 25 ms;

        -- End of simulation
        wait;
    end process;

end Testbench;
