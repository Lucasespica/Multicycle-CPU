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
