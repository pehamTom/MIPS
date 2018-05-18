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

architecture behav of alu is
 -------components-------------
 component adder
		port(a,b: in STD_LOGIC_VECTOR(31 downto 0);
			 cin: in STD_LOGIC;
			 y: out STD_LOGIC_VECTOR(31 downto 0)
			);
 end component;
 component mux4
    generic(width: integer);
    port(d0, d1, d2, d3:    in STD_LOGIC_VECTOR(width-1 downto 0);
         s:         in STD_LOGIC_VECTOR(1 downto 0);
         y:         out STD_LOGIC_VECTOR(width-1 downto 0));
 end component;
 component inverter
	generic(widht: integer);
	port(input: in STD_LOGIC_VECTOR(width-1 downto 0),
		 output: out STD_LOGIC_VECTOR(width-1 downto 0));
 end component;
 component mux2 generic(width: integer);
		port(d0, d1: in STD_LOGIC_VECTOR(width-1 downto 0);
			 s: 	 in STD_LOGIC;
			 y:		 out STD_LOGIC_VECTOR(width-1 downto 0));
 end component;
 component
	generic(width: integer);
	port(a: in STD_LOGIC_VECTOR(width-1 downto 0);
		 y: out STD_LOGIC
	    );
 end component;
 ----------singals-----------
 signal ADD_result: STD_LOGIC_VECTOR(31 downto 0);
 signal SLT_result: STD_LOGIC_VECTOR(31 downto 0);
 signal not_equal: STD_LOGIC;
 signal invers_b: STD_LOGIC_VECTOR(31 downto 0);
 signal adder_b: STD_LOGIC_VECTOR(31 downto 0);
	

begin 
	------------SUB-----------
	INVERTER: inverter generic map (width <= 32) port map(b,invers_b);
    MUX_SUB: mux2 generic map(width <= 32) port map(b,invers_b,alucontrol(2));
		
	------------SLT-----------
	OR_GATE: or_gate generic map(width <= 32) port map(ADD_result,not_equal);
	zero <= not not_equals;
	SLT_result(0) <= ADD_result(31) or (not not_equal);
	SLT_result(31 downto 1) <= (others => '0');
	
	------------ADD-----------
	ADDER_1: adder port map(a,adder_b,'0',ADD_result);
	

	

	--You can set the Values by switching the signals around
	--ADD alucontrol = 000
	--SUB alucontrol = 100 would be cool if this could stay like this because i might be able to only use a 4 mux and one adder.
	--SLT alucontrol = 101 this sets the adder to sub and the output to the segent on the 4mux
						
	MUX: mux4 generic map(width <= 32) port map(ADD_result,SLT_result,,,alucontrol(1 downto 0),result);


end;


