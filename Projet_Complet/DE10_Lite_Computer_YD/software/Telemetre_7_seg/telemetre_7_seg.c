#include <stdio.h>
#include <unistd.h> // Pour usleep
#include "system.h"
#include "io.h"
#include "altera_avalon_pio_regs.h"
const int SEG7_TABLE[10] = {
    0x3F, // 0: 0b00111111
    0x06, // 1: 0b00000110
    0x5B, // 2: 0b01011011
    0x4F, // 3: 0b01001111
    0x66, // 4: 0b01100110
    0x6D, // 5: 0b01101101
    0x7D, // 6: 0b01111101
    0x07, // 7: 0b00000111
    0x7F, // 8: 0b01111111
    0x6F  // 9: 0b01101111
};

void display_number(int value) {
    if (value < 0 || value > 999) {
        return;
    }

    int c = value / 100;
    int d = (value / 10) % 10;
    int u = value % 10;
    long hex0_3 = 0;
    hex0_3 |= SEG7_TABLE[u] << 0;  // HEX0
    hex0_3 |= SEG7_TABLE[d] << 8;   // HEX1
    hex0_3 |= SEG7_TABLE[c] << 16; // HEX2


	long long hex4_5 = 0;
    hex4_5 = 0;
    IOWR_ALTERA_AVALON_PIO_DATA(HEX3_HEX0_BASE, hex0_3);
    IOWR_ALTERA_AVALON_PIO_DATA(HEX5_HEX4_BASE, hex4_5);
}

int main()
{
	int Dist_cm = 0;
	while(1){
		Dist_cm =  IORD(TELEMETRE_0_BASE,0) ;
		printf("Value: %d cm\n", Dist_cm);
		display_number(Dist_cm);
		usleep(500000);

	}


  return 0;
}
