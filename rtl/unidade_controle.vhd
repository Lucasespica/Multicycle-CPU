-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Unidade de controle: máquina de estados (Moore) com 13 estados.
-- O registrador de estado guarda direto o código do cpu_pkg, que é o mesmo
-- mostrado em LEDG[3:0]. Muda de estado só quando en = '1'; rst é assíncrono
-- e volta para BUSCA. Sinais por estado: doc/divisao_cpu.md, seção 4.
--   D1: no EXEC_R o opcode tipo R vira ULACtl.
--   D3: RegSrc2 = 1 para ST, BEQ e BNE, em qualquer estado.
--   D5: MEM_LER e MEM_LER2 repetem A + imm na ULA.
--   D6: opcodes livres (1011 a 1110) vão para HALT, como o próprio HALT.
-- Zero não entra aqui: a condição do desvio fica no cpu.vhd (D2).
library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity unidade_controle is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    en          : in  std_logic;
    opcode      : in  std_logic_vector(3 downto 0);
    PCWrite     : out std_logic;
    PCWriteCond : out std_logic;
    PCSource    : out std_logic_vector(1 downto 0);
    IorD        : out std_logic;
    MemWrite    : out std_logic;
    IRWrite     : out std_logic;
    RDMWrite    : out std_logic;
    RegWrite    : out std_logic;
    RegSrc2     : out std_logic;
    MemtoReg    : out std_logic;
    ULASrcA     : out std_logic;
    ULASrcB     : out std_logic_vector(1 downto 0);
    ULACtl      : out std_logic_vector(2 downto 0);
    Halt        : out std_logic;
    Estado      : out std_logic_vector(3 downto 0)
  );
end entity unidade_controle;

architecture fsm of unidade_controle is
  signal estado_atual, estado_prox : std_logic_vector(3 downto 0);
begin

  -- Registrador de estado
  process (clk, rst)
  begin
    if rst = '1' then
      estado_atual <= E_BUSCA;
    elsif rising_edge(clk) then
      if en = '1' then
        estado_atual <= estado_prox;
      end if;
    end if;
  end process;

  -- Próximo estado
  process (estado_atual, opcode)
  begin
    case estado_atual is
      when E_BUSCA  => estado_prox <= E_BUSCA2;
      when E_BUSCA2 => estado_prox <= E_DECOD;

      when E_DECOD =>
        case opcode is
          when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_SLT => estado_prox <= E_EXEC_R;
          when OP_ADDI | OP_LD | OP_ST                   => estado_prox <= E_EXEC_I;
          when OP_BEQ | OP_BNE                           => estado_prox <= E_DESVIO;
          when OP_JMP                                    => estado_prox <= E_SALTO;
          when others                                    => estado_prox <= E_HALT;  -- HALT e D6
        end case;

      when E_EXEC_R => estado_prox <= E_ESCRITA_ULA;

      when E_EXEC_I =>
        case opcode is
          when OP_LD  => estado_prox <= E_MEM_LER;
          when OP_ST  => estado_prox <= E_MEM_ESCR;
          when others => estado_prox <= E_ESCRITA_ULA;  -- ADDI
        end case;

      when E_MEM_LER  => estado_prox <= E_MEM_LER2;
      when E_MEM_LER2 => estado_prox <= E_ESCRITA_MEM;

      when E_ESCRITA_ULA | E_ESCRITA_MEM | E_MEM_ESCR | E_DESVIO | E_SALTO =>
        estado_prox <= E_BUSCA;

      when E_HALT => estado_prox <= E_HALT;  -- só sai com reset

      when others => estado_prox <= E_BUSCA; -- 1101 a 1111 não existem
    end case;
  end process;

  -- Saídas: dependem só do estado (e do opcode no EXEC_R, D1)
  process (estado_atual, opcode)
  begin
    PCWrite     <= '0';
    PCWriteCond <= '0';
    PCSource    <= "00";
    IorD        <= '0';
    MemWrite    <= '0';
    IRWrite     <= '0';
    RDMWrite    <= '0';
    RegWrite    <= '0';
    MemtoReg    <= '0';
    ULASrcA     <= '0';
    ULASrcB     <= "00";
    ULACtl      <= ULA_AND;
    Halt        <= '0';

    case estado_atual is
      when E_BUSCA =>                 -- endereço da memória <- PC
        IorD <= '0';

      when E_BUSCA2 =>                -- RI <- Mem; RDM <- Mem; PC <- PC + 1
        PCWrite  <= '1';
        PCSource <= "00";
        IorD     <= '0';
        IRWrite  <= '1';
        RDMWrite <= '1';
        ULASrcA  <= '0';
        ULASrcB  <= "01";
        ULACtl   <= ULA_ADD;

      when E_DECOD =>                 -- SaídaULA <- PC + ext(imm)
        ULASrcA <= '0';
        ULASrcB <= "10";
        ULACtl  <= ULA_ADD;

      when E_EXEC_R =>                -- SaídaULA <- A op B
        ULASrcA <= '1';
        ULASrcB <= "00";
        case opcode is
          when OP_SUB => ULACtl <= ULA_SUB;
          when OP_AND => ULACtl <= ULA_AND;
          when OP_OR  => ULACtl <= ULA_OR;
          when OP_SLT => ULACtl <= ULA_SLT;
          when others => ULACtl <= ULA_ADD;  -- ADD
        end case;

      when E_EXEC_I =>                -- SaídaULA <- A + ext(imm)
        ULASrcA <= '1';
        ULASrcB <= "10";
        ULACtl  <= ULA_ADD;

      when E_ESCRITA_ULA =>           -- R[Ri] <- SaídaULA
        RegWrite <= '1';
        MemtoReg <= '0';

      when E_MEM_LER =>               -- endereço <- SaídaULA; ULA repete A + imm (D5)
        IorD    <= '1';
        ULASrcA <= '1';
        ULASrcB <= "10";
        ULACtl  <= ULA_ADD;

      when E_MEM_LER2 =>              -- RDM <- Mem; ULA repete A + imm (D5)
        IorD     <= '1';
        RDMWrite <= '1';
        ULASrcA  <= '1';
        ULASrcB  <= "10";
        ULACtl   <= ULA_ADD;

      when E_ESCRITA_MEM =>           -- R[Ri] <- RDM
        RegWrite <= '1';
        MemtoReg <= '1';

      when E_MEM_ESCR =>              -- Mem[SaídaULA] <- B
        IorD     <= '1';
        MemWrite <= '1';

      when E_DESVIO =>                -- ULA faz A - B; PC <- SaídaULA se a condição valer
        PCWriteCond <= '1';
        PCSource    <= "01";
        ULASrcA     <= '1';
        ULASrcB     <= "00";
        ULACtl      <= ULA_SUB;

      when E_SALTO =>                 -- PC <- "0000" & end
        PCWrite  <= '1';
        PCSource <= "10";

      when E_HALT =>
        Halt <= '1';

      when others =>
        null;
    end case;
  end process;

  -- D3: depende só do opcode
  RegSrc2 <= '1' when opcode = OP_ST or opcode = OP_BEQ or opcode = OP_BNE else '0';

  Estado <= estado_atual;

end architecture fsm;
