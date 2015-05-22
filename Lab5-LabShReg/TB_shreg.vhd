--Example test bench for simulating SRFF modules.
--The header normally supplied with the auto-generated template has 
--  been removed. Don't auto generate. Just cannablize this file for future test benches
----------------------------------------------------------------------------
LIBRARY ieee;	--declare standard vhdl libraries
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use std.textio.all;	--***This line is needed to use vhdl file handling statements.

ENTITY TB_shreg IS	--There is no port signals for a test bench model. It never gets synthesized.
END TB_shreg;

ARCHITECTURE model OF TB_shreg IS 

	--*** Component Declaration for the Unit Under Test (UUT)
	COMPONENT LFSR
	  port(  clk50:	in std_logic;	--external 50MHz clock.
				iShift13: out std_logic_vector(12 downto 0);
				clk10kHz: out std_logic
--				reset13: in std_logic

		);
	END COMPONENT;
	
	signal shiftstate: std_logic_vector(12 downto 0);
	SIGNAL  clk:    std_logic;
	signal clk10kHz: std_logic;
--	signal reset: std_logic;
---------------------------------------------------------------------------
BEGIN   ---The test bench architecture starts here
---------------------------------------------------------------------------
----- Instantiate the Unit Under Test (UUT). This is always supplied with the label, UUT:
UUT: LFSR PORT MAP(
		clk50=>clk,
		iShift13=>shiftstate,
		clk10kHz=>clk10kHz
--		reset13=>reset
		);

--------------------------------------------------------------
PROCESS  is    BEGIN   --example of a 50 MHz clock generator
      clk <= '0';
      wait for 5 ns;	--with this version you can control the duty cycle by the delays
      clk <= '1';
      wait for 5 ns;
 END PROCESS;	--this process repeats forever since there is no final "wait"
---------------------------------------------------------------
tb : PROCESS  
	BEGIN
	--Always start with a wait 100 ns for global reset to finish
	wait for 100 ns;
	shiftstate<=(others=>'0');
	wait for 100 ns;
	
	--============================================================================
	wait; --an indefinite WAIT will wait forever, so this process never repeats
	END PROCESS;
END model;