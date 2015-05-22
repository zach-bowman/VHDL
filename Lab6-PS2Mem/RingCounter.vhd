library IEEE;
use IEEE.std_logic_1164.all;

entity RingCounter is
	generic( WIDTH: integer:= 4);
	port(	clk: in std_logic
			--reset: in std_logic;
--			output: out std_logic
	);
end RingCounter;

architecture RingARCH of RingCounter is
	--signal reset: std_logic;
	signal r_reg: std_logic_vector(WIDTH-1 downto 0);
	signal r_nxt: std_logic_vector(WIDTH-1 downto 0);
	constant STATE1: STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0):=(0=>'1', OTHERS=>'0');
	constant STATERESET: STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0):=(WIDTH-1=>'1', OTHERS=>'0');
begin
	process(clk)
	begin
		if rising_edge(clk) then
			r_reg<=r_nxt;
		end if;
	end process;
	r_nxt<=STATE1 when r_reg=STATERESET else r_reg(0)&r_reg(WIDTH-1 downto 1);

end RingArch;