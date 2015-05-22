--Example test bench for simulating SRFF modules.
--The header normally supplied with the auto-generated template has 
--  been removed. Don't auto generate. Just cannablize this file for future test benches
----------------------------------------------------------------------------
LIBRARY ieee;	--declare standard vhdl libraries
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use std.textio.all;	--***This line is needed to use vhdl file handling statements.

ENTITY TB_clk_div IS	--There is no port signals for a test bench model. It never gets synthesized.
END TB_clk_div;

ARCHITECTURE model OF TB_clk_div IS 

	--*** Component Declaration for the Unit Under Test (UUT)
	COMPONENT clk_div
	generic(MAXD: natural:=5);	--upper bound on divisor
	PORT(
			clk:		in std_logic;	--input clock
			reset:	in std_logic;	--asynchronous counter reset
			div:		in integer range 0 to MAXD;	--divisor magnitude
			div_clk:	out std_logic	--output divided clock
		);
	END COMPONENT;
	--Inputs. Signal declarations must agree with UUT Port definitions.

	SIGNAL reset :  std_logic := '1';   --  but not in any synthesizable code.
	--Outputs. Signal declarations must agree with UUT Port definitions.
	SIGNAL div_clk:  std_logic;
	--clock signal (may be commented out if not needed)
	--There may already be a clock signal declaration if there is a clock input to your entity.
	--For DFACE it will be called C, for example.   
	SIGNAL  clk:    std_logic;  		
	--SIGNAL div: std_logic;
------We can add some other signal and constant declarations as needed------
--***An array of values for the set & reset signals has to be added,
--       so the test bench process can loop through these values to run the test.
--Vectors of (set, reset) values for the test:
--These 5 element vectors are just an example, and must be redone by the student 
constant RLIST: std_logic_vector(0 to 9):=('0','1','1','1','1','0','0','0','0','1');


---------------------------------------------------------------------------
BEGIN   ---The test bench architecture starts here
---------------------------------------------------------------------------
----- Instantiate the Unit Under Test (UUT). This is always supplied with the label, UUT:
UUT: clk_div
generic map(MAXD=>2) 
PORT MAP(
		clk=>clk,	--input clock
			reset=>reset,	--asynchronous counter reset
			div=>2,	--divisor magnitude
			div_clk=>div_clk	--output divided clock

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
	

LP: loop
	--assign next set and reset signal values from constant lists
	reset<= RLIST(J);
	wait for 200 ns;	--wait for new state to happen
	------------------------

	-----------------------
   J:= J + 1;		--loop to next set-reset pair
	exit when J> RLIST'HIGH;	--this means "exit the loop", not the process.
end loop;

--============================================================================
	
	wait; --an indefinite WAIT will wait forever, so this process never repeats
	END PROCESS;

END model;
