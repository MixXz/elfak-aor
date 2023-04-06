-- a) kruzni brojac koji broji do 9
library ieee;
use ieee.logic_std_1164.all;
use ieee.numeric_std.all;

entity counter is 
    port(
        clk, rst, en: in std_logic;
        out_port: out std_logic_vector(3 downto 0)
    );
end entity counter;
architecture arch_counter of counter is
begin
    counting: process(clk) is
        variable cnt: std_logic_vector(3 downto 0);
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                cnt := (others => 0);
            elsif en = '1' then
                if cnt = "1001" then 
                    cnt := (others => 0);
                else
                    cnt := cnt + "1001";
                end if;
            end if;
        end if;
    out_port <= cnt;
    end process;
end architecture arch_counter;
    

-- b) BCD dekoder za 7-segmentni displej
library ieee;
use ieee.logic_std_1164.all;
use ieee.numeric_std.all;

entity decoder is
    port(
        zero: in std_logic
        in_port: in std_logic_vector(3 downto 0);
        out_port: out std_logic_vector(7 downto 0)
    );
end entity decoder;
architecture arch_decoder of decoder is
begin
    decoding: process(clk) is
    begin
        if zero = '1' then
            out_port <= "11111110";
        elsif zero = '0' then 
            out_port <= "00000000";
        else
            case in_port is
                when "0000" => out_port <= "1111110";
                when "0001" => out_port <= "0110000";
                when "0010" => out_port <= "1101101";
                when "0011" => out_port <= "1111001";
                when "0100" => out_port <= "0110011";
                when "0101" => out_port <= "1011011";
                when "0110" => out_port <= "1011111";
                when "0111" => out_port <= "1110000";
                when "1000" => out_port <= "1111111";
                when "1001" => out_port <= "1111011";
            end case;
        end if;
    end process;
end architecture arch_decoder;


-- control unit
library ieee;
use ieee.logic_std_1164.all;
use ieee.numeric_std.all;

type arr_type is array(natural range <>) of std_logic_vector(7 downto 0);

entity control_unit is
    generic(n: natural);
    port(
        clk, en, rst: in std_logic;
    );
end entity control_unit;
architecture arch_control_unit of control_unit is
    signal cnt_val: std_logic_vector(7 downto 0);
    signal dec_outputs: arr_type(0 to n - 1); -- nzm stvarno sta je hteo sa ovim zadatkom
begin
    counter: entity work.counter(arch_counter)
    port map(clk, rst, en, cnt_val);

    displays: for i in 0 to n - 1 generate
    begin
        display: entity work.decoder(arch_decoder)
        port map('Z', cnt_val, dec_outputs(i));
    end generate;
end architecture arch_control_unit;
