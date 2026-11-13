-- Caminho de dados da CPU multiciclo: liga controle, banco, ULA, memória
-- e os registradores PC, RI, RDM, A, B e SaídaULA.
-- Tudo roda em clk (CLOCK_50); registradores só mudam quando en = '1'.
library ieee;
use ieee.std_logic_1164.all;

entity cpu is
  generic (
    ARQ_MIF : string := "../mif/final.mif"
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    en      : in  std_logic;
    pc_out  : out std_logic_vector(15 downto 0);
    rdm_out : out std_logic_vector(15 downto 0);
    ula_out : out std_logic_vector(15 downto 0);
    estado  : out std_logic_vector(3 downto 0);
    halt    : out std_logic
  );
end entity cpu;

architecture estrutura of cpu is

  signal PCWrite, PCWriteCond : std_logic;
  signal PCSource             : std_logic_vector(1 downto 0);
  signal IorD, MemWrite       : std_logic;
  signal IRWrite, RDMWrite    : std_logic;
  signal RegWrite, RegSrc2    : std_logic;
  signal MemtoReg             : std_logic;
  signal ULASrcA              : std_logic;
  signal ULASrcB              : std_logic_vector(1 downto 0);
  signal ULACtl               : std_logic_vector(2 downto 0);

  signal pc, ri, rdm, reg_a, reg_b, saida_ula : std_logic_vector(15 downto 0);

  signal pc_prox, mem_q, wd, rd1, rd2  : std_logic_vector(15 downto 0);
  signal imm_ext, end_jmp              : std_logic_vector(15 downto 0);
  signal ula_a, ula_b, ula_r           : std_logic_vector(15 downto 0);
  signal mem_addr                      : std_logic_vector(11 downto 0);
  signal ra2                           : std_logic_vector(2 downto 0);
  signal pc_load, cond, zero           : std_logic;

  alias f_op  : std_logic_vector(3 downto 0)  is ri(15 downto 12);
  alias f_ri  : std_logic_vector(2 downto 0)  is ri(11 downto 9);
  alias f_rj  : std_logic_vector(2 downto 0)  is ri(8 downto 6);
  alias f_rk  : std_logic_vector(2 downto 0)  is ri(5 downto 3);
  alias f_imm : std_logic_vector(5 downto 0)  is ri(5 downto 0);
  alias f_end : std_logic_vector(11 downto 0) is ri(11 downto 0);

begin

  u_controle : entity work.unidade_controle
    port map (
      clk => clk, rst => rst, en => en, opcode => f_op,
      PCWrite => PCWrite, PCWriteCond => PCWriteCond, PCSource => PCSource,
      IorD => IorD, MemWrite => MemWrite, IRWrite => IRWrite,
      RDMWrite => RDMWrite, RegWrite => RegWrite, RegSrc2 => RegSrc2,
      MemtoReg => MemtoReg, ULASrcA => ULASrcA, ULASrcB => ULASrcB,
      ULACtl => ULACtl, Halt => halt, Estado => estado
    );

  -- ---------------- PC ----------------
  end_jmp <= "0000" & f_end;

  with PCSource select
    pc_prox <= ula_r     when "00",   -- PC + 1
               saida_ula when "01",   -- destino do desvio
               end_jmp   when "10",   -- JMP
               x"0000"   when others;

  -- BEQ (bit 12 = 0) desvia com Zero; BNE (bit 12 = 1) desvia sem Zero
  cond    <= zero when ri(12) = '0' else not zero;
  pc_load <= PCWrite or (PCWriteCond and cond);

  u_pc : entity work.reg16
    port map (clk => clk, rst => rst, en => en, load => pc_load, d => pc_prox, q => pc);

  -- ---------------- Memória ----------------
  with IorD select
    mem_addr <= pc(11 downto 0)        when '0',
                saida_ula(11 downto 0) when others;

  u_mem : entity work.memoria
    generic map (ARQ_MIF => ARQ_MIF)
    port map (clock => clk, wren => MemWrite, address => mem_addr, data => reg_b, q => mem_q);

  u_ri : entity work.reg16
    port map (clk => clk, rst => rst, en => en, load => IRWrite, d => mem_q, q => ri);

  u_rdm : entity work.reg16
    port map (clk => clk, rst => rst, en => en, load => RDMWrite, d => mem_q, q => rdm);

  -- ---------------- Banco de registradores ----------------
  with RegSrc2 select
    ra2 <= f_rk when '0',   -- tipo R
           f_ri when others; -- ST, BEQ, BNE

  with MemtoReg select
    wd <= saida_ula when '0',
          rdm       when others;

  u_banco : entity work.banco_regs
    port map (clk => clk, rst => rst, en => en, RegWrite => RegWrite,
              ra1 => f_rj, ra2 => ra2, wa => f_ri, wd => wd, rd1 => rd1, rd2 => rd2);

  u_a : entity work.reg16
    port map (clk => clk, rst => rst, en => en, load => '1', d => rd1, q => reg_a);

  u_b : entity work.reg16
    port map (clk => clk, rst => rst, en => en, load => '1', d => rd2, q => reg_b);

  -- ---------------- ULA ----------------
  u_ext : entity work.ext_sinal
    port map (imm => f_imm, ext => imm_ext);

  with ULASrcA select
    ula_a <= pc    when '0',
             reg_a when others;

  with ULASrcB select
    ula_b <= reg_b   when "00",
             x"0001" when "01",
             imm_ext when "10",
             x"0000" when others;

  u_ula : entity work.ULA
    port map (A => ula_a, B => ula_b, ULACtl => ULACtl,
              R => ula_r, Zero => zero, Overflow => open, Cout => open);

  -- carrega a cada passo: o controle repete A + imm em MEM_LER/MEM_LER2
  u_saida_ula : entity work.reg16
    port map (clk => clk, rst => rst, en => en, load => '1', d => ula_r, q => saida_ula);

  -- ---------------- Saídas ----------------
  pc_out  <= pc;
  rdm_out <= rdm;
  ula_out <= ula_r;

end architecture estrutura;
