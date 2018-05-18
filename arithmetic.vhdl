-- full adder
library IEEE; use IEEE.STD_LOGIC_1164.all;
entity FA is
  port(a,b,cin: in STD_LOGIC;
       cout,s: out STD_LOGIC);
end;

architecture behav of FA is
begin
  cout <= (a AND b) OR (a AND cin) OR (b AND cin);
  s <= a XOR b XOR cin;
end;

-- 32 bit carry-ripple adder
library IEEE; use IEEE.STD_LOGIC_1164.all;
entity adder is
    port(a, b: in STD_LOGIC_VECTOR(31 downto 0);
         cin: in STD_LOGIC;
         y:    buffer STD_LOGIC_VECTOR(31 downto 0));
end;

architecture behav of adder is
  component FA 
    port(a,b,cin: in STD_LOGIC;
         cout, s: out STD_LOGIC);
  end component;
  signal c: STD_LOGIC_VECTOR(31 downto 0) := X"00000000";
begin
  fa0: FA port map(a(0), b(0), cin, c(0), y(0));
  FA_GEN:
  for I in 1 to 31 generate
    FA_I : FA port map(a(I), b(I), c(I-1), c(I), y(I));
  end generate FA_GEN;
end;

-- Shift Right Arithmetic (SRA)
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all;
entity shift_right_arithmetic is
	port(a: in STD_LOGIC_VECTOR(31 downto 0);
		 b: in STD_LOGIC_VECTOR(4 downto 0);
		 y: out STD_LOGIC_VECTOR(31 downto 0));
end;

architecture behav of shift_right is 
begin
	y <= std_logic_vector(signed(a) sra to_integer(unsigned(b)));
end;


-- Arithmetic Logic Unit (ALU)
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all;
entity alu is
    port(a, b:          in STD_LOGIC_VECTOR(31 downto 0);
         alucontrol:    in STD_LOGIC_VECTOR(2 downto 0);
         result:        buffer STD_LOGIC_VECTOR(31 downto 0);
         zero:          out STD_LOGIC);
end;

-- TODO: Implement ALU
-- Hint: VHDL 2008 supports reduction operators. For example, assume that the signal "a" is a 32 bit vector. Then, the expression "y <= OR a" code assigns "y" to a(0) OR a(1) OR ... a(31).



