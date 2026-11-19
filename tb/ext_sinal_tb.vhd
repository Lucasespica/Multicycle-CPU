-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Testbench do ext_sinal.
-- Parte 1: casos nomeados (extremos e valores usados nos programas).
-- Parte 2: varredura exaustiva das 64 entradas possíveis, comparando com
--          resize(signed(imm), 16) da numeric_std.
-- Termina sozinho (sem clock), com "TODOS OS TESTES PASSARAM" ou failure.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ext_sinal_tb is
end entity ext_sinal_tb;

architecture teste of ext_sinal_tb is
  signal imm : std_logic_vector(5 downto 0) := (others => '0');
  signal ext : std_logic_vector(15 downto 0);
begin

  dut : entity work.ext_sinal
    port map (imm => imm, ext => ext);

  process
    variable erros : natural := 0;

    procedure checa(entrada  : std_logic_vector(5 downto 0);
                    esperado : std_logic_vector(15 downto 0);
                    nome     : string;
                    mostrar  : boolean := true) is
    begin
      imm <= entrada;
      wait for 10 ns;
      if ext /= esperado then
        report "FALHOU: " & nome & "  imm=" & to_string(entrada) &
               "  ext=" & to_hstring(ext) & "  esperado=" & to_hstring(esperado)
          severity error;
        erros := erros + 1;
      elsif mostrar then
        report "OK: " & nome & "  imm=" & to_string(entrada) &
               " -> 0x" & to_hstring(ext) severity note;
      end if;
    end procedure;

  begin
    -- ---------- Parte 1: casos nomeados ----------
    checa("000000", x"0000", "zero");
    checa("000001", x"0001", "+1");
    checa("011111", x"001F", "+31 (maior positivo)");
    checa("100000", x"FFE0", "-32 (menor negativo)");
    checa("111111", x"FFFF", "-1");
    checa("111110", x"FFFE", "-2");
    checa("010101", x"0015", "+21 (padrao alternado, positivo)");
    checa("101010", x"FFEA", "-22 (padrao alternado, negativo)");

    -- ---------- Parte 2: as 64 entradas ----------
    for i in -32 to 31 loop
      checa(std_logic_vector(to_signed(i, 6)),
            std_logic_vector(to_signed(i, 16)),
            "varredura " & integer'image(i), false);  -- só reporta se falhar
    end loop;

    if erros = 0 then
      report "TODOS OS TESTES PASSARAM (ext_sinal)" severity note;
    else
      report "TESTES COM FALHA (ext_sinal): " & integer'image(erros) severity failure;
    end if;
    wait;
  end process;

end architecture teste;
