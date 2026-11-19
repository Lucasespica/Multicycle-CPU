-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- ULA de 16 bits (deu pra usar o Lab04, sem mudanças na lógica).
-- ULACtl: 000 AND, 001 OR, 010 soma, 100 sub, 110 SLT (com sinal), 111 NOR.
-- Depende de somadorCompleto.vhd.

Library ieee;
Use ieee.std_logic_1164.all;

Entity ULA is
	PORT ( A, B     : IN  std_logic_vector (15 downto 0);
	       ULACtl   : IN  std_logic_vector (2 downto 0);
	       R        : OUT std_logic_vector (15 downto 0);
	       Zero     : OUT std_logic;
	       Overflow : OUT std_logic;
	       Cout     : OUT std_logic
	);
End ULA;

Architecture logicaULA of ULA is

	-- somador/subtrator de 16 bits (ripple carry com somadorCompleto)
	signal sub      : std_logic;                        -- '1' quando precisa subtrair (SUB e SLT)
	signal bx       : std_logic_vector (15 downto 0);   -- B ou NOT B
	signal c        : std_logic_vector (16 downto 0);   -- carries: c(0)=cin, c(16)=cout
	signal soma     : std_logic_vector (15 downto 0);   -- resultado de A + bx + sub
	signal ovf_raw  : std_logic;                        -- overflow (complemento de 2) do somador
	signal slt_bit  : std_logic;                        -- '1' se A < B (com sinal)

	-- resultados das operacoes logicas
	signal r_and, r_or, r_nor : std_logic_vector (15 downto 0);
	signal r_slt              : std_logic_vector (15 downto 0);

	signal resultado : std_logic_vector (15 downto 0);
	signal eh_addsub : std_logic;                       -- '1' se a operacao e soma ou subtracao

BEGIN

	-- Subtracao: A - B = A + (NOT B) + 1
	sub <= '1' when (ULACtl = "100" or ULACtl = "110") else '0';
	bx  <= B when sub = '0' else NOT B;
	c(0) <= sub;

	somador16: for i in 0 to 15 generate
		fa: entity work.somadorCompleto
			PORT MAP (Cin => c(i), x => A(i), y => bx(i), Cout => c(i+1), soma => soma(i));
	end generate;

	-- Overflow em complemento de 2: carry que entra no MSB xor carry que sai do MSB
	ovf_raw <= c(16) XOR c(15);

	-- SLT com sinal: A < B  <=>  sinal(A-B) xor overflow
	slt_bit <= soma(15) XOR ovf_raw;
	r_slt   <= "000000000000000" & slt_bit;

	-- Operacoes logicas
	r_and <= A AND B;
	r_or  <= A OR B;
	r_nor <= NOT (A OR B);

	-- Selecao do resultado (codigos nao especificados -> 0)
	with ULACtl select
		resultado <= r_and  when "000",
		             r_or   when "001",
		             soma   when "010",
		             soma   when "100",
		             r_slt  when "110",
		             r_nor  when "111",
		             (others => '0') when others;

	R <= resultado;

	-- Flags
	Zero <= '1' when resultado = "0000000000000000" else '0';

	eh_addsub <= '1' when (ULACtl = "010" or ULACtl = "100") else '0';
	Overflow  <= ovf_raw when eh_addsub = '1' else '0';
	Cout      <= c(16)   when eh_addsub = '1' else '0';

End logicaULA;
