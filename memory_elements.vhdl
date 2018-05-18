-- filp-flop
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all;
entity ff is
    generic(width: integer);
    port(clk, reset: in STD_LOGIC;
         d:          in STD_LOGIC_VECTOR(width-1 downto 0);
         q:          out STD_LOGIC_VECTOR(width-1 downto 0));
end;

architecture asynchronous of ff is
begin
    process(clk, reset)
    begin
        if reset = '1' then q <= (others => '0');
        elsif clk'event and clk='1' then
            q <= d;
        end if;
    end process;
end;


-- register file
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all;
entity regfile is
    port(clk:           in STD_LOGIC;
         we3:           in STD_LOGIC;
         ra1, ra2, wa3: in STD_LOGIC_VECTOR(4 downto 0);
         wd3:           in STD_LOGIC_VECTOR(31 downto 0);
         rd1, rd2:      out STD_LOGIC_VECTOR(31 downto 0));
end;

architecture behav of regfile is
    type ramtype is array(31 downto 0) of STD_LOGIC_VECTOR(31 downto 0);
    signal mem: ramtype := ((29 => X"00000200", others => (others=>'0')));
begin
    -- three-ported register file
    -- read two ports combinationally
    -- write third port on rising clock edge

    process(clk) begin
        if clk'event and clk='1' then
            if we3 = '1' then mem(to_integer(unsigned(wa3))) <= wd3;
            end if;  

        end if;
    end process;
    process(ra1, ra2) begin
        if ra1 = "00000" then rd1 <= X"00000000"; -- register 0 holds 0
        else rd1 <= mem(to_integer(unsigned(ra1)));
        end if;
        if ra2 = "00000" then rd2 <= X"00000000"; -- register 0 holds 0
        else rd2 <= mem(to_integer(unsigned(ra2)));
        end if;
    end process;
end;

-- data memory
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all; use STD.TEXTIO.all;
entity dmem is
    port(clk, we: in STD_LOGIC;
         a, wd:   in STD_LOGIC_VECTOR(31 downto 0);
         rd:      out STD_LOGIC_VECTOR(31 downto 0));
end;

architecture behave of dmem is
begin
    process is
        type ramtype is array(127 downto 64) of STD_LOGIC_VECTOR(31 downto 0);
        variable mem: ramtype := ((others=> (others=>'0')));
		file mem_file: TEXT;
        variable L: line;
        variable ch: character;
        variable index, char_hex: integer;
		variable result: STD_LOGIC_VECTOR(31 downto 0);
    begin
        index := 64;
        FILE_OPEN(mem_file, "dmem.dat", READ_MODE);
        while not endfile(mem_file) loop
            readline(mem_file, L);
            for i in 1 to 8 loop
                read(L, ch);
                if '0' <= ch and ch <= '9' then
                    char_hex := character'pos(ch) - character'pos('0');
                elsif 'a' <= ch and ch <= 'f' then
                    char_hex := character'pos(ch) - character'pos('a') + 10;
                elsif 'A' <= ch and ch <= 'F' then
                    char_hex := character'pos(ch) - character'pos('A') + 10;
                else report "Format error on line " & integer'image(index) severity error;
                end if;
				result((9-i)*4-1 downto (8-i)*4) := std_logic_vector(to_unsigned(char_hex, 4));
            end loop;
            mem(index) := result;
            index := index + 1;
        end loop;

        loop
            if clk'event and clk = '1' then 
                if we = '1' then mem(to_integer(unsigned(a(8 downto 2)))) := wd;
                end if;
            end if;
			if (to_integer(unsigned(a(8 downto 2))) >= 64) and (to_integer(unsigned(a(8 downto 2))) <= 127) then
	            rd <= mem(to_integer(unsigned(a(8 downto 2))));
			else 
	            rd <= X"00000000";
			end if;
            wait on clk, a;
        end loop;
    end process;
end;


-- instruction memory
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all; use STD.TEXTIO.all;
entity imem is
    port(a:  in STD_LOGIC_VECTOR(31 downto 0);
         rd: out STD_LOGIC_VECTOR(31 downto 0));
end;

architecture behave of imem is
begin
    process is
        file mem_file: TEXT;
        variable L: line;
        variable ch: character;
        variable index, char_hex: integer;
		variable result: STD_LOGIC_VECTOR(31 downto 0);
        type ramtype is array(63 downto 0) of STD_LOGIC_VECTOR(31 downto 0);
        variable mem: ramtype := ((others=> (others=>'0')));
    begin
        -- initialize memory from file
        index := 0;
        FILE_OPEN(mem_file, "imem.dat", READ_MODE);
        while not endfile(mem_file) loop
            readline(mem_file, L);
            for i in 1 to 8 loop
                read(L, ch);
                if '0' <= ch and ch <= '9' then
                    char_hex := character'pos(ch) - character'pos('0');
                elsif 'a' <= ch and ch <= 'f' then
                    char_hex := character'pos(ch) - character'pos('a') + 10;
                elsif 'A' <= ch and ch <= 'F' then
                    char_hex := character'pos(ch) - character'pos('A') + 10;
                else report "Format error on line " & integer'image(index) severity error;
                end if;
				result((9-i)*4-1 downto (8-i)*4) := std_logic_vector(to_unsigned(char_hex, 4));
            end loop;
            mem(index) := result;
            index := index + 1;
        end loop;

        loop
            rd <= mem(to_integer(unsigned(a(7 downto 2))));
            wait on a;
        end loop;
    end process;
end;

