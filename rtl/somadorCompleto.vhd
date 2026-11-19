-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Somador completo de 1 bit (Lab04). Usado 16 vezes pela ULA, em cadeia
-- (ripple carry): o Cout de um bit é o Cin do bit seguinte.

Library ieee;
Use ieee.std_logic_1164.all;

Entity somadorCompleto is
	PORT( Cin, x, y : IN std_logic;
			Cout, soma: OUT std_logic
	);
End somadorCompleto;

Architecture logicaSomCompleto of somadorCompleto is
	
	BEGIN 
	soma <= x XOR y XOR Cin;
	Cout <= (x AND y) OR (x AND Cin) OR (y AND Cin);
	
End logicaSomCompleto;
