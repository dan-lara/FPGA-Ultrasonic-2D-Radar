library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity TB_NeoPixel_DUT is
end TB_NeoPixel_DUT;

architecture Testbench of TB_NeoPixel_DUT is

    -- Signal
    signal clk        : std_logic := '0';
    signal Rst_n    : std_logic := '1';
    signal write_led     : std_logic_vector(3 downto 0) := ( others => '0' );
    signal color_led     : std_logic_vector(5 downto 0) := ( others => '0' );

    signal commande   : std_logic;

	  -- Component Declaration
    component DE10_Lite_Neopixel
        Port (
            clk         : In    std_logic;
            Rst_n       : In    std_logic;
            write_led   : In    std_logic_vector(3 downto 0);
            color_led   : In    std_logic_vector(5 downto 0);
            commande    : Out   std_logic
        );
    end component;
	 
begin

    -- Instanciation
    DUT : entity work.IP_NeoPixel
        Port map (
            clk         => clk,
            Rst_n     => Rst_n,
            write_led      => write_led,
				color_led => color_led,

            commande    => commande
        );

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for 10 ns;
        clk <= '1';
        wait for 10 ns;
    end process;

    -- Test process
    Test_bench : process
    begin
        -- Reset
        write_led <= "0010";
        color_led <= "000000";
        Rst_n <= '0';
        wait for 500 ns;
        Rst_n <= '1';

        write_led <= "1111";        
        color_led <= "000000";
        wait for 1000 us;
        Rst_n <= '0';
        wait for 500 ns;
        Rst_n <= '1';
        
        wait for 1000 us;
        write_led <= "1001";
        color_led <= "000000";

        wait for 1000 us;
        write_led <= "1001";
        color_led <= "110000";
        wait for 350 us;
		  
		  wait for 1000 us;
        write_led <= "0000";
        color_led <= "000000";
        wait for 350 us;

        wait;
    end process;
end Testbench;