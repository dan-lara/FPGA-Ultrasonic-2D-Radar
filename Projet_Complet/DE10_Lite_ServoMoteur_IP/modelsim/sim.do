# Creation de la lirairie de travail
vlib work

# Compilation
vcom -93 ../IP_Servo.vhd
vcom -93 ../TB_Servo.vhd

# Simulation
vsim TB_Servo_DUT

# Visualisation
view signals
add wave *
#add wave sim:/TB_Servo_DUT/G1/*

run 100 ms
wave zoom full