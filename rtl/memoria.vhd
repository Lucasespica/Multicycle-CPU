-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Memória única de 4096 x 16 (programa e dados), inicializada por ARQ_MIF.
-- Endereço registrado na borda de clock; saída q não registrada; grava se wren = '1'.
-- ESQUELETO: implementar com altsyncram ou o IP "RAM: 1-PORT" (P4).
library ieee;
use ieee.std_logic_1164.all;

entity memoria is
  generic (
    ARQ_MIF : string := "../mif/final.mif"
  );
  port (
    clock   : in  std_logic;
    wren    : in  std_logic;
    address : in  std_logic_vector(11 downto 0);
    data    : in  std_logic_vector(15 downto 0);
    q       : out std_logic_vector(15 downto 0)
  );
end entity memoria;

architecture esqueleto of memoria is
begin
  q <= (others => '0');
end architecture esqueleto;
