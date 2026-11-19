-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Dígito hexadecimal para 7 segmentos, ativo em nível baixo (seg(6..0) = g..a).
-- ESQUELETO: implementar a partir da função seg7 do Lab05 (P5).
library ieee;
use ieee.std_logic_1164.all;

entity hex7seg is
  port (
    valor : in  std_logic_vector(3 downto 0);
    seg   : out std_logic_vector(6 downto 0)
  );
end entity hex7seg;

architecture esqueleto of hex7seg is
begin
  seg <= (others => '1');   -- apagado
end architecture esqueleto;
