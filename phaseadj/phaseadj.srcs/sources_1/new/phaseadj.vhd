----------------------------------------------------------------------
-- Phase corrector (exercise 4.1)
-- Kevin Sheng

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------

entity phaseadj is
    port (x_re: in std_logic_vector(15 downto 0);
          x_im: in std_logic_vector(15 downto 0);
          y_re: out std_logic_vector(15 downto 0);
          y_im: out std_logic_vector(15 downto 0);
          clk: in std_logic
    );
end entity phaseadj;

architecture rtl of phaseadj is
    type complex_16 is record
        re: std_logic_vector(15 downto 0);
        im: std_logic_vector(15 downto 0);
    end record;
    type complex_32 is record
        re: std_logic_vector(31 downto 0);
        im: std_logic_vector(31 downto 0);
    end record;
    type arr_cplx is array (2 downto 0) of complex_16;
    type arr_real is array (1 downto 0) of std_logic_vector(15 downto 0);
    
    -- Constants
    constant a: arr_cplx := (("0000000000000000", "0000000000000000"), 
                             ("0000000000000000", "0000000000000000"), 
                             ("0000000000000000", "0000000000000000"));
    constant b: arr_cplx := (("0000000000000000", "0000000000000000"), 
                             ("0000000000000000", "0000000000000000"), 
                             ("0000000000000000", "0000000000000000"));
    constant Kp: complex_16 := ("0000000000000000", "0000000000000000");
    constant Ki: complex_16 := ("0000000000000000", "0000000000000000");

    signal mixer_out: arr_cplx := (("0000000000000000", "0000000000000000"), 
                             ("0000000000000000", "0000000000000000"), 
                             ("0000000000000000", "0000000000000000"));
    signal phase: complex_16 := ("0000000000000000", "0000000000000000");
    signal phase_corr: complex_16 := ("0000000000000000", "0000000000000000");
    signal delayline: arr_cplx := (("0000000000000000", "0000000000000000"), 
                                 ("0000000000000000", "0000000000000000"), 
                                 ("0000000000000000", "0000000000000000"));
    signal offset_delayline: arr_real := ("0000000000000000", "0000000000000000");
    
    -------------------------------------------
    -- add 16 bit real numbers
    -- saturate on overflow
    -- synthesized as combinatorial logic
    -------------------------------------------
    function add_real (a: std_logic_vector(15 downto 0); 
                       b: std_logic_vector(15 downto 0))
    return std_logic_vector is
        variable temp: signed(15 downto 0) := "0000000000000000";
    begin 
        temp := signed(a) + signed(b);
        if (temp < 0) and (a(15) = '0') and (b(15) = '0') then
            return "0111111111111111";
        elsif (temp > 0) and (a(15) = '1') and (b(15) = '1') then
            return "1000000000000000";
        else
            return std_logic_vector(temp);
        end if;
    end function add_real;

    -------------------------------------------
    -- multiply Q1.15 real numbers
    -- remove redundant sign bits, round
    -- then truncate
    -------------------------------------------
    function multiply_real (a: std_logic_vector(15 downto 0); 
                            b: std_logic_vector(15 downto 0))
    return std_logic_vector is
        variable temp: std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
        constant roundbit: signed(31 downto 0) := "00000000000000001000000000000000";
    begin 
        temp := std_logic_vector(shift_left(unsigned(signed(a) * signed(b)), 1));
        temp := std_logic_vector(signed(temp) + roundbit);
        return temp(31 downto 16);
    end function multiply_real;
    
    -------------------------------------------
    -- Add real and imaginary parts of 
    -- complex number, check for saturation
    -------------------------------------------
    function add_cplx (a: complex_16; 
                       b: complex_16)
    return complex_16 is
        variable temp_re: signed(15 downto 0) := "0000000000000000";
        variable temp_im: signed(15 downto 0) := "0000000000000000";
        variable sum: complex_16;
    begin 
        temp_re := signed(a.re) + signed(b.re);
        if (temp_re < 0) and (a.re(15) = '0') and (b.re(15) = '0') then
            sum.re := "0111111111111111";
        elsif (temp_re > 0) and (a.re(15) = '1') and (b.re(15) = '1') then
            sum.re := "1000000000000000";
        else
            sum.re := std_logic_vector(temp_re);
        end if;
        
        temp_im := signed(a.im) + signed(b.im);
        if (temp_im < 0) and (a.im(15) = '0') and (b.im(15) = '0') then
            sum.im := "0111111111111111";
        elsif (temp_im > 0) and (a.im(15) = '1') and (b.im(15) = '1') then
            sum.im := "1000000000000000";
        else
            sum.im := std_logic_vector(temp_im);
        end if;
        
        return sum;
        
    end function add_cplx;
    
    -------------------------------------------
    -- Multiply Q1.15 complex numbers, FOIL
    -------------------------------------------
    function multiply_cplx (a: complex_16; 
                            b: complex_16)
    return complex_16 is
        variable temp_re1: std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
        variable temp_re2: std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
        variable temp_im1: std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
        variable temp_im2: std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
        constant roundbit: signed(31 downto 0) := "00000000000000001000000000000000";
        variable product_re1: std_logic_vector(15 downto 0) := "0000000000000000";
        variable product_re2: std_logic_vector(15 downto 0) := "0000000000000000";
        variable product_im1: std_logic_vector(15 downto 0) := "0000000000000000";
        variable product_im2: std_logic_vector(15 downto 0) := "0000000000000000";
        variable product: complex_16;
        
    begin 
        temp_re1 := std_logic_vector(shift_left(unsigned(signed(a.re) * signed(b.re)), 1));
        temp_re1 := std_logic_vector(signed(temp_re1) + roundbit);
        product_re1 := temp_re1(31 downto 16);
        temp_re2 := std_logic_vector(-signed(shift_left(unsigned(signed(a.im) * signed(b.im)), 1)));
        temp_re2 := std_logic_vector(signed(temp_re2) + roundbit);
        product_re2 := temp_re2(31 downto 16);
        
        temp_im1 := std_logic_vector(shift_left(unsigned(signed(a.im) * signed(b.re)), 1));
        temp_im1 := std_logic_vector(signed(temp_im1) + roundbit);
        product_im1 := temp_im1(31 downto 16);
        temp_im2 := std_logic_vector(shift_left(unsigned(signed(a.re) * signed(b.im)), 1));
        temp_im2 := std_logic_vector(signed(temp_im2) + roundbit);
        product_im2 := temp_im2(31 downto 16);
        
        product.re := add_real(product_re1, product_re2);  
        product.im := add_real(product_im1, product_im2);
        
        return product;
    
    end function multiply_cplx;
    
begin

    -------------------------------------------
    -- clock:
    --  clock in new values of x
    -------------------------------------------
    clock: process (clk)
        variable temp1: complex_16;
        variable temp2: complex_16;
    begin
        if (clk'event and clk = '1') then
            temp1.re := x_re;
            temp1.im := x_im;
            temp2.re := std_logic_vector(-signed(phase.im));
            temp2.im := std_logic_vector(-signed(phase.re));

            mixer_out(2) <= mixer_out(1);
            mixer_out(1) <= mixer_out(0);
            mixer_out(0) <= multiply_cplx(temp1, temp2);
            
            delayline(2) <= delayline(1);
            delayline(1) <= delayline(0);
            
            y_re <= multiply_cplx(temp1, temp2).re;
            y_im <= multiply_cplx(temp1, temp2).im;
        end if;
    end process clock;
    
    
    -------------------------------------------
    -- add1:
    --  Delayline[0]= - Delayline[1]*a[1]
    --                - Delayline[2]*a[2]
    --                + Mixer_Out[0]*b[0]
    --                + Mixer_Out[1]*b[1]
    --                + Mixer_Out[2]*b[2];
    -------------------------------------------
    add1: process (mixer_out)
        variable prod1: complex_16;
        variable prod2: complex_16;
        variable prod3: complex_16;
        variable prod4: complex_16;
        variable prod5: complex_16;
    begin
        prod1 := multiply_cplx(delayline(1), a(1));
        prod2 := multiply_cplx(delayline(2), a(2));
        prod3 := multiply_cplx(mixer_out(0), b(0));
        prod4 := multiply_cplx(mixer_out(1), b(1));
        prod5 := multiply_cplx(mixer_out(2), b(2));
        delayline(0) <= add_cplx(prod1, add_cplx(prod2, add_cplx(prod3, add_cplx(prod4, prod5))));
    end process add1;

    -------------------------------------------
    -- getoffset:
    --  offset = real(Delayline[2]*Delayline[0]);
    --  offset_Delayline[0] = offset_Delayline[1];
    --  offset_Delayline[1] = offset;
    -------------------------------------------
    getoffset: process (delayline(0))
    begin
        offset_delayline(0) <= offset_delayline(1);
        offset_delayline(1) <= multiply_cplx(delayline(2), delayline(0)).re;
    end process getoffset;
    
    -------------------------------------------
    -- add2:
    --  offset = real(Delayline[2]*Delayline[0]);
    --  offset_Delayline[0] = offset_Delayline[1];
    --  offset_Delayline[1] = offset;
    --  phase_corr =   Kp*offset_Delayline[0]
    --               + Ki*offset_Delayline[1]
    --               + phase_corr
    --               - Kp*offset_Delayline[1];
    -------------------------------------------
    add2: process (delayline(0))
        variable prod1: complex_16;
        variable prod2: complex_16;
        variable prod3: complex_16;
        variable temp: complex_16;
    begin
        temp.re := std_logic_vector(-signed(Kp.re));
        temp.im := std_logic_vector(-signed(Kp.im));
        prod1 := multiply_cplx(delayline(0), Kp);
        prod2 := multiply_cplx(delayline(1), Ki);
        prod3 := multiply_cplx(delayline(1), temp);
        phase_corr <= add_cplx(prod1, add_cplx(prod2, add_cplx(prod3, phase_corr)));
    end process add2;
    
    -------------------------------------------
    -- add3:
    --  Accumulate phase
    -------------------------------------------
    add3: process (phase_corr)
    begin
        phase <= add_cplx(phase, phase_corr);
    end process add3;
end architecture rtl;
