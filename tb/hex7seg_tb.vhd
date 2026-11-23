-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Testbench do hex7seg: confere os 16 dígitos contra a tabela esperada.
-- Termina sozinho (sem clock), com "TODOS OS TESTES PASSARAM" ou failure.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hex7seg_tb is
end entity hex7seg_tb;

architecture teste of hex7seg_tb is
  type tabela_t is array (0 to 15) of std_logic_vector(6 downto 0);
  constant ESPERADO : tabela_t := (
    "1000000", "1111001", "0100100", "0110000",   -- 0 1 2 3
    "0011001", "0010010", "0000010", "1111000",   -- 4 5 6 7
    "0000000", "0010000", "0001000", "0000011",   -- 8 9 A b
    "1000110", "0100001", "0000110", "0001110"    -- C d E F
  );
  signal valor : std_logic_vector(3 downto 0) := (others => '0');
  signal seg   : std_logic_vector(6 downto 0);
begin

  dut : entity work.hex7seg port map (valor => valor, seg => seg);

  process
    variable erros : natural := 0;
  begin
    for i in 0 to 15 loop
      valor <= std_logic_vector(to_unsigned(i, 4));
      wait for 10 ns;
      if seg /= ESPERADO(i) then
        report "FALHOU: digito " & integer'image(i) severity error;
        erros := erros + 1;
      else
        report "OK: digito " & integer'image(i) severity note;
      end if;
    end loop;

    if erros = 0 then
      report "TODOS OS TESTES PASSARAM (hex7seg)" severity note;
    else
      report "TESTES COM FALHA (hex7seg): " & integer'image(erros) severity failure;
    end if;
    std.env.stop;
    wait;
  end process;

end architecture teste;
