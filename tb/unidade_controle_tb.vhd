-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Testbench da unidade_controle.
-- Para cada opcode, percorre a instrução inteira e confere, em cada estado,
-- o código do estado e todos os sinais contra a tabela "Sinais por estado"
-- (doc/divisao_cpu.md, seção 4), escrita aqui como a constante TABELA.
-- Também confere:
--   - en = 0 segura o estado (um ciclo sem en antes de cada passo);
--   - o desvio tomado e não tomado, com a mesma lógica do cpu.vhd (D2);
--   - HALT e opcodes livres (D6) ficam parados até o reset;
--   - reset assíncrono no meio de uma instrução.
-- Clock de 20 ns. Entradas mudam na borda de descida; saídas conferidas 1 ns
-- depois da borda de subida. Termina sozinho: ao final o clock para.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity unidade_controle_tb is
end entity unidade_controle_tb;

architecture teste of unidade_controle_tb is
  constant T : time := 20 ns;

  signal clk    : std_logic := '0';
  signal rst    : std_logic := '1';
  signal en     : std_logic := '0';
  signal opcode : std_logic_vector(3 downto 0) := OP_ADD;
  signal fim    : boolean := false;

  signal PCWrite, PCWriteCond, IorD, MemWrite, IRWrite, RDMWrite : std_logic;
  signal RegWrite, RegSrc2, MemtoReg, ULASrcA, Halt              : std_logic;
  signal PCSource, ULASrcB : std_logic_vector(1 downto 0);
  signal ULACtl            : std_logic_vector(2 downto 0);
  signal Estado            : std_logic_vector(3 downto 0);

  -- Uma linha da tabela de sinais (RegSrc2 fica de fora: depende só do opcode, D3)
  type t_sinais is record
    PCWrite, PCWriteCond : std_logic;
    PCSource             : std_logic_vector(1 downto 0);
    IorD, MemWrite, IRWrite, RDMWrite, RegWrite, MemtoReg, ULASrcA : std_logic;
    ULASrcB              : std_logic_vector(1 downto 0);
    ULACtl               : std_logic_vector(2 downto 0);
    Halt                 : std_logic;
  end record;

  type t_tabela is array (0 to 12) of t_sinais;

  -- Índice = código do estado. "---" no EXEC_R: vem do opcode (D1).
  constant TABELA : t_tabela := (
    --  PCW  PCWC PCSrc IorD MemW IRW  RDMW RegW MtoR SrcA SrcB  ULACtl Halt
    0  => ('0', '0', "00", '0', '0', '0', '0', '0', '0', '0', "00", "000", '0'),  -- BUSCA
    1  => ('1', '0', "00", '0', '0', '1', '1', '0', '0', '0', "01", "010", '0'),  -- BUSCA2
    2  => ('0', '0', "00", '0', '0', '0', '0', '0', '0', '0', "10", "010", '0'),  -- DECOD
    3  => ('0', '0', "00", '0', '0', '0', '0', '0', '0', '1', "00", "---", '0'),  -- EXEC_R
    4  => ('0', '0', "00", '0', '0', '0', '0', '0', '0', '1', "10", "010", '0'),  -- EXEC_I
    5  => ('0', '0', "00", '0', '0', '0', '0', '1', '0', '0', "00", "000", '0'),  -- ESCRITA_ULA
    6  => ('0', '0', "00", '1', '0', '0', '0', '0', '0', '1', "10", "010", '0'),  -- MEM_LER
    7  => ('0', '0', "00", '1', '0', '0', '1', '0', '0', '1', "10", "010", '0'),  -- MEM_LER2
    8  => ('0', '0', "00", '0', '0', '0', '0', '1', '1', '0', "00", "000", '0'),  -- ESCRITA_MEM
    9  => ('0', '0', "00", '1', '1', '0', '0', '0', '0', '0', "00", "000", '0'),  -- MEM_ESCR
    10 => ('0', '1', "01", '0', '0', '0', '0', '0', '0', '1', "00", "100", '0'),  -- DESVIO
    11 => ('1', '0', "10", '0', '0', '0', '0', '0', '0', '0', "00", "000", '0'),  -- SALTO
    12 => ('0', '0', "00", '0', '0', '0', '0', '0', '0', '0', "00", "000", '1')   -- HALT
  );

  type t_seq is array (natural range <>) of std_logic_vector(3 downto 0);

  constant SEQ_R    : t_seq := (E_BUSCA, E_BUSCA2, E_DECOD, E_EXEC_R, E_ESCRITA_ULA);
  constant SEQ_ADDI : t_seq := (E_BUSCA, E_BUSCA2, E_DECOD, E_EXEC_I, E_ESCRITA_ULA);
  constant SEQ_LD   : t_seq := (E_BUSCA, E_BUSCA2, E_DECOD, E_EXEC_I, E_MEM_LER, E_MEM_LER2, E_ESCRITA_MEM);
  constant SEQ_ST   : t_seq := (E_BUSCA, E_BUSCA2, E_DECOD, E_EXEC_I, E_MEM_ESCR);
  constant SEQ_BR   : t_seq := (E_BUSCA, E_BUSCA2, E_DECOD, E_DESVIO);
  constant SEQ_JMP  : t_seq := (E_BUSCA, E_BUSCA2, E_DECOD, E_SALTO);
  constant SEQ_HALT : t_seq := (E_BUSCA, E_BUSCA2, E_DECOD, E_HALT);

  function nome_estado(e : std_logic_vector(3 downto 0)) return string is
  begin
    case e is
      when E_BUSCA       => return "BUSCA";
      when E_BUSCA2      => return "BUSCA2";
      when E_DECOD       => return "DECOD";
      when E_EXEC_R      => return "EXEC_R";
      when E_EXEC_I      => return "EXEC_I";
      when E_ESCRITA_ULA => return "ESCRITA_ULA";
      when E_MEM_LER     => return "MEM_LER";
      when E_MEM_LER2    => return "MEM_LER2";
      when E_ESCRITA_MEM => return "ESCRITA_MEM";
      when E_MEM_ESCR    => return "MEM_ESCR";
      when E_DESVIO      => return "DESVIO";
      when E_SALTO       => return "SALTO";
      when E_HALT        => return "HALT";
      when others        => return "?" & to_string(e);
    end case;
  end function;

  -- D1: opcode tipo R -> ULACtl
  function ulactl_r(op : std_logic_vector(3 downto 0)) return std_logic_vector is
  begin
    case op is
      when OP_ADD => return "010";
      when OP_SUB => return "100";
      when OP_AND => return "000";
      when OP_OR  => return "001";
      when OP_SLT => return "110";
      when others => return "XXX";
    end case;
  end function;

begin

  dut : entity work.unidade_controle
    port map (
      clk => clk, rst => rst, en => en, opcode => opcode,
      PCWrite => PCWrite, PCWriteCond => PCWriteCond, PCSource => PCSource,
      IorD => IorD, MemWrite => MemWrite, IRWrite => IRWrite,
      RDMWrite => RDMWrite, RegWrite => RegWrite, RegSrc2 => RegSrc2,
      MemtoReg => MemtoReg, ULASrcA => ULASrcA, ULASrcB => ULASrcB,
      ULACtl => ULACtl, Halt => Halt, Estado => Estado
    );

  clk <= not clk after T / 2 when not fim else '0';

  process
    variable erros : natural := 0;

    procedure falha(msg : string) is
    begin
      report "FALHOU: " & msg severity error;
      erros := erros + 1;
    end procedure;

    -- Confere o estado atual e todos os sinais de controle.
    procedure confere(esperado : std_logic_vector(3 downto 0); op : std_logic_vector(3 downto 0);
                      ctx : string) is
      variable s      : t_sinais;
      variable rs2    : std_logic;
    begin
      if Estado /= esperado then
        falha(ctx & ": estado=" & nome_estado(Estado) & " esperado=" & nome_estado(esperado));
        return;
      end if;

      s := TABELA(to_integer(unsigned(esperado)));
      if esperado = E_EXEC_R then
        s.ULACtl := ulactl_r(op);
      end if;
      if op = OP_ST or op = OP_BEQ or op = OP_BNE then rs2 := '1'; else rs2 := '0'; end if;

      if PCWrite     /= s.PCWrite     then falha(ctx & ": PCWrite="     & to_string(PCWrite));     end if;
      if PCWriteCond /= s.PCWriteCond then falha(ctx & ": PCWriteCond=" & to_string(PCWriteCond)); end if;
      if PCSource    /= s.PCSource    then falha(ctx & ": PCSource="    & to_string(PCSource));    end if;
      if IorD        /= s.IorD        then falha(ctx & ": IorD="        & to_string(IorD));        end if;
      if MemWrite    /= s.MemWrite    then falha(ctx & ": MemWrite="    & to_string(MemWrite));    end if;
      if IRWrite     /= s.IRWrite     then falha(ctx & ": IRWrite="     & to_string(IRWrite));     end if;
      if RDMWrite    /= s.RDMWrite    then falha(ctx & ": RDMWrite="    & to_string(RDMWrite));    end if;
      if RegWrite    /= s.RegWrite    then falha(ctx & ": RegWrite="    & to_string(RegWrite));    end if;
      if MemtoReg    /= s.MemtoReg    then falha(ctx & ": MemtoReg="    & to_string(MemtoReg));    end if;
      if ULASrcA     /= s.ULASrcA     then falha(ctx & ": ULASrcA="     & to_string(ULASrcA));     end if;
      if ULASrcB     /= s.ULASrcB     then falha(ctx & ": ULASrcB="     & to_string(ULASrcB));     end if;
      if ULACtl      /= s.ULACtl      then falha(ctx & ": ULACtl="      & to_string(ULACtl) &
                                                 " esperado=" & to_string(s.ULACtl));            end if;
      if Halt        /= s.Halt        then falha(ctx & ": Halt="        & to_string(Halt));        end if;
      if RegSrc2     /= rs2           then falha(ctx & ": RegSrc2="     & to_string(RegSrc2));     end if;
    end procedure;

    -- Um ciclo de clock com en = e. Depois da borda, en volta a 0 (pulso de 1 ciclo).
    procedure ciclo(e : std_logic) is
    begin
      wait until falling_edge(clk);
      en <= e;
      wait until rising_edge(clk);
      wait for 1 ns;
      en <= '0';
    end procedure;

    -- Lógica do desvio do cpu.vhd (D2): o PC carrega se PCWrite or (PCWriteCond and cond).
    procedure confere_desvio(op : std_logic_vector(3 downto 0)) is
      variable cond, pc_load : std_logic;
      variable tomado        : std_logic;
    begin
      for z in std_logic range '0' to '1' loop
        if op(0) = '0' then cond := z; else cond := not z; end if;  -- op(0) = RI[12]
        pc_load := PCWrite or (PCWriteCond and cond);
        if op = OP_BEQ then tomado := z; else tomado := not z; end if;
        if pc_load /= tomado then
          falha(nome_estado(Estado) & " op=" & to_string(op) & " Zero=" & to_string(z) &
                ": pc_load=" & to_string(pc_load));
        elsif tomado = '1' then
          report "OK: op=" & to_string(op) & " Zero=" & to_string(z) & " -> desvio tomado" severity note;
        else
          report "OK: op=" & to_string(op) & " Zero=" & to_string(z) & " -> desvio nao tomado" severity note;
        end if;
      end loop;
    end procedure;

    -- Roda uma instrução inteira a partir de BUSCA.
    -- Antes de cada passo há um ciclo com en = 0, que não pode mudar nada.
    procedure instrucao(op : std_logic_vector(3 downto 0); seq : t_seq; nome : string) is
      variable antes : natural;
    begin
      antes := erros;
      wait until falling_edge(clk);
      opcode <= op;
      wait for 1 ns;
      for i in seq'range loop
        confere(seq(i), op, nome & " passo " & integer'image(i + 1) & " (" & nome_estado(seq(i)) & ")");
        if seq(i) = E_DESVIO then
          confere_desvio(op);
        end if;
        ciclo('0');
        confere(seq(i), op, nome & " en=0 em " & nome_estado(seq(i)));
        ciclo('1');
      end loop;
      if seq(seq'high) /= E_HALT then
        confere(E_BUSCA, op, nome & " volta para BUSCA");
      end if;
      if erros = antes then
        report "OK: " & nome & " (" & integer'image(seq'length) & " estados)" severity note;
      end if;
    end procedure;

    -- Depois de chegar em HALT: fica parado com en, e só o reset tira.
    procedure fica_em_halt(op : std_logic_vector(3 downto 0); nome : string) is
      variable antes : natural;
    begin
      antes := erros;
      for i in 1 to 3 loop
        ciclo('1');
        confere(E_HALT, op, nome & " parado em HALT, pulso " & integer'image(i));
      end loop;
      wait until falling_edge(clk);
      en <= '0';
      wait for 3 ns;
      rst <= '1';
      wait for 1 ns;
      confere(E_BUSCA, op, nome & " reset sai do HALT");
      wait until falling_edge(clk);
      rst <= '0';
      if erros = antes then
        report "OK: " & nome & " fica em HALT ate o reset" severity note;
      end if;
    end procedure;

  begin
    -- Reset inicial: começa em BUSCA mesmo com en = 1.
    en <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;
    confere(E_BUSCA, OP_ADD, "reset com en=1");
    wait until falling_edge(clk);
    rst <= '0';
    en  <= '0';

    -- Tipo R (D1)
    instrucao(OP_ADD, SEQ_R, "ADD");
    instrucao(OP_SUB, SEQ_R, "SUB");
    instrucao(OP_AND, SEQ_R, "AND");
    instrucao(OP_OR,  SEQ_R, "OR");
    instrucao(OP_SLT, SEQ_R, "SLT");

    -- Tipo I
    instrucao(OP_ADDI, SEQ_ADDI, "ADDI");
    instrucao(OP_LD,   SEQ_LD,   "LD");
    instrucao(OP_ST,   SEQ_ST,   "ST");

    -- Desvios: tomado e não tomado conferidos no DESVIO
    instrucao(OP_BEQ, SEQ_BR, "BEQ");
    instrucao(OP_BNE, SEQ_BR, "BNE");

    instrucao(OP_JMP, SEQ_JMP, "JMP");

    -- Reset assíncrono no meio de um LD (em MEM_LER)
    wait until falling_edge(clk);
    opcode <= OP_LD;
    for i in 1 to 4 loop
      ciclo('1');
    end loop;
    confere(E_MEM_LER, OP_LD, "LD antes do reset");
    wait until falling_edge(clk);
    en <= '0';
    wait for 3 ns;
    rst <= '1';
    wait for 1 ns;
    confere(E_BUSCA, OP_LD, "reset assincrono no MEM_LER");
    wait until falling_edge(clk);
    rst <= '0';

    -- Depois do reset, uma instrução normal volta a funcionar
    instrucao(OP_ADD, SEQ_R, "ADD apos reset");

    -- HALT e opcodes livres (D6)
    instrucao(OP_HALT, SEQ_HALT, "HALT");
    fica_em_halt(OP_HALT, "HALT");
    for op in 11 to 14 loop
      instrucao(std_logic_vector(to_unsigned(op, 4)), SEQ_HALT,
                "opcode livre " & to_string(std_logic_vector(to_unsigned(op, 4))));
      fica_em_halt(std_logic_vector(to_unsigned(op, 4)),
                   "opcode livre " & to_string(std_logic_vector(to_unsigned(op, 4))));
    end loop;

    if erros = 0 then
      report "TODOS OS TESTES PASSARAM (unidade_controle)" severity note;
    else
      report "TESTES COM FALHA (unidade_controle): " & integer'image(erros) severity failure;
    end if;
    fim <= true;
    wait;
  end process;

end architecture teste;
