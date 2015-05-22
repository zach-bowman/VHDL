--Example test bench for simulating SRFF modules.
--The header normally supplied with the auto-generated template has 
--  been removed. Don't auto generate. Just cannablize this file for future test benches
----------------------------------------------------------------------------
LIBRARY ieee;	--declare standard vhdl libraries
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use std.textio.all;	--***This line is needed to use vhdl file handling statements.

ENTITY TB_SRFF_Ex IS	--There is no port signals for a test bench model. It never gets synthesized.
END TB_SRFF_Ex;

ARCHITECTURE model OF TB_SRFF_Ex IS 
DFACE.vhdLab1B.vhdSRFF1.vhdSRFF2.vhdTB_DFACE.vhdTB_SRFF_Ex.vhdTB_Toggle1.vhdToggle1.vhd
	--*** Component Declaration for the Unit Under Test (UUT)
	COMPONENT SRFF2
	PORT(
		set : IN std_logic;
		reset : IN std_logic;          
		q : OUT std_logic
		);
	END COMPONENT;
	--Inputs. Signal declarations must agree with UUT Port definitions.
	SIGNAL set :  std_logic := '1';  --Signals in a model can be initialized,
	SIGNAL reset :  std_logic := '1';   --  but not in any synthesizable code.
	--Outputs. Signal declarations must agree with UUT Port definitions.
	SIGNAL q :  std_logic;
	--clock signal (may be commented out if not needed)
	--There may already be a clock signal declaration if there is a clock input to your entity.
	--For DFACE it will be called C, for example.   
	SIGNAL  clk:    std_logic;  		
------We can add some other signal and constant declarations as needed------
--***An array of values for the set & reset signals has to be added,
--       so the test bench process can loop through these values to run the test.
--Vectors of (set, reset) values for the test:
--These 5 element vectors are just an example, and must be redone by the student 
constant RLIST: std_logic_vector(0 to 4):=('1','0','1','0','1');
constant SLIST: std_logic_vector(0 to 4):=('1','0','0','1','1');
--*** A file must be defined to store test results. 
--*** "text" is a file type defined in the textio library.
--*** If no folder path is specified the file is created in your project folder.
file output: text open WRITE_MODE is "SRFF2_TEST.txt";  --open the results file 
---------------------------------------------------------------------------
BEGIN   ---The test bench architecture starts here
---------------------------------------------------------------------------
----- Instantiate the Unit Under Test (UUT). This is always supplied with the label, UUT:
UUT: SRFF2 PORT MAP(
		set => set,
		reset => reset,
		q => q
		);
--------------------------------------------------------------
-----This is a process to generate a clock signal
--If you are cutting and pasting from a previous test bench, then you have to be sure the 
-- clock signal name used in the process agrees with the declaration above.
--All you have to do is change the clock name and the period, which is determined by the "waits".
--
PROCESS  is    BEGIN   --example of a 50 MHz clock generator
      clk <= '0';
      wait for 10 ns;	--with this version you can control the duty cycle by the delays
      clk <= '1';
      wait for 10 ns;
 END PROCESS;	--this process repeats forever since there is no final "wait"
---------------------------------------------------------------


--This is the main process in the test bench model. It will repeat until it hits an indefinite WAIT
tb : PROCESS  
-----------------------------
--***any process variables used must be declared inside the process block before the BEGIN statement
variable J: integer:=0;		--variables can be initialized
variable buf: LINE;			--line buffer of string data
-----------------------------
	BEGIN
	--Always start with a wait 100 ns for global reset to finish
	wait for 100 ns;
	
--=========We add VHDL to the process to define a model that perform the test==============
--***Code to write header text to the result file. Run the test bench as is before you  
--   change it to be sure it runs, and see the results file created by this code.
--write title and column labels (note that output goes into a line buffer for eventual output)
	write(buf, string'("SRFF2 Test Results")); --write text to next line buffer.
	writeline(output, buf);	 --send the line out to file
	write(buf, string'("---------------------")); 	--write a separater line to buffer
	writeline(output, buf);	--send the line out to file
	--write a column header for the signal states
   write(buf, string'(" Time   old-Q set reset new-Q"));	--write column headings to buffer
   writeline(output,buf);	--send the line out
-------End of the Header text-----------------------------------
	--loop thru all signal cases in 10 ns steps.
LP: loop
	--start the next line of output
	write(buf, NOW, right, 4); 			--write current sim time to buf
	write(buf, TO_BIT(q), right, 4);	--add the current Q (right adjusted, 4 char wide)
	-------------------------	--assign next set and reset signal values from constant lists
	reset<= RLIST(J);
	set<= SLIST(J);
	wait for 20 ns;	--wait for new state to happen
	------------------------
	--add the new state info to the line, field by field
	write(buf, TO_BIT(set), right, 5); --add 'set' value as 5 chars wide
	write(buf, TO_BIT(reset), right, 5);
	write(buf, TO_BIT(q), right, 6);
   writeline(output, buf);	--send the whole line out to file
	-----------------------
   J:= J + 1;		--loop to next set-reset pair
	exit when J> SLIST'HIGH;	--this means "exit the loop", not the process.
end loop;

	write(buf, string'("-----Test Completed-------------"));
	writeline(output, buf);
--============================================================================
	
	wait; --an indefinite WAIT will wait forever, so this process never repeats
	END PROCESS;

END model;
