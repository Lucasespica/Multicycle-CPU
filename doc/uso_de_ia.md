# Uso de IA

Cada integrante anota o que fez com IA e por quê. P5 consolida esta seção no PDF.

## P1 – Arquitetura e integração

- **Ferramenta:** Claude (Claude Code).
- **O que foi feito com IA:** a organização do plano do P1 (`plano_p1.md`) e do contrato de interfaces, com as portas de cada entidade e o `rtl/cpu_pkg.vhd` (opcodes, estados e códigos da ULA); os esqueletos das entidades; o projeto do Quartus (`quartus/cpu.qpf` e `cpu.qsf`, com a pinagem da DE2-115) e o `tb/rodar.do`; o README e o `.gitignore`; e os rascunhos de `doc/caminho_de_dados.drawio` e `doc/topologia.md`. A IA partiu do `doc/divisao_cpu.md` e das decisões D1 a D8, e não propôs um desenho próprio.
- **`rtl/cpu.vhd`:** escrito à mão pelo P1. A IA foi usada como apoio de estudo: para entender a sintaxe e os padrões de VHDL necessários (instanciação de componentes, `with … select` para os muxes, sinais internos e a lógica de carga do PC) e para orientar a ordem de montagem do caminho de dados. O código em si não foi gerado pela IA.
- **Por quê:** o caminho de dados já estava definido no plano do grupo. Escrever o `cpu.vhd` à mão foi uma forma de entender como cada registrador e cada mux se ligam, e a IA serviu para tirar dúvidas de VHDL no caminho. No restante, a IA foi usada para montar logo no início a estrutura do repositório e do projeto do Quartus, para que os outros integrantes tivessem as portas congeladas desde o kickoff.
- **Decisões do P1:** D2 (a condição do desvio fica no `cpu.vhd`: `pc_load = PCWrite or (PCWriteCond and cond)`), D4 (A, B e SaídaULA carregam a cada `en`), D7 (`wren = MemWrite`, sem passar pelo `en`) e D8 (os muxes ficam dentro do `cpu.vhd`).
- **Revisão:** conferir cada instrução pela tabela de sinais por estado (seção 6 do `plano_p1.md`), fazer a revisão cruzada com o P2 (controle × caminho de dados) e rodar `do tb/rodar.do cpu_tb` com os 4 programas na integração.

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
