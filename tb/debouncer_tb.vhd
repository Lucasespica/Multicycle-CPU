-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Testbench do debouncer, com LIMITE = 4 para a simulação ser curta.
-- Casos: 3 apertos com trepidação na descida e na subida (esperado: 3 pulsos)
-- e um ruído curto de 2 ciclos (esperado: nenhum pulso).
-- Também confere que cada pulso dura exatamente um ciclo.
-- Termina sozinho (para o clock), com "TODOS OS TESTES PASSARAM" ou failure.
library ieee;
use ieee.std_logic_1164.all;

entity debouncer_tb is
end entity debouncer_tb;

architecture teste of debouncer_tb is
  constant T     : time := 10 ns;
  signal clk     : std_logic := '0';
  signal botao   : std_logic := '0';
  signal pulso   : std_logic;
  signal rodando : boolean := true;
  signal pulsos  : natural := 0;
  signal erro_largura : boolean := false;
begin

  clk <= not clk after T / 2 when rodando else '0';

  dut : entity work.debouncer
    generic map (LIMITE => 4)
    port map (clk => clk, botao => botao, pulso => pulso);

  -- conta os pulsos e confere a largura
  process (clk)
    variable ant : std_logic := '0';
  begin
    if rising_edge(clk) then
      if pulso = '1' then
        pulsos <= pulsos + 1;
        if ant = '1' then
          erro_largura <= true;
        end if;
      end if;
      ant := pulso;
    end if;
  end process;

  process
    procedure apertar is
    begin
      -- trepidação ao apertar
      for k in 1 to 3 loop
        botao <= '1'; wait for T;
        botao <= '0'; wait for T;
      end loop;
      botao <= '1'; wait for 20 * T;       -- apertado e estável
      -- trepidação ao soltar
      for k in 1 to 3 loop
        botao <= '0'; wait for T;
        botao <= '1'; wait for T;
      end loop;
      botao <= '0'; wait for 20 * T;       -- solto e estável
    end procedure;
  begin
    wait for 5 * T;

    apertar;
    apertar;
    apertar;

    -- ruído curto: não pode gerar pulso
    botao <= '1'; wait for 2 * T;
    botao <= '0'; wait for 20 * T;

    if pulsos = 3 then
      report "OK: 3 apertos com trepidacao = 3 pulsos; ruido ignorado" severity note;
    else
      report "FALHOU: " & integer'image(pulsos) & " pulso(s), esperado 3" severity error;
    end if;
    if not erro_largura then
      report "OK: cada pulso dura 1 ciclo" severity note;
    else
      report "FALHOU: pulso com mais de 1 ciclo" severity error;
    end if;

    if pulsos = 3 and not erro_largura then
      report "TODOS OS TESTES PASSARAM (debouncer)" severity note;
    else
      report "TESTES COM FALHA (debouncer)" severity failure;
    end if;

    rodando <= false;
    std.env.stop;
    wait;
  end process;

end architecture teste;
