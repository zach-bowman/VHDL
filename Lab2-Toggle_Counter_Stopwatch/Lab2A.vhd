library IEEE;
use IEEE.std_logic_1164.all;
library UNISIM;
use UNISIM.VComponents.all;

use WORK.MyDeclares.GenClks;
use WORK.MyDeclares.Toggle1;
use WORK.MyDeclares.LED_DCD;


entity Lab2A is		--top level for toggle counter.
  port( clk50:	in std_logic;	--external 50MHz clock.
	sw1:	in std_logic;
	swrst:in std_logic;	--signals from XST board buttons
	rs:	out std_logic_vector(6 downto 0); --out to XST LED's-Right
	ls:	out std_logic_vector(6 downto 0); --Left
	fceb:	out std_logic;	--flash disable
	bg:	out std_logic_vector(7 downto 0) --bargraph LED
	);
end Lab2A;

architecture Lab2A_ARCH of Lab2A is
	signal clk16_toclk: std_logic;
	signal bit_toxaleft: std_logic_vector(3 downto 0);
	signal bit_toxaright: std_logic_vector(3 downto 0);
	signal Q_tocenb: std_logic;
	signal bit_section: std_logic_vector(15 downto 0);
	signal open_bits: std_logic_vector(7 downto 0);
	---------------------
	component TCount16 
		port(clk:	in std_logic;	--clock input for LSB
				cenb:	in std_logic;	--active high clock enable for LSB
				reset:in std_logic;	--asynchronous clear of entire counter
				bits:	out std_logic_vector(15 downto 0)	--counter state
				); 
	end component;
	---------------------
	begin	
		Left_LED_DCD: LED_DCD 
			port map(xa=>bit_toxaleft,
						xs=>ls); --connect bits 8-11 to left decoder and left LED
		------------------------
		Right_LED_DCD: LED_DCD 
			port map(xa=>bit_toxaright,
						xs=>rs); --connect bits 4-7 to right decoder and right LED
		------------------------
		ZACH_GenClks: GenClks 
			port map(clk50=>clk50, 
						reset=>not swrst,
						clk10m=>open,
						clk16hz=>clk16_toclk);
		------------------------				
		ZACH_TCount16: TCount16 
			port map(clk=>clk16_toclk,
						cenb=>Q_tocenb,
						reset=>not swrst,
						bits=>bit_section);
		------------------------				
		ZACH_Toggle1: Toggle1 
			port map(S=>sw1, 
						reset=>not swrst, 
						Q=>Q_tocenb); 
		------------------------
		open_bits(3 downto 0)<=bit_section(3 downto 0);
		bit_toxaright<=bit_section(7 downto 4);
		bit_toxaleft<=bit_section(11 downto 8);
		open_bits(7 downto 4)<=bit_section(15 downto 12);
		bg(3 downto 0)<=bit_toxaright;
		bg(7 downto 4)<=bit_toxaleft;
		------------------------
		fceb<='1'; --disable XSA flash memory
end Lab2A_ARCH;