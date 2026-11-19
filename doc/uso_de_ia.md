# Uso de IA

Cada integrante anota o que fez com IA e por quê. P5 consolida esta seção no PDF.

## P2 – Unidade de controle

- **Ferramenta:** Claude (Claude Code).
- **O que foi feito:** a primeira versão de `rtl/unidade_controle.vhd`, `tb/unidade_controle_tb.vhd`, `doc/unidade_controle.md` e `doc/estados.drawio`. A IA partiu da tabela de sinais por estado e das decisões D1 a D8 do `doc/divisao_cpu.md`.
- **Por quê:** a FSM e a tabela de sinais já estavam definidas no plano. A IA foi usada para transcrever a tabela para VHDL e montar um testbench que confere a FSM contra a mesma tabela.
- **Revisão:** conferir a tabela de sinais com o grupo e rodar `do tb/rodar.do unidade_controle_tb` no ModelSim.
