-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Testbench do reg16.
-- Clock de 20 ns (50 MHz, como o CLOCK_50 da placa). As entradas mudam na
-- borda de descida e a saída é conferida 1 ns depois da borda de subida,
-- para não haver dúvida sobre qual borda capturou o dado.
-- Termina sozinho: ao final o clock para e não há mais eventos.
library ieee;
use ieee.std_logic_1164.all;

entity reg16_tb is
end entity reg16_tb;

architecture teste of reg16_tb is
  constant T : time := 20 ns;

  signal clk  : std_logic := '0';
  signal rst  : std_logic := '1';
  signal en   : std_logic := '0';
  signal load : std_logic := '0';
  signal d    : std_logic_vector(15 downto 0) := (others => '0');
  signal q    : std_logic_vector(15 downto 0);
  signal fim  : boolean := false;
begin

  dut : entity work.reg16
    generic map (N => 16)
    port map (clk => clk, rst => rst, en => en, load => load, d => d, q => q);

  clk <= not clk after T / 2 when not fim else '0';

  process
    variable erros : natural := 0;

    -- Muda as entradas logo após a borda de descida (longe da borda de subida).
    procedure entradas(r, e, l : std_logic; dado : std_logic_vector(15 downto 0)) is
    begin
      wait until falling_edge(clk);
      rst <= r; en <= e; load <= l; d <= dado;
    end procedure;

    -- Espera a próxima borda de subida e confere q 1 ns depois.
    procedure borda_e_checa(esperado : std_logic_vector(15 downto 0); nome : string) is
    begin
      wait until rising_edge(clk);
      wait for 1 ns;
      if q /= esperado then
        report "FALHOU: " & nome & "  q=" & to_hstring(q) &
               "  esperado=" & to_hstring(esperado) severity error;
        erros := erros + 1;
      else
        report "OK: " & nome & "  q=" & to_hstring(q) severity note;
      end if;
    end procedure;

  begin
    -- 1. Reset ativo vence en/load: mesmo com tudo em 1, q fica 0.
    entradas('1', '1', '1', x"ABCD");
    borda_e_checa(x"0000", "reset ativo ignora en=1 load=1");

    -- 2. Carga normal.
    entradas('0', '1', '1', x"1234");
    borda_e_checa(x"1234", "en=1 load=1 carrega d");

    -- 3. Sem en (botão não apertado): mantém.
    entradas('0', '0', '1', x"5555");
    borda_e_checa(x"1234", "en=0 load=1 mantem");

    -- 4. Sem load (controle não manda escrever): mantém.
    entradas('0', '1', '0', x"5555");
    borda_e_checa(x"1234", "en=1 load=0 mantem");

    -- 5. Nenhum dos dois: mantém.
    entradas('0', '0', '0', x"5555");
    borda_e_checa(x"1234", "en=0 load=0 mantem");

    -- 6. Carga de outro valor, todos os bits em 1.
    entradas('0', '1', '1', x"FFFF");
    borda_e_checa(x"FFFF", "carrega FFFF");

    -- 7. d muda entre bordas: q não pode mudar antes da borda (é síncrono).
    entradas('0', '1', '1', x"0F0F");
    wait for 2 ns;                       -- ainda longe da borda de subida
    if q /= x"FFFF" then
      report "FALHOU: q mudou sem borda  q=" & to_hstring(q) severity error;
      erros := erros + 1;
    else
      report "OK: q nao muda entre bordas  q=" & to_hstring(q) severity note;
    end if;
    borda_e_checa(x"0F0F", "na borda seguinte captura 0F0F");

    -- 8. Reset assíncrono: zera no meio do ciclo, sem esperar borda.
    wait until falling_edge(clk);
    wait for 3 ns;
    rst <= '1';
    wait for 1 ns;
    if q /= x"0000" then
      report "FALHOU: reset nao foi assincrono  q=" & to_hstring(q) severity error;
      erros := erros + 1;
    else
      report "OK: reset assincrono zera sem borda  q=" & to_hstring(q) severity note;
    end if;

    -- 9. Saindo do reset, volta a carregar normalmente.
    entradas('0', '1', '1', x"8001");
    borda_e_checa(x"8001", "volta a carregar apos reset");

    if erros = 0 then
      report "TODOS OS TESTES PASSARAM (reg16)" severity note;
    else
      report "TESTES COM FALHA (reg16): " & integer'image(erros) severity failure;
    end if;
    fim <= true;
    wait;
  end process;

end architecture teste;
