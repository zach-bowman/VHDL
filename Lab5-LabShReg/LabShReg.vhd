library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.MyDeclares.all;

entity LabShReg is		--top level for toggle counter.
  port(  clk50:	in std_logic;	--external 50MHz clock.
			sw1:	in std_logic;
			swrst:in std_logic;	--signals from XST board buttons
			fceb:	out std_logic;	--flash disable
			bg:	out std_logic_vector(9 downto 0); --bargraph LED
			lsdp: out std_logic; --heartbeat
			sig1: out std_logic; --debug
			sig2: out std_logic	--debug
	);
end LabShReg;

architecture ARCH of LabShReg is
-------------
signal feedback1: std_logic;
signal feedback2: std_logic;
signal reset: std_logic;
signal clk2: std_logic;	--2Hz clock
signal clk10: std_logic;	--10kHz clock
signal lfsr10,lfsr10nxt: std_logic_vector(12 downto 0);
signal lfsr2,lfsr2nxt: std_logic_vector(12 downto 0);
constant SEED: STD_LOGIC_VECTOR(12 DOWNTO 0):=("0000000000000"); --initial state
signal STATE5K: STD_LOGIC_VECTOR(12 downto 0); --rollover state, made it a signal because the synthesizer got mad at me otherwise
-------------
--signal counter: integer:=0;
signal dutycycle: integer:=20;
----------------------
signal beat: std_logic; --heartbeat output
signal DutyEnable: std_logic;
------------------------------------------

begin

STATE5K<=find_lfsr_decode(5000); --find rollover state

--======LFSR CLOCK DIVIDERS======--
	process(clk50,reset) is	--driven by the external 50MHz clock and the reset signal
	begin
		if reset='1' then
			clk10<='0';
			lfsr10<=SEED;			--when it reaches the correct state, reset LFSR to 0's
		elsif rising_edge(clk50) then
			if lfsr10=STATE5K then
				clk10<='1';
				lfsr10<=SEED;
			else
				clk10<='0';
				lfsr10<=lfsr10nxt;
			end if;
		end if;
	end process;
	--==next state logic
	feedback1<=lfsr10(12) xnor lfsr10(3) xnor lfsr10(2) xnor lfsr10(0); --feedback logic
	lfsr10nxt<=lfsr10(11 downto 0) & feedback1; --shift

	process(clk10,reset) is  --same exact process, driven by the 10kHz clock
	begin
		if reset='1' then
			clk2<='0';
			lfsr2<=SEED;			--when it reaches the correct state, reset LFSR to 0's
		elsif rising_edge(clk10) then
			if lfsr2=STATE5K then
				clk2<='1';
				lfsr2<=SEED;
			else
				clk2<='0';
				lfsr2<=lfsr2nxt;
			end if;
		end if;
	end process;
	--==next state logic
	feedback2<=lfsr2(12) xnor lfsr2(3) xnor lfsr2(2) xnor lfsr2(0); --feedback logic
	lfsr2nxt<=lfsr2(11 downto 0) & feedback2; --shift

--======DUTY CYCLE PROCESSES======--
	process(clk2,DutyEnable) is
	begin
		if DutyEnable='1' then				--only functions when DutyEnable is high
			if rising_edge(clk2) then
				if dutycycle<80 then
					dutycycle<=dutycycle+5;
				else
					dutycycle<=20;
				end if;
			end if;
		end if;
	end process;
	
	process(clk10,clk2,DutyEnable) is
	variable counter: integer:=0;
	begin
		if DutyEnable='1' then				--only functions when DutyEnable is high
			if rising_edge(clk10) then
				if counter<dutycycle then	--turns LEDs on for counter2/100 times
					bg(7)<='1';
					bg(5)<='1';
					bg(3)<='1';
					bg(1)<='1';
					counter:=counter+1;
				elsif counter<100 then		--then turns them off for 100-counter2 times
					bg(7)<='0';
					bg(5)<='0';
					bg(3)<='0';
					bg(1)<='0';
					counter:=counter+1;
				else
					counter:=0;					--after 100 counts, reset to 0
				end if;
			end if;
		end if;
	end process;
--==DUTY CYCLE ENABLE==--
DUTYENABLER: ToggleD 
	port map(S=>sw1, 
				reset=>not swrst, 
				clk50=>clk50,
				Q=>DutyEnable
	);
--==HEARTBEAT==--	
HEARTBEAT: DFACE
	port map(
		d=>not beat,
		q=>beat,
		c=>clk2,
		ce=>'1',
		clr=>not swrst
	);
lsdp<=beat;
------------------
fceb<='1';	 --disable flash memory				
bg(6)<='1';  --every other BG LED ON
bg(4)<='1';
bg(2)<='1';
bg(0)<='1';
------------------
reset<=not swrst;
bg(9)<=DutyEnable;
bg(8)<=DutyEnable;
sig1<=clk10;
sig2<=clk2;
end ARCH;