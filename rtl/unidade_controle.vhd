-- Unidade de controle: máquina de estados com 13 estados (cpu_pkg).
-- Muda de estado só quando en = '1'. Sinais por estado: doc/divisao_cpu.md, seção 4.
-- ESQUELETO: implementar (P2).
library ieee;
use ieee.std_logic_1164.all;

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

architecture esqueleto of unidade_controle is
begin
  PCWrite     <= '0';
  PCWriteCond <= '0';
  PCSource    <= "00";
  IorD        <= '0';
  MemWrite    <= '0';
  IRWrite     <= '0';
  RDMWrite    <= '0';
  RegWrite    <= '0';
  RegSrc2     <= '0';
  MemtoReg    <= '0';
  ULASrcA     <= '0';
  ULASrcB     <= "00";
  ULACtl      <= "000";
  Halt        <= '0';
  Estado      <= "0000";
end architecture esqueleto;
