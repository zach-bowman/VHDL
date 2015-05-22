library IEEE;
use IEEE.std_logic_1164.all;

entity SRFF1 is
port(set: in STD_LOGIC;
	reset: 	in STD_LOGIC;
	q: 	 	out STD_LOGIC 	 --Note: output must be assigned from internal signal
	);		   			 	 --   when it is used in internal logic.
end SRFF1;
----------------------------------
architecture ARCH of SRFF1 is  
signal qb, qi: STD_LOGIC;				--Internal signals declared.
----------------------
attribute s: string;				--These 3 lines will be explained in a later lecture.
attribute s of qi: signal is "yes";	--They are included to preserve signal names in the schematic
attribute s of qb: signal is "yes";

----------------------
begin
  q<= qi;						--Note: port output assigned from internal signal.
  qi<= (not qb) or (not set);	--These signal asssignments are all concurrent.
  qb<= (not qi) or (not reset);
end ARCH;
-----------------------------------



