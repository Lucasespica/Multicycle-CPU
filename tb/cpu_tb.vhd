-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Testbench da CPU inteira. Roda os 4 programas de mif/, cada um duas vezes:
-- com en sempre em 1 e com um pulso de en a cada 4 ciclos (como o botão na
-- placa, ver D5). São 8 CPUs em paralelo, cada uma com a sua memória.
--
-- Para cada execução o TB confere:
--   - cada escrita, na ordem: R[Ri] <- wd (ESCRITA_ULA e ESCRITA_MEM) e
--     Mem[endereço] <- B (MEM_ESCR), contra a lista de valores esperados;
--   - ao chegar no HALT: os 8 registradores, o PC, o número de instruções
--     e que mais 3 pulsos de en não tiram a CPU do HALT.
-- Na execução com en contínuo ele imprime PC, RI e os registradores ao fim
-- de cada instrução. Os valores esperados estão em doc/testes.md.
-- Usa nomes externos (VHDL-2008) para ri, wd, mem_addr e reg_b e o
-- signal_spy do ModelSim para o vetor de registradores do banco.
-- Termina sozinho: ao final o clock para.

-- ---------------------------------------------------------------------
-- Valores esperados de cada programa
-- ---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package cpu_tb_pkg is

  -- 'R': escrita em R[ender] (inclui tentativas em R0); 'M': escrita em Mem[ender]
  type evento_t is record
    tipo  : character;
    ender : natural;
    valor : std_logic_vector(15 downto 0);
  end record;
  type eventos_t is array (natural range <>) of evento_t;
  type regs_t is array (0 to 7) of std_logic_vector(15 downto 0);

  -- t1_ula
  constant EV_T1 : eventos_t := (
    ('R', 16#001#, x"001F"), ('R', 16#002#, x"FFE0"), ('R', 16#000#, x"0005"),
    ('R', 16#003#, x"FFFF"), ('R', 16#004#, x"FFC1"), ('R', 16#005#, x"0001"),
    ('R', 16#006#, x"0001"), ('R', 16#007#, x"0007"), ('R', 16#007#, x"0000"),
    ('R', 16#005#, x"FFC0"), ('R', 16#001#, x"FFDF"), ('R', 16#002#, x"0000"),
    ('R', 16#000#, x"FFBE"));
  constant REGS_T1 : regs_t := (x"0000", x"FFDF", x"0000", x"FFFF", x"FFC1", x"FFC0", x"0001", x"0000");
  constant PC_T1   : std_logic_vector(15 downto 0) := x"000E";
  constant NI_T1   : natural := 14;

  -- t2_mem
  constant EV_T2 : eventos_t := (
    ('R', 16#001#, x"0010"), ('R', 16#002#, x"1234"), ('R', 16#003#, x"ABCD"),
    ('R', 16#004#, x"BE01"), ('M', 16#012#, x"BE01"), ('R', 16#005#, x"BE01"),
    ('R', 16#006#, x"001F"), ('M', 16#01E#, x"ABCD"), ('R', 16#007#, x"ABCD"),
    ('M', 16#01F#, x"1234"), ('R', 16#001#, x"1234"));
  constant REGS_T2 : regs_t := (x"0000", x"1234", x"1234", x"ABCD", x"BE01", x"BE01", x"001F", x"ABCD");
  constant PC_T2   : std_logic_vector(15 downto 0) := x"000C";
  constant NI_T2   : natural := 12;

  -- t3_desvios
  constant EV_T3 : eventos_t := (
    ('R', 16#001#, x"0003"), ('R', 16#002#, x"0000"), ('R', 16#002#, x"0002"),
    ('R', 16#001#, x"0002"), ('R', 16#002#, x"0004"), ('R', 16#001#, x"0001"),
    ('R', 16#002#, x"0006"), ('R', 16#001#, x"0000"), ('R', 16#005#, x"0005"));
  constant REGS_T3 : regs_t := (x"0000", x"0000", x"0006", x"0000", x"0000", x"0005", x"0000", x"0000");
  constant PC_T3   : std_logic_vector(15 downto 0) := x"000E";
  constant NI_T3   : natural := 16;

  -- final
  constant EV_FINAL : eventos_t := (
    ('R', 16#001#, x"0005"), ('R', 16#002#, x"0000"), ('R', 16#003#, x"0001"),
    ('R', 16#002#, x"0001"), ('R', 16#003#, x"0002"), ('R', 16#002#, x"0003"),
    ('R', 16#003#, x"0003"), ('R', 16#002#, x"0006"), ('R', 16#003#, x"0004"),
    ('R', 16#002#, x"000A"), ('R', 16#003#, x"0005"), ('R', 16#002#, x"000F"),
    ('M', 16#01F#, x"000F"), ('R', 16#004#, x"000F"), ('R', 16#005#, x"0001"));
  constant REGS_FINAL : regs_t := (x"0000", x"0005", x"000F", x"0005", x"000F", x"0001", x"0000", x"0000");
  constant PC_FINAL   : std_logic_vector(15 downto 0) := x"000B";
  constant NI_FINAL   : natural := 25;

  function eventos(p : natural) return eventos_t;
  function regs_esperados(p : natural) return regs_t;
  function pc_esperado(p : natural) return std_logic_vector;
  function ni_esperado(p : natural) return natural;

end package cpu_tb_pkg;

package body cpu_tb_pkg is

  function eventos(p : natural) return eventos_t is
  begin
    case p is
      when 1      => return EV_T1;
      when 2      => return EV_T2;
      when 3      => return EV_T3;
      when others => return EV_FINAL;
    end case;
  end function;

  function regs_esperados(p : natural) return regs_t is
  begin
    case p is
      when 1      => return REGS_T1;
      when 2      => return REGS_T2;
      when 3      => return REGS_T3;
      when others => return REGS_FINAL;
    end case;
  end function;

  function pc_esperado(p : natural) return std_logic_vector is
  begin
    case p is
      when 1      => return PC_T1;
      when 2      => return PC_T2;
      when 3      => return PC_T3;
      when others => return PC_FINAL;
    end case;
  end function;

  function ni_esperado(p : natural) return natural is
  begin
    case p is
      when 1      => return NI_T1;
      when 2      => return NI_T2;
      when 3      => return NI_T3;
      when others => return NI_FINAL;
    end case;
  end function;

end package body cpu_tb_pkg;

-- ---------------------------------------------------------------------
-- Uma execução: uma CPU, um programa, um modo de en
-- ---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
library modelsim_lib;
use modelsim_lib.util.all;
use work.cpu_pkg.all;
use work.cpu_tb_pkg.all;

entity cpu_tb_prog is
  generic (
    NOME     : string;            -- nome do programa, para as mensagens
    ARQ_MIF  : string;            -- relativo à raiz do repositório
    PROG     : natural;           -- 1 = t1, 2 = t2, 3 = t3, 4 = final
    ESPACADO : boolean;           -- false: en sempre 1; true: 1 pulso a cada 4 ciclos
    CAMINHO  : string             -- caminho desta instância, para o signal_spy
  );
  port (
    clk    : in  std_logic;
    inicio : in  boolean;         -- a CPU fica em reset até inicio = true
    feito  : out boolean := false;
    ok    : out boolean := false
  );
end entity cpu_tb_prog;

architecture teste of cpu_tb_prog is
  constant MAX_PASSOS : natural := 2000;  -- proteção contra laço infinito

  signal rst     : std_logic := '1';
  signal en      : std_logic := '0';
  signal pc      : std_logic_vector(15 downto 0);
  signal rdm     : std_logic_vector(15 downto 0);
  signal ula     : std_logic_vector(15 downto 0);
  signal estado  : std_logic_vector(3 downto 0);
  signal halt    : std_logic;
  signal regs    : regs_t;
  signal parar   : boolean := false;

  function modo return string is
  begin
    if ESPACADO then
      return "en espacado";
    else
      return "en continuo";
    end if;
  end function;

  function h(v : std_logic_vector) return string is
  begin
    return to_hstring(v);
  end function;

  procedure imprime(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin

  dut : entity work.cpu
    generic map (ARQ_MIF => ARQ_MIF)
    port map (clk => clk, rst => rst, en => en, pc_out => pc, rdm_out => rdm,
              ula_out => ula, estado => estado, halt => halt);

  -- Reset por 2 ciclos; depois en contínuo ou um pulso a cada 4 ciclos
  gera_en : process
  begin
    rst <= '1';
    en  <= '0';
    if not inicio then
      wait until inicio;
    end if;
    for i in 1 to 2 loop
      wait until falling_edge(clk);
    end loop;
    rst <= '0';
    while not parar loop
      wait until falling_edge(clk);
      en <= '1';
      if ESPACADO then
        wait until falling_edge(clk);
        en <= '0';
        for i in 1 to 2 loop
          wait until falling_edge(clk);
        end loop;
      end if;
    end loop;
    en <= '0';
    wait;
  end process;

  confere : process
    alias ri       is <<signal dut.ri       : std_logic_vector(15 downto 0)>>;
    alias wd       is <<signal dut.wd       : std_logic_vector(15 downto 0)>>;
    alias mem_addr is <<signal dut.mem_addr : std_logic_vector(11 downto 0)>>;
    alias reg_b    is <<signal dut.reg_b    : std_logic_vector(15 downto 0)>>;

    constant EV : eventos_t := eventos(PROG);
    constant RE : regs_t    := regs_esperados(PROG);

    variable erros     : natural := 0;
    variable n_ev      : natural := 0;
    variable n_instr   : natural := 0;
    variable passos    : natural := 0;
    variable pc_instr  : std_logic_vector(15 downto 0) := (others => '0');
    variable pc_halt   : std_logic_vector(15 downto 0);
    variable tipo      : character;
    variable ender     : natural;
    variable valor     : std_logic_vector(15 downto 0);

    procedure falha(s : string) is
    begin
      report "FALHOU [" & NOME & ", " & modo & "]: " & s severity error;
      erros := erros + 1;
    end procedure;

    -- Linha do trace: instrução que acabou de terminar
    procedure linha_trace is
      variable s : line;
    begin
      if not ESPACADO then
        write(s, "  [" & NOME & "] #" & integer'image(n_instr) &
                 "  PC=" & h(pc_instr) & "  RI=" & h(ri) & " |");
        for k in 1 to 7 loop
          write(s, " R" & integer'image(k) & "=" & h(regs(k)));
        end loop;
        writeline(output, s);
      end if;
    end procedure;

    -- "R3" ou "Mem[01F]"
    function alvo(t : character; e : natural) return string is
    begin
      if t = 'R' then
        return "R" & integer'image(e);
      else
        return "Mem[" & to_hstring(to_unsigned(e, 12)) & "]";
      end if;
    end function;

    procedure registra(t : character; e : natural; v : std_logic_vector(15 downto 0)) is
    begin
      if n_ev > EV'high then
        falha("escrita a mais: " & alvo(t, e) & " <- " & h(v));
      elsif EV(n_ev).tipo /= t or EV(n_ev).ender /= e or EV(n_ev).valor /= v then
        falha("escrita " & integer'image(n_ev + 1) & " (PC " & h(pc_instr) & "): " &
              alvo(t, e) & " <- " & h(v) & ", esperado " &
              alvo(EV(n_ev).tipo, EV(n_ev).ender) & " <- " & h(EV(n_ev).valor));
      end if;
      n_ev := n_ev + 1;
    end procedure;
  begin
    init_signal_spy(CAMINHO & "/dut/u_banco/regs", CAMINHO & "/regs");
    if not inicio then
      wait until inicio;
    end if;
    if not ESPACADO then
      imprime("---- " & NOME & " (" & ARQ_MIF & ") ----");
    end if;
    wait until rst = '0';

    -- Executa até a CPU chegar no HALT, conferindo cada escrita
    while halt /= '1' loop
      wait until rising_edge(clk);
      if en = '1' then
        passos := passos + 1;
        -- os valores lidos aqui são os de antes da borda
        if estado = E_BUSCA then
          if n_instr > 0 then
            linha_trace;
          end if;
          n_instr  := n_instr + 1;
          pc_instr := pc;
        elsif estado = E_ESCRITA_ULA or estado = E_ESCRITA_MEM then
          registra('R', to_integer(unsigned(ri(11 downto 9))), wd);
        elsif estado = E_MEM_ESCR then
          registra('M', to_integer(unsigned(mem_addr)), reg_b);
        end if;
        if passos >= MAX_PASSOS then
          falha("nao chegou no HALT em " & integer'image(MAX_PASSOS) & " passos");
          exit;
        end if;
      end if;
      wait for 1 ns;
    end loop;
    linha_trace;

    -- Mais 3 pulsos de en: a CPU tem que continuar parada
    pc_halt := pc;
    for i in 1 to 3 loop
      wait until rising_edge(clk) and en = '1';
    end loop;
    wait for 1 ns;
    if estado /= E_HALT or halt /= '1' then
      falha("saiu do HALT: estado " & to_string(estado));
    end if;
    if pc /= pc_halt then
      falha("PC mudou em HALT: " & h(pc));
    end if;

    -- Estado final
    if n_ev /= EV'length then
      falha(integer'image(n_ev) & " escritas, esperado " & integer'image(EV'length));
    end if;
    if n_instr /= ni_esperado(PROG) then
      falha(integer'image(n_instr) & " instrucoes, esperado " &
            integer'image(ni_esperado(PROG)));
    end if;
    if pc /= pc_esperado(PROG) then
      falha("PC final " & h(pc) & ", esperado " & h(pc_esperado(PROG)));
    end if;
    for k in 0 to 7 loop
      if regs(k) /= RE(k) then
        falha("R" & integer'image(k) & " = " & h(regs(k)) & ", esperado " & h(RE(k)));
      end if;
    end loop;

    if erros = 0 then
      imprime("OK     [" & NOME & ", " & modo & "]: " & integer'image(n_instr) &
              " instrucoes, " & integer'image(passos) & " passos, PC final " & h(pc));
    else
      imprime("FALHOU [" & NOME & ", " & modo & "]: " & integer'image(erros) & " erro(s)");
    end if;
    ok    <= erros = 0;
    feito <= true;
    parar <= true;
    wait;
  end process;

end architecture teste;

-- ---------------------------------------------------------------------
-- Topo: as 4 execuções com en contínuo rodam uma depois da outra, para o
-- trace sair em ordem; depois as 4 com en espaçado rodam juntas
-- ---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity cpu_tb is
end entity cpu_tb;

architecture teste of cpu_tb is
  constant T : time := 20 ns;

  signal clk   : std_logic := '0';
  signal fim   : boolean := false;
  signal feito : boolean_vector(0 to 7);
  signal ok    : boolean_vector(0 to 7);
  constant JA  : boolean := true;
begin

  clk <= not clk after T / 2 when not fim else '0';

  t1_cont : entity work.cpu_tb_prog
    generic map ("t1_ula", "mif/t1_ula.mif", 1, false, "/cpu_tb/t1_cont")
    port map (clk, JA, feito(0), ok(0));
  t2_cont : entity work.cpu_tb_prog
    generic map ("t2_mem", "mif/t2_mem.mif", 2, false, "/cpu_tb/t2_cont")
    port map (clk, feito(0), feito(1), ok(1));
  t3_cont : entity work.cpu_tb_prog
    generic map ("t3_desvios", "mif/t3_desvios.mif", 3, false, "/cpu_tb/t3_cont")
    port map (clk, feito(1), feito(2), ok(2));
  final_cont : entity work.cpu_tb_prog
    generic map ("final", "mif/final.mif", 4, false, "/cpu_tb/final_cont")
    port map (clk, feito(2), feito(3), ok(3));

  t1_esp : entity work.cpu_tb_prog
    generic map ("t1_ula", "mif/t1_ula.mif", 1, true, "/cpu_tb/t1_esp")
    port map (clk, feito(3), feito(4), ok(4));
  t2_esp : entity work.cpu_tb_prog
    generic map ("t2_mem", "mif/t2_mem.mif", 2, true, "/cpu_tb/t2_esp")
    port map (clk, feito(3), feito(5), ok(5));
  t3_esp : entity work.cpu_tb_prog
    generic map ("t3_desvios", "mif/t3_desvios.mif", 3, true, "/cpu_tb/t3_esp")
    port map (clk, feito(3), feito(6), ok(6));
  final_esp : entity work.cpu_tb_prog
    generic map ("final", "mif/final.mif", 4, true, "/cpu_tb/final_esp")
    port map (clk, feito(3), feito(7), ok(7));

  process
  begin
    wait until feito = (feito'range => true);
    if ok = (ok'range => true) then
      report "TODOS OS TESTES PASSARAM (cpu)" severity note;
    else
      report "TESTES COM FALHA (cpu)" severity failure;
    end if;
    fim <= true;
    wait;
  end process;

end architecture teste;
