----------------------------------------------------------------------
-- Test Bench for multiply accumulator (exercise 3.3)
-- Kevin Sheng
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------

entity mac_tb is
end entity mac_tb;

architecture testbench of mac_tb is
    signal x_test: std_logic_vector(31 downto 0);
    signal y_test: std_logic_vector(31 downto 0);
    signal a_test: std_logic_vector(31 downto 0);
    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
    signal stop: std_logic:= '0';
    
    component mac is
        port (x: in std_logic_vector(31 downto 0);
              y: in std_logic_vector(31 downto 0); 
              accum: out std_logic_vector(31 downto 0);
              clk: in std_logic; 
              rst: in std_logic
        );
    end component;
    
begin
        UUT: mac port map (x => x_test, y => y_test, accum => a_test, clk => clock, rst => reset);
        clock <= not clock after 5 ns when stop /= '1' else '0';
        
        process
        begin
            reset <= '1';
            wait for 20 ns;
            reset <= '0';
    
            -- Start accumulating
            x_test <= "00000000000000000000000000000000";
            y_test <= "11111111111111111111111111111111";
            wait for 20 ns;
            assert a_test = "00000000000000000000000000000000"
            report "Error: Incorrect Output"
            severity failure;
            
            -- .1 * 1
            x_test <= "00111101110011001100110011001101";
            y_test <= "00111111100000000000000000000000";
            wait for 20 ns;
            assert a_test = "00111101110011001100110011001101"
            report "Error: Incorrect Output"
            severity failure;
            
            -- .1 * 2
            x_test <= "00111101110011001100110011001101";
            y_test <= "01000000000000000000000000000000";
            wait for 20 ns;
            assert a_test = "00111110010011001100110011001101"
            report "Error: Incorrect Output"
            severity failure;
            
            -- -.3 * 1
            x_test <= "10111110100110011001100110011010";
            y_test <= "00111111100000000000000000000000";
            wait for 20 ns;
            assert a_test = "00000000000000000000000000000000"
            report "Error: Incorrect Output"
            severity failure;
            
            stop <= '1';
        end process;
end architecture testbench;
