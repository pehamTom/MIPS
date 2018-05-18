-- MIPS processor
library IEEE; use IEEE.STD_LOGIC_1164.all;
entity mips is 
    port(clk, reset:        in STD_LOGIC);
end;

architecture struct of mips is
    component controller
        port(op, funct:             in STD_LOGIC_VECTOR(5 downto 0);
             zero:                  in STD_LOGIC;
             memtoreg, memwrite:    out STD_LOGIC;
             branchandzero, alusrc:         out STD_LOGIC;
             regdst, regwrite:      out STD_LOGIC;
             jump:                  out STD_LOGIC;
             alucontrol:            out STD_LOGIC_VECTOR(2 downto 0));
    end component;
    component datapath
        port(clk, reset:        in STD_LOGIC;
             memtoreg, branchandzero:   in STD_LOGIC;
             alusrc, regdst:    in STD_LOGIC;
             regwrite, jump:    in STD_LOGIC;
             memwrite:          in STD_LOGIC;
             alucontrol:        in STD_LOGIC_VECTOR(2 downto 0);
             zero:              out STD_LOGIC;
             instr:             out STD_LOGIC_VECTOR(31 downto 0));
    end component;
    signal memtoreg, memwrite, branchandzero, alusrc, regdst, regwrite, jump, zero: STD_LOGIC := '0';
    signal alucontrol: STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal instr: STD_LOGIC_VECTOR(31 downto 0);
begin
    cont: controller port map(instr(31 downto 26), instr(5 downto 0), zero, memtoreg, memwrite, branchandzero, alusrc, regdst, regwrite, jump, alucontrol);
    dp: datapath port map(clk, reset, memtoreg, branchandzero, alusrc, regdst, regwrite, jump, memwrite, alucontrol, zero, instr);
end;

-- Controller
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all;
entity controller is
    port(op, funct:             in STD_LOGIC_VECTOR(5 downto 0);
         zero:                  in STD_LOGIC;
         memtoreg, memwrite:    out STD_LOGIC;
         branchandzero, alusrc: out STD_LOGIC;
         regdst, regwrite:      out STD_LOGIC;
         jump		            out STD_LOGIC;
         alucontrol:            out STD_LOGIC_VECTOR(2 downto 0));
end;

architecture struct of controller is
    signal branch:  STD_LOGIC := '0';
    signal controls: STD_LOGIC_VECTOR(9 downto 0) := "0000000000";
begin    
    process(op, funct) begin
		-- TODO: Set controll signals accordingly. Use - to denote don't cares and 0 or 1 if the value is fixed.
        case op is
            when "000000" => -- R-Type
                case funct is
                    when "100000" => controls <= "----------"; -- ADD
                    when "100010" => controls <= "----------"; -- SUB
                    when "100100" => controls <= "----------"; -- AND
                    when "100101" => controls <= "----------"; -- OR
                    when "101010" => controls <= "----------"; -- SLT
                    when "001000" => controls <= "----------"; -- JR
					when "000011" => controls <= "----------"; -- SRA
                    when others   => controls <= "----------";
                end case;
            when "100011" => controls <= "----------"; -- LW
            when "101011" => controls <= "----------"; -- SW
            when "000100" => controls <= "----------"; -- BEQ
            when "001000" => controls <= "----------"; -- ADDI
            when "000010" => controls <= "----------"; -- J
            when "000011" => controls <= "----------"; -- JAL
            when "100000" => controls <= "----------"; -- LB
            when others   => controls <= "----------"; -- illegal op
        end case;
    end process;

    regwrite     <= controls(9);
    regdst       <= controls(8);
    alusrc       <= controls(7);
    branch       <= controls(6);
    memwrite     <= controls(5);
    memtoreg     <= controls(4);
    jump         <= controls(3);
    alucontrol   <= controls(2 downto 0);

    branchandzero <= branch and zero;
end;

-- datapath
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all;
entity datapath is
    port(clk, reset:        in STD_LOGIC;
         memtoreg, branchandzero:   in STD_LOGIC;
         alusrc, regdst:    in STD_LOGIC;
         regwrite, jump:    in STD_LOGIC;
         memwrite:          in STD_LOGIC;
         alucontrol:        in STD_LOGIC_VECTOR(2 downto 0);
         zero:              out STD_LOGIC;
         instr:             out STD_LOGIC_VECTOR(31 downto 0));
end;


-- TODO: Implement datapath of the MIPS processor
-- Important: the instance of the component regfile must be named rf. Otherwise, the testbench cannot read out the final results.





-- testbench
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all; use STD.ENV.STOP;
entity testbench is
end;

architecture test of testbench is
    component mips
        port(clk, reset: in STD_LOGIC);
    end component;
    signal clk, reset:    STD_LOGIC := '0';
    type ramtype is array(31 downto 0) of STD_LOGIC_VECTOR(31 downto 0);
begin
    -- initiate device to be tested
    dut: mips port map(clk, reset);

    -- generate clock with 10 ns period
    process begin
		for i in  1 to 200 loop 
	        clk <= '1';	
	        wait for 5 ps;
	        clk <= '0';
    	    wait for 5 ps;
		end loop;
		report "Simulation ran into timeout of 1000 clock cycles" severity error;
		wait;
    end process;

    -- generate reset
    process begin
        reset <= '1';
        wait for 22 ps;
        reset <= '0';
        wait;
    end process;

    process(clk) is
        variable mem: ramtype;
        variable sig1,sig2,sig3: integer;
        variable pc: integer;
        variable instr: STD_LOGIC_VECTOR(31 downto 0);
    begin
        if (clk'event and clk='0') then
			instr := <<signal dut.instr : STD_LOGIC_VECTOR(31 downto 0)>>;
            if(instr = x"0000000c") then
                mem := (<<signal dut.dp.rf.mem : ramtype>>);
                sig1 := to_integer(signed(mem(16)));
				sig2 := to_integer(signed(mem(17)));
				sig3 := to_integer(signed(mem(18)));
				report "Program terminated --- Results are:" & lf & "            Length of string 'acghoptuz' is " & integer'image(sig1) & lf & "            Index of 'p' in string is " & integer'image(sig2) & lf & "            Index of 'f' in string is " & integer'image(sig3);
                stop;
            end if;
        end if;
    end process;
end;
