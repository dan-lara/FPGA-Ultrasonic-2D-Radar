# Creation de la lirairie de travail
vlib work

# Compilation
vcom -93 ../IP_NeoPixel.vhd
vcom -93 ../TB_NeoPixel.vhd

# Simulation
vsim TB_NeoPixel_DUT

# Visualisation
view signals
add wave *
#add wave sim:/TB_NeoPixel_DUT/G1/*

run 5 ms
wave zoom full