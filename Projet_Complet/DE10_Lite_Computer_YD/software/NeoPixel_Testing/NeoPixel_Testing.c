#include <stdio.h>
#include <string.h>
#include <math.h>
#include "altera_avalon_pio_regs.h"
#include "unistd.h" // Pour usleep
#include "system.h"
#include "io.h"

int fromBinaryString(const char *binaryStr);
void toBinaryString(int value, char *binaryStr, int size);
void sendColorAndValue(const char *color, int value);
int i =1;
int value = 0;
char *red = "001100";
char *yellow = "111100";
int main()
{
	while (1)
	{
		printf("Valeur actuelle : %d, Coleur Actuelle : %s\n",value, red);
        sendColorAndValue(red, value);
		value +=i;

		if (value>12)
			i=-1;
		else if (value ==0)
			i=1;

		usleep(200000);
	}
	return 0;
}

int fromBinaryString(const char *binaryStr) {
    int value = 0;
    int length = strlen(binaryStr);

    for (int i = 0; i < length; i++) {
        if (binaryStr[i] == '1') {
            value |= (1 << (length - 1 - i));
        } else if (binaryStr[i] != '0') {
            printf("Erreur: Caractère invalide dans la chaîne binaire.\n");
            return -1; // Retourne -1 pour indiquer une erreur
        }
    }
    return value;
}

void toBinaryString(int value, char *binaryStr, int size) {
    for (int i = 0; i < size; i++) {
        binaryStr[size - 1 - i] = (value & (1 << i)) ? '1' : '0';
    }
    binaryStr[size] = '\0'; // Termine la chaîne avec null
}

void sendColorAndValue(const char *color, int value) {
    int colorValue = fromBinaryString(color);
    int combinedValue = (colorValue << 4) | (value & 0xF);
    IOWR(NEOPIXEL_0_BASE, 0, combinedValue);
}
