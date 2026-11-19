-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Entidade de topo da DE2-115. KEY0 = passo (en), KEY3 = reset, SW17 escolhe RDM ou ULA.
-- HEX0-3 = PC, HEX4-7 = RDM ou ULA, LEDG[3:0] = estado, LEDG8 = HALT.
-- ESQUELETO: implementar (P5).
library ieee;
use ieee.std_logic_1164.all;

entity top_de2 is
  port (
    CLOCK_50 : in  std_logic;
    KEY      : in  std_logic_vector(3 downto 0);
    SW       : in  std_logic_vector(17 downto 0);
    HEX0     : out std_logic_vector(6 downto 0);
    HEX1     : out std_logic_vector(6 downto 0);
    HEX2     : out std_logic_vector(6 downto 0);
    HEX3     : out std_logic_vector(6 downto 0);
    HEX4     : out std_logic_vector(6 downto 0);
    HEX5     : out std_logic_vector(6 downto 0);
    HEX6     : out std_logic_vector(6 downto 0);
    HEX7     : out std_logic_vector(6 downto 0);
    LEDG     : out std_logic_vector(8 downto 0)
  );
end entity top_de2;

architecture esqueleto of top_de2 is
begin
  HEX0 <= (others => '1');
  HEX1 <= (others => '1');
  HEX2 <= (others => '1');
  HEX3 <= (others => '1');
  HEX4 <= (others => '1');
  HEX5 <= (others => '1');
  HEX6 <= (others => '1');
  HEX7 <= (others => '1');
  LEDG <= (others => '0');
end architecture esqueleto;
