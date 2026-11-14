-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Extensão de sinal do imediato: 6 para 16 bits.
-- ESQUELETO: implementar (P3).
library ieee;
use ieee.std_logic_1164.all;

entity ext_sinal is
  port (
    imm : in  std_logic_vector(5 downto 0);
    ext : out std_logic_vector(15 downto 0)
  );
end entity ext_sinal;

architecture esqueleto of ext_sinal is
begin
  ext <= (others => '0');
end architecture esqueleto;
