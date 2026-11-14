-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Banco de 8 registradores de 16 bits. Leitura combinacional; escrita na borda
-- quando en = '1' e RegWrite = '1'. R0 vale sempre 0. rst assíncrono zera tudo.
-- ESQUELETO: implementar (P3).
library ieee;
use ieee.std_logic_1164.all;

entity banco_regs is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    en       : in  std_logic;
    RegWrite : in  std_logic;
    ra1      : in  std_logic_vector(2 downto 0);
    ra2      : in  std_logic_vector(2 downto 0);
    wa       : in  std_logic_vector(2 downto 0);
    wd       : in  std_logic_vector(15 downto 0);
    rd1      : out std_logic_vector(15 downto 0);
    rd2      : out std_logic_vector(15 downto 0)
  );
end entity banco_regs;

architecture esqueleto of banco_regs is
begin
  rd1 <= (others => '0');
  rd2 <= (others => '0');
end architecture esqueleto;
