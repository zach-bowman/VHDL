--Example test bench for simulating SRFF modules.
--The header normally supplied with the auto-generated template has 
--  been removed. Don't auto generate. Just cannablize this file for future test benches
----------------------------------------------------------------------------
LIBRARY ieee;	--declare standard vhdl libraries
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use std.textio.all;	--***This line is needed to use vhdl file handling statements.

ENTITY TB_Toggle1 IS	--There is no port signals for a test bench model. It never gets synthesized.
END TB_Toggle1;

ARCHITECTURE model OF TB_Toggle1 IS 

	--*** Component Declaration for the Unit Under Test (UUT)
	COMPONENT Toggle1
	port(S: in std_logic; --S input will come from an active low push button
	reset: 	in std_logic; --reset =>'1' reset Q to '0'.
	Q: 	 	buffer std_logic --output state toggles when S goes low 
	);
	END COMPONENT;
	--Inputs. Signal declarations must agree with UUT Port definitions.
	SIGNAL S : std_logic ;  --Signals in a model can be initialized,
	SIGNAL reset : std_logic;   --  but not in any synthesizable code.
	--Outputs. Signal declarations must agree with UUT Port definitions.
	SIGNAL Q : std_logic;
	--clock signal (may be commented out if not needed)
	--There may already be a clock signal declaration if there is a clock input to your entity.
	--For DFACE it will be called C, for example.     		
---------------------------------------------------------------------------
BEGIN   ---The test bench architecture starts here
---------------------------------------------------------------------------
----- Instantiate the Unit Under Test (UUT). This is always supplied with the label, UUT:
UUT: Toggle1 PORT MAP(
		S => S,
		reset => reset,
		Q => Q
		);
--------------------------------------------------------------
-----This is a process to generate a clock signal
--If you are cutting and pasting from a previous test bench, then you have to be sure the 
-- clock signal name used in the process agrees with the declaration above.
--All you have to do is change the clock name and the period, which is determined by the "waits".
--
--PROCESS  is    BEGIN   --example of a 50 MHz clock generator
  --    C <= '0';
    --  wait for 10 ns;	--with this version you can control the duty cycle by the delays
      --C <= '1';
     -- wait for 10 ns;
 --END PROCESS;	--this process repeats forever since there is no final "wait"
---------------------------------------------------------------


--This is the main process in the test bench model. It will repeat until it hits an indefinite WAIT
tb : PROCESS  
BEGIN
	--Always start with a wait 100 ns for global reset to finish
	wait for 100 ns;
	S<='1';
	reset<='0';
	wait for 30 ns;
	S<='0';
	wait for 30 ns;
	S<='1';
	
	
	--============================================================================
	wait; --an indefinite WAIT will wait forever, so this process never repeats
	END PROCESS;

END model;
