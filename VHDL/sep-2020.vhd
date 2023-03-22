library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- a) registar specijalne namene
entity spec_reg is
    port(
        clk, rst, enable: in std_logic;
        din: in integer(0 to 255);
        enable_next: out std_logic;
        dout, value_out: out integer(0 to 255)
    );
end entity spec_reg;

architecture arch_spec_reg of spec_reg is
begin
    reg: process(clk) is
        variable storage, tmp: integer(0 to 255);
    begin 
        if clk'event and clk = '1' then
            if rst = '1' then
                storage := 0;
                tmp := 0;
            elsif enable = '1' then
                if storage = 0 then
                    storage := din;
                    enable_next <= '0';
                elsif din > storage then
                    tmp := storage;
                    storage := din;
                    dout <= tmp;
                    enable_next <= '1';
                else 
                    dout <= din;
                    enable_next <= '1';
                end if;
            else
                enable_next <= '0';
            end if;
        end if;
        value_out <= storage;
    end process reg;
end architecture arch_spec_reg;

--------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- b) brojac navise;
entity counter is
    generic(gornja_granica: integer);
    port(
        clk, rst, en: in std_logic;
        overflow: out std_logic;
    );
end entity counter;

architecture arch_counter of counter is
begin
    counting: process(clk) is
        variable cnt: integer(0 to gornja_granica);
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                cnt := 0;
                overflow <= '0';
            elsif en = '1' then
                if cnt = gornja_granica then
                    overflow <= '1';
                else
                    cnt := cnt + 1;
                end if;
            end if;
        end if;
    end process counting;
end architecture arch_counter;

--------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

type int_array: is array(natural range <>) of integer(0 to 255);

-- unit
entity control_unit is
    generic(n: integer := 8)
    port(
        clk, rst, enable: in std_logic;
        din: in integer(0 to 255);
        dout: out integer(0 to 255);
        dout_parallel: out int_array(n - 1 downto 0)
    );
end entity control_unit;

architecture arch_control_unit of control_unit is
    signal connections: int_array(n - 1 downto 0);
    signal conn_next: std_logic_vector(n - 1 downto 0);
    signal overflow: std_logic;
begin
    connections(n - 1) <= din;
    dout_parallel(0) <= connections(0);

    counter: entity work.counter(arch_counter)
    generic map(gornja_granica => n)
    port map(
        clk => clk,
        rst => rst,
        en => enable,
        overflow => overflow
    );

    sort: for i in n - 2 downto 0 generate
    begin
        s_reg: entity work.spec_reg(arch_spec_reg)
        port map(
            clk => clk,
            rst => rst,
            enable => conn_next(i + 1),
            din => connections(i + 1),
            dout => connections(i),
            enable_next => conn_next(i),
            value_out => dout_parallel(i + 1)
        );
    end generate;
    
    main: process(clk, overflow) is
    begin
        if overflow = '1' then
            conn_next(n - 1) <= '0'
            dout <= din;
        else
            conn_next(n - 1) <= enable;
        end if;
    end process;
end architecture arch_control_unit;

--------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

type int_array: is array(natural range <>) of integer(0 to 255);

entity testbench is 
end entity testbench;
architecture arch_testbench of testbench is
    signal clk, rst, enable: std_logic;
    signal din, dout: integer(0 to 255);
    signal dout_parallel: int_array(7 downto 0);
begin
    c_unit: entity work.control_unit(arch_control_unit)
    begin
        port map(clk, rst, enable, din, dout, dout_parallel);
    
    process
    begin
        clk <= '1';
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;
    end process;

        process
        begin
            rst<='1';
            wait for 30 ns;
            rst<='0';
            enable<='1';
            din<=4;
            wait for 21ns;
            din<=8;
            wait for 21ns;
            din<=1;
            wait for 21ns;
            din<=23;
            wait for 21ns;
            din<=7;
            wait for 21ns;
            din<=5;
            wait for 21ns;
            din<=59;
            wait for 21ns;
            din<=9;
            wait for 21ns;
            din<=5;
            wait for 21ns;
            din<=59;
            wait for 21ns;
            din<=9;
            wait for 21ns;
        end process;
end architecture arch_testbench;