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

architecture behav of shift_right_arithmetic is
begin
	y <= std_logic_vector(shift_right(unsigned(a),to_integer(unsigned(b))));
end;


-- Arithmetic Logic Unit (ALU)
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all;
entity alu is
    port(a, b:          in STD_LOGIC_VECTOR(31 downto 0); --operands
		 shamt:			in STD_LOGIC_VECTOR(4 downto 0);  --amount to shift b by when SRA instruction is used
		 alucontrol:    in STD_LOGIC_VECTOR(2 downto 0);  --controlls which operation the ALU should perform 
         result:        buffer STD_LOGIC_VECTOR(31 downto 0); --result of the operation
		 zero:          out STD_LOGIC);					  --zero is set in the case that a SUB operation
														  --results in 0
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

 component mux2
	 generic(width: integer);
		port(d0, d1: in STD_LOGIC_VECTOR(width-1 downto 0);
			 s: 	 in STD_LOGIC;
			 y:		 out STD_LOGIC_VECTOR(width-1 downto 0));
 end component;

--this or gate will take width inputs and has 1 output.
 component or_gate
	generic(width: integer);
	port(a: in STD_LOGIC_VECTOR(width-1 downto 0);
		 y: out STD_LOGIC
	    );
 end component;

 component shift_right_arithmetic
	port(a: in STD_LOGIC_VECTOR(31 downto 0);
		 b: in STD_LOGIC_VECTOR(4 downto 0);
		 y: out STD_LOGIC_VECTOR(31 downto 0));
 end component;


 ----------signals-----------
 signal ADD_result: STD_LOGIC_VECTOR(31 downto 0);		
 signal SLT_result: STD_LOGIC_VECTOR(31 downto 0);		
 signal not_equal: STD_LOGIC;							
 signal adder_b: STD_LOGIC_VECTOR(31 downto 0);			--adder_b either B or the invers of B depending		
														--alucontrol(2). Output of MUX_SUB. 
 signal SRA_result: STD_LOGIC_VECTOR(31 downto 0);		--result of the shift_right_arithmetic component
 signal AND_result: STD_LOGIC_VECTOR(31 downto 0);	
 signal OR_result: STD_LOGIC_VECTOR(31 downto 0);
 signal temp_SLT_SRA: STD_LOGIC_VECTOR(31 downto 0);	--signal contains SLT_result if alucontrol(2) is 1 
														--and SRA_result if alucontrol(2) is 0. Connected to
														--the result output of the ALU when alucontrol(1 downto 0) is 11
begin
	------------SUB-----------
	--MUX_SUB is used to select between the subtracting and adding by sending the b or the inverted
	--b signal to the adder
	MUX_SUB: mux2 generic map(width => 32) 
				  port map(b,not b,alucontrol(2),adder_b);

	------------SLT-----------
	--To implement the SLT operation we use the adder in sub mode -> alucontrol(2) = 1
	--When a is smaller then b the sign bit will be set. The sign bit is connectet to the LSB of the 
	--SLT_Result and all other bits of the SLT_Result are set to 0. 
	SLT_result(0) <= ADD_result(31);
	SLT_result(31 downto 1) <= (others => '0');
	
	--A = B if the result of a SUB instruction is 0. a0 or a1 or .... or a31 ist 0 wenn A = B
	OR_GATE: or_gate generic map(width => 32) port map (ADD_result,not_equal);
	zero <= not not_equal;
	
	------------ADD-----------
	--ADDER_1 is used for add, sub and slt operation
	ADDER_1: adder port map(a,adder_b,alucontrol(2),ADD_result);

	------------SRA-----------
	SHIFTER: shift_right_arithmetic port map(b,shamt,SRA_result);

	--When alucontrol(1 downto 0) is 11, alucontrol(2) will be used to select between SLT and SRA
	MUX_SHIFT_SLT: mux2 generic map(width => 32) port map(SRA_result,
														  SLT_result,
														  alucontrol(2),temp_SLT_SRA);
	-----------AND OR-----------
	AND_result <= a and adder_b;
	OR_result <= a or adder_b;

	--You can set the Values by switching the signals around
	
	--AND alucontrol = 000
	--OR alucontrol	 = 001
	--ADD alucontrol = 010
	--SRA alucontrol = 011
	--SUB alucontrol = 110
	--SLT alucontrol = 111

	MUX: mux4	generic map(width => 32) 
				port map(AND_result,	-- 00 a and b
						 OR_result,		-- 01 a or b
						 ADD_result,	-- 10 adder output. Either a + b or a - b.
						 temp_SLT_SRA,	-- 11 SLT_result if alucontrol(2) is 1 and
										--	  SRA_result if alucontrol(2) is 0.
						 alucontrol(1 downto 0),result);
end;
