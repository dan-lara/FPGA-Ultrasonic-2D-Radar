library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IP_NeoPixel is
    port (
        clk             : in  std_logic;       -- horloge Version Alone 50 MHz
        Rst_n           : in  std_logic;       -- reset actif bas
        write_led       : in  std_logic_vector(3 downto 0);
        color_led       : in  std_logic_vector(5 downto 0);

        commande        : out std_logic        -- signal WS2812
    );
end entity;

architecture RTL of IP_NeoPixel is

-- Signals
    -- Donnees initiales pour tester les LEDs GRB
    constant GREEN      : std_logic_vector(23 downto 0) := "111111110000000000000000";
    constant GREEN2     : std_logic_vector(23 downto 0) := "110001010001011010010100";
    constant BLUE       : std_logic_vector(23 downto 0) := "000000000000000011111111";
	constant RED        : std_logic_vector(23 downto 0)  := "000000001111111100000000";
    constant MAGENTA    : std_logic_vector(23 downto 0) := "000000001111111111111111";
    constant ROSE_BAISER : std_logic_vector(23 downto 0):= "000101111111111101000100";
    constant PURPLE     : std_logic_vector(23 downto 0) := "000101000101111101000101";
    constant YELLOW     : std_logic_vector(23 downto 0) := "111111111111111100000000";
	constant ORANGE     : std_logic_vector(23 downto 0) := "011111111111111100000000";
    constant CYAN       : std_logic_vector(23 downto 0) := "111111110000000011111111";
    constant WHITE      : std_logic_vector(23 downto 0) := (others => '1');
    constant BLACK      : std_logic_vector(23 downto 0) := (others => '0');
    constant LIGHT_BLUE : std_logic_vector(23 downto 0) := "000011111111111111111111";
    constant PINK       : std_logic_vector(23 downto 0) := "111111110000111100001111";
    constant LIME       : std_logic_vector(23 downto 0) := "001111110000111100000000";

    -- Déclaration des signaux internes
    signal counter      : integer := 0; -- Clock Counter jusqu'a 20ms
    constant FREQ_DIV   : integer := 1; -- 100MHz -> 2, 50MHz -> 1
    signal bit_x        : integer := 0; -- Bit actuel en cours de transmission
    signal led_x        : integer := 0; -- Led actuel en cours de transmission
    
    signal state_fsm            : std_logic := '0'; -- Etat FSM (0 = haut, 1 = bas)
    signal state_bit            : std_logic := '0'; -- Flag pour le bit actuel
    signal state_rst            : std_logic := '0'; -- Flag pour le reset
    
    signal index_led    : std_logic_vector(3 downto 0)  := "0000";
    --signal color        : std_logic_vector(5 downto 0) := (others => '0'); 

    signal led_adress   : std_logic_vector(3 downto 0) := (others => '0');
    signal led_data     : std_logic_vector(23 downto 0) := (others => '0');

begin

-- Content

process(clk, Rst_n)
begin
    if Rst_n = '0' then
        commande <= '0';
        -- Initialisation des signaux
        counter <= 0;
        bit_x <= 0;
        led_x <= 0;
        
        led_adress <= "0000";
        led_data <= (others => '0');
        --
        state_rst <= '0';
        state_bit <= '0';
        state_fsm <= '0';
        
    elsif rising_edge(clk) and Rst_n = '1' then
        -- Selection des donnees en fonction de l index des LEDs
        if color_led = "000000" then
            case index_led is
                when "0000" => led_data <= std_logic_vector(unsigned(RED));       -- LED 1 Red
                when "0001" => led_data <= std_logic_vector(unsigned(ORANGE));    -- LED 2 Orange
                when "0010" => led_data <= std_logic_vector(unsigned(YELLOW));    -- LED 3 Yellow
                when "0011" => led_data <= std_logic_vector(unsigned(GREEN));     -- LED 4 Green
                when "0100" => led_data <= std_logic_vector(unsigned(GREEN2));    -- LED 5 Green2
                when "0101" => led_data <= std_logic_vector(unsigned(CYAN));      -- LED 6 Cyan
                when "0110" => led_data <= std_logic_vector(unsigned(LIME));      -- LED 7 Lime
                when "0111" => led_data <= std_logic_vector(unsigned(BLUE));      -- LED 8 Blue
                when "1000" => led_data <= std_logic_vector(unsigned(PURPLE));    -- LED 9 Purple
                when "1001" => led_data <= std_logic_vector(unsigned(MAGENTA));   -- LED 10 Magenta
                when "1010" => led_data <= std_logic_vector(unsigned(ROSE_BAISER));-- LED 11 Rose Baiser
                when "1011" => led_data <= std_logic_vector(unsigned(WHITE));     -- LED 12 White

                when "1111" => led_data <= std_logic_vector(unsigned(BLACK));     -- LED 13 Black
                when others => led_data <= (others => '1'); -- Led else ( 11 ) white
            end case;    
        else
            if unsigned(index_led) >= 12 then
                led_data <= std_logic_vector(unsigned(BLACK));                
            else
                led_data <= (others => '0');
                for i in 0 to 5 loop
                    if color_led(i) = '1' then
                        led_data((i+1)*4-1 downto i*4) <= (others => '1');
                    else
                        led_data((i+1)*4-1 downto i*4) <= (others => '0');
                    end if;
                end loop;
            end if;           
        end if;
        
        if led_adress = "0000" then
            led_data <= std_logic_vector(unsigned(BLACK));
        end if;
       
        -- gestion du reset
        if state_rst = '0' then
            led_adress <= write_led(3 downto 0);

            if unsigned(led_adress) > 12 then
                led_adress <= "1100";
            end if;
            
            if counter < (2500 * FREQ_DIV) then -- Reset = 50 us  = 2500 cycles Clk_50_MHz
                counter <= counter + 1;
                commande <= '0';  -- maintenir le reset
            else
                counter <= 0;
                state_rst <= '1';  -- le reset est termine
            end if;

        else
            -- transmission des donnees
            if state_fsm = '0' then
                -- etat haut fsm
                if state_bit = '1' then
                    -- bit "1"
                    if counter < (35 * FREQ_DIV) then -- T1H = 700 ns = 35 periodes 50 MHz
                        commande <= '1';
                        counter <= counter + 1;
                    else
                        state_fsm <= '1';
                        counter <= 0;
                    end if;
                else
                    -- bit "0"
                    if counter <= 17 then -- T0H = 350 ns = 17.5 periodes 50 MHz
                        commande <= '1';
                        counter <= counter + 1;
                    else
                        state_fsm <= '1'; 
                        counter <= 0;
                    end if;
                end if;

            else
                -- etat bas fsm
                if state_bit = '1' then
                    -- bit "1"
                    if counter < (30 * FREQ_DIV) then -- T1L = 600 ns = 30 periodes 50 MHz
                        commande <= '0';
                        counter <= counter + 1;
                    else
                        state_fsm <= '0';  
                        counter <= 0;
                        bit_x <= bit_x + 1; -- Prochain bit
                    end if;
                else
                    -- bit "0"
                    if counter < (40 * FREQ_DIV) then -- T0L = 8oo ns = 40 periodes 50 MHz
                        commande <= '0';
                        counter <= counter + 1;
                    else
                        state_fsm <= '0';
                        counter <= 0;
                        bit_x <= bit_x + 1; -- Prochain bit
                    end if;
                end if;
            end if;

            if bit_x < 24 then
                state_bit <= led_data(23 - bit_x);
            else
                bit_x <= 0;
                if led_x < 11 then
                    led_x <= led_x + 1;
                    if (led_x + 2> unsigned(led_adress)) then
                        index_led   <= "1111";
                    else
                        index_led   <= std_logic_vector(unsigned(index_led) + 1);
                    end if;
                else
                    index_led   <= (others => '0');
                    led_x <= 0;
                    state_rst  <= '0';
                end if;
            end if;
        end if;
    end if;
end process;

end architecture;