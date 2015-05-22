library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.MyDeclares.all;
use WORK.sdramj.all;			--sdramcntl package for XSA brds.
use WORK.audio.all;

entity LabTones2 is
	port(	
		clk100:	in std_logic;
		swrst:	in std_logic;
		fceb:		out std_logic;
		mclk:		out std_logic;
		lrck:		out std_logic;
		serclk:	out std_logic;
		sdout:	in	std_logic;
		sdin:		out std_logic;
		sig1:		out std_logic;
		sig2:		out std_logic;
		sig3:		out std_logic;
		bg:		out std_logic_vector(3 downto 0);
		-----------SDRAM I/O connections----------- 
		sclkfb:	in std_logic;				-- feedback SDRAM clock with PCB delays
		sclk: 	out std_logic;				-- clock to SDRAM
		cke: 		out std_logic;				-- SDRAM clock-enable
		cs_n: 	out std_logic;				-- SDRAM chip-select	
		ras_n: 	out std_logic;				-- SDRAM RAS
		cas_n: 	out std_logic;				-- SDRAM CAS
		we_n: 	out std_logic;				-- SDRAM write-enable
		ba: 		out std_logic_vector(1 downto 0);		-- SDRAM bank-address
		saddr: 	out std_logic_vector(12 downto 0);		-- SDRAM address bus
		sdat: 	inout std_logic_vector(15 downto 0);	-- data bus to SDRAM

		dqmh: 	out std_logic;				-- SDRAM DQMH
		dqml: 	out std_logic				-- SDRAM DQML
	);
end LabTones2;

architecture ARCHtones of LabTones2 is
	type SM_Type is (S0,S1,S2,S3);	--state machine for memory access
	signal SMRAM: SM_Type;
	---======= Set SDRAM generics ==========	
	constant FREQ 	: integer 	:= 100_000;
	constant CLK_DIV	: real		:= 2.0;    	--uses 100 Mhz  input clk
	constant NROWS	: integer	:= 8192;
	constant NCOLS	: integer	:= 512;
	---======= JTAG signals ================
	signal bscan: std_logic_vector(3 downto 0);
	signal fromPC: std_logic_vector(63 downto 0);
		--could've done aliases, but whatever
		signal Enable: std_logic;	--is fromPC(0);
		signal Control: integer;	--is fromPC(15 downto 8);
		signal Waveform: std_logic_vector(3 downto 0);-- is fromPC(19 downto 16);
		signal Filter: std_logic;	--fromPC(20);
	signal toPC: std_logic_vector(63 downto 0);

	signal reset: std_logic;	--project reset
	signal accumulator: signed(31 downto 0); --accumulator for DDS process
	signal filteracc: signed(31 downto 0);		--accumulator for filter
	
	signal incr: signed(31 downto 0);	--DDS increment 
	signal filterinc: signed(31 downto 0):=DDS_INCR(43000.0);	--filter increment
	signal CordInc: signed(31 downto 0);	--cordic wave DDc increment
	signal sample: std_logic_vector(19 downto 0);	--input sine wave

	signal samplechoice,square,saw,sine: std_logic_vector(15 downto 0);
	signal cordic: signed(15 downto 0);
	--filter signals and constants--
	CONSTANT B1: SIGNED:=TO_SIGNED(INTEGER(33),18);
	CONSTANT B2: SIGNED:=TO_SIGNED(INTEGER(11),18);
	CONSTANT B3: SIGNED:=TO_SIGNED(INTEGER(33),18);
	CONSTANT B4: SIGNED:=TO_SIGNED(INTEGER(11),18);
	CONSTANT A1: SIGNED:=TO_SIGNED(INTEGER(88736),18);
	CONSTANT A2: SIGNED:=TO_SIGNED(INTEGER(-80514),18);
	CONSTANT A3: SIGNED:=TO_SIGNED(INTEGER(24458),18);
	CONSTANT FILTERGAIN: INTEGER:=2**15;
	signal x0,x1,x2,x3: signed(15 downto 0):=(others=>'0');
	signal y0,y1,y2,y3,y0_nxt: signed(15 downto 0):=(others=>'0');
	signal PrevSig: std_logic;
begin
--==COUNTER PROCESS==--
process (accumulator, reset, Enable, masterclk) is
begin
	if Enable='1' then
		if rising_edge(masterclk) then
			if WaveForm="1000" then
				accumulator<=accumulator+CordInc;	
			else
				accumulator<=accumulator+incr;
			end if;
		end if;
	end if;
end process;

--==SQUARE WAVE==--
process(accumulator, masterclk) is
begin
	if accumulator(31)='1' then
		square(15 downto 14)<=("00");
		square(13 downto 0)<=(others=>'1');
	else
		square(15 downto 14)<=("11");
		square(13 downto 0)<=(others=>'0');
	end if;
end process;

--==SAW WAVE==--
saw<=std_logic_vector(accumulator(31 downto 16));

--==CORDIC WAVE==--
process(accumulator(22), masterclk) is
	variable x: signed(15 downto 0):="0010000000000000";
	variable y: signed(15 downto 0):=(others=>'0');
begin
	if rising_edge(accumulator(22)) then
		cordic<=x;
		x:=x+(y/128);
		y:=y-(x/128);
	end if;
end process;

--==FILTER==--
process (filteracc, reset, Enable, masterclk) is
begin
	if Enable='1' then
		if rising_edge(masterclk) then
			filteracc<=filteracc+filterinc; --43kHz
		end if;
	end if;
end process;

process (filteracc(31), reset) is 
--a simple pushdown stack that samples the waveforms
begin
	if falling_edge(filteracc(31)) then
		x0<=signed(samplechoice);
		x1<=x0;
		x2<=x1;
		x3<=x2;
		y1<=y0;
		y2<=y1;
		y3<=y2;
	end if;
	if rising_edge(filteracc(31)) then
		y0<=y0_nxt;
	end if;
end process;
y0_nxt<=(B1*x0+B2*x1+B3*x2+B4*x3+A1*y1+A2*y2+A3*y3)/FILTERGAIN;

--==FILTER SELECT==--
sample(19 downto 4)<=std_logic_vector(y0) when Filter='1' else samplechoice;

--==JTAG SIGNAL ASSIGNMENT==--
Enable<=fromPC(0);	--Enable signal for DDS process
Control<=to_integer(unsigned(fromPC(15 downto 8))); --decides which frequency to output
Waveform<=fromPC(19 downto 16);	--decides which waveform to output
Filter<=fromPC(20);	--decides whether the signal is filtered or not

--==FREQUENCY SELECTION==--
with Control select
	incr<=
		DDS_INCR(261.63) when 1,
      DDS_INCR(277.18) when 2,
      DDS_INCR(293.66) when 3,
      DDS_INCR(311.13) when 4,
      DDS_INCR(329.63) when 5,
      DDS_INCR(349.23) when 6,
      DDS_INCR(369.99) when 7,
      DDS_INCR(392.00) when 8,
      DDS_INCR(415.30) when 9,
      DDS_INCR(440.00) when 10,
      DDS_INCR(466.16) when 11,
      DDS_INCR(493.88) when 12,
      DDS_INCR(523.25) when 13,
      DDS_INCR(554.37) when 14,
      DDS_INCR(587.33) when 15,
      DDS_INCR(622.25) when 16,
      DDS_INCR(659.26) when 17,
      DDS_INCR(1000.0) when 18,
      DDS_INCR(2000.0) when 19,
      DDS_INCR(3000.0) when 20,
      DDS_INCR(4000.0) when 21,
      DDS_INCR(5000.0) when 22,
      DDS_INCR(6000.0) when 23,
      DDS_INCR(7000.0) when 24,
      DDS_INCR(8000.0) when 25,
      DDS_INCR(9000.0) when 26,
      DDS_INCR(10000.0)when others;
		
--==DDS CORDIC INCREMENT SELECTION==--
with Control select
	CordInc<= 
		DDS_INCR(408.80) when 1,
		DDS_INCR(433.09) when 2,
		DDS_INCR(458.84) when 3,
		DDS_INCR(486.14) when 4,
		DDS_INCR(515.05) when 5,
		DDS_INCR(545.67) when 6,
		DDS_INCR(578.11) when 7,
		DDS_INCR(612.50) when 8,
		DDS_INCR(648.91) when 9,
		DDS_INCR(687.50) when 10,
		DDS_INCR(728.38) when 11,
		DDS_INCR(771.69) when 12,
		DDS_INCR(817.58) when 13,
		DDS_INCR(866.20) when 14,
		DDS_INCR(917.70) when 15,
		DDS_INCR(972.27) when 16,
		DDS_INCR(1030.09)when 17,
		DDS_INCR(1562.5) when 18,
		DDS_INCR(3125.0) when 19,
		DDS_INCR(4687.5) when 20,
		DDS_INCR(6250.0) when 21,
		DDS_INCR(7812.5) when 22,
		DDS_INCR(9375.0) when 23,
		DDS_INCR(10937.5)when 24,
		DDS_INCR(12500.0)when 25,
		DDS_INCR(14062.5)when 26,
		DDS_INCR(14062.5)when others;
		
--==WAVE SELECTION==--
with Waveform select
	samplechoice<=	
		sine when "0000",
		sine when "0001",
		square when "0010",
		('0' & saw(15 downto 1)) when "0100",
		std_logic_vector(cordic) when "1000",
		(others=>'0') when others;

--==LOOPBACK INTERFACE==--
UCODEC: Loopback
	generic map(
		XST_2_1_X=>TRUE,	--codec type for XST-3 board
		XSB_300E=>FALSE	--this parameter must the the TRUE one for the XST-4
	)
	port map(
		clk=>masterclk,	--same 50MHz clock
		reset=>reset,		--project reset
		mclk=>mclk,			--codec clock out to codec pin
		lrck=>lrck,			--codec left/right channel select out to codec pin
		sclk=>serclk,		--codec serial data clock out to codec pin
		sdout=>sdout,		--codec serial data coming in from the codec ADC pin
		sdin=>sdin,			--codec serial data going into codec DAC pin
		ladcdat=>open,
		radcdat=>open,
		ldacdat=>sample,	--generated wave samples feed both DAC channels
		rdacdat=>sample	
	);

---===SDRAM===---
URAMCTL: XSASDRAMJ	     -- XSASDRAM interface to the control module------
 generic map ( PIPE_EN => 	FALSE,
		FREQ 	=> 	FREQ,
		CLK_DIV => CLK_DIV,
		NROWS => 	NROWS,
		NCOLS  => 	NCOLS )  	
port map(
    ------ host side---------
   clk      	 => clk100,    	-- external FPGA clock in 
   rst        	=> rst_int,   	-- internal reset held high until lock, then switches to project reset.
   clk1x	   	=> masterclk,	-- divided input clock buffered and sync'ed for use by project as 50Mhz
   clk2x		=> open,	-- sync'ed 100Mhz clock
   rd        	=> hrd,       	-- host-side SDRAM read control
   wr       	 => hwr,       	-- host-side SDRAM write control
   lock	  	=> lock, 	-- valid DLL synchronized clocks indicator
   rdPending 	=> open,	-- read still in pipeline
   opBegun   	=> opBegun,   -- memory read/write begun indicator
   earlyOpBegun => open,   	-- memory read/write begun (async)
   rdDone    	=> open,      	-- memory pipelined read done indicator
   done      	=> done,	-- memory read/write done indicator
   hAddr     	=> hAddr,   	-- std_logic 24-bit host-side address from project
   hdIn      	=> hdIn,    	-- std_logic 16-bit write data from project
   hdOut    	 => hdout,   	-- std_logic 16-bit  SDRAM data output to project       
    ---- SDRAM side. These are the top level port signals------
   sclkfb 	=> sclkfb,		-- clock from SDRAM after PCB delays
   sclk		=> sclk,		-- SDRAM clock sync'ed to master clock
   cke     	=> cke,		-- SDRAM clock enable
   cs_n   	 => cs_n,		-- SDRAM chip-select
   ras_n  	 => ras_n,		-- SDRAM RAS
   cas_n   	=> cas_n,		-- SDRAM CAS
   we_n    	=> we_n,		-- SDRAM write-enable
   ba     		=> ba,			-- SDRAM bank address
   saddr   	=> saddr,		-- SDRAM address
   sdata		=> sdat,		-- SDRAM inout data bus
   dqmh   	 => dqmh,		-- SDRAM DQMH
   dqml    	=> dqml		-- SDRAM DQML
  		);			
---End of SDRAM interface module
---=====================================================

--==SMRAM==--
process (masterclk, reset, SMRAM, opbegun, done, hrd, hdout) is
begin	--RAM state machine constantly reads from memory for sine wave output
	if reset='1' then
		SMRAM<=S0;
	elsif rising_edge(masterclk) then
		case SMRAM is
			when S0=>
				bg<=("0001");
				hAddr(13 downto 0)<=std_logic_vector(accumulator(31 downto 18)); --latch address value constantly
				SMRAM<=S1;
			when S1=>
				bg<=("0010");
				--make a read request
				hrd<='1';
				SMRAM<=S2;
			when S2=>
				bg<=("0100");
				--wait for the read instruction to begin, then turn the read request low
				if opbegun='1' then
					hrd<='0';
					SMRAM<=S3;
				end if;
			when S3=>
				bg<=("1000");
				--wait for the read to finish and latch the result
				if done='1' then
					sine<=hdout;
					SMRAM<=S0;
				end if;
			when others => null;
		end case;
	end if;
end process;

--==JTAG==--
JTAG: JTAG_IFC
	port map(
		bscan=>bscan,
		dat_to_pc=>toPC,
		dat_from_pc=>fromPC
	);
------------
sample(3 downto 0)<=(others=>'0');	--pad last 4 sample bits to 0
hAddr(23 downto 14)<=(others=>'0');	--pad leading 10 address bits to 0
reset<=not swrst;
fceb<='1';
hwr<='0';									--tie write request signal low

--DEBUG SIGNALS--
toPC(63 downto 48)<=hdout;
toPC(45 downto 32)<=hAddr(13 downto 0);
toPC(29 downto 16)<=std_logic_vector(accumulator(31 downto 18));
toPC(15 downto 0)<=sine;

sig1<=hrd;
sig2<=opbegun;
sig3<=done;

end ARCHtones;