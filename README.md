# FPGA-Ultrasonic-2D-Radar

## Description
Ce projet utilise un FPGA pour créer un radar 2D à ultrasons. Le système utilise des capteurs à ultrasons pour détecter des objets et afficher leur position sur une interface graphique.

## Prérequis
- FPGA DE10Lite
- Capteurs à ultrasons
- Quartus 18.1
- Servomoteur MG90s
- Converseur Serial-USB
- Écran VGA
- NeoPixel 12 LEDS
- Câbles de connexion
- Ordinateur avec un port USB

## Installation
1. Clonez le dépôt du projet :
    ```sh
    git clone https://github.com/votre-utilisateur/FPGA-Ultrasonic-2D-Radar.git
    cd FPGA-Ultrasonic-2D-Radar/
    quartus18.1
    ```
2. Ouvrez le projet inside DE10_Lite_computer_YD/ dans votre logiciel Quartus.
3. Compilez le projet pour générer le fichier binaire pour le FPGA et programmer.
4. Ouvrier le NIOS II et tester le projet

## Utilisation
1. Connectez les capteurs à ultrasons aux ports appropriés du FPGA.
2. Allumez le FPGA et assurez-vous qu'il est correctement alimenté.
3. Lancez le logiciel de visualisation sur votre ordinateur pour afficher les données du radar.
4. Le radar commencera à détecter les objets et à afficher leur position en temps réel.
