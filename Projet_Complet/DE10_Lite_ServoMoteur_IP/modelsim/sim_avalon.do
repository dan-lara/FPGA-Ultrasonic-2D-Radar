# Creation de la lirairie de travail
vlib work

# Compilation
vcom -93 ../IP_Servo_Avalon.vhd
vcom -93 ../TB_Servo_Avalon.vhd

# Simulation
vsim TB_Servo_Avalon_DUT

# Visualisation
view signals
add wave *

run 150 ms
wave zoom full