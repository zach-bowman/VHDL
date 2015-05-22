library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.MyDeclares.all;

entity LabPLL is
	port(	
		clk100:	in std_logic;
		swrst:	in std_logic;
		sw1:		in std_logic;
		sig1:		out std_logic;
		sig2:		out std_logic;
		sig3:		in std_logic;
		fceb:		out std_logic;
		lsdp:		out std_logic;
		bg0:		out std_logic
		);
end LabPLL;

architecture PLL_ARCH of LabPLL is
	signal Enable: std_logic;
	signal reset: std_logic;
	signal InputSignal: std_logic;
	signal PrevSig: std_logic;
	signal phase: signed(31 downto 0);
	signal ph0: signed(31 downto 0);
	signal M: signed(31 downto 0):=DDS_INCR(125000.0);
	CONSTANT GAIN: INTEGER:=2**11;
	
begin
--==COUNTER PROCESS==--
process (clk100,phase,reset) is
begin
	if reset='1' then				--on reset, reinitialize phase and M to defaults
		phase<=(others=>'0');
		M<=DDS_INCR(125000.0);
	elsif rising_edge(clk100) then
		InputSignal<=sig3;		
		PrevSig<=InputSignal;	--test for falling edge of the input signal
		if (PrevSig /= InputSignal) and (InputSignal = '0') and (Enable='1') then	--as written in the write-up
				ph0<=phase;			--latch the current phase
				phase<=M;			--reset the phase to zero (it's M because it's set a clock after this)
				M<=M-ph0/GAIN;		--update the phase error using previous phase
		else
				phase<=phase+M;	--otherwise, let the phase keep going
		end if;
	end if;
end process;
--==LOCK PROCESS==--
lsdp<='1' when ph0<(2*M) else '0';	--left dec pt is high when error is less that 2*M
--==ENABLE==--
ENABLER: ToggleD 
	port map(
		S=>sw1, 
		reset=>not swrst, 
		clk50=>clk100,
		Q=>Enable
	);
bg0<=Enable;
---------------
fceb<='1';
reset<=not swrst;		--external reset signal
sig1<=InputSignal;	--function generator output
sig2<=phase(31);		--phase clock signal
end PLL_ARCH;