----------------------------------------------------------------------
-- 13 bit floating point multiplier (exercise 3.1)
-- 1 sign bit, 4 exponent bits, 8 mantissa bits, 7 bias
-- Kevin Sheng

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

----------------------------------------------------------------------

entity fpmultiplier is
    port (x : in  std_logic_vector(12 downto 0);
          y : in  std_logic_vector(12 downto 0); 
          z : out std_logic_vector(12 downto 0));
end entity fpmultiplier;

architecture behavioral of fpmultiplier is
    -- Input signals
    signal x_mant : std_logic_vector(7 downto 0);
    signal x_expn : std_logic_vector(3 downto 0);
    signal x_sign : std_logic;
    signal y_mant : std_logic_vector(7 downto 0);
    signal y_expn : std_logic_vector(3 downto 0);
    signal y_sign : std_logic;
    
    -- Intermediate representations and signals
    signal x_mant_full : std_logic_vector(8 downto 0);
    signal y_mant_full : std_logic_vector(8 downto 0);
    signal z_mant_full : std_logic_vector(17 downto 0);
    signal z_expn_unadj : std_logic_vector(3 downto 0);
    signal shiftamt : integer := 0;
    
    -- Output signals
    signal z_mant : std_logic_vector(7 downto 0);
    signal z_expn : std_logic_vector(3 downto 0);
    signal z_sign : std_logic;
    
begin
    -------------------------------------------
    -- combinational:
    --  Do combinational "preprocessing".
    -------------------------------------------
    combinational : process (x,y)
    begin
        x_mant <= x(7 downto 0);
        x_expn <= x(11 downto 8);
        x_sign <= x(12);
        y_mant <= y(7 downto 0);
        y_expn <= y(11 downto 8);
        y_sign <= y(12);
    end process combinational;
    
    -------------------------------------------
    -- addapp:
    --  Add exponents and subtract bias, append 
    --  implied bit to mantissa.
    -------------------------------------------
    addapp : process (x_mant, y_mant, x_expn, y_expn)
        variable expn_sum : integer;
    begin
        x_mant_full <= '1' & x_mant;
        y_mant_full <= '1' & y_mant;
        if (x_expn = 0) then
            x_mant_full <= '0' & x_mant;
        end if;
        if (y_expn = 0) then
            y_mant_full <= '0' & y_mant;
        end if;
        
        expn_sum := to_integer(unsigned(x_expn)) + to_integer(unsigned(y_expn)) - 7;
        if (expn_sum >= 0) then
            z_expn_unadj <= std_logic_vector(unsigned(x_expn) + unsigned(y_expn) - 7);
            shiftamt <= 0;
        else
            z_expn_unadj <= (others => '0');
            shiftamt <= -expn_sum;
        end if;
        -- May need to adjust later to normalize

    end process addapp;
    
    -------------------------------------------
    -- multiply:
    --  13 bit floating point multiplication of
    --  inputs, untruncated/unnormalized
    -------------------------------------------
    multiply : process (x_mant_full, y_mant_full, shiftamt)
    begin
        z_mant_full <= (others => '0');
        if (shiftamt > 0) then
            -- Right shift results if exponent sum is negative
            z_mant_full <=  std_logic_vector(shift_right(unsigned(x_mant_full * y_mant_full), shiftamt));
        else
            z_mant_full <= x_mant_full * y_mant_full;
        end if;
    end process multiply;

    -------------------------------------------
    -- normalize:
    --  Normalize result and check for edge 
    --  cases, and get final result.
    -------------------------------------------
    normalize : process (x_expn, x_sign, y_expn, y_sign, z_expn_unadj, z_mant_full)
        variable first_one: integer;
    begin
        -- XOR sign bits to get resulting sign
        z_sign <= x_sign xor y_sign;
        
        -- Check infinity cases
        if (x_expn = "1111" or y_expn = "1111") then
            z_mant <= "00000000";
            z_expn <= "1111";   
        else
            if (z_mant_full(17) = '1') then
                -- Normalize result: if first bit is 1, shift left and increase exponent
                -- Truncate bits
                z_mant <= z_mant_full(16 downto 9);
                z_expn <= z_expn_unadj + '1';         
            else
                -- denormalized * denormalized
                -- Search for most signifiant one
                first_one := -1;
                for i in z_mant_full'range loop
                  if (z_mant_full(i) = '1') then
                    first_one := i;
                    exit;
                  end if;
                end loop;
                if (16 - first_one <=  to_integer(unsigned(z_expn_unadj))) then
                    -- Normalized result
                    z_expn <= z_expn_unadj - std_logic_vector(to_unsigned((16 - first_one), 4));
                    z_mant <= z_mant_full((first_one-1) downto (first_one-8));
                elsif (first_one > -1) then
                    -- Denormalized result
                    z_expn <= "0000";
                    z_mant <= z_mant_full((16-to_integer(unsigned(z_expn_unadj))-1) downto (16-to_integer(unsigned(z_expn_unadj))-8));
                else
                    -- Zero
                    z_expn <= "0000";
                    z_sign <= '0';
                    z_mant <= "00000000";
                end if;
            end if;
        end if;
    end process normalize;
    
    -------------------------------------------
    -- output:
    --  Output result.
    -------------------------------------------
    output : process (z_sign, z_expn, z_mant)
    begin
        z(12) <= z_sign;
        z(11 downto 8) <= z_expn;
        z(7 downto 0) <= z_mant;
    end process output;
end architecture behavioral;
