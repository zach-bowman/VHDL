library IEEE;
use IEEE.std_logic_1164.all;
library UNISIM;
use UNISIM.VComponents.all;

entity Toggle1 is
port(S: in std_logic; --S input will come from an active low push button
	reset: 	in std_logic; --reset =>'1' reset Q to '0'.
	Q: 	 	out std_logic --output state toggles when S goes low 
	);
end Toggle1;

architecture Toggle1_ARCH of Toggle1 is
signal BUFtoC: std_logic; --internal signal that connects the buffer to the input and the clock
signal QtoD: std_logic;
component BUFG port(I: in std_logic; O: out std_logic);  end component;
component DFACE port( D:     in std_logic; --Data input
							 C:     in std_logic; --Clock input
							 CE:    in std_logic; --Active-high clock enable
							 CLR:   in std_logic; --Active-high reset
							 Q:     out std_logic --Data out
							); end component;
begin	
ZACH_BUFG: BUFG port map( I=>not S, O=>BUFtoC ); 
--inverts the input (to be active low), 
--output to internal connection signal
ZACH_DFACE: DFACE port map( D=>not QtoD, CE=>'1', CLR=>reset, Q=>QtoD, C=>BUFtoC);
Q<=QtoD;	
--D is the inverted Q signal, 
--CLR is tied to reset, 
--output to output, 
--and the clock is tied to the internal signal
end Toggle1_ARCH;