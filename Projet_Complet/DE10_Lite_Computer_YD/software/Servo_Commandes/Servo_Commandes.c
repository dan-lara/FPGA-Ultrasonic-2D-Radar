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

void display_number(int value, int value2) {
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
    c = value2 / 100;
	d = (value2 / 10) % 10;
	u = value2 % 10;
	hex0_3 |= SEG7_TABLE[u] << 24; // HEX3
	hex4_5 |= SEG7_TABLE[d] << 0;  // HEX4
	hex4_5 |= SEG7_TABLE[c] << 8;  // HEX5

    IOWR_ALTERA_AVALON_PIO_DATA(HEX3_HEX0_BASE, hex0_3);
    IOWR_ALTERA_AVALON_PIO_DATA(HEX5_HEX4_BASE, hex4_5);
}
void set_servo_angle(int angle) {
    int pulse_width = 10*angle; // Conversion de 0-1800
    IOWR(SERVO_0_BASE, 0, pulse_width);  // Ecrire l'angle
    usleep(20000);                   // D�lai de 20 ms pour stabiliser le servomoteur
}
int main()
{
	int angle = 0;
	int Dist_cm = 0;
	int pas = 5;
	int up = 0;
	int max = 180;
	while(1){

		Dist_cm =  IORD(TELEMETRE_0_BASE,0) ;
		set_servo_angle(angle);
		//printf("%d,%d.", angle, Dist_cm);//Pour le processing
		printf("%d -> %d cm\n", angle, Dist_cm);
		//printf("Angle : %d�\n", angle);
		display_number(Dist_cm, angle);

		if (angle >= max)
			up = -1;
		else if(angle <= 0)
			up = 1;

		angle += up*pas;

		usleep(110000);
	}

  return 0;
}
