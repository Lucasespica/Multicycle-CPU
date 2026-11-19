-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Extensão de sinal do imediato: 6 para 16 bits.
-- O bit 5 (sinal, em complemento de 2) é copiado para os bits 15..6, de modo
-- que o valor numérico se mantém: 011111 (+31) -> 0x001F, 100000 (-32) -> 0xFFE0.
-- Circuito puramente combinacional (só fios, nenhuma porta lógica).
library ieee;
use ieee.std_logic_1164.all;

entity ext_sinal is
  port (
    imm : in  std_logic_vector(5 downto 0);
    ext : out std_logic_vector(15 downto 0)
  );
end entity ext_sinal;

architecture comportamento of ext_sinal is
begin
  ext(15 downto 6) <= (others => imm(5));  -- replica o bit de sinal
  ext(5 downto 0)  <= imm;                 -- parte baixa sem mudança
end architecture comportamento;
