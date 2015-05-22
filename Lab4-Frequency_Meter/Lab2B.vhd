library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.MyDeclares.clk_div;
use WORK.MyDeclares.cnt_bcd;
use WORK.MyDeclares.JTAG_IFC;
use WORK.MyDeclares.bcd_ctl;
use WORK.MyDeclares.IBUFG;

entity Lab2B is 
	port(	clk50: in std_logic;		--input clock to be divided to m_reset and rclk
			sig3: in std_logic;		--unknown square wave input
			swrst:in std_logic; 	--resets the counter
			fceb: out std_logic;		--flash mempry
			lsdp: out std_logic		--overflow signal
			);
end Lab2B;

architecture ARCH of Lab2B is
	
	signal ref: std_logic; --to differentiate from signals used in bcd_ctl
	signal oneHZ: std_logic;
	signal ctl_tobcd_enb: std_logic;
	signal tclkin: std_logic;
	signal overflow: std_logic;
	----
	signal bscanSIG: std_logic_vector(3 downto 0);
	signal OUTtoPC: std_logic_vector(63 downto 0);
		alias unit: std_logic_vector(3 downto 0) is OUTtoPC(3 downto 0);
		alias tens: std_logic_vector(3 downto 0) is OUTtoPC(7 downto 4);
		alias hundreds: std_logic_vector(3 downto 0) is OUTtoPC(11 downto 8);
	signal fromPC: std_logic_vector(63 downto 0);
		alias divset: std_logic_vector(23 downto 0) is fromPC(23 downto 0);
	----
	signal actual_div: integer;
begin
	UIBUF: IBUFG
		port map(
			I=>sig3,
			O=>tclkin
		);
------------BCD_ENB-------------
	CTL: bcd_ctl
		port map(
			rclk=>ref,
			mreset=>oneHZ,
			enable=>ctl_tobcd_enb
		);
---------CLOCK DIVIDERS---------
	RCLKCLK: clk_div
		generic map(MAXD=>10000000)
		port map(
			clk=>clk50, 
			reset=>not swrst,
			div=>actual_div,
			div_clk=>ref
		);
	MRESETCLK: clk_div 
		generic map(MAXD=>50000000)
		port map(
			clk=>clk50, 
			reset=>not swrst, 
			div=>50000000,
			div_clk=>oneHZ 
		);
--------COUNTER DISPLAY--------
	BCD: cnt_bcd
		port map( 
			clk=>tclkin,
			m_reset=>oneHZ,
			bcd_enb=>ctl_tobcd_enb,
			full=>overflow,
			bcd_u=>unit,
			bcd_d=>tens,
			bcd_h=>hundreds
		);
-----------JTAG-----------------
	JTAG: JTAG_IFC
		port map(
			bscan=>bscanSIG,
			dat_to_pc=>OUTtoPC,
			dat_from_pc=>fromPC
		);
---------------------------------
-------SIGNAL ASSIGNMENTS--------
---------------------------------
actual_div<=to_integer(unsigned(divset));
fceb<='1';
OUTtoPC(63 downto 12)<=(others=>'0');
fromPC(63 downto 24)<=(others=>'0');
lsdp<=overflow;
end ARCH;