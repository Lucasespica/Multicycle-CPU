# Multicycle-CPU

CPU **multiciclo de 16 bits** em VHDL, com 11 instruções e mais HALT. Ela é testada em simulação no ModelSim e na placa **Terasic DE2-115** (Cyclone IV E, EP4CE115F29C7).

Projeto da disciplina Arquitetura de Sistemas Computacionais da PUC-Campinas. A entrega é em **27/11/2026**.

## A CPU em resumo

- Palavra e instrução de 16 bits. São 8 registradores de 16 bits, de R0 a R7, e o R0 vale sempre zero.
- Uma única memória de 4096 × 16 guarda programa e dados. Ela é inicializada por um arquivo `.mif`.
- A unidade de controle é uma máquina de estados com 13 estados. O estado atual aparece nos LEDs verdes.
- Todo o circuito roda em `CLOCK_50`. Cada aperto de KEY0 gera um pulso `en` de um ciclo, que avança um estado.

| Opcode | Instrução | Tipo | Significado |
|---|---|---|---|
| 0000 | `ADD Ri, Rj, Rk` | R | Ri ← Rj + Rk |
| 0001 | `SUB Ri, Rj, Rk` | R | Ri ← Rj − Rk |
| 0010 | `AND Ri, Rj, Rk` | R | Ri ← Rj and Rk (bit a bit) |
| 0011 | `OR Ri, Rj, Rk` | R | Ri ← Rj or Rk (bit a bit) |
| 0100 | `SLT Ri, Rj, Rk` | R | Ri ← 1 se Rj < Rk (com sinal), senão 0 |
| 0101 | `ADDI Ri, Rj, imm` | I | Ri ← Rj + imm |
| 0110 | `LD Ri, Rj, imm` | I | Ri ← Mem[Rj + imm] |
| 0111 | `ST Ri, Rj, imm` | I | Mem[Rj + imm] ← Ri |
| 1000 | `BEQ Ri, Rj, imm` | I | se Ri = Rj: PC ← PC + 1 + imm |
| 1001 | `BNE Ri, Rj, imm` | I | se Ri ≠ Rj: PC ← PC + 1 + imm |
| 1010 | `JMP end` | J | PC ← end (12 bits, completados com zeros) |
| 1111 | `HALT` | – | para a CPU |

```
Tipo R:  | opcode 15..12 | Ri 11..9 | Rj 8..6 | Rk 5..3 | 000 2..0 |
Tipo I:  | opcode 15..12 | Ri 11..9 | Rj 8..6 |  imediato 5..0 (−32 a +31) |
Tipo J:  | opcode 15..12 |                end 11..0                    |
```

## Uso da placa

| Recurso | Função |
|---|---|
| KEY0 | Clock manual: cada aperto avança um estado (com debouncer) |
| KEY3 | Reset |
| HEX0–HEX3 | PC em hexadecimal |
| HEX4–HEX7 | RDM (SW17 = 0) ou saída da ULA (SW17 = 1) |
| LEDG[3:0] | Código do estado da unidade de controle |
| LEDG8 | CPU parada em HALT |

## Estrutura de arquivos

O git não guarda pastas vazias. Cada pasta passa a existir no repositório quando recebe o primeiro arquivo.

```
Multicycle-CPU/
├── README.md                   
├── .gitignore                  arquivos gerados pelo Quartus e pelo ModelSim
├── rtl/                        código VHDL sintetizável
│   ├── cpu_pkg.vhd             opcodes, códigos dos estados e da ULA (compilar primeiro)
│   ├── ula.vhd                 ULA do Lab04: AND, OR, soma, subtração, SLT, NOR
│   ├── reg16.vhd               registrador genérico com en e load (PC, RI, RDM, A, B, SaídaULA)
│   ├── banco_regs.vhd          8 registradores de 16 bits, R0 = 0
│   ├── ext_sinal.vhd           extensão de sinal de 6 para 16 bits
│   ├── memoria.vhd             RAM 4096 × 16 (altsyncram) inicializada por .mif
│   ├── unidade_controle.vhd    máquina de estados com 13 estados e todos os sinais de controle
│   ├── cpu.vhd                 caminho de dados: liga todos os componentes acima
│   ├── debouncer.vhd           debounce do botão e detector de borda (gera o pulso en)
│   ├── hex7seg.vhd             hexadecimal para 7 segmentos (ativo em nível baixo)
│   └── top_de2.vhd             entidade de topo: liga a CPU aos pinos da DE2-115
├── tb/                         testbenches (só simulação)
│   ├── rodar.do                script do ModelSim: compila tudo e roda os testes
│   ├── ula_tb.vhd
│   ├── banco_regs_tb.vhd
│   ├── memoria_tb.vhd
│   ├── unidade_controle_tb.vhd
│   └── cpu_tb.vhd              roda um programa .mif e confere os registradores
├── mif/                        programas de teste, codificados à mão (cada um termina em HALT)
│   ├── t1_ula.mif              ADD, SUB, AND, OR, SLT e ADDI
│   ├── t2_mem.mif              LD e ST
│   ├── t3_desvios.mif          BEQ, BNE, JMP e HALT
│   └── final.mif               programa completo: soma de 1 a N
├── quartus/
│   ├── cpu.qpf                 projeto do Quartus
│   └── cpu.qsf                 dispositivo, lista de arquivos e pinagem da DE2-115
└── doc/
    ├── divisao_cpu.md          plano de ação: decisões, divisão do trabalho, cronograma e interfaces
    ├── img/                    diagramas, prints das formas de onda e fotos da placa
    ├── caminho_de_dados.drawio
    ├── estados.drawio
    ├── testes.md               programas de teste, valores esperados e resultados da simulação
    └── uso_de_ia.md            o que foi feito com IA e por quê (seção do relatório)
```

### Equipe e responsáveis por arquivo

| Papel | Responsável | Arquivos |
|---|---|---|
| P1 Integração | Lucas K. | `cpu_pkg.vhd`, `cpu.vhd`, `quartus/`, `tb/rodar.do`, `doc/caminho_de_dados.drawio` |
| P2 Controle | Gui | `unidade_controle.vhd`, `unidade_controle_tb.vhd`, `doc/estados.drawio` |
| P3 ULA e componentes | Lucas Espica | `ula.vhd`, `reg16.vhd`, `banco_regs.vhd`, `ext_sinal.vhd` e os testbenches deles |
| P4 Memória e testes | Lucas K. e Rafa | `memoria.vhd`, `memoria_tb.vhd`, `cpu_tb.vhd`, `mif/` |
| P5 Placa e documento | Lucas K. e Rafa | `top_de2.vhd`, `debouncer.vhd`, `hex7seg.vhd`, `doc/img/`, PDF final |

## Como simular (ModelSim-Intel)

1. Abra o ModelSim e vá para a pasta raiz do repositório: `File > Change Directory`.
2. No Transcript, rode:

   ```
   do tb/rodar.do
   ```

3. Cada testbench escreve `OK` ou `FALHOU` no Transcript.

A memória usa a biblioteca `altera_mf`, então a simulação precisa do ModelSim que vem com o Quartus.

## Como compilar e gravar (Quartus Prime Lite 20.1)

1. `File > Open Project` e escolha `quartus/cpu.qpf`.
2. `Processing > Start Compilation`.
3. `Tools > Programmer`, com o USB-Blaster no modo JTAG, e grave `output_files/cpu.sof`.

Clone o repositório num caminho **sem acentos nem espaços**. O Quartus e o ModelSim falham com caminhos como `Área de Trabalho`.

## Regras do grupo

- **Branches:** um por papel, `p1-integracao`, `p2-controle`, `p3-componentes`, `p4-memoria-testes` e `p5-placa`. O merge na `main` é feito pelo P1, depois que o testbench do módulo passa.
- **Comentários:** só o mínimo para dizer o que o arquivo ou o bloco faz. Os nomes dos integrantes ficam só neste README.
- **Nomes:** os sinais têm o mesmo nome no VHDL, no diagrama de caminho de dados e na tabela de sinais.
- **Arquivos gerados:** os do Quartus e do ModelSim não entram no git. O `.gitignore` já cuida disso.
- **Uso de IA:** registre em `doc/uso_de_ia.md` o que foi feito com IA e por quê.
