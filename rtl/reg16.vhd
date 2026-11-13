-- Registrador genérico: na borda de subida, q <= d se en = '1' e load = '1'. rst assíncrono zera.
-- ESQUELETO: implementar (P3).
library ieee;
use ieee.std_logic_1164.all;

entity reg16 is
  generic (
    N : positive := 16
  );
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    en   : in  std_logic;
    load : in  std_logic;
    d    : in  std_logic_vector(N-1 downto 0);
    q    : out std_logic_vector(N-1 downto 0)
  );
end entity reg16;

architecture esqueleto of reg16 is
begin
  q <= (others => '0');
end architecture esqueleto;
