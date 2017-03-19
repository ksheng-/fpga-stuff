----------------------------------------------------------------------
-- 4 coefficient FIR filter (exercise 3.12)
-- Kevin Sheng

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------

entity fir is
    port (x: in std_logic_vector(15 downto 0);
          y: out std_logic_vector(17 downto 0); 
          h03: in std_logic_vector(15 downto 0); 
          h12: in std_logic_vector(15 downto 0);
          clk: in std_logic
    );
end entity fir;

architecture rtl of fir is
    -- Folded structure: y[n] = h0(x[n]+x[n-3]) + h1(x[n-1]+x[n-2])
    -- Arrays to hold intermediate values
    type arr2_16 is array (1 downto 0) of std_logic_vector(15 downto 0);
    type arr2_18 is array (1 downto 0) of std_logic_vector(17 downto 0);
    type arr2_32 is array (1 downto 0) of std_logic_vector(31 downto 0);
    type arr4_16 is array (3 downto 0) of std_logic_vector(15 downto 0);
    
    -- Addition results
    signal sum: arr2_16;
    -- Result of multiplication
    signal product: arr2_32;
    signal product_rounded: arr2_32;
    signal product_truncated: arr2_18;
    -- Inputs and output arrays
    signal xn: arr4_16;
    
begin
    -------------------------------------------
    -- timestep:
    --  clock new values of x
    -------------------------------------------
    timestep: process (clk)
    begin
        if (clk'event and clk = '1') then
            xn(0) <= x;
            xn(1) <= xn(0);
            xn(2) <= xn(1);
            xn(3) <= xn(2);
        end if;
    end process timestep;
    
    -------------------------------------------
    -- add:
    --  Add x[n] and x[n-3], x[n-1] and x[n-2]
    --  and check for saturation
    -------------------------------------------
    add: process (xn)
        variable tempsum: signed(15 downto 0);
        variable tempsum2: signed(15 downto 0);
    begin
            tempsum := signed(xn(0)) + signed(xn(3));
            -- Check for overflow in addition, saturate. 
            if (tempsum < 0) and (xn(0)(15) = '0') and (xn(3)(15) = '0') then
                sum(0) <= "0111111111111111";
            elsif (tempsum > 0) and (xn(0)(15) = '1') and (xn(3)(15) = '1') then
                sum(0) <= "1000000000000000";
            else
                sum(0) <= std_logic_vector(tempsum);
            end if;
            
            tempsum2 := signed(xn(1)) + signed(xn(2));
            -- Check for overflow in addition, saturate. 
            if (tempsum2 < 0) and (xn(1)(15) = '0') and (xn(2)(15) = '0') then
                sum(1) <= "0111111111111111";
            elsif (tempsum2 > 0) and (xn(1)(15) = '1') and (xn(2)(15) = '1') then
                sum(1) <= "1000000000000000";
            else
                sum(1) <= std_logic_vector(tempsum2);
            end if;
    end process add;
    
    -------------------------------------------
    -- multiply:
    --  Multiply by corresponding filter coefficient
    --  Q1.15 * Q1.15 results in Q2.30, shift 
    --  left to remove redudant sign bit resulting
    --  in Q1.31
    -------------------------------------------
    multiply: process (sum)
    begin
            product(0) <= std_logic_vector(shift_left(unsigned(signed(sum(0)) * signed(h03)), 1));
            product(1) <= std_logic_vector(shift_left(unsigned(signed(sum(1)) * signed(h12)), 1));
    end process multiply;

    -------------------------------------------
    -- round:
    --  Round for Q1.17 by adding 1 to bit 13
    -------------------------------------------
    round: process (product)
        constant roundbit: signed(31 downto 0) := "00000000000000000010000000000000";
    begin
            product_rounded(0) <= std_logic_vector(signed(product(0)) + roundbit);
            product_rounded(1) <= std_logic_vector(signed(product(1)) + roundbit);
    end process round;
    
    -------------------------------------------
    -- truncate:
    --  Truncate to Q1.17
    -------------------------------------------
    truncate: process (product_rounded)
    begin
            product_truncated(0) <= product_rounded(0)(31 downto 14);
            product_truncated(1) <= product_rounded(1)(31 downto 14);
    end process truncate;
 
    -------------------------------------------
    -- output:
    --  output y[n]
    -------------------------------------------
    output: process (product_truncated)
        variable tempsum: signed(17 downto 0);
    begin
            tempsum := signed(product_truncated(0)) + signed(product_truncated(1));
            -- Check for overflow in addition, saturate. 
            if (tempsum < 0) and (product_truncated(0)(17) = '0') and (product_truncated(1)(17) = '0') then
                y <= "011111111111111111";
            elsif (tempsum > 0) and (product_truncated(0)(17) = '1') and (product_truncated(1)(17) = '1') then
                y <= "100000000000000000";
            else
                y <= std_logic_vector(tempsum);
            end if;
    end process output;
    
end architecture rtl;
