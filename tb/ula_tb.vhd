-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Testbench da ULA (Lab04), com 25 casos originais mais 5 casos que imitam
-- o uso da ULA dentro da CPU. Confere R, Zero, Overflow e Cout.
-- Termina sozinho (sem clock).

Library ieee;
Use ieee.std_logic_1164.all;

Entity ULA_tb is
End ULA_tb;

Architecture teste of ULA_tb is

	signal A, B, R   : std_logic_vector (15 downto 0) := (others => '0');
	signal ULACtl    : std_logic_vector (2 downto 0)  := "000";
	signal Zero, Overflow, Cout : std_logic;

BEGIN

	dut: entity work.ULA
		PORT MAP (A => A, B => B, ULACtl => ULACtl, R => R,
		          Zero => Zero, Overflow => Overflow, Cout => Cout);

	estimulos: process

		variable erros : integer := 0;

		procedure check (
			constant nome : in string;
			constant ctl  : in std_logic_vector (2 downto 0);
			constant va, vb, er : in std_logic_vector (15 downto 0);
			constant ez, eo, ec : in std_logic ) is
		begin
			ULACtl <= ctl;
			A <= va;
			B <= vb;
			wait for 10 ns;
			if (R /= er) or (Zero /= ez) or (Overflow /= eo) or (Cout /= ec) then
				report "FALHOU: " & nome severity error;
				erros := erros + 1;
			else
				report "OK: " & nome severity note;
			end if;
		end procedure;

	begin
		-- ===== AND (000) =====
		check("AND basico",         "000", x"0F0F", x"00FF", x"000F", '0','0','0');
		check("AND zero (Zero=1)",  "000", x"F0F0", x"0F0F", x"0000", '1','0','0');

		-- ===== OR (001) =====
		check("OR basico",          "001", x"F000", x"000F", x"F00F", '0','0','0');
		check("OR tudo 1",          "001", x"F0F0", x"0F0F", x"FFFF", '0','0','0');
		check("OR zero (Zero=1)",   "001", x"0000", x"0000", x"0000", '1','0','0');

		-- ===== SOMA (010) =====
		check("SOMA basica",                 "010", x"0001", x"0002", x"0003", '0','0','0');
		check("SOMA carry (Cout=1, Zero=1)", "010", x"FFFF", x"0001", x"0000", '1','0','1');
		check("SOMA overflow positivo",      "010", x"7FFF", x"0001", x"8000", '0','1','0');
		check("SOMA overflow negativo",      "010", x"8000", x"8000", x"0000", '1','1','1');
		check("SOMA overflow (8000 + FFFF)",  "010", x"8000", x"FFFF", x"7FFF", '0','1','1');
		check("SOMA neg + pos (-1 + 1)",     "010", x"FFFF", x"0001", x"0000", '1','0','1');

		-- ===== SUBTRACAO (100) =====
		check("SUB basica (Cout=1)",         "100", x"0005", x"0003", x"0002", '0','0','1');
		check("SUB resultado negativo",      "100", x"0003", x"0005", x"FFFE", '0','0','0');
		check("SUB iguais (Zero=1)",         "100", x"0005", x"0005", x"0000", '1','0','1');
		check("SUB overflow (neg - pos)",    "100", x"8000", x"0001", x"7FFF", '0','1','1');
		check("SUB overflow (pos - neg)",    "100", x"7FFF", x"FFFF", x"8000", '0','1','0');

		-- ===== SLT (110) =====
		check("SLT A<B",                     "110", x"0003", x"0005", x"0001", '0','0','0');
		check("SLT A>B",                     "110", x"0005", x"0003", x"0000", '1','0','0');
		check("SLT A=B",                     "110", x"0005", x"0005", x"0000", '1','0','0');
		check("SLT com sinal (-1 < 1)",      "110", x"FFFF", x"0001", x"0001", '0','0','0');
		check("SLT 7FFF < 8000? (nao)",      "110", x"7FFF", x"8000", x"0000", '1','0','0');
		check("SLT 8000 < 7FFF? (sim)",      "110", x"8000", x"7FFF", x"0001", '0','0','0');

		-- ===== NOR (111) =====
		check("NOR tudo 0 -> tudo 1",        "111", x"0000", x"0000", x"FFFF", '0','0','0');
		check("NOR zero (Zero=1)",           "111", x"F0F0", x"0F0F", x"0000", '1','0','0');
		check("NOR basico",                  "111", x"00FF", x"0F00", x"F000", '0','0','0');

		-- ===== Usos da ULA dentro da CPU =====
		check("CPU: PC + 1 (BUSCA2)",              "010", x"0007", x"0001", x"0008", '0','0','0');
		check("CPU: Rj + imm negativo (LD/ST -2)", "010", x"0010", x"FFFE", x"000E", '0','0','1');
		check("CPU: ADDI R0 + (-1)",               "010", x"0000", x"FFFF", x"FFFF", '0','0','0');
		check("CPU: BEQ, Ri = Rj (Zero=1)",        "100", x"1234", x"1234", x"0000", '1','0','1');
		check("CPU: BNE, Ri /= Rj (Zero=0)",       "100", x"1234", x"1235", x"FFFF", '0','0','0');

		-- ===== resumo =====
		if erros = 0 then
			report "TODOS OS TESTES PASSARAM (ula)" severity note;
		else
			report "TESTES COM FALHA (ula): " & integer'image(erros) severity failure;
		end if;
		wait;
	end process;

End teste;
