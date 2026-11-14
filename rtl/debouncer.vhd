-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Debounce do botão (Lab05) mais detector de borda: gera um pulso de um ciclo
-- de clk a cada aperto. botao é '1' enquanto apertado (o top inverte o KEY).
-- ESQUELETO: implementar (P5).
library ieee;
use ieee.std_logic_1164.all;

entity debouncer is
  generic (
    LIMITE : positive := 1_000_000   -- 20 ms a 50 MHz
  );
  port (
    clk   : in  std_logic;
    botao : in  std_logic;
    pulso : out std_logic
  );
end entity debouncer;

architecture esqueleto of debouncer is
begin
  pulso <= '0';
end architecture esqueleto;
