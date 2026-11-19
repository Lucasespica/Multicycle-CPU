# Uso de IA

Cada integrante anota o que fez com IA e por quê. P5 consolida esta seção no PDF.

## P2 – Unidade de controle

- **Ferramenta:** Claude (Claude Code).
- **O que foi feito:** a primeira versão de `rtl/unidade_controle.vhd`, `tb/unidade_controle_tb.vhd`, `doc/unidade_controle.md` e `doc/estados.drawio`. A IA partiu da tabela de sinais por estado e das decisões D1 a D8 do `doc/divisao_cpu.md`.
- **Por quê:** a FSM e a tabela de sinais já estavam definidas no plano. A IA foi usada para transcrever a tabela para VHDL e montar um testbench que confere a FSM contra a mesma tabela.
- **Revisão:** conferir a tabela de sinais com o grupo e rodar `do tb/rodar.do unidade_controle_tb` no ModelSim.

## P4 – Memória e programas de teste

- **Ferramenta:** Claude (Claude Code).
- **O que foi feito:** `rtl/memoria.vhd` (altsyncram), `tb/memoria_tb.vhd`, `tb/cpu_tb.vhd`, os 4 programas de `mif/` e `doc/testes.md`. A IA codificou os programas a partir da tabela de opcodes e do rascunho do `final.mif` no `doc/divisao_cpu.md`, e calculou as tabelas de valores esperados com um script de apoio, que não faz parte da entrega.
- **Por quê:** a codificação à mão de cada instrução em binário e os valores esperados são trabalhosos e fáceis de errar. Com o script, a mesma fonte gera o .mif, a tabela do relatório e a lista de valores esperados do `cpu_tb`.
- **Revisão:** conferir a codificação de algumas instruções à mão (por exemplo `ADD R1, R2, R3` = 0x0298 e `BNE R1, R0, laco` = 0x923D) e rodar `do tb/rodar.do cpu_tb` no ModelSim. Para confirmar que o testbench detecta erros, foram introduzidos 3 erros de propósito numa cópia do código (ver `doc/testes.md`).
