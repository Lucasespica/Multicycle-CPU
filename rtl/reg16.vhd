-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Registrador genérico de N bits (padrão 16), usado para PC, RI, RDM, A, B e SaídaULA.
--   rst = '1'               -> q zera na hora (assíncrono, não espera o clock)
--   borda de subida de clk  -> q <= d, mas só se en = '1' e load = '1'
--   qualquer outro caso     -> q mantém o valor
-- en é o pulso de "passo" que vem do KEY0 (um ciclo por aperto); load é o sinal
-- de escrita da unidade de controle (PCWrite, IRWrite, RDMWrite) ou '1' fixo.
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

architecture comportamento of reg16 is
begin
  process (clk, rst)          -- rst na lista: o reset age sem esperar o clock
  begin
    if rst = '1' then
      q <= (others => '0');
    elsif rising_edge(clk) then
      if en = '1' and load = '1' then
        q <= d;
      end if;                 -- sem "else": o flip-flop guarda o valor anterior
    end if;
  end process;
end architecture comportamento;
