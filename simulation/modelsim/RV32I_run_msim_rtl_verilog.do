transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/FPU_Control_Unit.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Sign_Unit.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/NR_Iteration.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Normalizer.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Mantissa_Normalisation.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Mantissa_Multiplier.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/FP_Sub.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/FP_Mul.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/FP_Div.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/FP_Add.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Floating_Seperation.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Adder_Exponent_Bias.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/FPU.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/FP_Register_File.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/if_id_registers.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/id_ex_registers.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/ex_mem_registers.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/mem_wb_registers.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/fetch_stage.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/decode_stage.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/execute_stage.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/memory_stage.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/writeback_stage.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/RV32I.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/hazard_control.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/PC_module.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/mux.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/PC_Adder.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Control_Unit.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Main_Decoder.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/ALU_Decoder.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Register_File.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Sign_Extend.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/ALU.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Data_Memory.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/hazard_unit.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/Instruction_Memory.v}

vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/RV32IM_pineline {C:/altera/13.0sp1/RV32IM_pineline/RV32I_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneii_ver -L rtl_work -L work -voptargs="+acc"  RV32I_tb

add wave *
view structure
view signals
run -all
