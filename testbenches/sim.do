
vlib work
vmap work

vlog +acc test_bitcoin_miner.v
vlog +acc ../src/bitcoin_miner.v
vlog +acc ../src/sha256_transform.v
vlog +acc ../src/sha-256-functions.v

vsim -L work test_bitcoin_miner

view wave
add wave -h cycle
add wave -h uut/*
run 2us
