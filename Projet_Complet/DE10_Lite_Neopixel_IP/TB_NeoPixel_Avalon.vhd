library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity TB_NeoPixel_Avalon_DUT is
end TB_NeoPixel_Avalon_DUT;

architecture Testbench of TB_NeoPixel_Avalon_DUT is

    -- Signal
    signal clk        :  std_logic := '0';
    signal Rst_n    :  std_logic := '1';
    signal chipselect  :   std_logic;           
    signal write_n     :  std_logic;
    signal WriteData   :  std_logic_vector(31 downto 0);

    signal commande   : std_logic;

	  -- Component Declaration
    component DE10_Lite_Neopixel
        port (
            clk             : in  std_logic;       
            Rst_n           : in  std_logic;       -- reset actif bas
            chipselect      : in  std_logic;          -- Sélection du périphérique Avalon 
            write_n         : in  std_logic;               
            WriteData       : in  std_logic_vector(31 downto 0);

            commande        : out std_logic        -- signal WS2812
        );
    end component;
	 
begin

    -- Instanciation
    DUT : entity work.IP_NeoPixel_Avalon
        Port map (
            clk         => clk,
            Rst_n     => Rst_n,
            chipselect  => chipselect,
            write_n     => write_n,
            WriteData   => WriteData,

            commande    => commande
        );

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

    -- Test process
    Test_bench : process
    begin
        -- Reset
        --write_led <= "0010";
        --color_led <= "000000";
        chipselect <= '0';
        write_n <= '1';
        WriteData <= "00000000000000000000000000000010";
        Rst_n <= '0';
        wait for 500 ns;
        Rst_n <= '1';

        --write_led <= "1111";        
        --color_led <= "000000";
        chipselect <= '1';
        write_n <= '0';
        WriteData <= "00000000000000000000000000001111";
        wait for 1000 us;
        Rst_n <= '0';
        wait for 500 ns;
        Rst_n <= '1';
        
        wait for 1000 us;
        --write_led <= "1001";
        --color_led <= "000000";
        chipselect <= '1';
        write_n <= '0';
        WriteData <= "00000000000000000000000000001001";

        wait for 1000 us;
        --write_led <= "1001";
        --color_led <= "110000";
        chipselect <= '1';
        write_n <= '0';
        WriteData <= "00000000000000000000001100001001";
        wait for 350 us;
		  
		  wait for 1000 us;
        --write_led <= "0000";
        --color_led <= "000000";
        chipselect <= '1';
        write_n <= '0';
        WriteData <= "00000000000000000000000000000000";
        wait for 350 us;

        wait;
    end process;
end Testbench;