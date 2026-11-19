# Testes e resultados da simulação

Seção do relatório (P4). Os programas estão em `mif/`. Os testbenches são `tb/memoria_tb.vhd` e `tb/cpu_tb.vhd`. A memória está em `rtl/memoria.vhd`.

## Como rodar

No Transcript do ModelSim, na raiz do repositório:

```
do tb/rodar.do memoria_tb
do tb/rodar.do cpu_tb
```

O resultado esperado é `TODOS OS TESTES PASSARAM (memoria)` e `TODOS OS TESTES PASSARAM (cpu)`.

Os testbenches abrem os .mif pelo caminho `mif/<programa>.mif`, a partir da raiz do repositório. No Quartus, o caminho padrão do generic `ARQ_MIF` é `../mif/final.mif`, a partir da pasta `quartus/`. Para gravar outro programa na placa, troque esse generic.

## Memória (`memoria.vhd`)

É uma `altsyncram` de uma porta, com 4096 × 16 bits, inicializada pelo arquivo `ARQ_MIF`:

- O endereço, o dado e o `wren` são registrados na borda de subida de `clock`.
- A saída `q` **não** é registrada: o dado aparece um ciclo depois do endereço. Por isso existem os estados BUSCA2 e MEM_LER2.
- A escrita ocorre em toda borda com `wren = 1`. `wren` é ligado direto a `MemWrite`, sem passar pelo `en` (D7).
- O clock da memória é o `CLOCK_50`. Ela relê o endereço a cada ciclo, mesmo sem `en`.

### `memoria_tb`

| Caso | O que confere |
|---|---|
| Conteúdo do .mif | Código (`Mem[000]`, `Mem[001]`, `Mem[00B]`), dados (`Mem[010]`, `Mem[011]`, `Mem[012]`) e preenchimento com HALT (`Mem[00C]`, `Mem[020]`, `Mem[FFF]`), lidos de `t2_mem.mif` |
| Atraso de um ciclo | Depois que o endereço muda, `q` mantém o dado antigo até a borda seguinte |
| Escrita | ST em `012` e `01E`, com leitura de volta, sem afetar o outro endereço |
| `wren = 0` | Endereço e dado presentes, mas a memória não muda |
| Último endereço | Escrita em `FFF` sem afetar `000` |

## Testbench da CPU (`cpu_tb`)

O `cpu_tb` roda os 4 programas, e cada um roda duas vezes:

1. **`en` contínuo**: um estado por ciclo de clock.
2. **`en` espaçado**: um pulso de `en` a cada 4 ciclos. É o que acontece na placa, onde a memória continua recebendo `CLOCK_50` entre os apertos de KEY0. Esse modo existe por causa da armadilha da decisão D5.

Para cada execução, o testbench confere:

- **Cada escrita, na ordem em que acontece.** Toda borda com `en = 1` em ESCRITA_ULA ou ESCRITA_MEM gera um evento `R[Ri] ← wd`. Toda borda em MEM_ESCR gera `Mem[endereço] ← B`. Cada evento é comparado com a lista de valores esperados, então um resultado errado aparece já na instrução que o causou, mesmo que o registrador seja sobrescrito depois. As tentativas de escrita em R0 também entram na lista.
- **Estado final, ao chegar no HALT:** os 8 registradores, o PC, o número de instruções executadas e o número de escritas.
- **HALT parado:** mais 3 pulsos de `en` não mudam o estado nem o PC.
- **Laço infinito:** se a CPU não chega ao HALT em 2000 passos, o teste falha.

Na execução com `en` contínuo, o Transcript mostra uma linha ao fim de cada instrução, com o número da instrução, o PC, o RI e os registradores de R1 a R7:

```
#   [final] #4  PC=0003  RI=0498 | R1=0005 R2=0001 R3=0001 R4=0000 R5=0000 R6=0000 R7=0000
```

O testbench lê `ri`, `wd`, `mem_addr` e `reg_b` de dentro da CPU por nomes externos (VHDL-2008). Os registradores do banco ele lê pelo `signal_spy` do ModelSim. Nenhuma porta da CPU foi criada só para o teste.

## Programas de teste

Regras usadas em todos os programas:

- Cada programa termina em HALT.
- As posições livres da memória são preenchidas com HALT (`F000`), e não com `0000`. Assim, um PC desgovernado para em vez de executar ADDs.
- O deslocamento dos desvios é `destino − (PC + 1)`.
- Os dados ficam entre `0x10` e `0x1F`.
- O PC final é o endereço do HALT + 1, porque o PC é incrementado no BUSCA2, antes do DECOD.

Passos por instrução: tipo R, ADDI e ST levam 5; LD leva 7; BEQ, BNE e JMP levam 4. O HALT leva 3 passos até chegar ao estado HALT.

### t1_ula: ADD, SUB, AND, OR, SLT e ADDI

**Objetivo:** conferir as operações da ULA pelos dois caminhos, tipo R (EXEC_R) e ADDI (EXEC_I), incluindo a extensão de sinal do imediato e o R0 fixo.

| End. | Assembly | Binário | Hex | Escrita esperada | Por quê |
|---|---|---|---|---|---|
| 000 | `ADDI R1, R0, 31` | `0101 001 000 011111` | 521F | R1 ← 001F | maior imediato (+31) |
| 001 | `ADDI R2, R0, -32` | `0101 010 000 100000` | 5420 | R2 ← FFE0 | menor imediato (−32): extensão de sinal |
| 002 | `ADDI R0, R0, 5` | `0101 000 000 000101` | 5005 | R0 ← 0005, ignorada | R0 fixo em zero (tipo I) |
| 003 | `ADD R3, R1, R2` | `0000 011 001 010 000` | 0650 | R3 ← FFFF | 31 + (−32) = −1 |
| 004 | `SUB R4, R2, R1` | `0001 100 010 001 000` | 1888 | R4 ← FFC1 | −32 − 31 = −63 |
| 005 | `ADDI R5, R0, 1` | `0101 101 000 000001` | 5A01 | R5 ← 0001 | lê R0 depois da escrita: tem que dar 0 + 1 |
| 006 | `SLT R6, R3, R5` | `0100 110 011 101 000` | 4CE8 | R6 ← 0001 | −1 < 1 com sinal |
| 007 | `ADDI R7, R0, 7` | `0101 111 000 000111` | 5E07 | R7 ← 0007 | valor que o SLT seguinte deve apagar |
| 008 | `SLT R7, R5, R3` | `0100 111 101 011 000` | 4F58 | R7 ← 0000 | 1 < −1 é falso (sem sinal daria 1) |
| 009 | `AND R5, R2, R4` | `0010 101 010 100 000` | 2AA0 | R5 ← FFC0 | FFE0 and FFC1 |
| 00A | `OR R1, R1, R4` | `0011 001 001 100 000` | 3260 | R1 ← FFDF | 001F or FFC1 |
| 00B | `SUB R2, R2, R2` | `0001 010 010 010 000` | 1490 | R2 ← 0000 | resultado zero |
| 00C | `ADD R0, R1, R1` | `0000 000 001 001 000` | 0048 | R0 ← FFBE, ignorada | R0 fixo em zero (tipo R) |
| 00D | `HALT` | `1111 000000000000` | F000 | – | fim |

**Esperado no final:** R0 = 0000, R1 = FFDF, R2 = 0000, R3 = FFFF, R4 = FFC1, R5 = FFC0, R6 = 0001, R7 = 0000. PC = 000E. São 14 instruções em 68 passos.

### t2_mem: LD e ST

**Objetivo:** conferir o cálculo do endereço (`Rj + imm`), a leitura em dois estados (MEM_LER e MEM_LER2), a escrita da memória e o RegSrc2 do ST, que lê Ri na segunda porta do banco.

Dados iniciais no .mif: `Mem[010] = 1234`, `Mem[011] = ABCD`. As posições `012`, `01E` e `01F` começam em `0000`.

| End. | Assembly | Binário | Hex | Escrita esperada | Por quê |
|---|---|---|---|---|---|
| 000 | `ADDI R1, R0, 16` | `0101 001 000 010000` | 5210 | R1 ← 0010 | base da área de dados |
| 001 | `LD R2, R1, 0` | `0110 010 001 000000` | 6440 | R2 ← 1234 | LD de um dado vindo do .mif |
| 002 | `LD R3, R1, 1` | `0110 011 001 000001` | 6641 | R3 ← ABCD | idem, com imediato |
| 003 | `ADD R4, R2, R3` | `0000 100 010 011 000` | 0898 | R4 ← BE01 | 1234 + ABCD |
| 004 | `ST R4, R1, 2` | `0111 100 001 000010` | 7842 | Mem[012] ← BE01 | ST com base em registrador |
| 005 | `LD R5, R1, 2` | `0110 101 001 000010` | 6A42 | R5 ← BE01 | ST seguido de LD no mesmo endereço |
| 006 | `ADDI R6, R0, 31` | `0101 110 000 011111` | 5C1F | R6 ← 001F | nova base |
| 007 | `ST R3, R6, -1` | `0111 011 110 111111` | 77BF | Mem[01E] ← ABCD | deslocamento negativo |
| 008 | `LD R7, R6, -1` | `0110 111 110 111111` | 6FBF | R7 ← ABCD | deslocamento negativo |
| 009 | `ST R2, R0, 31` | `0111 010 000 011111` | 741F | Mem[01F] ← 1234 | base R0 |
| 00A | `LD R1, R0, 31` | `0110 001 000 011111` | 621F | R1 ← 1234 | base R0; sobrescreve a base antiga |
| 00B | `HALT` | `1111 000000000000` | F000 | – | fim |

**Esperado no final:** R0 = 0000, R1 = 1234, R2 = 1234, R3 = ABCD, R4 = BE01, R5 = BE01, R6 = 001F, R7 = ABCD. Mem[012] = BE01, Mem[01E] = ABCD, Mem[01F] = 1234. PC = 000C. São 12 instruções em 68 passos.

### t3_desvios: BEQ, BNE, JMP e HALT

**Objetivo:** conferir o destino `(PC + 1) + imm` para frente e para trás, a escolha entre BEQ e BNE pelo bit 12 do RI (D2), o desvio tomado e o não tomado, o JMP e a parada no HALT.

As instruções em `006` e `009` estão no caminho de desvios tomados e nunca devem executar. Se executarem, R3 ou R4 mudam. A instrução em `00A` só executa se o BEQ em `007` desviar por engano, e nesse caso R7 vira FFFF.

| End. | Rótulo | Assembly | Binário | Hex | Comportamento esperado |
|---|---|---|---|---|---|
| 000 | | `ADDI R1, R0, 3` | `0101 001 000 000011` | 5203 | R1 ← 3 (contador) |
| 001 | | `ADDI R2, R0, 0` | `0101 010 000 000000` | 5400 | R2 ← 0 |
| 002 | laco | `ADDI R2, R2, 2` | `0101 010 010 000010` | 5482 | R2 += 2 |
| 003 | | `ADDI R1, R1, -1` | `0101 001 001 111111` | 527F | R1 −= 1 |
| 004 | | `BNE R1, R0, laco` | `1001 001 000 111101` | 923D | imm = 2 − 5 = −3. Tomado 2 vezes (para trás), não tomado 1 vez |
| 005 | | `BEQ R1, R0, pula` | `1000 001 000 000001` | 8201 | imm = 7 − 6 = +1. Tomado (para frente) |
| 006 | | `ADDI R3, R0, 1` | `0101 011 000 000001` | 5601 | pulada |
| 007 | pula | `BEQ R2, R0, erro` | `1000 010 000 000010` | 8402 | imm = A − 8 = +2. Não tomado (R2 = 6) |
| 008 | | `JMP fim` | `1010 000000001100` | A00C | PC ← 00C (salto para frente) |
| 009 | | `ADDI R4, R0, 1` | `0101 100 000 000001` | 5801 | pulada |
| 00A | erro | `ADDI R7, R0, -1` | `0101 111 000 111111` | 5E3F | só executa se um desvio falhar |
| 00B | | `HALT` | `1111 000000000000` | F000 | parada de erro |
| 00C | fim | `ADDI R5, R0, 5` | `0101 101 000 000101` | 5A05 | R5 ← 5 |
| 00D | | `HALT` | `1111 000000000000` | F000 | fim |

Sequência de PCs esperada: 000, 001, 002, 003, 004, 002, 003, 004, 002, 003, 004, 005, 007, 008, 00C, 00D.

Escritas esperadas, em ordem: R1 ← 0003, R2 ← 0000, R2 ← 0002, R1 ← 0002, R2 ← 0004, R1 ← 0001, R2 ← 0006, R1 ← 0000, R5 ← 0005.

**Esperado no final:** R1 = 0000, R2 = 0006, R5 = 0005. R3, R4, R6 e R7 continuam em 0000. PC = 000E, depois do HALT em 00D e não do HALT de erro em 00B. São 16 instruções em 72 passos.

### final: soma de 1 a N

**Objetivo:** um programa completo, com laço, desvio, salto, acesso à memória e comparação: soma de 1 a 5, guarda o resultado em `Mem[01F]`, lê de volta e confere com SLT.

| End. | Rótulo | Assembly | Binário | Hex | Comentário |
|---|---|---|---|---|---|
| 000 | | `ADDI R1, R0, 5` | `0101 001 000 000101` | 5205 | N = 5 |
| 001 | | `ADDI R2, R0, 0` | `0101 010 000 000000` | 5400 | soma = 0 |
| 002 | | `ADDI R3, R0, 1` | `0101 011 000 000001` | 5601 | i = 1 |
| 003 | laco | `ADD R2, R2, R3` | `0000 010 010 011 000` | 0498 | soma += i |
| 004 | | `BEQ R3, R1, fim` | `1000 011 001 000010` | 8642 | se i = N, sai (imm = 7 − 5 = +2) |
| 005 | | `ADDI R3, R3, 1` | `0101 011 011 000001` | 56C1 | i += 1 |
| 006 | | `JMP laco` | `1010 000000000011` | A003 | volta para 003 |
| 007 | fim | `ST R2, R0, 31` | `0111 010 000 011111` | 741F | Mem[01F] = soma |
| 008 | | `LD R4, R0, 31` | `0110 100 000 011111` | 681F | R4 = Mem[01F] |
| 009 | | `SLT R5, R0, R4` | `0100 101 000 100 000` | 4A20 | R5 = (0 < soma) |
| 00A | | `HALT` | `1111 000000000000` | F000 | fim |

Valores a cada volta do laço, depois do ADD em `003`:

| Volta | i (R3) | soma (R2) | BEQ em 004 |
|---|---|---|---|
| 1 | 1 | 0001 | não tomado |
| 2 | 2 | 0003 | não tomado |
| 3 | 3 | 0006 | não tomado |
| 4 | 4 | 000A | não tomado |
| 5 | 5 | 000F | tomado → 007 |

**Esperado no final:** R1 = 0005, R2 = 000F, R3 = 0005, R4 = 000F, R5 = 0001, R6 = R7 = 0000, Mem[01F] = 000F. PC = 000B. São 25 instruções em 116 passos.

## Resultados da simulação

Todos os testbenches passam com `do tb/rodar.do`. Rodado no ModelSim-Intel FPGA Edition 2020.1, que vem com o Quartus Prime Lite 20.1:

```
OK     [t1_ula, en continuo]: 14 instrucoes, 68 passos, PC final 000E
OK     [t2_mem, en continuo]: 12 instrucoes, 68 passos, PC final 000C
OK     [t3_desvios, en continuo]: 16 instrucoes, 72 passos, PC final 000E
OK     [final, en continuo]: 25 instrucoes, 116 passos, PC final 000B
OK     [t2_mem, en espacado]: 12 instrucoes, 68 passos, PC final 000C
OK     [t1_ula, en espacado]: 14 instrucoes, 68 passos, PC final 000E
OK     [t3_desvios, en espacado]: 16 instrucoes, 72 passos, PC final 000E
OK     [final, en espacado]: 25 instrucoes, 116 passos, PC final 000B
TODOS OS TESTES PASSARAM (cpu)
```

Os valores obtidos são iguais às tabelas acima em cada escrita, não só no final. O número de passos também confere com a conta por instrução. No t1, por exemplo, são 13 instruções de 5 passos mais 3 passos do HALT, o que dá 68.

O Transcript mostra também 16 avisos `NUMERIC_STD.TO_INTEGER: metavalue detected` no tempo 0. Eles vêm do `banco_regs`, que lê o RI antes de o reset agir. Não afetam o resultado.

### O testbench pega erros?

Para saber se o `cpu_tb` detecta erros de verdade, introduzimos três erros de propósito, numa cópia do código:

| Erro introduzido | Resultado |
|---|---|
| Condição do desvio sempre `Zero`, de modo que o BNE vira BEQ | O t3 falha: o laço não repete, a instrução pulada em `006` executa e R3 vira 0001 |
| SLT trocado por SUB na unidade de controle | O t1 falha (R6 = FFFE e R7 = 0002) e o final também (R5 = FFF1) |
| MEM_LER sem repetir A + imm (sem a D5) | Com `en` contínuo **tudo passa**. Com `en` espaçado o t2 falha: os LD leem `5210`, o conteúdo do endereço `000`, no lugar dos dados |

O terceiro caso confirma a armadilha descrita no plano. Com `en` contínuo, a memória registra o endereço certo na borda que sai do MEM_LER e entrega o dado certo no ciclo seguinte. Com `en` espaçado, a SaídaULA já trocou de valor e a memória relê o endereço errado a cada ciclo de clock antes do pulso que carrega o RDM. É o que aconteceria na placa. Por isso o `cpu_tb` roda os dois modos.

Uma observação sobre a D5: a repetição de A + imm só é necessária no MEM_LER. Tirar a repetição só do MEM_LER2 não muda nada, porque a SaídaULA só troca de valor na mesma borda em que o RDM já está carregando. A repetição no MEM_LER2 é inofensiva e foi mantida, como na tabela de sinais.

### Formas de onda

Para os prints do relatório, rode `vsim -L altera_mf work.cpu_tb` e adicione ao Wave, para uma das execuções (por exemplo `/cpu_tb/final_cont/dut`), os sinais `estado`, `pc`, `ri`, `saida_ula`, `rdm`, `mem_addr`, `mem_q` e `u_banco/regs`. Os trechos que mais valem um print:

- uma volta do laço do `final`, com o BEQ não tomado e o JMP;
- o LD em `008` do `final`, com MEM_LER, MEM_LER2 e ESCRITA_MEM;
- o mesmo LD na execução `final_esp`, para mostrar o endereço estável entre os pulsos de `en`.
