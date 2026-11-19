-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Banco de 8 registradores de 16 bits (R0 a R7), adaptado do bancoReg do Lab05.
--   2 portas de leitura, combinacionais: rd1 = R[ra1], rd2 = R[ra2]
--   1 porta de escrita, síncrona: R[wa] <= wd na borda de subida,
--     só se en = '1' e RegWrite = '1'
--   R0 vale sempre 0: escrita em R0 é ignorada e a leitura de R0 é forçada a 0
--   rst assíncrono zera todos os registradores
-- Mudanças em relação ao Lab05: nomes das portas, entrada en, reset zerando
-- (sem os valores iniciais do lab) e leitura de R0 forçada a zero.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

architecture comportamento of banco_regs is
  type regs_t is array (0 to 7) of std_logic_vector(15 downto 0);
  signal regs : regs_t := (others => (others => '0'));
begin

  -- Escrita (síncrona) e reset (assíncrono)
  process (clk, rst)
  begin
    if rst = '1' then
      regs <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if en = '1' and RegWrite = '1' and wa /= "000" then
        regs(to_integer(unsigned(wa))) <= wd;
      end if;
    end if;
  end process;

  -- Leitura (combinacional): R0 sempre 0, os demais vêm do vetor
  rd1 <= (others => '0') when ra1 = "000" else regs(to_integer(unsigned(ra1)));
  rd2 <= (others => '0') when ra2 = "000" else regs(to_integer(unsigned(ra2)));

end architecture comportamento;
