library IEEE;
use IEEE.std_logic_1164.all;

entity SRFF2 is
port(set: in STD_LOGIC;
	reset: 	in STD_LOGIC;
	q: 	 	out STD_LOGIC 	 --Note: output must be assigned from internal signal
	);		   			 	 --   when it is used in internal logic.
end SRFF2;
----------------------------------
architecture ARCH of SRFF2 is  
begin
process(set,reset) is begin --SR latch process driven by set and reset
  if reset='0' and set='1' then
		q <='0';
  elsif reset='1' and set='0' then
		q <='1';
  end if;
end process;
end ARCH;
-----------------------------------



