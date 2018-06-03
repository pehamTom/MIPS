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
         branchandzero, alusrc: out STD_LOGIC;
         regdst, regwrite:      out STD_LOGIC;
         lb:                    out STD_LOGIC;
         storepc:               out STD_LOGIC;
         jump:		                out STD_LOGIC_VECTOR(1 downto 0);
         alucontrol:            out STD_LOGIC_VECTOR(2 downto 0));
    end component;
    component datapath
    port(clk, reset:        in STD_LOGIC;
         memtoreg, branchandzero:   in STD_LOGIC;
         alusrc, regdst:    in STD_LOGIC;
         regwrite:    		in STD_LOGIC;
		 jump: 				in STD_LOGIC_VECTOR(1 downto 0);
         memwrite:          in STD_LOGIC;
		 storePc:			in STD_LOGIC;
		 loadByte: 			in STD_LOGIC;
         alucontrol:        in STD_LOGIC_VECTOR(2 downto 0);
         zero:              out STD_LOGIC;
         instr:             out STD_LOGIC_VECTOR(31 downto 0));
       
    end component;
    signal memtoreg, memwrite, branchandzero, alusrc, regdst, regwrite, zero, loadByte, storepc: STD_LOGIC := '0';
	signal jump: STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal alucontrol: STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal instr: STD_LOGIC_VECTOR(31 downto 0);
begin
    cont: controller port map(instr(31 downto 26), instr(5 downto 0), zero, memtoreg, memwrite, branchandzero, alusrc, regdst, regwrite, loadByte, storepc, jump, alucontrol);
    dp: datapath port map(clk, reset, memtoreg, branchandzero, alusrc, regdst, regwrite, jump, memwrite, storePc, loadByte, alucontrol, zero, instr);
end;

-- Controller
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all;
entity controller is
    port(op, funct:             in STD_LOGIC_VECTOR(5 downto 0);
         zero:                  in STD_LOGIC;
         memtoreg, memwrite:    out STD_LOGIC;
         branchandzero, alusrc: out STD_LOGIC;
         regdst, regwrite:      out STD_LOGIC;
         lb:                    out STD_LOGIC;
         storepc:               out STD_LOGIC;
         jump:		                out STD_LOGIC_VECTOR(1 downto 0);
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
                    when "100000" => controls <= "110000-000010"; -- ADD
                    when "100010" => controls <= "110000-000110"; -- SUB
                    when "100100" => controls <= "110000-000-00"; -- AND
                    when "100101" => controls <= "110000-000-01"; -- OR
                    when "101010" => controls <= "110000-000111"; -- SLT
                    when "001000" => controls <= "0---0---10---"; -- JR
					          when "000011" => controls <= "11-000-000011"; -- SRA
                    when others   => controls <= "----------";
                end case;
            when "100011" => controls <= "1010100000010"; -- LW
            when "101011" => controls <= "0-101---00010"; -- SW
            when "000100" => controls <= "0-110--000110"; -- BEQ
            when "001000" => controls <= "101000-000010"; -- ADDI
            when "000010" => controls <= "0---0---01---"; -- J
            when "000011" => controls <= "1---0--101---"; -- JAL
            when "100000" => controls <= "1010011000010"; -- LB
            when others   => controls <= "----------"; -- illegal op
        end case;
    end process;

    regwrite     <= controls(12);
    regdst       <= controls(11);
    alusrc       <= controls(10);
    branch       <= controls(9);
    memwrite     <= controls(8);
    memtoreg     <= controls(7);
    lb           <= controls(6);
    storepc      <= controls(5);
    jump         <= controls(4 downto 3);
    alucontrol   <= controls(2 downto 0);

    branchandzero <= branch and zero;
end;


-- datapath
library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.NUMERIC_STD.all;
entity datapath is
    port(clk, reset:        in STD_LOGIC;
         memtoreg, branchandzero:   in STD_LOGIC;
         alusrc, regdst:    in STD_LOGIC;
         regwrite:    		in STD_LOGIC;
		 jump: 				in STD_LOGIC_VECTOR(1 downto 0);
         memwrite:          in STD_LOGIC;
		 storePc:			in STD_LOGIC;
		 loadByte: 			in STD_LOGIC;
         alucontrol:        in STD_LOGIC_VECTOR(2 downto 0);
         zero:              out STD_LOGIC;
         instr:             out STD_LOGIC_VECTOR(31 downto 0));
end;


-- TODO: Implement datapath of the MIPS processor
-- Important: the instance of the component regfile must be named rf. Otherwise, the testbench cannot read out the final results.

architecture behav of datapath is
 -------components-------------
 component adder
		port(a,b: in STD_LOGIC_VECTOR(31 downto 0);
			 cin: in STD_LOGIC;
			 y: out STD_LOGIC_VECTOR(31 downto 0)
			);
 end component;
 component mux2
	 generic(width: integer);
		port(d0, d1: in STD_LOGIC_VECTOR(width-1 downto 0);
			 s: 	 in STD_LOGIC;
			 y:		 out STD_LOGIC_VECTOR(width-1 downto 0));
 end component;
 component controller
         port(op, funct:             in STD_LOGIC_VECTOR(5 downto 0);
              zero:                  in STD_LOGIC;
              memtoreg, memwrite:    out STD_LOGIC;
              branchandzero, alusrc:         out STD_LOGIC;
              regdst, regwrite:      out STD_LOGIC;
              jump:                  out STD_LOGIC;
              alucontrol:            out STD_LOGIC_VECTOR(2 downto 0));
 end component;
 component alu
 	port(a, b:          in STD_LOGIC_VECTOR(31 downto 0);
		 shamt: 		in STD_LOGIC_VECTOR(4 downto 0);
         alucontrol:    in STD_LOGIC_VECTOR(2 downto 0);
         result:        buffer STD_LOGIC_VECTOR(31 downto 0);
         zero:          out STD_LOGIC);
 end component;
 component rf 
 	port(clk:           in STD_LOGIC;
          we3:           in STD_LOGIC;
          ra1, ra2, wa3: in STD_LOGIC_VECTOR(4 downto 0);
          wd3:           in STD_LOGIC_VECTOR(31 downto 0);
          rd1, rd2:      out STD_LOGIC_VECTOR(31 downto 0));
 end component;
 component dmem
 	port(clk, we: in STD_LOGIC;
          a, wd:   in STD_LOGIC_VECTOR(31 downto 0);
          rd:      out STD_LOGIC_VECTOR(31 downto 0));
 end component;
 component imem
 	port(a:  in STD_LOGIC_VECTOR(31 downto 0);
          rd: out STD_LOGIC_VECTOR(31 downto 0));
 end component;
 component sl2 
 	port(a: in STD_LOGIC_VECTOR(31 downto 0);
          y: out STD_LOGIC_VECTOR(31 downto 0));
 end component;
 component signext
 	port(a: in STD_LOGIC_VECTOR(width_in-1  downto 0);
          y: out STD_LOGIC_VECTOR(width_out-1 downto 0));
 end component;
 component ff
 	port(clk, reset: in STD_LOGIC;
          d:          in STD_LOGIC_VECTOR(width-1 downto 0);
          q:          out STD_LOGIC_VECTOR(width-1 downto 0));
 end component;
 component mux4 
     generic(width: integer);
     port(d0, d1, d2, d3:    in STD_LOGIC_VECTOR(width-1 downto 0);
          s:         in STD_LOGIC_VECTOR(1 downto 0);
          y:         out STD_LOGIC_VECTOR(width-1 downto 0));
 end component; 
 
 signal Op, Funct : std_logic_vector (5 downto 0);
 signal MemToReg, MemWrite, Branch, BranchAndZero std_logic;
 signal InstrInternal, PC, Immediate, ImmediateShifted, WD3, BranchAddress, BranchAddressA, BranchAddressB, JumpAddress, Result, ALUResult, ReadData, WriteData, NextAddress, SrcA, SrcB, MuxBranch_out, MuxJump_out, MuxStorePc_out, MuxStorePcAddress_out, JumpAddressCombined, ExtendedLoadedByte, WordOrByte: std_logic_vector (31 downto 0);
 signal RF_A1, RF_A2, DestinationReg, DestinationReg1, DestinationReg0, Shamt: std_logic_vector(4 downto 0); 
 signal IMM : std_logic_vector (15 downto 0);
 signal JumpAddress, JumpAddressUnshifted : std_logic_vector (25 downto 0);
 signal LoadedByte : std_logic_vector (7 downto 0);
 
 
 PC_FF: ff PORT MAP (clk, reset, mux2_out, PC)
 
 IMem: imem PORT MAP (PC, InstrInternal)
 
 instr <= InstrInternal;
 
 
 
 Op <= InstrInternal(31 downto 26);
 Funct <= InstrInternal(5 downto 0);
 DestinationReg0 <= InstrInternal(20 downto 16);
 DestinationReg1 <= InstrInternal(15 downto 11);
 RF_A1 <= InstrInternal(25 downto 21);
 RF_A2 <= InstrInternal(20 downto 16);
 IMM <= InstrInternal(15 downto 0);
 JumpAddressUnshifted <= InstrInternal(25 downto 0);
 Shamt <= InstrInternal (10 downto 6);
 
 RegisterFile: rf PORT MAP (clk, regwrite, RF_A1, RF_A2, DestinationReg, Result, SrcA, WriteData)
 MUX_SrcB: mux2 GENERIC MAP (width => 32) PORT MAP (WriteData, Immediate, alusrc, SrcB)
 ALU: alu PORT MAP (SrcA, SrcB, Shamt, alucontrol, ALUResult, zero)
 MUX_Destination: mux2 GENERIC MAP (width => 5) PORT MAP (DestinationReg0, DestinationReg1, regdst, DestinationReg)
 DataMemory: dmem PORT MAP (clk, memwrite, AluResult, WriteData, ReadData)
 ImmediateSignExt: signext GENERIC MAP (width_in => 16, width_out => 32) PORT MAP (IMM, Immediate)
 ImmediateShift: sl2 PORT MAP (Immediate, ImmediateShifted)
 BranchAddressAdder: adder PORT MAP (ImmediateShifted, NextAddress, '0', BranchAddress)
 NextAddress: adder PORT MAP (PC, "0000000000000000000000000000100", '0', NextAddress)
 JumpAddressShift: sl2 PORT MAP (instr, JumpAddress)
 
 JumpAddressCombined <= NextAddress(31 downto 28) & JumpAddress(27 downto 0);
 
 MUX_Branch: mux2 GENERIC MAP (width => 32) PORT MAP (NextAddress, BranchAddress, BranchAndZero, MuxBranch_out)
 MUX_Jump: mux4 GENERIC MAP (width => 32) PORT MAP (Mux1_out, JumpAddressCombined, SrcA, open, jump, MuxJump_out)
 MUX_StorePC: mux2 GENERIC MAP (width => 32) PORT MAP (Result, NextAddress, storePc, MuxStorePc_out)
 MUX_StorePCAddress: mux2 GENERIC MAP (width => 32) PORT MAP (DestinationReg, "0000 0000 0000 0000 0000 0000 0011 1111", storePc, MuxStorePcAddress_out)
 MUX_LoadByte: mux2 GENERIC MAP (width => 32) PORT MAP (ReadData, ExtendedLoadedByte, loadByte, WordOrByte)
 MUX_ByteIndex: mux4 GENERIC MAP (width => 8) PORT MAP(ReadData(7 downto 0), ReadData(15 downto 8), ReadData(23 downto 16), ReadData(31 downto 24), ALUResult(1 downto 0, LoadedByte)
 SignExtend_ByteIndex: signext GENERIC MAP (width_in => 8, width_out => 32) PORT MAP (LoadedByte, ExtendedLoadedByte)
 MUX_Result: mux2 GENERIC MAP (width => 32) PORT MAP (ALUResult, WordOrByte, memtoreg, Result)
 
 
end; 


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
