library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.MyDeclares.all;
use WORK.sdramj.all;			--sdramcntl package for XSA brds.

entity LabPS2Mem is
	port( clk100: 	in std_logic;	
			swrst: 	in std_logic;
			ps2_dat: in std_logic;	--data from keyboard
			ps2_clk: in std_logic;	--ps2 clock signal
			fceb: 	out std_logic;
				--DEBUG SIGNALS--
			lsdp: 	out std_logic;	
			bg: 		out std_logic_vector(9 downto 0);
			rs: 		out std_logic_vector(6 downto 0);
			ls: 		out std_logic_vector(6 downto 0);
			------------SDRAM I/O connections------------ 
			sclkfb:	in std_logic;				-- feedback SDRAM clock with PCB delays
			sclk:		out std_logic;				-- clock to SDRAM
			cke: 		out std_logic;				-- SDRAM clock-enable
			cs_n: 	out std_logic;				-- SDRAM chip-select	
			ras_n: 	out std_logic;				-- SDRAM RAS
			cas_n: 	out std_logic;				-- SDRAM CAS
			we_n: 	out std_logic;				-- SDRAM write-enable
			ba: 		out std_logic_vector( 1 downto 0);	-- SDRAM bank-address
			saddr: 	out std_logic_vector(12 downto 0);	-- SDRAM address bus
			sdat: 	inout std_logic_vector(15 downto 0);	-- data bus to SDRAM
			dqmh: 	out std_logic;				-- SDRAM DQMH
			dqml: 	out std_logic				-- SDRAM DQML
	);
end LabPS2Mem;

architecture PS2_ARCH of LabPS2Mem is
	type SM_Type is (S0,S1,S2,S3,S4,S5);	--state machines for ps2 protocol and memory access
	signal SMKBRD,SMRAM: SM_Type;
	
	signal ps2clk: std_logic;
	signal reset: std_logic;
	signal newcode: std_logic; 						--will go high to signify that a new code has been sampled
	signal state: unsigned(3 downto 0); 			--debug, this shows the state of the RAM
	signal state2: unsigned(3 downto 0); 			--debug, this shows the state of the PS2 SM

	signal parity:		 std_logic; 						 --parity signal
	signal ascii:		 std_logic_vector(7 downto 0); --the decoded ascii code
	signal ring:		 std_logic_vector(10 downto 0):="00000000001"; --ring counter
	signal ring_nxt: 	 std_logic_vector(10 downto 0);--next state ring
	CONSTANT RESETRING:std_logic_vector(10 downto 0):="00000000001"; --resetted ring counter state
	
	signal keycode:	std_logic_vector(10 downto 0);	--start, stop, parity, and byte from the keyboard
	signal breakcode1: std_logic_vector(10 downto 0);	--the first break code
	signal breakcode2: std_logic_vector(10 downto 0);	--the second break code
	
	constant F0: std_logic_vector(7 downto 0):="11110000"; --break code constants
	constant E0: std_logic_vector(7 downto 0):="11100000";
	---======= SDRAM generics ==========	
	constant FREQ 	: integer 	:= 100_000;
	constant CLK_DIV	: real	:= 2.0;    	--uses 100 Mhz input clk
	constant NROWS	: integer	:= 8192;
	constant NCOLS	: integer	:= 512;
	----JTAG SIGNALS----
	signal bscan: std_logic_vector(3 downto 0);
	signal toPC: std_logic_vector(63 downto 0);
	signal fromPC: std_logic_vector(63 downto 0);
begin
---===SDRAM===---
URAMCTL: XSASDRAMJ	     -- XSASDRAM interface to the control module------
 generic map(	
	PIPE_EN =>	FALSE,
	FREQ 	=>	FREQ,
	CLK_DIV => CLK_DIV,
	NROWS =>	NROWS,
	NCOLS  => NCOLS )  	
port map(
	---host side---
   clk      	=> clk100,  -- external FPGA clock in 
   rst        	=> rst_int, -- internal reset held high until lock, then switches to project reset.
   clk1x	   	=> masterclk,-- divided input clock buffered and sync'ed for use by project as 50Mhz
   clk2x			=> open,		-- sync'ed 100Mhz clock
   rd        	=> hrd,     -- host-side SDRAM read control
   wr       	=> hwr,     -- host-side SDRAM write control
   lock	  		=> lock, 	-- valid DLL synchronized clocks indicator
   rdPending 	=> open,		-- read still in pipeline
   opBegun   	=> opBegun, -- memory read/write begun indicator
   earlyOpBegun=> open,   	-- memory read/write begun (async)
   rdDone    	=> open,    -- memory pipelined read done indicator
   done      	=> done,		-- memory read/write done indicator
   hAddr     	=> hAddr,   -- std_logic 24-bit host-side address from project
   hdIn      	=> hdIn,    -- std_logic 16-bit write data from project
   hdOut    	=> hdout,   -- std_logic 16-bit  SDRAM data output to project       
	---SDRAM side. These are the top level port signals------
   sclkfb 		=> sclkfb,	-- clock from SDRAM after PCB delays
   sclk			=> sclk,		-- SDRAM clock sync'ed to master clock
   cke     		=> cke,		-- SDRAM clock enable
   cs_n   	 	=> cs_n,		-- SDRAM chip-select
   ras_n 		=> ras_n,	-- SDRAM RAS
   cas_n   		=> cas_n,	-- SDRAM CAS
   we_n    		=> we_n,		-- SDRAM write-enable
   ba     		=> ba,		-- SDRAM bank address
   saddr   		=> saddr,	-- SDRAM address
   sdata			=> sdat,		-- SDRAM inout data bus
   dqmh   	 	=> dqmh,		-- SDRAM DQMH
   dqml    		=> dqml		-- SDRAM DQML
);			
		
--==FIRST STATE MACHINE: SMKBRD==--
BRD: process (masterclk, ps2_dat, ps2clk, reset, SMKBRD) is
begin
	if reset='1' then
		--reset everything
		keycode<=(others=>'0');
		breakcode1<=(others=>'0');
		breakcode2<=(others=>'0');
		ring<=RESETRING;
		parity<='0';
		newcode<='0';
		SMKBRD<=S0;	--S0 as explicit reset state makes this the power-up state.
	elsif falling_edge(ps2clk) then
		case SMKBRD is
			when S0=>
				state2<="0000";
				newcode<='0';
				parity<='0';
				ring<=RESETRING;
				SMKBRD<=S1;
			when S1=>
				state2<="0001"; --for debug
				if ring_nxt(0)='1' then
					SMKBRD<=S2;		--shift in a bit until you get 11
					ring<=RESETRING;
				else
					ring<=ring_nxt;--circular rotate left
					keycode<=ps2_dat & keycode(10 downto 1); --shift keycode in from the left
					parity<=ps2_dat xor parity; --calculate parity, including the start and stop bits shouldn't matter
				end if;
			when S2=>
				state2<="0010"; --for debug
				if keycode(8 downto 1)=F0 or keycode(8 downto 1)=E0 then --is it a break code?
					SMKBRD<=S3;
				elsif keycode(9)=parity then	--test for validity
					newcode<='1';					--if ok, newcode goes high
					SMKBRD<=S0;
				else
					SMKBRD<=S0;	--otherwise, trash the keycode, return to start
				end if;
			when S3=>
				state2<="0011"; --for debug
				if ring_nxt(0)='1' then
					SMKBRD<=S4;	--shift in a bit until you get 11
				else
					ring<=ring_nxt; --circular rotate left
					breakcode1<=ps2_dat & breakcode1(10 downto 1);	--grab the first break code
					SMKBRD<=S3;
				end if;
			when S4=>
				state2<="0100";
				if ring_nxt(0)='1' then
					SMKBRD<=S0;		--shift in a bit until you get 11
				else
					ring<=ring_nxt;--circular rotate left
					breakcode2<=ps2_dat & breakcode2(10 downto 1); --grab the second break code
					SMKBRD<=S4;	
				end if;
			when others => null;
		end case;
	end if;
end process BRD;
--NEXT-STATE LOGIC--
ring_nxt<=ring(9 downto 0) & ring(10);

--==SECOND STATE MACHINE: SMRAM==--
RAM: process (masterclk, reset, SMRAM, newcode) is
begin
	if reset='1' then
		rst_int<='1';
		haddr<=(others=>'0');
		SMRAM<=S0;
	elsif rising_edge(masterclk) then
		case SMRAM is
			when S0=> 
				state<="0000"; 		--for debug
				if newcode='1' then	--wait for newcode to go high
					hwr<='1';			--make a write request
					hdin(7 downto 0)<=toASCII(keycode(8 downto 1)); --latch the ascii code
					SMRAM<=S1;
				end if;
			when S1=>
			state<="0001"; 			--for debug
				if opbegun='1' then	--wait for opbegun to go high
					hwr<='0';			--turn off the write request, it already happened
					haddr<=std_logic_vector(unsigned(haddr)+1); --increment address
					SMRAM<=S2;
				end if;
			when S2=>
				state<="0010"; 		--for debug
				if newcode='0' then	--wait for newcode to go low, then restart
					SMRAM<=S0;
				end if;
			when others => null;
		end case;
	end if;
end process RAM;
	-----==JTAG==-----
	JTAG: JTAG_IFC
		port map(
			bscan=>bscan,
			dat_to_pc=>toPC,
			dat_from_pc=>fromPC
		);
---===DEBUG SIGNALS===---
bg<=keycode(9 downto 0);
toPC(7 downto 0)<=toASCII(keycode(8 downto 1));
toPC(15 downto 8)<=breakcode1(8 downto 1);
toPC(23 downto 16)<=breakcode2(8 downto 1);
toPC(63 downto 40)<=haddr;
rs<=ledHI(std_logic_vector(state));
ls<=ledHI(std_logic_vector(state2));
lsdp<=newcode;
-------------------------
reset<=not swrst;
fceb<='1';
hrd<='0';
hdin(15 downto 8)<=(others=>'0');
ps2clk<=ps2_clk;
ascii<=toASCII(keycode(8 downto 1));

end PS2_ARCH;	