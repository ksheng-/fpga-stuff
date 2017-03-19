----------------------------------------------------------------------
-- 32 bit floating point multiply accumulator (exercise 3.3)
-- Kevin Sheng
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------

entity mac is
    port (x: in std_logic_vector(31 downto 0);
          y: in std_logic_vector(31 downto 0); 
          clk: in std_logic; 
          rst: in std_logic; 
          accum: out std_logic_vector(31 downto 0)
    );
end entity mac;

architecture rtl of mac is
    -- Input signals
    signal x_mant: std_logic_vector(22 downto 0);
    signal x_expn: std_logic_vector(7 downto 0);
    signal x_sign: std_logic;
    signal y_mant: std_logic_vector(22 downto 0);
    signal y_expn: std_logic_vector(7 downto 0);
    signal y_sign: std_logic;
    
    -- Intermediate representations and signals, Z is the intermediate product untruncated
    signal x_mant_full: std_logic_vector(23 downto 0);
    signal y_mant_full: std_logic_vector(23 downto 0);
    
    signal z_mant_full: std_logic_vector(47 downto 0);
    signal z_expn_unadj: std_logic_vector(7 downto 0);
    signal z_sign: std_logic;
    signal shiftamt: integer := 0;
    
    signal acc_mant_full: std_logic_vector(47 downto 0);
    signal acc_expn_unadj: std_logic_vector(7 downto 0);
    
    -- Output signals
    signal acc_mant: std_logic_vector(22 downto 0);
    signal acc_expn: std_logic_vector(7 downto 0);
    signal acc_sign: std_logic;
    
begin
    process (clk, rst)
    begin
        if (rst = '1') then
            x_mant <= (others => '0');
            x_expn <= (others => '0');
            x_sign <= '0';
            y_mant <= (others => '0');
            y_expn <= (others => '0');
            y_sign <= '0';
        elsif (clk'event and clk = '1') then
            x_mant <= x(22 downto 0);
            x_expn <= x(30 downto 23);
            x_sign <= x(31);
            y_mant <= y(22 downto 0);
            y_expn <= y(30 downto 23);
            y_sign <= y(31);
        end if;
    end process;
    
    -------------------------------------------
    -- addapp:
    --  Add exponents and subtract bias, append 
    --  implied bit to mantissa.
    -------------------------------------------
    addapp: process (x_mant, y_mant, x_expn, y_expn)
        variable expn_sum: integer;
    begin
        x_mant_full <= '1' & x_mant;
        y_mant_full <= '1' & y_mant;
        if (x_expn = "00000000") then
            x_mant_full <= '0' & x_mant;
        end if;
        if (y_expn = "00000000") then
            y_mant_full <= '0' & y_mant;
        end if;
        
        expn_sum := to_integer(unsigned(x_expn)) + to_integer(unsigned(y_expn)) - 127;
        if (expn_sum >= 0) then
            z_expn_unadj <= std_logic_vector(unsigned(x_expn) + unsigned(y_expn) - 127);
            shiftamt <= 0;
        else
            -- handle unnormalized numbers
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
    multiply: process (x_sign, y_sign, x_mant_full, y_mant_full, shiftamt)
    begin
        -- XOR sign bits to get resulting sign
        z_sign <= x_sign xor y_sign; 
        z_mant_full <= (others => '0');
        if (shiftamt > 0) then
            -- Right shift results if exponent sum is negative
            z_mant_full <=  std_logic_vector(shift_right(unsigned(x_mant_full) * unsigned(y_mant_full), shiftamt));
        else
            z_mant_full <= std_logic_vector(unsigned(x_mant_full) * unsigned(y_mant_full));
        end if;
    end process multiply;
    
    -------------------------------------------
    -- accumulate:
    --  Add accumulator into product
    -------------------------------------------
    accumulate: process (z_sign, z_expn_unadj, z_mant_full, acc_sign, acc_expn, acc_mant)
        variable acc_mant_temp: std_logic_vector(47 downto 0);
        variable z_expn_temp: std_logic_vector(7 downto 0);
        variable z_mant_temp: std_logic_vector(47 downto 0);
        variable sum_mant_temp: std_logic_vector(47 downto 0);
    begin
        -- Immediate output of multiplier is 1 sign bit, 8 expn bits, and 48 mantissa bits (two appended bits)
        -- Need to add to 32 bit accumulator output before normalizing
        if (acc_expn = "00000000") then
            acc_mant_temp := '0' & acc_mant & (23 downto 0 => '0');
        else
            acc_mant_temp := '1' & acc_mant & (23 downto 0 => '0');
        end if;
        
        z_expn_temp := std_logic_vector(unsigned(z_expn_unadj) + 1);
        -- Shift smaller right
        if (unsigned(z_expn_temp) - unsigned(acc_expn) >= 0) then
            acc_mant_temp := std_logic_vector(shift_right(unsigned(acc_mant_temp), to_integer(unsigned(z_expn_temp) - unsigned(acc_expn)))); 
            z_mant_temp := z_mant_full;
            acc_expn_unadj <=  z_expn_temp;
        else
            z_mant_temp := std_logic_vector(shift_right(unsigned(z_mant_full), to_integer(unsigned(acc_expn) - unsigned(z_expn_temp))));
            acc_expn_unadj <=  acc_expn;
        end if;
        
        sum_mant_temp := std_logic_vector(unsigned(z_mant_temp) + unsigned(acc_mant_temp));
        -- If the operand is negative, take the twos complements of the mantissa then add
        if (z_sign = '1') then
            sum_mant_temp := std_logic_vector(signed(not z_mant_temp) + 1 + signed(acc_mant_temp));
        end if;
        if (acc_sign = '1') then
            sum_mant_temp := std_logic_vector(signed(z_mant_temp) + signed(not acc_mant_temp) + 1);
        end if;
        
        -- If the result is negative, take the twos complement again
        if (sum_mant_temp(47) = '1') then
            sum_mant_temp := std_logic_vector(unsigned(not sum_mant_temp) + 1);
        end if;
        
        acc_mant_full <= sum_mant_temp;
    end process accumulate;

    -------------------------------------------
    -- normalize:
    --  Normalize result and check for edge 
    --  cases, and get final result.
    -------------------------------------------
    normalize: process (acc_expn_unadj, acc_mant_full)
        variable first_one: integer;
    begin
        -- Check infinity cases
        if (acc_mant_full /= (47 downto 0 => '0')) then
            if (z_mant_full(47) = '1') then
                -- Normalize result: if first bit is 1, shift left and increase exponent
                -- Truncate bits
                acc_mant <= z_mant_full(46 downto 24);
                acc_expn <= std_logic_vector(unsigned(z_expn_unadj) + 1);         
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
                if (46 - first_one <=  to_integer(unsigned(z_expn_unadj))) and (first_one > -1) then
                    -- Normalized result
                    acc_expn <= std_logic_vector(unsigned(z_expn_unadj) - to_unsigned(46 - first_one, 8));
                    acc_mant <= z_mant_full((first_one-1) downto (first_one-23));
                elsif (first_one > -1) then
                    -- Denormalized result
                    acc_expn <= "00000000";
                    acc_mant <= z_mant_full((46-to_integer(unsigned(z_expn_unadj))-1) downto (46-to_integer(unsigned(z_expn_unadj))-23));
                else
                    -- Zero
                    acc_expn <= "00000000";
                    acc_sign <= '0';
                    acc_mant <= "00000000000000000000000";
                end if;
            end if;
        else
            acc_expn <= "00000000";
            acc_sign <= '0';
            acc_mant <= "00000000000000000000000";
        end if;

    end process normalize;
    
    -------------------------------------------
    -- output:
    --  Output result.
    -------------------------------------------
    output: process (acc_sign, acc_expn, acc_mant)
    begin
        accum(31) <= acc_sign;
        accum(30 downto 23) <= acc_expn;
        accum(22 downto 0) <= acc_mant;
    end process output;
end architecture rtl;
