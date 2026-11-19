-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Testbench do banco_regs.
-- Clock de 20 ns (50 MHz). Entradas mudam na borda de descida; leituras são
-- conferidas 1 ns depois da borda de subida (ou sem borda, quando o objetivo
-- é mostrar que a leitura é combinacional).
-- Termina sozinho: ao final o clock para.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity banco_regs_tb is
end entity banco_regs_tb;

architecture teste of banco_regs_tb is
  constant T : time := 20 ns;

  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';
  signal en       : std_logic := '0';
  signal RegWrite : std_logic := '0';
  signal ra1, ra2, wa : std_logic_vector(2 downto 0) := "000";
  signal wd       : std_logic_vector(15 downto 0) := (others => '0');
  signal rd1, rd2 : std_logic_vector(15 downto 0);
  signal fim      : boolean := false;

  -- Valor diferente para cada registrador: 1111, 2222, ..., 7777
  function valor(i : natural) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(i * 16#1111#, 16));
  end function;
begin

  dut : entity work.banco_regs
    port map (clk => clk, rst => rst, en => en, RegWrite => RegWrite,
              ra1 => ra1, ra2 => ra2, wa => wa, wd => wd, rd1 => rd1, rd2 => rd2);

  clk <= not clk after T / 2 when not fim else '0';

  process
    variable erros : natural := 0;

    -- Prepara uma escrita (ou tentativa) e espera a borda de subida.
    procedure escreve(e, w : std_logic; endereco : natural; dado : std_logic_vector(15 downto 0)) is
    begin
      wait until falling_edge(clk);
      en <= e; RegWrite <= w;
      wa <= std_logic_vector(to_unsigned(endereco, 3)); wd <= dado;
      wait until rising_edge(clk);
      wait for 1 ns;
      en <= '0'; RegWrite <= '0';
    end procedure;

    -- Lê dois registradores ao mesmo tempo e confere rd1 e rd2.
    procedure le(r1, r2 : natural; esp1, esp2 : std_logic_vector(15 downto 0); nome : string) is
    begin
      ra1 <= std_logic_vector(to_unsigned(r1, 3));
      ra2 <= std_logic_vector(to_unsigned(r2, 3));
      wait for 1 ns;
      if rd1 /= esp1 or rd2 /= esp2 then
        report "FALHOU: " & nome & "  R" & integer'image(r1) & "=" & to_hstring(rd1) &
               " (esp " & to_hstring(esp1) & ")  R" & integer'image(r2) & "=" &
               to_hstring(rd2) & " (esp " & to_hstring(esp2) & ")" severity error;
        erros := erros + 1;
      else
        report "OK: " & nome & "  R" & integer'image(r1) & "=" & to_hstring(rd1) &
               "  R" & integer'image(r2) & "=" & to_hstring(rd2) severity note;
      end if;
    end procedure;

  begin
    -- 1. Durante o reset tudo lê 0.
    wait for 5 ns;
    le(1, 7, x"0000", x"0000", "reset: R1 e R7 em zero");
    wait until falling_edge(clk);
    rst <= '0';

    -- 2. Escreve em R1..R7 um valor diferente em cada um.
    for i in 1 to 7 loop
      escreve('1', '1', i, valor(i));
    end loop;
    for i in 1 to 7 loop
      le(i, 8 - i, valor(i), valor(8 - i), "escreve e le R1..R7");
    end loop;

    -- 3. Tentativa de escrever em R0: deve continuar 0.
    escreve('1', '1', 0, x"BEEF");
    le(0, 0, x"0000", x"0000", "escrita em R0 ignorada");
    le(0, 1, x"0000", valor(1), "R0 nas duas portas, R1 intacto");

    -- 4. Sem RegWrite: não escreve.
    escreve('1', '0', 3, x"DEAD");
    le(3, 3, valor(3), valor(3), "RegWrite=0 nao escreve");

    -- 5. Sem en (botão não apertado): não escreve.
    escreve('0', '1', 3, x"DEAD");
    le(3, 3, valor(3), valor(3), "en=0 nao escreve");

    -- 6. Sobrescrita só afeta o registrador endereçado.
    escreve('1', '1', 5, x"ABCD");
    le(5, 4, x"ABCD", valor(4), "sobrescreve R5, R4 intacto");
    le(6, 7, valor(6), valor(7), "R6 e R7 intactos");

    -- 7. Leitura combinacional: trocar o endereço muda a saída sem borda.
    wait until falling_edge(clk);
    le(2, 6, valor(2), valor(6), "leitura sem borda (combinacional) 1");
    le(7, 1, valor(7), valor(1), "leitura sem borda (combinacional) 2");

    -- 8. Valor negativo (bit 15 = 1) é guardado sem alteração.
    escreve('1', '1', 2, x"8000");
    le(2, 2, x"8000", x"8000", "valor negativo 8000 em R2");

    -- 9. Reset assíncrono no meio do ciclo zera tudo, sem borda.
    wait until falling_edge(clk);
    wait for 3 ns;
    rst <= '1';
    le(5, 7, x"0000", x"0000", "reset assincrono zera R5 e R7");
    le(1, 2, x"0000", x"0000", "reset assincrono zera R1 e R2");

    if erros = 0 then
      report "TODOS OS TESTES PASSARAM (banco_regs)" severity note;
    else
      report "TESTES COM FALHA (banco_regs): " & integer'image(erros) severity failure;
    end if;
    fim <= true;
    wait;
  end process;

end architecture teste;
