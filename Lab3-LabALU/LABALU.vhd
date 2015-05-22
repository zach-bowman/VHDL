library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.mydeclares.all;

entity LABALU is									--Port signals for top level module are to outside world
	port	(sw1:					in std_logic;	--input from xst push button
			 swrst:				in std_logic;	--input from xst reset push button
			 clk50:           in std_logic;	--clock
			 
			 bg9:				out std_logic; --JTAG
          bg8:				out std_logic; --carry
			 
--			 lsdp:				out std_logic;	--left dec. point
			 fceb:            out std_logic	--flash not-select
			);
   end LABALU;
----------------------------------------------------------------------------------------
architecture Behavioral of LABALU is

constant YES: std_logic:= '1';
constant NO:  std_logic:= '0'; 

signal clk10toc: std_logic; 
--signal mode_in: std_logic;

signal mode_out: std_logic_vector(2 downto 0); 
signal a_out: std_logic_vector(15 downto 0);
signal b_out: std_logic_vector(15 downto 0);

signal toPC: std_logic_vector(63 downto 0);
signal bscanIN: std_logic_vector(3 downto 0);

signal fromPC: std_logic_vector(63 downto 0);
 alias RegA: std_logic_vector(15 downto 0) is fromPC(15 downto 0);
 alias RegB: std_logic_vector(15 downto 0) is fromPC(31 downto 16);
 alias RegMode: std_logic_vector(2 downto 0) is fromPC(34 downto 32);

----------------------------------------------------------------------------------------
begin
fceb<='1';
toPC(63 downto 51) <= (others => '0');
toPC(31 downto 16) <= RegB;
toPC(47 downto 32) <= RegA;
toPC(50 downto 48) <= RegMode;

bg9 <= bscanIN(2);
-------------------------------------------
JTAG: JTAG_IFC
   port map(bscan=>open,
      dat_to_pc=>toPC,
      dat_from_pc=>fromPC
   );
-------------------------------------------
MY_GenClks: GenClks
	Port Map(
		clk50=>clk50,
		reset=>not swrst,
		clk10m=>clk10toc,
		clk16hz=>open
		);
-------------------------------------------
RA: RegN generic map(NBITS=>16) 
		Port Map(
			CLK	=> clk10toc,
			CE		=> not sw1,
			CLR	=> not swrst,
			D	   => RegA,
			Q	 	=> a_out
			);
-------------------------------------------
RB: RegN generic map(NBITS=>16) 
		Port Map(
			CLK	=> clk10toc,
			CE		=> not sw1,
			CLR	=> not swrst,
			D	   => RegB,
			Q	 	=> b_out
			);
-------------------------------------------
IR: RegN generic map(NBITS=>3) 
		Port Map(
			CLK	=> clk10toc,
			CE		=> YES,
			CLR	=> not swrst,
			D	   => RegMode,
			Q	 	=> mode_out
			);
-------------------------------------------
ALUNA: ALUNA generic map(NBITS=>16) 
		Port Map( 
		   alu_a		=> a_out,
			alu_b 	=> b_out,
			mode     => mode_out,
			alu_out 	=> toPC(15 downto 0),
			alu_ovfl => bg8
			);
-------------------------------------------

end Behavioral;

