library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is 
    generic(n => natural := 4);
    port(
        clk, rst, enable: in std_logic;
        broj_a, broj_b: in std_logic_vector(n - 1 downto 0);
        operacija: in std_logic_vector(1 downto 0);
        result: out std_logic_vector(n - 1 downto 0)
    );
end entity alu;

architecture arch_alu of alu is
begin
    process(clk, rst) is 
        variable a, b, c: integer(0 to 2**n - 1);
    begin
        if rst '1' then -- asinhroni reset
            a := 0; b := 0; c: = 0;
        elsif clk'event and clk = '1' then
            if enable = '1' then
                a := to_integer(signed(broj_a));
                b := to_integer(signed(broj_b));
                case op is
                    when "00" => c := a + b;
                    when "01" => c := a - b;
                    when "10" => c := a * b;
                    when "11" => c := a / b;
                end case;
            end if;
        end if;
        result <= std_logic(to_signed(c, n));
    end process;
end architecture arch_alu;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
    generic(
        k: natural := 4,
        n: natural := 4 
    );
    port(
        clk, rst, enable: in std_logic;
        brojevi: in std_logic_vector(k * n - 1 downto 0);
        n_operacija: in std_logic_vector(2 * (k - 1) - 1 downto 0); -- (k - 1) operacija puta 2 bita za svaku operaciju i minus 1 zbog indeksiranja
        result: out std_logic_vector(n - 1 downto 0);
    );
end entity control_unit;

architecture arch_control_unit of control_unit is
    type op_array is array(k - 1 downto 0) of std_logic_vector(n - 1 downto 0);
    signal operands: op_array;
begin 
    operands(k - 1) <= operands(k * n - 1 downto k * (n - 1));

    generics: for i in k - 2 downto 0 generate
    alu: entity work.alu(arch_alu)
    generic map(n);
        port map(
            clk => clk,
            rst => rst,
            enable => enable,
            broj_a => operands(i + 1),
            broj_b => brojevi((i + 1) * n - 1 downto i * n),
            operacija => n_operacija(i * 2 + 1 downto i * 2)
        );
    end generate;
    resutl <= operandi(0);
end architecture arch_control_unit;

-- testbench
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
    generic(
        n: natural := 8;
        k: natural := 4
    );
end testbench;

architecture arch_testbench of testbench is
    signal clk, rst, enable: std_logic;
    signal brojevi: std_logic_vector(k * n - 1 downto 0);
    signal n_operacija: std_logic_vector(2 * (k - 1) - 1 downto 0);
    signal result: std_logic_vector(n - 1 downto 0);
begin
    unit: entity work.control_unit(arch_control_unit)
    generic map(k, n)
    port map(clk, rst, enable, brojevi n_operacija, result);

    process 
    begin
        clk <= '1';
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;
    end process;

    process
    begin 
        rst <= '1'
        wait for 30 ns;

        --izraz: (4 * 4 + 5) - 3
        rst <= '0'
        enable <= '1'
        brojevi <= "00000100000001000000010100000011";
        noperacija <= "100011";
        wait for 200ns;

        rst<='1';
        wait for 30ns;

        --izraz: 4 - 3 + 7 + 0
        rst<='0';
        enable<='1';
        brojevi<="00000100000000110000011100000000";
        noperacija<="010000";
        wait for 200ns;
    end process;
end architecture arch_testbench;

