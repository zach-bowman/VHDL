--Example package for 424 class. Contains examples of declarations and functions.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--For correct simulation of a module that instantiates a XILINX library primitive, 
--  add the following library declaration to the code.
--library UNISIM;
--use UNISIM.VComponents.all;

---*******************************
PACKAGE MyDeclares is
---*******************************
constant YES:		std_logic := '1';	--examples of declaring a constant.
constant NO:		std_logic := '0';
constant HI:  	   	std_logic := '1';	--Such entries can be used in signal assignments for readability
constant LO:		std_logic := '0';
constant DIV16HZ:	integer   := 3124999;	--divisor for 16hz from 50Mhz.
----example of a ROM implementation-----------------
type ROM16X4 is array (0 to 11) of std_logic_vector (3 downto 0); --define a new signal type
constant LUT_L: ROM16X4:=	("1000", "1101","0010","1100", --initilize a constant of that type
"0100","0101","0100","0010","1101","0000","0100","0001");
-----Example of a user defined array type--------------
type EIGHT_BYTE is array (1 to 8) of std_logic_vector(7 downto 0); --used in USB interface
----some function examples------------------------------
function LOG2(v: in natural) return natural;
function UNSIGNED_TO_STDV (ARG: unsigned) return std_logic_vector;
function STDV_TO_UNSIGNED (ARG: std_logic_vector) return unsigned;
function ENCODE (vect: std_logic_vector) return integer;
function LEDHi(xa: std_logic_vector(3 downto 0)) return std_logic_vector;
function  find_lfsr_decode(steps: integer) return  std_logic_vector;
function toASCII(make: std_logic_vector(7 downto 0)) return std_logic_vector;
function toCAPS(make: std_logic_vector(7 downto 0)) return std_logic_vector;
function DDS_INCR(fout: real) return signed;
-----------Xilinx library primitives declarations------
component BUFG port(I: in std_logic; O: out std_logic); end component;
component IBUFG port(I: in std_logic; O: out std_logic); end component;
component IBUF port(I: in std_logic; O: out std_logic); end component;

-----------User VHDL component declarations-----------
component fulladd   -- single bit full adder cell by structure
  port (I1: in std_logic;
        I2: in std_logic;
        cin: in std_logic;
        sum: out std_logic;
        cout: out std_logic );
  end component;
---------------------------------
component Toggle1   
  port (S: in std_logic; 	--S is usually an Xstend pushbutton(active low).
        reset: in std_logic; 	--reset is NOT-swrst pushbutton
        Q: out std_logic );   	--output state toggles on button push
end component;
---------------------------------
component ToggleD   
  port (S: in std_logic; 	--S is usually an Xstend pushbutton(active low).
        clk50: in std_logic; --input clock for clock divider
		reset: in std_logic; 	--reset is NOT-swrst pushbutton
        Q: out std_logic );   	--output state toggles on button push
end component;
---------------------------------
component DFACE 
  port( D: in std_logic; --Data input
	C: in std_logic; --Clock input
	CE:in std_logic; --Active-high clock enable
	CLR: in std_logic; --Active-high reset
	Q: out std_logic --Data out
	); end component;
-----------------------------
component GenClks is		--clock generation module for 520.424 class projects
   port (clk50: in std_logic;
  	reset: 	in std_logic;
  	clk10m: out std_logic;
	clk16hz: out std_logic );
end component;
-----------------------------
component Virt_ledc  is		
port(clk50: 	in 	std_logic;			--50mhz clk in 
	vclk:		in	std_logic;			--bit clock in from parallel port
	reset: 		in 	std_logic; 
	d1,d2,d3,d4: in std_logic_vector(3 downto 0);	--4 hex values for display
	pps: 		out std_logic_vector(5 downto 3)	--data out to parallel port-S
	);  end component;
-----------------------------
component PortD200  is	--interface to port-D for xsa200+ uses only ppd(5 4 3 2 0)
port(clk50:in 	std_logic;				--50 Mhz external clock
	ppd: 	in  std_logic_vector(4 downto 0);  --Port-D data in
	reset: 	in  std_logic;
	pdbyte:	out std_logic_vector(7 downto 0)  --port-D byte written by PC as 2 nibbles
	);  end component;
-----------------------------
component JTAG_IFC  is	--interface to port-D for xsa200+ uses only ppd(5 4 3 2 0)
port(--clk100:		in 	std_logic;		--external clock for tclk sync must be 100Mhz  (not currently used)
	bscan: 			out  	std_logic_vector(3 downto 0);  --boundary scan debug
	dat_to_pc: 		in  	std_logic_vector(63 downto 0);	--data to bscan tdo
	dat_from_pc: 	out  	std_logic_vector(63 downto 0)  --data from bscan tdi
	);  end component;
-----------------------------
component LED_DCD	--LED decoder to drive active-high, 7 segment XESS LED.
 port( xa: in std_logic_vector(3 downto 0); --input nibble
	xs: out std_logic_vector(6 downto 0) --output signal to drive LED digit.
	);
end component;
-----------------------------
component ALU1A		--single bit ALU cell, version A
	port(	a:	in std_logic;  --input bit a
		b:	in std_logic;  --input bit b
		cin:	in std_logic;  --carry into bit
		mode:	in std_logic_vector(2 downto 0); --ALU mode control
		output:	out std_logic;	--output data bit
		cout:	out std_logic	--output carry
		);
end component;
-----------------------------
component ALUNA		--N-bit, 8 function ALU, version A
 generic(NBITS: natural:=8);	--generic ALU width
	port(	alu_a:	in std_logic_vector(NBITS-1 downto 0);
		alu_b:	in std_logic_vector(NBITS-1 downto 0);
		mode:	in std_logic_vector(2 downto 0); --ALU mode control
		alu_out:out std_logic_vector(NBITS-1 downto 0); --output
		alu_ovfl: out std_logic --overflow indicator
		);
end component;
-----------------------------
component RegN	--N-bit DFF register with clear and enable
  generic(NBITS: natural:=8);
	port(	c:	in std_logic;
		ce:	in std_logic;
		clr:	in std_logic;
		d:	in std_logic_vector(NBITS-1 downto 0);
		q:	out std_logic_vector(NBITS-1 downto 0)
	);
end component;
------------------------------
component clk_div
	generic(MAXD: natural:=5);		--upper bound on divisor
	port( 	clk:	in std_logic;	--input clock
		reset:	in std_logic;	--asynchronous counter reset
		div:	in integer range 0 to MAXD;	--divisor magnitude
		div_clk:out std_logic
	);
end component;
-------------------------------
component cnt_bcd
	port( clk:	in std_logic;		--input clock being measured
			m_reset:in std_logic;		--m_reset initializes for new bcd measurement
			bcd_enb:in std_logic;		--counter control starts and stops measurement
			full:	out std_logic;		--overflow indicator goes high when count=all 9's
			bcd_u:	out std_logic_vector(3 downto 0);	--bcd outputs of any desired length fr display
			bcd_d:	out std_logic_vector(3 downto 0);
			bcd_h:	out std_logic_vector(3 downto 0)
			);
end component;
-------------------------------
component bcd_ctl
	port( 	rclk: in std_logic;
			enable: out std_logic;
			mreset: in std_logic
	);
end component;
-------------------------------
component RingCounter
	generic( WIDTH: integer:= 4);
	port(	clk: in std_logic;
			reset: in std_logic;
			output: out std_logic
	);
end component;
-------------------------------
component PRN10
	port( clk: in std_logic;		--bit rate clock. Shift on leading edge
			reset: in std_logic;
			enable: in std_logic;	--enable signal low delays code by stopping shift
			code: out std_logic;		--output code bit
			sync: out std_logic		--indicates that the current state is all zeroes
	);
end component;
-------------------------------
component PRN64
	port( clk: in std_logic;		--bit rate clock. Shift on leading edge
			code: out std_logic		--output code bit
	);
end component;
-------------------------------
component voice_detector
	port(
		clk: 	in std_logic;
		reset:	in std_logic;
		sig_in:	in std_logic_vector(15 downto 0);
		voice_detected: out std_logic
	);
end component;
-------------------------------
component ircontrol
	port(
		carrier_clk: in std_logic;
--		pulse_clk: in std_logic;
		reset: in std_logic;
		enable: in std_logic;
	--	address: in std_logic_vector(15 downto 0);
	--	command: in std_logic_vector(15 downto 0);
		irout: out std_logic
	);
end component;
-------------------------------
component xcorr
	port(
		clk:	in std_logic;	--clock signal
		reset:	in std_logic;	--asynchronous reset
		enable:	in std_logic;	--begin computation
		addr1:	in std_logic_vector(23 downto 0);	--pointer to beginning of first frame
		addr2:	in std_logic_vector(23 downto 0);	--pointer to beginning of second frame
		size:		in integer;	--size of frames
		donex:	out std_logic;	--signals the end of the computation
		peak:		out integer:=0		--xcorr peak value
	);

end component;

---********************************************************
END PACKAGE MyDeclares; 
---********************************************************

--A Package body includes functions or procedures that a user or project team has 
--developed to handle their own signal types and processes.
--The below examples won't be used in the class, but let you see how a function is defined.
--Later you'll write your own function, and add it to the package body for use in your projects.
---***************************************
PACKAGE BODY MyDeclares  is	 
---***************************************
--These functions are included as examples.
function LOG2(v: in natural) return natural is	--return Log2 of arg.
	variable n: natural;
	variable logn: natural;
begin
	n := 1;
	for i in 0 to 128 loop
		logn := i;
		exit when (n>=v);
		n := n * 2;
	end loop;
	return logn;
end function log2;
-----------------------------------------------------
function STDV_TO_UNSIGNED (ARG:std_logic_vector) return UNSIGNED is
 -- Convert std_logic_vector to unsigned vector
variable result: unsigned(ARG'HIGH downto ARG'LOW);
begin
for i in ARG'HIGH downto ARG'LOW loop --notice, attributes are used for generality
	result(i):=ARG(i);
end loop;
return result;
end function STDV_TO_UNSIGNED;
-----------------------------------------------------
function UNSIGNED_TO_STDV (ARG:UNSIGNED) return STD_LOGIC_VECTOR is
 -- Convert unsigned vector to std_logic_vector
variable result: std_logic_vector(ARG'HIGH downto ARG'LOW);
begin
for i in ARG'HIGH downto ARG'LOW loop
	result(i):= ARG(i);
end loop;
return result;
end UNSIGNED_TO_STDV;
-----------------------------------------------------
function ENCODE (vect: std_logic_vector) return integer is
--Assumes vect has elements M downto 0, returns integer of range 0 to M.
--The returned value is the largest subscript of any element in vect that is a '1'.
variable numlit: integer range 0 to 1+vect'HIGH;
begin
numlit:=0;
for j in vect'HIGH downto 0 loop
    if vect(j)='1' then
		if numlit=0 then
        	numlit:= j;
		else
			numlit:=1+vect'HIGH;
 		    exit;
		end if;
     end if;
end loop;
return numlit;
end ENCODE;
-----------------------------------------------
function LEDHi (xa: std_logic_vector(3 downto 0)) return std_logic_vector is
variable xs: std_logic_vector(6 downto 0);
begin
	case xa is
		when "0001"=>xs:="0010010";
		when "0010"=>xs:="1011101";
		when "0011"=>xs:="1011011";
		when "0100"=>xs:="0111010";
		when "0101"=>xs:="1101011";
		when "0110"=>xs:="1101111";
		when "0111"=>xs:="1010010";
		when "1000"=>xs:="1111111";
		when "1001"=>xs:="1111011";
		when "1010"=>xs:="1111110";
		when "1011"=>xs:="0101111";
		when "1100"=>xs:="1100101";
		when "1101"=>xs:="0011111";
		when "1110"=>xs:="1101101";
		when "1111"=>xs:="1101100";
		when others=>xs:="1110111";
		end case;
	return xs;
end LEDHi;
------------------------------------
function  find_lfsr_decode (steps: in integer)  return  std_logic_vector is
   variable  reg: std_logic_vector(13 downto 1);
   variable  xnorred: std_logic;
begin 
	reg:=  (others=>'0');
	for i in 1 to steps loop
     xnorred:=  reg(13) xnor reg(4) xnor reg(3) xnor reg(1);
     reg:=  reg(reg'HIGH - 1 downto reg'LOW) & xnorred;  --shift in new lsb
	end loop;
return reg;        --return final state as a std_logic_vector
end find_lfsr_decode;
----------------------------------------------
function toASCII(make: std_logic_vector(7 downto 0)) return std_logic_vector is
variable ascii: std_logic_vector(7 downto 0);
begin
	case make is
		when "00011100"=>ascii:="01100001"; --a
		when "00110010"=>ascii:="01100010"; --b
		when "00100001"=>ascii:="01100011"; --c
		when "00100011"=>ascii:="01100100"; --d
		when "00100100"=>ascii:="01100101"; --e
		when "00101011"=>ascii:="01100110"; --f
		when "00110100"=>ascii:="01100111"; --g
		when "00110011"=>ascii:="01101000"; --h
		when "01000011"=>ascii:="01101001"; --i
		when "00111011"=>ascii:="01101010"; --j
		when "01000010"=>ascii:="01101011"; --k
		when "01001011"=>ascii:="01101100"; --l
		when "00111010"=>ascii:="01101101"; --m
		when "00110001"=>ascii:="01101110"; --n
		when "01000100"=>ascii:="01101111"; --o
		when "01001101"=>ascii:="01110000"; --p
		when "00010101"=>ascii:="01110001"; --q
		when "00101101"=>ascii:="01110010"; --r
		when "00011011"=>ascii:="01110011"; --s
		when "00101100"=>ascii:="01110100"; --t
		when "00111100"=>ascii:="01110101"; --u
		when "00101010"=>ascii:="01110110"; --v
		when "00011101"=>ascii:="01110111"; --w
		when "00100010"=>ascii:="01111000"; --x
		when "00110101"=>ascii:="01111001"; --y
		when "00011010"=>ascii:="01111010"; --z
		when "11110000"=>ascii:="11110000"; --break code F0
		when "11100000"=>ascii:="11100000"; --break code E0
		
		when others=>ascii:="00000000";
		end case;
	return ascii;
end toASCII;
----------------------------------------------
function toCAPS(make: std_logic_vector(7 downto 0)) return std_logic_vector is
variable ascii: std_logic_vector(7 downto 0);
begin
	case make is
		when "00011100"=>ascii:="01000001"; --A
		when "00110010"=>ascii:="01000010"; --B
		when "00100001"=>ascii:="01000011"; --C
		when "00100011"=>ascii:="01000100"; --D
		when "00100100"=>ascii:="01000101"; --E
		when "00101011"=>ascii:="01000110"; --F
		when "00110100"=>ascii:="01000111"; --G
		when "00110011"=>ascii:="01001000"; --H
		when "01000011"=>ascii:="01001001"; --I
		when "00111011"=>ascii:="01001010"; --J
		when "01000010"=>ascii:="01001011"; --K
		when "01001011"=>ascii:="01001100"; --L
		when "00111010"=>ascii:="01001101"; --M
		when "00110001"=>ascii:="01001110"; --N
		when "01000100"=>ascii:="01001111"; --O
		when "01001101"=>ascii:="01010000"; --P
		when "00010101"=>ascii:="01010001"; --Q
		when "00101101"=>ascii:="01010010"; --R
		when "00011011"=>ascii:="01010011"; --S
		when "00101100"=>ascii:="01010100"; --T
		when "00111100"=>ascii:="01010101"; --U
		when "00101010"=>ascii:="01010110"; --V
		when "00011101"=>ascii:="01010111"; --W
		when "00100010"=>ascii:="01011000"; --X
		when "00110101"=>ascii:="01011001"; --Y
		when "00011010"=>ascii:="01011010"; --Z
		when "11110000"=>ascii:="11110000"; --break code F0
		when "11100000"=>ascii:="11100000"; --break code E0
		
		when others=>ascii:="00000000";
		end case;
	return ascii;
end toCAPS;
-------------------------------------------------
function DDS_INCR(fout: real) return signed is
begin
return to_signed(integer(fout*2.0**32/50_000000.0),32);
end DDS_INCR;
-------------------------------------------------
----*****************************************************
END PACKAGE BODY MyDeclares; 
----*****************************************************

