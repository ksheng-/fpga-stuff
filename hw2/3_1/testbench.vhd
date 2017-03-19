----------------------------------------------------------------------
-- Test Bench for 13 bit floating point multiplier (exercise 3.1)
-- Kevin Sheng

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

----------------------------------------------------------------------

entity fpmultiplier_tb is
end entity fpmultiplier_tb;

architecture testbench of fpmultiplier_tb is
    signal x_test : std_logic_vector(12 downto 0);
    signal y_test : std_logic_vector(12 downto 0);
    signal z_test : std_logic_vector(12 downto 0);
    
    component fpmultiplier is
        port (x : in  std_logic_vector(12 downto 0);
              y : in  std_logic_vector(12 downto 0); 
              z : out std_logic_vector(12 downto 0)
        );
    end component;
    
begin
        UUT: fpmultiplier port map (x => x_test, y => y_test, z => z_test);
        
        process
        begin
            -- normalized * normalized
            x_test <= "0101000010010";
            y_test <= "1001110010010";
            wait for 10 ns;
            assert z_test = "1011010101110"
            report "Error: Incorrect Product"
            severity failure;
            -- denormalized * denormalized
            x_test <= "0000000010010";
            y_test <= "0000010010010";
            wait for 10 ns;
            assert z_test = "0000000000000"
            report "Error: Incorrect Product"
            severity failure;
            -- normalized * denormalized
            x_test <= "0000000010010";
            y_test <= "0101000010010";
            wait for 10 ns;
            assert z_test = "0000010011010"
            report "Error: Incorrect Product"
            severity failure;
            -- zero * zero
            x_test <= "0000000000000";
            y_test <= "0000000000000";
            wait for 10 ns;
            assert z_test = "0000000000000"
            report "Error: Incorrect Product"
            severity failure;
            -- infinite * infinite
            x_test <= "0111100000000";
            y_test <= "0111100000000";
            wait for 10 ns;
            assert z_test = "0111100000000"
            report "Error: Incorrect Product"
            severity failure;
            -- -infinite * -infinite
            x_test <= "1111100000000";
            y_test <= "1111100000000";
            wait for 10 ns;
            assert z_test = "0111100000000"
            report "Error: Incorrect Product"
            severity failure;
            -- infinite * finite
            x_test <= "1111100000000";
            y_test <= "1001100110100";
            wait for 10 ns;
            assert z_test = "0111100000000"
            report "Error: Incorrect Product"
            severity failure;
            -- zero * nonzero
            x_test <= "0000000000000";
            y_test <= "0101000001010";
            wait for 10 ns;
            assert z_test = "0000000000000"
            report "Error: Incorrect Product"
            severity failure;
        end process;
end architecture testbench;
