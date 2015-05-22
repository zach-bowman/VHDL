--Example test bench for simulating SRFF modules.
--The header normally supplied with the auto-generated template has 
--  been removed. Don't auto generate. Just cannablize this file for future test benches
----------------------------------------------------------------------------
LIBRARY ieee;	--declare standard vhdl libraries
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use std.textio.all;	--***This line is needed to use vhdl file handling statements.

ENTITY TB_DFACE IS	--There is no port signals for a test bench model. It never gets synthesized.
END TB_DFACE;

ARCHITECTURE model OF TB_DFACE IS 

	--*** Component Declaration for the Unit Under Test (UUT)
	COMPONENT DFACE
	PORT (D:     in std_logic; --Data input
         C:     in std_logic; --Clock input
         CE:    in std_logic; --Active-high clock enable
         CLR:   in std_logic; --Active-high reset
         Q:     out std_logic --Data out
         );
	END COMPONENT;
	--Inputs. Signal declarations must agree with UUT Port definitions.
	SIGNAL D : std_logic ;  --Signals in a model can be initialized,
	SIGNAL CLR : std_logic;   --  but not in any synthesizable code.
	SIGNAL CE : std_logic;
	--Outputs. Signal declarations must agree with UUT Port definitions.
	SIGNAL Q : std_logic;
	--clock signal (may be commented out if not needed)
	--There may already be a clock signal declaration if there is a clock input to your entity.
	--For DFACE it will be called C, for example.   
	SIGNAL C : std_logic;  		
---------------------------------------------------------------------------
BEGIN   ---The test bench architecture starts here
---------------------------------------------------------------------------
----- Instantiate the Unit Under Test (UUT). This is always supplied with the label, UUT:
UUT: DFACE PORT MAP(
		D => D,
		CE => CE,
		CLR => CLR,
		C => C,
		Q => Q
		);
--------------------------------------------------------------
-----This is a process to generate a clock signal
--If you are cutting and pasting from a previous test bench, then you have to be sure the 
-- clock signal name used in the process agrees with the declaration above.
--All you have to do is change the clock name and the period, which is determined by the "waits".
--
PROCESS  is    BEGIN   --example of a 50 MHz clock generator
      C <= '0';
      wait for 10 ns;	--with this version you can control the duty cycle by the delays
      C <= '1';
      wait for 10 ns;
 END PROCESS;	--this process repeats forever since there is no final "wait"
---------------------------------------------------------------


--This is the main process in the test bench model. It will repeat until it hits an indefinite WAIT
tb : PROCESS  
BEGIN
	--Always start with a wait 100 ns for global reset to finish
	wait for 100 ns;
	D<='1';
	
	--assign next set and reset signal values from constant lists
	CLR<= '1';
	CE<= '0';

	wait for 20 ns;	--wait for new state to happen
	CLR<= '0';
	CE<= '0';

	wait for 20 ns;
	CLR<= '0';
	CE<= '1';

	wait for 20 ns;
	D<='0';

	wait for 20 ns;
	D<='1';

	--============================================================================
	wait; --an indefinite WAIT will wait forever, so this process never repeats
	END PROCESS;

END model;
