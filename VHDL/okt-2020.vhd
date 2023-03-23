-- a) registar koji cuva jednu 8bitnu vrednost
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register is
    port(
        clk, rst, enable: in std_logic;
        din: in std_logic_vector(7 downto 0);
        dout: out std_logic_vector(7 downto 0);
    );
end entity register;
architecture arch_register of register is
begin
    saving: process(clk) is 
        variable val: std_logic_vector(7 downto 0);
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                val := (others => '0');
            elsif enable = '1' then
                val := din;
            end if;
        end if;
        dout <= val;
    end process;
end architecture arch_register;

-- b) BCD brojač (ne znam sme li da se koristi implementacija sa konvertovanjem integer-a u std_logic i prost rad sa brojevima)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bcd_counter is 
    generic(target: std_logic_vector(7 downto 0));
    port(
        clk, rst, enable: in std_logic;
        out_port: out std_logic_vector(7 downto 0)
    );
end entity bcd_counter;
architecture arch_bcd_counter of bcd_counter is
begin
    counting: process (clk) is
        variable msd, lsd: unsigned(3 downto 0);
    begin:
        if clk'event and clk = '1' then
            if rst = '1' then
                msd := "0000";
                lsd := "0000";
            elsif enable = '1' then
                if msd & lsd = target then 
                    msd := "0000";
                    lsd := "0000";
                elsif lsd = "1001" then
                    if msd = "1001" then
                        lsd := "0000";
                        msd := "0000";
                    else 
                        lsd := "0000";
                        msd := msd + "0001";
                    end if;
                else
                    lsd := lsd + "0001";
                end if;
            end if;
        end if;
        out_port <= std_logic_vector(msd & lsd);
    end process;
end architecture arch_bcd_counter;


-- c) Dekoder
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder is
    generic(n: natural);
    port(
        clk, rst, enable: in std_logic;
        in_port: in std_logic_vector(7 downto 0);
        out_port: out std_logic_vector(n - 1 downto 0);
    );
end entity decoder;
architecture arch_decoder of decoder is
begin
    decoding: process (clk) is
        variable val: natural;
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                out_port <= (others => '0');
            elsif enable = '1' then
                val := to_integer(unsigned(in_port));
                for i in out_port'range loop
                    out_port(i) <= '1' when i + 1 = val else '0';
                end loop;
            end if;
                out_port <= (others => '0');
        end if;
    end process;
end architecture arch_decoder;


-- control unit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

type arr_type: is array(natural range <>) of std_logic_vector(7 downto 0);

entity control_unit is
    generic(n: natural);
    port(
        clk, rst, enable: in std_logic;
        din: in std_logic_vector(7 downto 0);
        dout: out std_logic_vector(7 downto 0);
        dout_parallel: out arr_type(0 to n - 1);
    );
end entity control_unit;
architecture arch_control_unit of control_unit is
    signal cnt_val: std_logic_vector(7 downto 0);
    signal dec_val: std_logic_vector(n - 1 downto 0);
begin
    counter: entity work.bcd_counter(arch_bcd_counter)
    generic map(n)
    port map(clk, rst, enable, cnt_val);

    decoder: entity work.decoder(arch_decoder)
    generic map(n)
    port map(clk, rst, enable, cnt_val, dec_val);

    registers: for i in 0 to n - 1 generate
    begin
        reg: entity work.register(arch_register)
        port map(
            clk => clk,
            rst => rst,
            enable => dec_val(i),
            din => din,
            dout => dout_parallel(i)
        );
    end generate;

    dout <= cnt_val;
end architecture arch_control_unit;


--testbench
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

type arr_type: is array(natural range <>) of std_logic_vector(7 downto 0);

entity testbench is 
end entity testbench;
architecture arch_testbench of testbench is
    signal clk, rst, enable: std_logic;
    signal din: std_logic_vector(7 downto 0);
    signal dout: std_logic_vector(7 downto 0);
    signal dout_parallel: arr_type(0 to n - 1);
begin
    uut: entity work.control_unit(arch_control_unit)
    generic map(4)
    port map(clk, rst, enable, din, dout, dout_parallel);

    process 
        constant half_p: time := 2.5 ns;
    begin
        clk <= '1';
        wait for half_p
        clk <= '0';
        wait for half_p
    end process;

    process 
    begin
        rst <= '1';
        wait for 20 ns;

        rst <= '0';
        enable <= '1';
        din<="00000111";
        wait for 20 ns;

        din<="10011000";
        wait for 20 ns;

        din<="01110111";
        wait for 20 ns;

        din<="01010101";
        wait for 20 ns;
    end process;
end architecture arch_testbench;
