library IEEE;
use IEEE.std_logic_1164.all;

entity Lab1B is			--Port signals for top level module are to outside world.
port(sw1: in std_logic; --input from xst push button
	swrst: in std_logic; --input from xst reset push button
	fceb: out std_logic; --flash not-select 
	bg0:	out std_logic	--output to xst bargraph LED element
	);
end Lab1B;

architecture Lab1B_ARCH of Lab1B is
	component Toggle1 port( S: in std_logic; --S input will come from an active low push button
									reset: 	in std_logic; --reset =>'1' reset Q to '0'.
									Q: 	 	out std_logic --output state toggles when S goes low 
								 ); end component;
	begin	
		ZACH_Toggle1: Toggle1 port map(S=>sw1, reset=>not swrst, Q=>bg0); 
		--Tie outside signals to top module
		fceb<='1'; 
		--disable XSA flash memory
end Lab1B_ARCH;