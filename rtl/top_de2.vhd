-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Entidade de topo da DE2-115. KEY0 = passo (en), KEY3 = reset, SW17 escolhe RDM ou ULA.
-- HEX0-3 = PC, HEX4-7 = RDM (SW17 = 0) ou saída da ULA (SW17 = 1),
-- LEDG[3:0] = estado, LEDG8 = HALT. Os KEY são ativos em nível baixo.
-- Para gravar outro programa, troque ARQ_MIF (caminho relativo à pasta quartus/).
library ieee;
use ieee.std_logic_1164.all;

entity top_de2 is
  generic (
    ARQ_MIF : string := "../mif/final.mif"
  );
  port (
    CLOCK_50 : in  std_logic;
    KEY      : in  std_logic_vector(3 downto 0);
    SW       : in  std_logic_vector(17 downto 0);
    HEX0     : out std_logic_vector(6 downto 0);
    HEX1     : out std_logic_vector(6 downto 0);
    HEX2     : out std_logic_vector(6 downto 0);
    HEX3     : out std_logic_vector(6 downto 0);
    HEX4     : out std_logic_vector(6 downto 0);
    HEX5     : out std_logic_vector(6 downto 0);
    HEX6     : out std_logic_vector(6 downto 0);
    HEX7     : out std_logic_vector(6 downto 0);
    LEDG     : out std_logic_vector(8 downto 0)
  );
end entity top_de2;

architecture estrutura of top_de2 is
  signal rst, botao, en, halt : std_logic;
  signal pc, rdm, ula, dado   : std_logic_vector(15 downto 0);
  signal estado               : std_logic_vector(3 downto 0);
begin

  -- ---------------- Botões ----------------
  rst   <= not KEY(3);   -- reset ativo alto, assíncrono
  botao <= not KEY(0);   -- '1' enquanto apertado

  u_deb : entity work.debouncer
    port map (clk => CLOCK_50, botao => botao, pulso => en);

  -- ---------------- CPU ----------------
  u_cpu : entity work.cpu
    generic map (ARQ_MIF => ARQ_MIF)
    port map (
      clk => CLOCK_50, rst => rst, en => en,
      pc_out => pc, rdm_out => rdm, ula_out => ula,
      estado => estado, halt => halt
    );

  -- ---------------- Displays ----------------
  -- SW17 multiplexa o que aparece em HEX4-7
  dado <= ula when SW(17) = '1' else rdm;

  u_hex0 : entity work.hex7seg port map (valor => pc(3 downto 0),     seg => HEX0);
  u_hex1 : entity work.hex7seg port map (valor => pc(7 downto 4),     seg => HEX1);
  u_hex2 : entity work.hex7seg port map (valor => pc(11 downto 8),    seg => HEX2);
  u_hex3 : entity work.hex7seg port map (valor => pc(15 downto 12),   seg => HEX3);
  u_hex4 : entity work.hex7seg port map (valor => dado(3 downto 0),   seg => HEX4);
  u_hex5 : entity work.hex7seg port map (valor => dado(7 downto 4),   seg => HEX5);
  u_hex6 : entity work.hex7seg port map (valor => dado(11 downto 8),  seg => HEX6);
  u_hex7 : entity work.hex7seg port map (valor => dado(15 downto 12), seg => HEX7);

  -- ---------------- LEDs ----------------
  LEDG(3 downto 0) <= estado;
  LEDG(7 downto 4) <= (others => '0');
  LEDG(8)          <= halt;

end architecture estrutura;
