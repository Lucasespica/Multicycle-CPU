-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- ULA de 16 bits (Lab04). ULACtl: 000 AND, 001 OR, 010 soma, 100 sub, 110 SLT, 111 NOR.
-- ESQUELETO: substituir pela ULA do Lab04 (P3).
library ieee;
use ieee.std_logic_1164.all;

entity ULA is
  port (
    A        : in  std_logic_vector(15 downto 0);
    B        : in  std_logic_vector(15 downto 0);
    ULACtl   : in  std_logic_vector(2 downto 0);
    R        : out std_logic_vector(15 downto 0);
    Zero     : out std_logic;
    Overflow : out std_logic;
    Cout     : out std_logic
  );
end entity ULA;

architecture esqueleto of ULA is
begin
  R        <= (others => '0');
  Zero     <= '0';
  Overflow <= '0';
  Cout     <= '0';
end architecture esqueleto;
