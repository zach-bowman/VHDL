library IEEE;
use IEEE.std_logic_1164.all;

------------------------------------
entity DFACE is  --rising-edge triggered DFF with asynchronous clk enable and reset.
	port (D:     in std_logic; --Data input
         C:     in std_logic; --Clock input
         CE:    in std_logic; --Active-high clock enable
         CLR:   in std_logic; --Active-high reset
         Q:     out std_logic --Data out
         );
end DFACE; --We have chosen these names to be consistent with the Spartan library names
--------------------------------------
architecture DFACE_ARCH of DFACE is
	signal Q_reg: std_logic; --Output of the DFF 
	signal Q_next: std_logic; --Next value of the DFF
begin
	---------DFF---------
	process(C,CLR) --Process depends on change in state of the reset or the clock signal
	begin
		if (CLR='1') then --If reset is high,
			Q_reg <='0';   --Clear the DFF to 0
		elsif rising_edge(C) then --Otherwise (reset is low), 
			Q_reg <= Q_next;		  --set the next value of Q when the clock goes high
		end if;
	end process;
	-- next-state logic --
	Q_next <= D when CE='1'	else Q_reg; --Output is set as the input when enable is high, stays the same if low
	-- output logic --
	Q <= Q_reg;
end DFACE_ARCH;