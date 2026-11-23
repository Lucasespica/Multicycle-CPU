-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo   RA 24013443
--   Guilherme Eid Godoy                RA 24002322
--   Lucas Espica Rezende               RA 24006575
--   Lucas Kitsuta Sabino               RA 24001484
--   Rafael Martiniano Nogueira Filho   RA 24008538
-- =====================================================================
-- Debounce do botão (Lab05) mais detector de borda: gera um pulso de um ciclo
-- de clk a cada aperto. botao é '1' enquanto apertado (o top inverte o KEY).
--   1. Sincronizador de 2 flip-flops: o botão é assíncrono ao CLOCK_50.
--   2. Filtro: o valor estável só muda depois de LIMITE ciclos seguidos
--      com o mesmo valor novo (20 ms a 50 MHz). A trepidação zera a contagem.
--   3. Detector de borda de subida: pulso = estável agora e não no ciclo anterior.
library ieee;
use ieee.std_logic_1164.all;

entity debouncer is
  generic (
    LIMITE : positive := 1_000_000   -- 20 ms a 50 MHz
  );
  port (
    clk   : in  std_logic;
    botao : in  std_logic;
    pulso : out std_logic
  );
end entity debouncer;

architecture filtro of debouncer is
  signal sinc1, sinc2         : std_logic := '0';
  signal estavel, estavel_ant : std_logic := '0';
  signal cont                 : natural range 0 to LIMITE - 1 := 0;
begin

  process (clk)
  begin
    if rising_edge(clk) then
      -- 1. sincronizador
      sinc1 <= botao;
      sinc2 <= sinc1;

      -- 2. filtro de trepidação
      if sinc2 = estavel then
        cont <= 0;
      elsif cont = LIMITE - 1 then
        estavel <= sinc2;
        cont    <= 0;
      else
        cont <= cont + 1;
      end if;

      -- 3. valor do ciclo anterior, para o detector de borda
      estavel_ant <= estavel;
    end if;
  end process;

  pulso <= estavel and not estavel_ant;

end architecture filtro;
