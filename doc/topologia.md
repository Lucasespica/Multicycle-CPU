# Descrição e topologia da CPU

Seção do relatório (P1). O código está em `rtl/cpu.vhd`. O diagrama editável está em `doc/caminho_de_dados.drawio`.

> **Rascunho.** Os números de ciclos foram contados a partir da `unidade_controle.vhd`.

## Visão geral

A CPU executa as 11 instruções do enunciado mais HALT.

**Arquitetura:**
- **Palavra e instruções:** a palavra tem 16 bits, e as instruções também.
- **Registradores:** 8 de uso geral, de 16 bits. O R0 vale sempre zero.
- **Memória:** uma única, de 4096 × 16, guarda o programa e os dados (arquitetura Von Neumann). Ela é inicializada por um arquivo `.mif`.
- **Organização:** multiciclo. Cada instrução passa por 4 a 7 estados de uma máquina de estados com 13 estados. Em cada estado, a CPU faz no máximo uma operação na ULA e um acesso à memória.

A base é o caminho de dados multiciclo do Patterson & Hennessy, adaptado para 16 bits e para esta ISA.

**Diferenças em relação ao MIPS do livro:**
- O PC soma 1, e não 4, porque a memória é endereçada por palavra.
- O imediato tem 6 bits e não é deslocado antes de entrar na ULA.
- O endereço do JMP tem 12 bits, completados com zeros.
- Existe um mux a mais na 2ª leitura do banco (RegSrc2). ST, BEQ e BNE leem o registrador Ri.
- Existem dois estados de espera, BUSCA2 e MEM_LER2, porque a RAM da FPGA é síncrona.

## Topologia

O caminho de dados liga cinco blocos:

| Bloco | Arquivo | Função |
|---|---|---|
| Unidade de controle | `unidade_controle.vhd` | Máquina de estados que gera os sinais de controle a partir do estado e do opcode |
| Memória | `memoria.vhd` | RAM de 4096 × 16, com endereço registrado e saída direta |
| Banco de registradores | `banco_regs.vhd` | R0 a R7, com duas leituras combinacionais e uma escrita síncrona |
| ULA | `ula.vhd` | AND, OR, soma, subtração e SLT, com a flag Zero |
| Extensor de sinal | `ext_sinal.vhd` | Leva o imediato de 6 para 16 bits |

### Registradores internos

Todos são instâncias de `reg16` e só mudam na borda de clock em que `en = 1`.

| Registrador | Guarda | Carrega quando |
|---|---|---|
| PC | Endereço da próxima instrução | `pc_load = PCWrite or (PCWriteCond and cond)` |
| RI | Instrução atual | IRWrite (BUSCA2) |
| RDM | Último dado lido da memória | RDMWrite (BUSCA2 e MEM_LER2) |
| A | R[Rj] | A cada passo |
| B | R[Rk] ou R[Ri] | A cada passo |
| SaídaULA | Resultado da ULA, para o estado seguinte | A cada passo |

### Multiplexadores

| Mux | Saída | Entradas |
|---|---|---|
| IorD | `mem_addr`, endereço da memória | 0: PC · 1: SaídaULA |
| RegSrc2 | `ra2`, 2ª leitura do banco | 0: Rk (tipo R) · 1: Ri (ST, BEQ, BNE) |
| MemtoReg | `wd`, dado escrito no banco | 0: SaídaULA · 1: RDM |
| ULASrcA | `ula_a` | 0: PC · 1: A |
| ULASrcB | `ula_b` | 00: B · 01: constante 1 · 10: imediato estendido |
| PCSource | `pc_prox` | 00: saída da ULA (PC + 1) · 01: SaídaULA (destino do desvio) · 10: `"0000" & end` |

A 1ª leitura do banco é sempre Rj, e a escrita é sempre em Ri.

### Desvio condicional

A condição do desvio é calculada no `cpu.vhd`, pelo bit 12 do RI, que é o que diferencia os opcodes:

- **BEQ** (1000) desvia se `Zero = 1`.
- **BNE** (1001) desvia se `Zero = 0`.

No estado DESVIO, a ULA calcula A − B. O PC recebe a SaídaULA, que guarda o destino calculado no DECOD.

## Execução de uma instrução

1. **Busca** (BUSCA e BUSCA2). A memória recebe o PC. No passo seguinte, o RI e o RDM guardam a palavra lida, e o PC recebe PC + 1, calculado pela ULA.
2. **Decodificação** (DECOD). A e B recebem os registradores lidos. A SaídaULA recebe PC + imediato, que é o destino de um possível desvio.
3. **Execução**, que depende do opcode:
   - **EXEC_R** calcula A op B.
   - **EXEC_I** calcula A + imediato.
   - **DESVIO** compara A e B.
   - **SALTO** carrega o endereço do JMP.
4. **Memória** (só LD e ST).
   - O LD passa por MEM_LER e MEM_LER2, até o RDM receber o dado.
   - O ST grava B no endereço da SaídaULA em MEM_ESCR.
5. **Escrita** (ESCRITA_ULA ou ESCRITA_MEM). O registrador Ri recebe a SaídaULA ou o RDM.

| Instrução | Estados | Passos |
|---|---|---|
| ADD, SUB, AND, OR, SLT | BUSCA, BUSCA2, DECOD, EXEC_R, ESCRITA_ULA | 5 |
| ADDI | BUSCA, BUSCA2, DECOD, EXEC_I, ESCRITA_ULA | 5 |
| LD | BUSCA, BUSCA2, DECOD, EXEC_I, MEM_LER, MEM_LER2, ESCRITA_MEM | 7 |
| ST | BUSCA, BUSCA2, DECOD, EXEC_I, MEM_ESCR | 5 |
| BEQ, BNE | BUSCA, BUSCA2, DECOD, DESVIO | 4 |
| JMP | BUSCA, BUSCA2, DECOD, SALTO | 4 |
| HALT | BUSCA, BUSCA2, DECOD, HALT | fica em HALT até o reset |

## Clock e passo

O circuito todo roda em CLOCK_50.

- **Botão de passo:** o botão KEY0 passa pelo debouncer e por um detector de borda. Cada aperto gera um pulso `en` de um ciclo.
- **Avanço:** os registradores e a máquina de estados só mudam quando `en = 1`, então cada aperto avança um estado.
- **Vantagem:** o botão não é usado como clock de verdade, o que evita bordas falsas.

A memória é a exceção. Ela fica ligada direto em CLOCK_50 e relê o endereço a cada ciclo. Por isso o endereço precisa ficar estável durante o LD:

- A SaídaULA carrega a cada passo.
- Nos estados MEM_LER e MEM_LER2 a unidade de controle repete o cálculo A + imediato.
- Assim a SaídaULA não muda, e a memória continua lendo o endereço certo até o RDM ser carregado.
