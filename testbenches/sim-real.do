
vlib work
vmap work

vlog +acc +define+SIM test_fpgaminer_top.v
vlog +acc +define+SIM ../src/fpgaminer_top.v
vlog +acc +define+SIM ../src/sha256_transform.v
vlog +acc +define+SIM ../src/sha-256-functions.v

#vlog +acc ../src/main_pll.v

#vlog +acc ../src/uart_tx_fifo.v
#vlog +acc ../src/uart_comm.v
#vlog +acc ../src/uart_tx.v
#vlog +acc ../src/uart_rx.v
#vlog +acc ../src/virtual_wire.v


vsim -L work test_fpgaminer_top

view wave
add wave -h uut/*
run 2us