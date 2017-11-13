transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+F:/Unum/unumIII_32_3_multiplier_pipeline3 {F:/Unum/unumIII_32_3_multiplier_pipeline3/unum_multiplier.v}
vlog -vlog01compat -work work +incdir+F:/Unum/unumIII_32_3_multiplier_pipeline3 {F:/Unum/unumIII_32_3_multiplier_pipeline3/frac_mult.v}

vlog -vlog01compat -work work +incdir+F:/Unum/unumIII_32_3_multiplier_pipeline3/simulation/modelsim {F:/Unum/unumIII_32_3_multiplier_pipeline3/simulation/modelsim/unum_multiplier.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  unum_multiplier_vlg_tst

add wave *
view structure
view signals
run 10 ps
