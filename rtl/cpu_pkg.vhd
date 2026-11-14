-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Constantes compartilhadas: opcodes, códigos dos estados (LEDG[3:0]) e ULACtl.
library ieee;
use ieee.std_logic_1164.all;

package cpu_pkg is

  constant OP_ADD  : std_logic_vector(3 downto 0) := "0000";
  constant OP_SUB  : std_logic_vector(3 downto 0) := "0001";
  constant OP_AND  : std_logic_vector(3 downto 0) := "0010";
  constant OP_OR   : std_logic_vector(3 downto 0) := "0011";
  constant OP_SLT  : std_logic_vector(3 downto 0) := "0100";
  constant OP_ADDI : std_logic_vector(3 downto 0) := "0101";
  constant OP_LD   : std_logic_vector(3 downto 0) := "0110";
  constant OP_ST   : std_logic_vector(3 downto 0) := "0111";
  constant OP_BEQ  : std_logic_vector(3 downto 0) := "1000";
  constant OP_BNE  : std_logic_vector(3 downto 0) := "1001";
  constant OP_JMP  : std_logic_vector(3 downto 0) := "1010";
  constant OP_HALT : std_logic_vector(3 downto 0) := "1111";

  constant E_BUSCA       : std_logic_vector(3 downto 0) := "0000";
  constant E_BUSCA2      : std_logic_vector(3 downto 0) := "0001";
  constant E_DECOD       : std_logic_vector(3 downto 0) := "0010";
  constant E_EXEC_R      : std_logic_vector(3 downto 0) := "0011";
  constant E_EXEC_I      : std_logic_vector(3 downto 0) := "0100";
  constant E_ESCRITA_ULA : std_logic_vector(3 downto 0) := "0101";
  constant E_MEM_LER     : std_logic_vector(3 downto 0) := "0110";
  constant E_MEM_LER2    : std_logic_vector(3 downto 0) := "0111";
  constant E_ESCRITA_MEM : std_logic_vector(3 downto 0) := "1000";
  constant E_MEM_ESCR    : std_logic_vector(3 downto 0) := "1001";
  constant E_DESVIO      : std_logic_vector(3 downto 0) := "1010";
  constant E_SALTO       : std_logic_vector(3 downto 0) := "1011";
  constant E_HALT        : std_logic_vector(3 downto 0) := "1100";

  constant ULA_AND : std_logic_vector(2 downto 0) := "000";
  constant ULA_OR  : std_logic_vector(2 downto 0) := "001";
  constant ULA_ADD : std_logic_vector(2 downto 0) := "010";
  constant ULA_SUB : std_logic_vector(2 downto 0) := "100";
  constant ULA_SLT : std_logic_vector(2 downto 0) := "110";

end package cpu_pkg;
