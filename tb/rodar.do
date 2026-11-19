# Compila rtl/ e roda os testbenches de tb/ que existirem.
# No Transcript do ModelSim, na raiz do repositório:
#   do tb/rodar.do            roda todos
#   do tb/rodar.do cpu_tb     roda só um
# Cada testbench precisa terminar sozinho (parar o clock ou chamar std.env.stop).

onbreak {resume}

if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

set rtl {cpu_pkg somadorCompleto ula reg16 ext_sinal banco_regs memoria unidade_controle cpu debouncer hex7seg top_de2}
foreach f $rtl {
    vcom -2008 -quiet rtl/$f.vhd
}

set tbs {ula_tb reg16_tb ext_sinal_tb banco_regs_tb memoria_tb unidade_controle_tb cpu_tb}
if {$argc > 0} { set tbs [list $1] }

foreach tb $tbs {
    if {![file exists tb/$tb.vhd]} {
        echo "-- $tb: tb/$tb.vhd não existe, pulado"
        continue
    }
    vcom -2008 -quiet tb/$tb.vhd
    echo "################ $tb ################"
    vsim -quiet -L altera_mf work.$tb
    run -all
    quit -sim
}

echo "################ fim ################"
