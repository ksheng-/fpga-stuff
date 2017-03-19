----------------------------------------------------------------------
-- Test Bench for phase corrector (exercise 4.1)
-- Kevin Sheng

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------

entity phaseadj_tb is
end entity phaseadj_tb;

architecture testbench of phaseadj_tb is
    signal x_re_test : std_logic_vector(15 downto 0);
    signal x_im_test : std_logic_vector(15 downto 0);
    signal y_re_test : std_logic_vector(15 downto 0);
    signal y_im_test : std_logic_vector(15 downto 0);
    signal clock  : std_logic := '0';
    signal stop   : std_logic := '0';
    
    component phaseadj is
        port (x_re: in std_logic_vector(15 downto 0);
              x_im: in std_logic_vector(15 downto 0);
              y_re: out std_logic_vector(15 downto 0);
              y_im: out std_logic_vector(15 downto 0);
              clk: in std_logic
        );
    end component;
    
begin
        UUT: phaseadj port map (x_re => x_re_test, x_im => x_im_test, y_re => y_re_test, y_im => y_im_test, clk => clock);
        clock <= not clock after 5 ns when stop /= '1' else '0';
        
        process
        begin
            x_re_test <= "0000000000000000";
            x_im_test <= "0000000000000000";
            wait for 100 ns;
            x_re_test <= "0000000000000000";
            x_im_test <= "0000000000000000";
            wait for 10 ns;
            assert y_re_test = "0000000000000000"
            report "Error: Incorrect Output"
            severity failure;
            assert y_im_test = "0000000000000000"
            report "Error: Incorrect Output"
            severity failure;
            
            stop <= '1';
        end process;
end architecture testbench;
