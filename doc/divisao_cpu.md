# Projeto CPU 16 bits – Divisão do Trabalho

Arquitetura de Sistemas Computacionais · PUC-Campinas · versão corrigida de 13/11/2026

> **O que mudou em relação à primeira versão:**
> - O prazo passou para **27/11**, e o dia 20/11 é de trabalho.
> - O código fica no repositório `Multicycle-CPU`.
> - O escopo foi enxugado: saíram o montador, os LEDR com o RI e os muxes como arquivos separados.
> - Os testes passaram a ser 4 programas codificados à mão.
> - As decisões D1 a D8 entraram na seção 2.
> - As interfaces da seção 8 foram ajustadas.

## 1. Visão geral

**Objetivo:** projetar em VHDL uma CPU multiciclo de 16 bits que executa 11 instruções (ADD, SUB, AND, OR, SLT, ADDI, LD, ST, BEQ, BNE, JMP), mais uma instrução extra HALT. A CPU deve ser testada em simulação e na placa DE2-115.

**Entrega:** sexta-feira, **27/11/2026**, no Canvas. Um integrante posta. Também é a primeira data de apresentação, e a ordem é sorteada. O prazo interno é **quinta, 26/11, às 22h**.

**Escopo:** exatamente o que o enunciado pede, mais dois extras: a instrução HALT e um testbench por módulo.

**O que entregar:**

- Documento de especificação em PDF
- Todos os arquivos .vhd
- Todos os programas testados em .mif

**Placa:** DE2-115 (Cyclone IV E – EP4CE115F29C7).

| Recurso da placa | Uso |
|---|---|
| KEY0 | Clock manual (com debouncer) |
| KEY3 | Reset |
| HEX0–HEX3 | PC em hexadecimal |
| HEX4–HEX7 | RDM (SW17 = 0) ou saída da ULA (SW17 = 1) |
| LEDG[3:0] | Código do estado da unidade de controle (binário) |
| LEDG8 | CPU parada (HALT) |

## 2. Decisões de projeto (congeladas)

Respostas às perguntas iniciais. **Nada aqui muda sem avisar o grupo inteiro.**

| # | Questão | Decisão |
|---|---|---|
| 1 | Data de entrega | 27/11/2026 |
| 2 | Placa | DE2-115 |
| 3 | Opcodes | O grupo define (tabela abaixo) |
| 4 | AND / OR | Bit a bit |
| 5 | Base do desvio | PC já incrementado: destino = (PC + 1) + imm |
| 6 | SLT | Comparação com sinal (complemento de 2) |
| 7 | R0 | Fixo em zero; escritas em R0 são ignoradas |
| 8 | Memória | Única (Von Neumann): programa e dados no mesmo .mif |
| 9 | Tamanho da memória | 4096 × 16 (endereço de 12 bits) |
| 10 | Organização | Multiciclo |
| 11 | HALT | Sim, opcode 1111 |

### Decisões de interface (kickoff)

| # | Questão | Decisão |
|---|---|---|
| D1 | Quem traduz o opcode tipo R em ULACtl | A unidade de controle, no EXEC_R: ADD→010, SUB→100, AND→000, OR→001, SLT→110. A ULA do Lab04 entra sem mudar. |
| D2 | Onde fica a condição do desvio | No `cpu.vhd`. A condição é `Zero` quando `ri(12) = 0` (BEQ) e `not Zero` quando `ri(12) = 1` (BNE). O PC carrega quando `PCWrite or (PCWriteCond and cond)`. A unidade de controle não recebe Zero. |
| D3 | RegSrc2 | Vale 1 sempre que o opcode é ST, BEQ ou BNE, em qualquer estado |
| D4 | A, B e SaídaULA | Carregam a cada passo, sem sinal próprio. O RI tem IRWrite e o RDM tem RDMWrite. |
| D5 | ULA em MEM_LER e MEM_LER2 | A unidade de controle repete A + imm nesses dois estados (ULASrcA = 1, ULASrcB = 10, ULACtl = 010) |
| D6 | Opcodes livres, de 1011 a 1110 | Vão para HALT |
| D7 | Escrita na memória | `wren = MemWrite`, sem passar pelo `en` |
| D8 | Muxes | Ficam como `with … select` dentro do `cpu.vhd`. Não há `mux2` nem `mux4`. |

⚠️ **Por que a D5 é necessária:**
1. A SaídaULA carrega a cada passo.
2. Ao sair do MEM_LER, ela receberia um valor sem sentido.
3. Na placa a RAM roda em CLOCK_50 e relê o endereço o tempo todo. O LD leria então o endereço errado no MEM_LER2.
4. Na simulação com `en` sempre em 1 o erro não aparece. Por isso o `cpu_tb` também roda com pulsos de `en` espaçados.

### Opcodes

| Opcode | Instrução | Tipo | Significado |
|---|---|---|---|
| 0000 | ADD Ri, Rj, Rk | R | Ri ← Rj + Rk |
| 0001 | SUB Ri, Rj, Rk | R | Ri ← Rj − Rk |
| 0010 | AND Ri, Rj, Rk | R | Ri ← Rj and Rk |
| 0011 | OR Ri, Rj, Rk | R | Ri ← Rj or Rk |
| 0100 | SLT Ri, Rj, Rk | R | Ri ← 1 se Rj < Rk (com sinal); senão 0 |
| 0101 | ADDI Ri, Rj, imm | I | Ri ← Rj + imm |
| 0110 | LD Ri, Rj, imm | I | Ri ← Mem[Rj + imm] |
| 0111 | ST Ri, Rj, imm | I | Mem[Rj + imm] ← Ri |
| 1000 | BEQ Ri, Rj, imm | I | se Ri = Rj: PC ← PC + 1 + imm |
| 1001 | BNE Ri, Rj, imm | I | se Ri ≠ Rj: PC ← PC + 1 + imm |
| 1010 | JMP end | J | PC ← end (12 bits, completado com zeros) |
| 1111 | HALT | – | Para a CPU (extra) |

Os opcodes 1011 a 1110 ficam livres. Se aparecerem, a CPU vai para HALT (D6).

### Campos da instrução

| Bits | 15–12 | 11–9 | 8–6 | 5–3 | 2–0 |
|---|---|---|---|---|---|
| Tipo R | opcode | Ri | Rj | Rk | não usado (000) |
| Tipo I | opcode | Ri | Rj | imm[5:3] | imm[2:0] |
| Tipo J | opcode | end[11:9] | end[8:6] | end[5:3] | end[2:0] |

O imediato tem 6 bits com sinal (de −32 a +31) e passa por extensão de sinal para 16 bits.

Exemplos:

- `ADD R1, R2, R3` = 0000 001 010 011 000 = **0x0298**
- `ADDI R1, R0, -1` = 0101 001 000 111111 = **0x523F**

### Registradores

| Registrador | Qtde | Tamanho | Endereço / função |
|---|---|---|---|
| R0–R7 (banco) | 8 | 16 bits | 000 a 111; R0 = 0 sempre |
| PC | 1 | 16 bits | Contador de programa (só os 12 bits baixos endereçam a memória) |
| RI | 1 | 16 bits | Registrador de instrução |
| RDM | 1 | 16 bits | Registrador de dados da memória (último valor lido) |
| A, B | 2 | 16 bits | Saídas do banco, carregadas a cada passo (D4) |
| SaídaULA | 1 | 16 bits | Resultado da ULA guardado para o estado seguinte |

## 3. O que reaproveitar dos Lab04 e Lab05

| Componente | Origem | Situação | O que muda |
|---|---|---|---|
| `ula.vhd` | Lab04 | Reaproveitar sem mudanças | Já conferido: o SLT compara **com sinal** e corrige o overflow. A interface (A, B, ULACtl, R, Zero, Overflow, Cout) continua igual. |
| `ula_tb.vhd` | Lab04 | Reaproveitar | Já tem 21 casos, incluindo SLT com negativos e nos extremos. |
| Decodificador de 7 segmentos | Lab04 (`ula_board`) | Reaproveitar | Separar numa entidade própria (`hex7seg.vhd`) e instanciar 8 vezes. |
| Banco de registradores | Lab05 | Adaptar | Endereço de 3 bits, R0 fixo em zero, reset zerando tudo (sem valores pré-carregados) e entrada de enable. |
| PC | Lab05 | Adaptar | Passa a ter escrita controlada (PCWrite) e uma de três origens possíveis. |
| Memória de instruções | Lab05 | Substituir | Vira uma RAM única de 4096 × 16 (IP "RAM: 1-PORT" do Quartus, ou `altsyncram` instanciado direto) com escrita e arquivo .mif. A saída `q` **não** é registrada. |
| Debouncer do botão | Lab05 | Reaproveitar | Acrescentar um detector de borda que gera um pulso de enable de um ciclo (ver a seção 8). |
| Datapath de ciclo único | Lab05 | Base para o novo | Vira multiciclo: entram os registradores RI, RDM, A, B e SaídaULA, os muxes e a unidade de controle. |

Tabela de ULACtl do Lab04, mantida como está:

| ULACtl | Operação | Usada por |
|---|---|---|
| 000 | AND | AND |
| 001 | OR | OR |
| 010 | Soma | ADD, ADDI, LD, ST, PC + 1, cálculo do endereço de desvio |
| 100 | Subtração | SUB, BEQ, BNE (comparação pela flag Zero) |
| 110 | SLT | SLT |
| 111 | NOR | Não usada |

## 4. Arquitetura

A referência é o datapath multiciclo do Patterson & Hennessy (o mesmo livro das figuras do Lab05), adaptado para 16 bits e para esta ISA.

### Componentes do caminho de dados

- **Mux de endereço da memória (IorD):** 0 = PC, 1 = SaídaULA.
- **Mux da 2ª porta de leitura do banco (RegSrc2):** 0 = Rk (tipo R), 1 = Ri (ST, BEQ, BNE). ⚠️ Este mux é fácil de esquecer.
- **Endereço de escrita no banco:** sempre Ri.
- **Mux do dado escrito no banco (MemtoReg):** 0 = SaídaULA, 1 = RDM.
- **Mux da entrada A da ULA (ULASrcA):** 0 = PC, 1 = A.
- **Mux da entrada B da ULA (ULASrcB):** 00 = B, 01 = constante 1, 10 = imm com sinal estendido.
- **Mux de origem do PC (PCSource):** 00 = saída da ULA (PC + 1), 01 = SaídaULA (destino do desvio), 10 = end do JMP (12 bits completados com zeros).
- **Extensor de sinal:** 6 → 16 bits.

### Estados da unidade de controle

| Cód. (LEDG) | Estado | Microoperações | Próximo estado |
|---|---|---|---|
| 0000 | BUSCA | Endereço da memória ← PC | BUSCA2 |
| 0001 | BUSCA2 | RI ← Mem; RDM ← Mem; PC ← PC + 1 (pela ULA) | DECOD |
| 0010 | DECOD | A ← R[Rj]; B ← R[Rk ou Ri]; SaídaULA ← PC + ext(imm) | Depende do opcode |
| 0011 | EXEC_R | SaídaULA ← A op B | ESCRITA_ULA |
| 0100 | EXEC_I | SaídaULA ← A + ext(imm) | ADDI → ESCRITA_ULA; LD → MEM_LER; ST → MEM_ESCR |
| 0101 | ESCRITA_ULA | R[Ri] ← SaídaULA | BUSCA |
| 0110 | MEM_LER | Endereço da memória ← SaídaULA; ULA repete A + ext(imm) (D5) | MEM_LER2 |
| 0111 | MEM_LER2 | RDM ← Mem; ULA repete A + ext(imm) (D5) | ESCRITA_MEM |
| 1000 | ESCRITA_MEM | R[Ri] ← RDM | BUSCA |
| 1001 | MEM_ESCR | Mem[SaídaULA] ← B | BUSCA |
| 1010 | DESVIO | ULA faz A − B; se (BEQ e Zero) ou (BNE e não Zero): PC ← SaídaULA | BUSCA |
| 1011 | SALTO | PC ← 0000 & end | BUSCA |
| 1100 | HALT | Nada; LEDG8 acende | HALT (só sai com reset) |

No DECOD, os opcodes 1011 a 1110 também levam ao HALT (D6).

**Por que existem BUSCA2 e MEM_LER2:** a RAM do Quartus é síncrona e entrega o dado um ciclo depois de receber o endereço.

**Sinais de controle (lista mínima para P2):** PCWrite, PCWriteCond, PCSource[1:0], IorD, MemWrite, IRWrite, RDMWrite, RegWrite, RegSrc2, MemtoReg, ULASrcA, ULASrcB[1:0], ULACtl[2:0], Halt, Estado[3:0].

**Sinais por estado.** É a referência para o P2 e para a revisão cruzada. Campo vazio vale 0.

| Estado | PCWrite | PCWriteCond | PCSource | IorD | MemWrite | IRWrite | RDMWrite | RegWrite | MemtoReg | ULASrcA | ULASrcB | ULACtl | Halt |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| BUSCA | | | | 0 | | | | | | | | | |
| BUSCA2 | 1 | | 00 | 0 | | 1 | 1 | | | 0 | 01 | 010 | |
| DECOD | | | | | | | | | | 0 | 10 | 010 | |
| EXEC_R | | | | | | | | | | 1 | 00 | D1 | |
| EXEC_I | | | | | | | | | | 1 | 10 | 010 | |
| ESCRITA_ULA | | | | | | | | 1 | 0 | | | | |
| MEM_LER | | | | 1 | | | | | | 1 | 10 | 010 | |
| MEM_LER2 | | | | 1 | | | 1 | | | 1 | 10 | 010 | |
| ESCRITA_MEM | | | | | | | | 1 | 1 | | | | |
| MEM_ESCR | | | | 1 | 1 | | | | | | | | |
| DESVIO | | 1 | 01 | | | | | | | 1 | 00 | 100 | |
| SALTO | 1 | | 10 | | | | | | | | | | |
| HALT | | | | | | | | | | | | | 1 |

RegSrc2 = 1 quando o opcode é ST, BEQ ou BNE (D3).

### Interface com a placa

- **HEX0–3:** PC.
- **HEX4–7:** RDM (SW17 = 0) ou a saída **combinacional** R da ULA (SW17 = 1).
- **LEDG[3:0]:** estado atual; **LEDG8:** HALT.

## 5. Divisão do trabalho

Todos escrevem o próprio código, o próprio testbench e a própria seção do documento. **P5 consolida o PDF** e **P1 consolida o código.**

### P1 – Arquitetura e integração (líder técnico)

**VHDL:**

- `cpu.vhd`: caminho de dados completo, com os registradores PC, RI, RDM, A, B e SaídaULA e todos os muxes, instanciando ULA, banco, memória e unidade de controle.
- Projeto do Quartus: lista de arquivos e configuração da simulação.

**Testes:** integração em simulação junto com P4, até os 4 programas da seção 6 passarem.

**Documento:**

- Descrição textual e topologia da CPU.
- **Diagrama de caminho de dados** (draw.io), com o nome de cada sinal igual ao do VHDL.

**Também:** organiza a reunião de kickoff, mantém a pasta compartilhada e faz a revisão cruzada do código de P2.

### P2 – Unidade de controle

**VHDL:** `unidade_controle.vhd`, a FSM com os 13 estados e todos os sinais de controle, mais a saída Estado[3:0] para os LEDs. Ela segue D1, D3, D5 e D6 e usa a tabela de sinais por estado da seção 4.

**Testes:** `unidade_controle_tb.vhd`, que confere a sequência de estados e os sinais para cada opcode, os dois casos do desvio (tomado e não tomado) e o HALT.

**Documento:**

- **Diagrama de estados.**
- **Tabela de estados** (estado × próximo estado × condição).
- **Tabela de sinais:** cada sinal com o seu significado e o valor em cada estado.

**Também:** faz a revisão cruzada de `cpu.vhd` (P1).

### P3 – ULA, banco de registradores e componentes básicos

**VHDL:**

- `ula.vhd` (Lab04, sem mudar).
- `banco_regs.vhd` (Lab05 adaptado: 8 × 16, R0 = 0, reset, enable).
- `ext_sinal.vhd` (6 → 16 bits).
- `reg16.vhd`: registrador genérico com load e enable, usado para PC, RI, RDM, A, B e SaídaULA.

Os muxes ficam dentro do `cpu.vhd` (D8).

**Testes:**

- `ula_tb.vhd` (Lab04).
- `banco_regs_tb.vhd`, incluindo uma tentativa de escrever em R0.
- `reg16_tb.vhd` e `ext_sinal_tb.vhd`, curtos.

**Documento:**

- Especificação dos **registradores** (quantidade, endereço e tamanho).
- **Formato das instruções**, com a tabela de opcodes e exemplos de codificação.
- Tabela de operações da ULA.

**Também:** ajuda P1 a montar os muxes do caminho de dados e confere os valores esperados dos programas de P4.

### P4 – Memória e programas de teste

**VHDL:**

- `memoria.vhd`: RAM de 4096 × 16, inicializada pelo .mif.
- `memoria_tb.vhd`.
- `cpu_tb.vhd`: testbench da CPU inteira, que roda um .mif e imprime PC, RI e os registradores a cada instrução. Ele roda com `en` contínuo e com pulsos de `en` espaçados (ver D5).

**Programas:** os 4 da seção 6, **codificados à mão**. Cada um vem com duas tabelas:
- a de codificação, de assembly para binário e para hex;
- a de **valores esperados**.

O deslocamento dos desvios é destino − (PC + 1). As posições que sobram na memória são preenchidas com HALT (0xF000), e não com 0x0000, para que um PC desgovernado pare em vez de executar ADDs.

**Documento:**

- **Descrição dos testes.**
- **Resultados e discussão** da parte de simulação, com prints das formas de onda.

### P5 – Interface com a placa e editoração do documento

**VHDL:**

- `top_de2.vhd`: liga a CPU aos pinos e implementa o mux do SW17 para HEX4–7 e os LEDs.
- `debouncer.vhd` (Lab05) com o detector de borda.
- `hex7seg.vhd` (Lab04).
- Atribuição de pinos: importar o arquivo DE2_115 pin assignments.

**Testes:**

- Primeiro, testar o top com uma CPU "falsa" (só um contador no PC), para validar displays e botão antes da integração.
- Depois, rodar os 4 programas na placa, com fotos e um vídeo curto de cada um.

**Documento:**

- **Resultados na placa.**
- **Dificuldades encontradas** (recolhidas com todos).
- **Uso de IA** (recolhido com todos).
- Montagem, formatação e exportação do PDF final.
- Postagem no Canvas.

### Quem é quem

| Papel | Responsável |
|---|---|
| P1 Arquitetura e integração | Lucas K. |
| P2 Unidade de controle | Gui |
| P3 ULA e componentes | Lucas Espica |
| P4 Memória e programas | Lucas K.: `memoria.vhd`, `memoria_tb.vhd`, `cpu_tb.vhd` · Rafa: os 4 programas e as tabelas |
| P5 Placa e documento | Lucas K.: `top_de2.vhd` · Rafa: `debouncer.vhd`, `hex7seg.vhd`, top de teste, fotos e vídeos, montagem e postagem do PDF |

### Mapa das seções do PDF

| Seção exigida | Responsável | Contribuem |
|---|---|---|
| Descrição textual e topologia | P1 | – |
| Especificação: registradores | P3 | – |
| Especificação: formato das instruções | P3 | – |
| Especificação: unidade de controle (diagrama, tabela, sinais) | P2 | – |
| Diagrama de caminho de dados | P1 | P3 |
| Descrição dos testes | P4 | – |
| Resultados e discussão | P4 (simulação) | P5 (placa) |
| Dificuldades encontradas | P5 | Todos |
| Uso de IA | P5 | Todos |

## 6. Programas de teste (.mif)

Cada programa termina com HALT. Para cada um, P4 entrega uma tabela com o valor esperado de cada registrador ao final e, para os curtos, também o PC, o RDM e a saída da ULA passo a passo. É essa tabela que se compara com a placa.

| Arquivo | O que testa | Casos importantes |
|---|---|---|
| `t1_ula.mif` | ADD, SUB, AND, OR, SLT e ADDI | Negativos; SLT com −1 < 1 (deve dar 1); resultado zero; imediatos +31 e −32; ADDI em R0 (deve continuar 0) |
| `t2_mem.mif` | LD e ST | ST seguido de LD no mesmo endereço; deslocamento negativo (base em registrador) |
| `t3_desvios.mif` | BEQ, BNE, JMP e HALT | Desvio para frente e para trás (laço); tomado e não tomado; salto para frente; parada no HALT |
| `final.mif` | Programa completo | Soma de 1 a N com laço, ST do resultado, LD e SLT de verificação |

Rascunho do `final.mif` (P4 refina):

```
        ADDI R1, R0, 5      ; N = 5
        ADDI R2, R0, 0      ; soma = 0
        ADDI R3, R0, 1      ; i = 1
laco:   ADD  R2, R2, R3     ; soma += i
        BEQ  R3, R1, fim    ; se i == N, sai
        ADDI R3, R3, 1      ; i++
        JMP  laco
fim:    ST   R2, R0, 31     ; Mem[31] = soma
        LD   R4, R0, 31     ; R4 = Mem[31]
        SLT  R5, R0, R4     ; R5 = 1, pois 0 < 15
        HALT
```

Resultado esperado: R2 = R4 = 0x000F, R5 = 0x0001, Mem[31] = 0x000F.

**Convenção de dados:** dados nos endereços 0x10 a 0x1F (base R0 com imediato positivo), longe do código.

## 7. Cronograma até 27/11

Hoje é sexta, 13/11. O feriado de 20/11 é dia de trabalho, para quem estiver atrasado.

| Datas | Marco | Quem | Pronto quando… |
|---|---|---|---|
| Sáb 14 – Dom 15/11 | Kickoff: ler este documento, juntar os códigos dos Lab04/05 e congelar as interfaces (seção 8). Commit inicial com os esqueletos; cada um cria seu branch. | Todos | Todas as entidades com portas definidas, mesmo que vazias |
| Seg 16 – Qui 19/11 | Módulos individuais com testbench; os 4 programas codificados; top com contador na primeira aula de laboratório | P2, P3, P4, P5 | Cada testbench passa sozinho |
| Seg 16 – Qui 19/11 | Caminho de dados (`cpu.vhd`) e diagrama em rascunho | P1 (+P3) | Compila no Quartus |
| Sex 20/11 (feriado) | **Checkpoint 1:** tudo na `main` e compilando | Todos | Testbenches unitários passam, os 4 .mif estão conferidos e abrem no Quartus |
| Sáb 21 – Dom 22/11 | Integração em simulação | P1, P2, P4 | Os 4 programas com os resultados esperados no `cpu_tb` |
| Dom 22/11 | **Checkpoint 2:** CPU funcionando em simulação; código congelado | Todos | – |
| Seg 23 – Ter 24/11 | CPU na placa, com fotos e vídeos; escrita das seções do documento | P5 (+P1); todos escrevem | Programa final roda na DE2-115; rascunho de cada seção entregue a P5 |
| Qua 25/11 | **Checkpoint 3:** PDF v1 completo | P5 | PDF circulando |
| Qui 26/11 | Revisão final e ensaio: todos leem o PDF; cada um explica um bloco que não escreveu | Todos | P5 posta no Canvas até 22h |
| Sex 27/11 | **Entrega e apresentação** | Todos presentes | – |

## 8. Contrato de interfaces e boas práticas

### Entidades (portas congeladas no kickoff)

| Entidade | Entradas | Saídas |
|---|---|---|
| `ULA` (Lab04, sem mudar) | A, B (16), ULACtl (3) | R (16), Zero, Overflow, Cout |
| `reg16` (generic N = 16) | clk, rst, en, load, d (N) | q (N) |
| `ext_sinal` | imm (6) | ext (16) |
| `banco_regs` | clk, rst, en, RegWrite, ra1 (3), ra2 (3), wa (3), wd (16) | rd1 (16), rd2 (16) |
| `memoria` (generic ARQ_MIF) | clock, address (12), data (16), wren | q (16) |
| `unidade_controle` | clk, rst, en, opcode (4) | Todos os sinais de controle da seção 4, Halt, Estado (4). **Sem Zero** (D2). |
| `cpu` (generic ARQ_MIF) | clk, rst, en | pc_out (16), rdm_out (16), ula_out (16), estado (4), halt |
| `top_de2` | CLOCK_50, KEY (3:0), SW (17:0) | HEX0–HEX7 (7 cada), LEDG (8:0) |
| `debouncer` | clk, botao | pulso (1 ciclo de clk) |
| `hex7seg` | valor (4) | seg (7, ativo em nível baixo) |

### Clock e reset

- **Clock:** todo o circuito roda em CLOCK_50. O botão KEY0, depois do debouncer e do detector de borda, gera `en`, um pulso de um ciclo. Todos os registradores e a FSM só mudam quando `en = 1`. Assim, cada aperto avança um estado, sem os problemas de usar o botão como clock de verdade.
- **Exceção da memória:** a RAM fica ligada direto em CLOCK_50 e grava sempre que MemWrite = 1 (D7). O endereço fica estável entre os apertos, então o dado já está pronto no aperto seguinte. A D5 garante isso no LD.
- **Reset:** KEY3 (ativo em nível baixo) gera `rst = not KEY(3)`, ativo alto e assíncrono. Ele zera o PC, os registradores e a FSM (estado BUSCA).

### Boas práticas

- **Nomes:** os sinais têm o mesmo nome no VHDL, no diagrama de caminho de dados e na tabela de sinais. Isso poupa horas na hora de escrever o documento.
- **Comentários:** só o mínimo para dizer o que o arquivo ou o bloco faz. Não há cabeçalho com nomes: os integrantes ficam no README, sem RA.
- **Repositório:** `Multicycle-CPU`, com a estrutura descrita no README.
  - `rtl/`: os .vhd
  - `tb/`: os testbenches e o `rodar.do`
  - `mif/`: os programas
  - `quartus/`
  - `doc/`: este plano, diagramas, imagens e `uso_de_ia.md`
- **Git:** um branch por papel (`p1-integracao`, `p2-controle`, `p3-componentes`, `p4-memoria-testes`, `p5-placa`). O merge na `main` é feito pelo P1, depois que o testbench do módulo passa.
- **Revisão cruzada:** P1 ↔ P2 (controle × caminho de dados), P3 → P4 (valores esperados) e P4 → P5 (resultados na placa).
- **Uso de IA:** cada pessoa anota, enquanto trabalha, o que fez com IA e por quê. A organização deste plano e a proposta inicial de arquitetura foram feitas com IA (Claude), e o grupo revisou e validou as decisões.
