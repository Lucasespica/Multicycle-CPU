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
