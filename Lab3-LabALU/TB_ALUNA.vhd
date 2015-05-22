
----------------------------------------------------------------------
--Student example of ALUNA test with text output instead of wave output.
--At the start, we add a little piece to do the wave window delay test so  
--  we can use the same test bench for everything.
--This TB needs to run for at least 2000ns to complete the example.
--Yours may need to run longer.
----------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use std.textio.all;

ENTITY TB_ALUNA_vhd IS
END TB_ALUNA_vhd;

ARCHITECTURE behavior OF TB_ALUNA_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT ALUNA
	generic(NBITS: natural);
	PORT(
		ALU_A : IN std_logic_vector(15 downto 0);
		ALU_B : IN std_logic_vector(15 downto 0);
		mode : IN std_logic_vector(2 downto 0);          
		ALU_out : OUT std_logic_vector(15 downto 0);
		ALU_ovfl : OUT std_logic
		);
	END COMPONENT;
	--Inputs
	SIGNAL ALU_A :  std_logic_vector(15 downto 0) := (others=>'0');
	SIGNAL ALU_B :  std_logic_vector(15 downto 0) := (others=>'0');
	SIGNAL mode :  std_logic_vector(2 downto 0) := (others=>'0');
	--Outputs
	SIGNAL ALU_out :  std_logic_vector(15 downto 0);
	SIGNAL ALU_ovfl :  std_logic;

	--The following A,B pairs do not constitute a thoughtful test; they are just an example.
	--You will have to design a better test
	type INT_VECTOR is array(0 to 1) of integer; --we create a user defined signal type
	constant AVALS: INT_VECTOR:=(125,0000); --we create two constant vectors of this type
	constant BVALS: INT_VECTOR:=(074,0000);	--to definfe the pairs of ALU inputs.
	----------------
	--32767,-32768,05,125,0000
	--00001,-00001,-3,074,0000
	--define a file for results. text is a file type in textio library.
	file output: text open WRITE_MODE is "ALU_TEST.txt";
BEGIN
	-- Instantiate the Unit Under Test (UUT)
	uut: ALUNA 
	generic map(NBITS=>16)
	PORT MAP(
		ALU_A => ALU_A,
		ALU_B => ALU_B,
		MODE => MODE,
		ALU_out => ALU_out,
		ALU_ovfl => ALU_ovfl
		);

tb : PROCESS	--we control the timing of signal assignments thru a series of waits.
	variable J: integer:=0;
	variable K: integer:=0;	--start at 0 for circuit delay test
	variable buf: LINE;
	
	BEGIN
	-- Wait 100 ns for global reset to finish
	wait for 100 ns;
	------------------------------------
----this part of the process can be skipped for the functional test	
--if K = 0 then 	 
--	--We create the case needed to measure the alu delay with circuit simulation
--	ALU_A <= x"01";		--set up the addition delay test for circuit sim 
--	ALU_B <= x"00";		--
--	MODE<= "001";
--	wait for 10ns;
--	ALU_B <= x"01";
--	K:= K + 1;
--	wait;	--this halts activity to keep the subsequent alu test from happening.
--end if;
	
	-----The ALU functional test------	
	write(buf, string'("ALUNA Test Results"));
	writeline(output, buf);
	write(buf, string'("---------------------"));
	writeline(output, buf);
		ALU_A <= std_logic_vector(to_signed(AVALS(K),16)); --convert our integers to std_logic
		ALU_B <= std_logic_vector(to_signed(BVALS(K),16));
	wait for 10 ns;
   write(buf, string'("A="));  --Print out the pair of numbers driving the ALU
	write(buf, TO_BITVECTOR(ALU_A));
	write(buf, string'("="));
	write(buf, TO_INTEGER(signed(ALU_A)));
	write(buf, string'(", B="));
	write(buf, TO_BITVECTOR(ALU_B), right, 9);
	write(buf, string'("="));
	write(buf, TO_INTEGER(signed(ALU_B)));
   writeline(output,buf);
	--write a column header for the next group
   write(buf, string'(" Time     MODE     ALU_out       ovfl"));
   writeline(output, buf);
   	
	J:= 0;   --loop on the ALU opcode
LP: loop  
		MODE<= std_logic_vector(to_unsigned(J,3));
		J:= J + 1;
	wait for 50 ns;
	write(buf, NOW, right, 4); --Print out the current simulation time
	write(buf, TO_BITVECTOR(MODE), right, 5);
	--write(buf, string'("  "));
	write(buf, TO_BITVECTOR(ALU_out), right, 10);
	write(buf, TO_INTEGER(signed(ALU_out)), right, 6);
	write(buf, TO_BIT(ALU_ovfl), right, 5);
   writeline(output, buf);
	exit when J>7;		--exit this loop after driving ALU with 8 opcodes
end loop;
--draw a line for the next case.
	write(buf, string'("---------------------------------"));
	writeline(output, buf);
	wait for 10 ns;
	--Here we take advantage of the fact that a process repeats continuously 
	K:= K + 1;	 --increment subscript for a new pair of ALU inputs
	if K > 5 then wait; -- wait forever to stop process after all cases complete
	end if;
END PROCESS;

END;
