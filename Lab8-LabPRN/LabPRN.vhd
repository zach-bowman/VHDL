library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.MyDeclares.all;

entity LabPRN is
	port(
		clk50:	in std_logic;
		swrst:	in std_logic;
		sw1:	in std_logic;
		bg: 		out std_logic_vector(4 downto 0);
		ls: 		out std_logic_vector(6 downto 0);
		rs: 		out std_logic_vector(6 downto 0);
		fceb:		out std_logic;
		sig1:		out std_logic;
		sig2:		out std_logic;
		sig3:		out std_logic;
		dipsw1:	in std_logic
	);
end LabPRN;

architecture PRN_ARCH of LabPRN is
	CONSTANT AVGPERIOD: 	UNSIGNED(15 DOWNTO 0):=TO_UNSIGNED(30690,16);
	signal THRESHOLD:  UNSIGNED(15 DOWNTO 0);--:=TO_UNSIGNED(15959+261,16);
	signal counter: 		unsigned(15 downto 0):=(others=>'0');
	signal counter_nxt: 	unsigned(15 downto 0);
	signal matches: 		unsigned(15 downto 0):=(others=>'0');
	signal matches_nxt: 	unsigned(15 downto 0);
	signal PrevSig:		std_logic;	--for 8Hz clock check
	------------------
	signal masterclock:	std_logic;	--10MHz project clock
	signal RESET: 			std_logic;	--project reset
	signal delay: 			std_logic;	--(tied to enable)turn low to delay the 10-bit external code process
	signal excode:			std_logic;	--bit stream from external code
	signal loccode:		std_logic;	--bit stream from local code
	signal exsync:			std_logic;	--tied to external code's sync signal
	signal locsync:		std_logic;	--tied to local code's sync signal
	signal clk16:			std_logic;	--output from 16Hz clock
	signal noisebits:		std_logic;	--output of the noise generator
	signal noise96:		std_logic;	--96% noisy bits
	signal externout:		std_logic;	--signal going into correlator chosen by dip switch
	signal reclock:		std_logic;	--receiver lock, goes high when the count exceeds the threshold
	signal truelock:		std_logic;	--goes high when both of the signals sync signals go high simultaneously
	signal measuring:		std_logic;	--measurement enable/disable
	signal lastmeasure:	std_logic;	--previous measurement
	signal newsearch:		std_logic;	--resets the external code for a new search
	------------------
	signal ring25:			std_logic_vector(24 downto 0):=(0=>'1', others=>'0');		--modulo 25 ring counter
	signal ring25_nxt:	std_logic_vector(24 downto 0);		--modulo 25 ring counter next state
	------------------
	signal ONEHERTZ:		std_logic;
	type SM_Type is (S0,S1,S2);
	signal SMCNT: SM_Type;
	signal SMD: SM_Type;
	------------------
	signal toPC: 			std_logic_vector(63 downto 0);
	signal fromPC: 		std_logic_vector(63 downto 0);
	signal bscan: 			std_logic_vector(3 downto 0):="0000";

begin
--==JTAG==--
JTAG: JTAG_IFC
	port map(
		bscan=>bscan,
		dat_to_pc=>toPC,
		dat_from_pc=>fromPC
	);

--==CORRELATOR==--
process (masterclock, SMCNT, RESET, clk16, truelock) is
begin
	if clk16='1' or RESET='1' then
		counter<=(others=>'0');
		matches<=(others=>'0');
	elsif rising_edge(masterclock) then
		if measuring='1' then
			counter<=counter+1;
			if (externout xor loccode)='0' then
				matches<=matches+1; --when the 8Hz clock goes high, increment matches only when the bits match
			end if;
		end if;
	end if;
end process;

--==MEASUREMENT INDICATOR==--
process (masterclock, measuring) is
begin
	--hold a signal high during the measurement period
	--when it's low, the measurement is finished
	if rising_edge(masterclock) then
		if counter<AVGPERIOD then
			measuring<='1';
		else
			measuring<='0';
		end if;
	end if;
end process;

--==DELAY SIGNAL STATE MACHINE==--
process (masterclock, SMD, RESET, truelock) is
begin
	if rising_edge(masterclock) then
		--STATE MACHINE, TWO STATES
		case SMD is
			when S0=>	--hold enable high and wait for the end of a measurement
				lastmeasure<=measuring;
				if (lastmeasure/=measuring) and (measuring='0') then
					SMD<=S1;	
				end if;
				delay<='1';
			when S1=>
				if matches<THRESHOLD then
					delay<='0';	--turn enable low for one clock cycle if the measurement is below threshold
					reclock<='0';	--no receiver lock
				else
					reclock<='1'; --matches exceeds threshold, therefore there is reciever lock
				end if;
				SMD<=S0;
			when others=>null;
		end case;
	end if;
end process;

--==TRUE LOCK SIGNAL==--
process (truelock, masterclock) is
begin
--true lock is achieved when both signals are synced
	if rising_edge(masterclock) then
		if (exsync='1' and locsync='1') then
			truelock<='1';
		elsif (exsync='0' and locsync='1') then
			truelock<='0';
		elsif (exsync='1' and locsync='0') then
			truelock<='0';
		end if;
	end if;
end process;

--==GENCLKS==--
CLOCKS: GenClks
	port map(
		clk50=>clk50,
		reset=>RESET,
		clk10m=>masterclock,
		clk16Hz=>clk16
	);

--==NOISE!==--
NOISE: PRN64
	port map(
		clk=>masterclock,
		code=>noisebits
	);

--==96% NOISE!==--
process (masterclock,ring25) is
begin --process simply rotates the ring counter on every clock edge
	if RESET='1' then
		ring25<=(0=>'1', others=>'0');
	elsif rising_edge(masterclock) then
		ring25<=ring25_nxt; 
	end if;
end process;
ring25_nxt<=ring25(23 downto 0) & ring25(24); 
noise96<=excode when ring25(0)='1' else (excode xor noisebits);

--==SIGNAL INTO CORRELATOR SELECT==--
process (masterclock, dipsw1) is
begin
	if rising_edge(masterclock) then
		if dipsw1='0' then
			externout<=noise96;
			bg(3)<='1';
			bg(4)<='0';
		else 
			externout<=excode;
			bg(3)<='0';
			bg(4)<='1';
		end if;
	end if;
end process;

--==LOCAL CODE==--
LOCAL: PRN10
	port map(
		clk=>masterclock,
		reset=>RESET,
		enable=>delay,
		code=>loccode,
		sync=>locsync
	);

--==EXTERNAL CODE==--
EXTERNAL: PRN10
	port map(
		clk=>masterclock,
		reset=>newsearch,
		enable=>'1',
		code=>excode,
		sync=>exsync		
	);

----------------
fceb<='1';
RESET<=not swrst;
bg(0)<=reclock;
bg(1)<=truelock;
bg(2)<=not delay;
sig1<=locsync;
sig2<=exsync;
newsearch<=not sw1;

process (masterclock) is
begin
	if rising_edge(masterclock) then
		if measuring='0' then
			ls<=LedHI(std_logic_vector(matches(15 downto 12)));
			rs<=LedHI(std_logic_vector(matches(11 downto 8)));
			toPC(15 downto 0)<=std_logic_vector(matches(15 downto 0));
		end if;
	end if;
end process;

toPC(63 downto 48)<=std_logic_vector(THRESHOLD);
THRESHOLD<=unsigned(fromPC(15 downto 0));
sig3<=noisebits;
end PRN_ARCH;