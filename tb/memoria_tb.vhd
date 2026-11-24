-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Testbench da memoria, carregada com mif/t2_mem.mif (programa + dados).
-- Clock de 20 ns. Entradas mudam na borda de descida; q é conferido 1 ns
-- depois da borda de subida. Confere: conteúdo do .mif (código, dados e
-- preenchimento com HALT), atraso de um ciclo na leitura, escrita com
-- wren = '1', wren = '0' não escreve e escrita no último endereço.
-- Termina sozinho: ao final o clock para.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memoria_tb is
end entity memoria_tb;

architecture teste of memoria_tb is
  constant T : time := 20 ns;

  signal clock   : std_logic := '0';
  signal wren    : std_logic := '0';
  signal address : std_logic_vector(11 downto 0) := (others => '0');
  signal data    : std_logic_vector(15 downto 0) := (others => '0');
  signal q       : std_logic_vector(15 downto 0);
  signal fim     : boolean := false;
begin

  dut : entity work.memoria
    generic map (ARQ_MIF => "mif/t2_mem.mif")
    port map (clock => clock, wren => wren, address => address, data => data, q => q);

  clock <= not clock after T / 2 when not fim else '0';

  process
    variable erros : natural := 0;

    procedure confere(esperado : std_logic_vector(15 downto 0); caso : string) is
    begin
      if q /= esperado then
        report "FALHOU: " & caso & ": q = " & to_hstring(q) &
               ", esperado " & to_hstring(esperado) severity error;
        erros := erros + 1;
      end if;
    end procedure;

    -- Apresenta o endereço e confere q depois da borda de subida.
    procedure le(endereco : natural; esperado : std_logic_vector(15 downto 0); caso : string) is
    begin
      wait until falling_edge(clock);
      wren    <= '0';
      address <= std_logic_vector(to_unsigned(endereco, 12));
      wait until rising_edge(clock);
      wait for 1 ns;
      confere(esperado, caso);
    end procedure;

    -- Uma borda de subida com wren = w, endereço e dado dados.
    procedure escreve(w : std_logic; endereco : natural; dado : std_logic_vector(15 downto 0)) is
    begin
      wait until falling_edge(clock);
      wren    <= w;
      address <= std_logic_vector(to_unsigned(endereco, 12));
      data    <= dado;
      wait until rising_edge(clock);
      wait for 1 ns;
      wait until falling_edge(clock);
      wren <= '0';
    end procedure;
  begin
    -- Conteúdo inicial: código do t2_mem
    le(16#000#, x"5210", "Mem[000] (ADDI R1, R0, 16)");
    le(16#001#, x"6440", "Mem[001] (LD R2, R1, 0)");
    le(16#00B#, x"F000", "Mem[00B] (HALT)");

    -- Dados e preenchimento com HALT
    le(16#010#, x"1234", "Mem[010] (dado)");
    le(16#011#, x"ABCD", "Mem[011] (dado)");
    le(16#012#, x"0000", "Mem[012] (dado)");
    le(16#00C#, x"F000", "Mem[00C] (preenchimento)");
    le(16#020#, x"F000", "Mem[020] (preenchimento)");
    le(16#FFF#, x"F000", "Mem[FFF] (ultimo endereco)");

    -- Atraso de um ciclo: antes da borda q ainda mostra o endereço anterior
    le(16#010#, x"1234", "Mem[010] antes da troca de endereco");
    wait until falling_edge(clock);
    address <= std_logic_vector(to_unsigned(16#011#, 12));
    wait for T / 4;
    confere(x"1234", "q so muda depois da borda");
    wait until rising_edge(clock);
    wait for 1 ns;
    confere(x"ABCD", "q muda na borda seguinte");

    -- Escrita e leitura de volta
    escreve('1', 16#012#, x"BE01");
    le(16#012#, x"BE01", "Mem[012] depois do ST");
    escreve('1', 16#01E#, x"ABCD");
    le(16#01E#, x"ABCD", "Mem[01E] depois do ST");
    le(16#012#, x"BE01", "Mem[012] nao muda com outra escrita");

    -- wren = '0' não escreve
    escreve('0', 16#010#, x"FFFF");
    le(16#010#, x"1234", "wren = 0 nao escreve");

    -- Escrita no último endereço, sem afetar o primeiro
    escreve('1', 16#FFF#, x"0F0F");
    le(16#FFF#, x"0F0F", "Mem[FFF] depois do ST");
    le(16#000#, x"5210", "Mem[000] intacto");

    if erros = 0 then
      report "TODOS OS TESTES PASSARAM (memoria)" severity note;
    else
      report "TESTES COM FALHA (memoria): " & integer'image(erros) severity failure;
    end if;
    fim <= true;
    wait;
  end process;

end architecture teste;
