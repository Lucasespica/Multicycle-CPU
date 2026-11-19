-- =====================================================================
-- CPU multiciclo de 16 bits - Arquitetura de Sistemas Computacionais
-- PUC-Campinas, 2026
--   Antonio Magalhaes Roquete Macedo
--   Guilherme Eid Godoy
--   Lucas Espica Rezende
--   Lucas Kitsuta Sabino
--   Rafael Martiniano Nogueira Filho
-- =====================================================================
-- Memória única de 4096 x 16 (programa e dados), inicializada por ARQ_MIF.
-- altsyncram de uma porta: endereço, dado e wren registrados na borda de
-- clock; saída q não registrada (o dado sai um ciclo depois do endereço).
-- Grava data em address na borda em que wren = '1' (D7: sem passar pelo en).
-- O caminho de ARQ_MIF é relativo à pasta de onde se compila ou simula:
-- "../mif/x.mif" no Quartus (pasta quartus/) e "mif/x.mif" no ModelSim (raiz).
library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity memoria is
  generic (
    ARQ_MIF : string := "../mif/final.mif"
  );
  port (
    clock   : in  std_logic;
    wren    : in  std_logic;
    address : in  std_logic_vector(11 downto 0);
    data    : in  std_logic_vector(15 downto 0);
    q       : out std_logic_vector(15 downto 0)
  );
end entity memoria;

architecture ram of memoria is
begin

  u_ram : altsyncram
    generic map (
      operation_mode                => "SINGLE_PORT",
      intended_device_family        => "Cyclone IV E",
      lpm_type                      => "altsyncram",
      lpm_hint                      => "ENABLE_RUNTIME_MOD=NO",
      width_a                       => 16,
      widthad_a                     => 12,
      numwords_a                    => 4096,
      width_byteena_a               => 1,
      outdata_reg_a                 => "UNREGISTERED",
      outdata_aclr_a                => "NONE",
      clock_enable_input_a          => "BYPASS",
      clock_enable_output_a         => "BYPASS",
      power_up_uninitialized        => "FALSE",
      read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
      init_file                     => ARQ_MIF
    )
    port map (
      clock0    => clock,
      wren_a    => wren,
      address_a => address,
      data_a    => data,
      q_a       => q
    );

end architecture ram;
