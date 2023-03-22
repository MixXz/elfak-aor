LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- a) pomeracki registar (u desno)
ENTITY pom_reg IS 
    GENERIC(n : integer := 8);
    PORT(
        din: IN std_logic_vector(n - 1 DOWNTO 0);
        dout: OUT std_logic_vector(n - 1 DOWNTO 0);
        clk, in_enable: IN std_logic
    );
END ENTITY pom_reg;

ARCHITECTURE arch_pom_reg OF pom_reg IS
    VARIABLE state: std_logic_vector(n - 1 DOWNTO 0);
BEGIN
    shift: PROCESS(clk) IS 
    BEGIN 
        IF clk'EVENT AND clk = '1' THEN
            IF in_enable = '1' THEN
                state := din;
            ELSE 
                dout <= state;
                state := '0' & state(n - 1 DOWNTO 1); -- shift right
            END IF;
        END IF;
    END PROCESS shift;
END ARCHITECTURE arch_pom_reg;

------------------------------------------------------ 
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- b) kruzni brojac;
ENTITY counter IS
    GENERIC(n: integer := 4);
    PORT(
        clk, reset: IN std_logic;
        count: OUT std_logic_vector(n - 1 DOWNTO 0)
    );
END ENTITY counter;

ARCHITECTURE arch_counter OF counter IS
BEGIN
    counting: PROCESS IS(clk, reset) IS
        VARIABLE cnt: integer RANGE 0 TO 2**n - 1;
        BEGIN
            IF rst = '1' THEN
                cnt := 0;
            elsIF clk'EVENT AND clk = '1' THEN
                IF cnt = 2**n - 1 THEN 
                    cnt := 0;
                ELSE 
                    cnt := cnt + 1;
                END IF;
            END IF;
            count <= std_logic_vector(to_unsigned(cnt, n));
        END PROCESS;
END ARCHITECTURE arch_counter;
    
------------------------------------------------------ 
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- Kolo
ENTITY unit IS
    GENERIC(
        generic_pattern: std_logic_vector(1 DOWNTO 0);
        n: integer := 4;
    );
    PORT(
        clk, start: IN std_logic;
        data: OUT std_logic_vector(31 DOWNTO 0);
        ready: OUT std_logic;
        count: OUT std_logic_vector(n - 1 DOWNTO 0)
    );
END ENTITY unit;

ARCHITECTURE arch_unit OF unit IS
    SIGNAL pom_reg_output: std_logic_vector(31 DOWNTO 0);
    SIGNAL is_match, reset_counter: std_logic;
BEGIN
    pom_reg: ENTITY WORK.pom_reg(arch_pom_reg)
    GENERIC MAP(n => 32)
    PORT MAP(
        clk => clk,
        in_enable => start -- uzima si sam podatke kad je start na 1
        din => data,
        dout => pom_reg_output
    );

    counter: ENTITY WORK.counter(arch_counter)
    GENERIC MAP(n => 4)
    PORT MAP(
        clk => is_match, -- da bi brojao samo kad imamo pogodak!
        reset => reset_counter,
        count => count
    );

    main: PROCESS IS
        VARIABLE pattern: std_logic_vector(31 DOWNTO 0);
        VARIABLE mask: std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
    BEGIN 
        WAIT UNTIL start = '1';

        ready <= '0';
        pattern(1 DOWNTO 0) := generic_pattern;
        mask(1 DOWNTO 0) := "11";
        count <= (OTHERS => '0');
        reset_counter <= '1';

        WAIT UNTIL clk'EVENT AND clk = '1'
        
        FOR i IN 0 TO 31 LOOP
            IF (pom_reg_output AND mask) = pattern THEN
                is_match <= '1';
            ELSE
                is_match <= '0';
            END IF;
            -- Nema logike da se shiftuje i pattern i podaci? sta dobijamo time?
            WAIT UNTIL clk'EVENT AND clk = '1';
        END LOOP;

        ready <= '1'; -- na count izlazu komponente se vec nalaze podaci koje je tamo smestio sam counter

    END PROCESS main;
END ARCHITECTURE arch_unit;




