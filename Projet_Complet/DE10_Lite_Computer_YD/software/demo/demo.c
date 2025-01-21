#include <stdio.h>
#include <math.h>
#include "system.h"
#include <unistd.h> // Pour usleep
#include "io.h"
#include "altera_avalon_pio_regs.h"

#include "radar.h" // Pour toutes les fonctions de radar

int Dist_cm = 0;
int angle = 0;
int pas = 5;
int up = 0;
int min = 0;
int max = 180;
//vga
int db;
int screen_x;
int screen_y;
int res_offset;
int col_offset;
char angle_text[40];

//NeoPixel
char *color;
char * red = RED;
char * blue = BLUE;
char * green = GREEN;

//UART
int speed = 1;

int main()
{
	//Setup de l'affichage
	volatile int *video_resolution = (int *)(PIXEL_BUF_CTRL_BASE + 0x8);
    screen_x = *video_resolution & 0xFFFF;
    screen_y = (*video_resolution >> 16) & 0xFFFF;

    volatile int *rgb_status = (int *)(RGB_RESAMPLER_BASE);
    int db = get_data_bits(*rgb_status & 0x3F);

    res_offset = (screen_x == 160) ? 1 : 0;
    col_offset = (db == 8) ? 1 : 0;

	video_box(0, 0, STANDARD_X, STANDARD_Y, 0, res_offset, col_offset);
	draw_radar_border(res_offset, col_offset);

	while(1){	
		int received_char = read_ascii();
		printf("received_char = %d\n", received_char);
		update_data(received_char, &min, &max, &speed);
		clear_previous_line(angle, res_offset, col_offset);

		Dist_cm = get_distance(); // IORD(TELEMETRE_0_BASE,0) ;
		set_servo_angle(angle);

		printf("Value: %d cm - ", Dist_cm);
		printf("Angle : %d°\n", angle);
		
		display_number(Dist_cm, angle);
		draw_radar_line(angle, Dist_cm, res_offset, col_offset);
		
		if (Dist_cm < 20)
		 color = RED;
		else
		 color = GREEN;
		printf("Valeur actuelle : %d, Coleur Actuelle : %s\n",angle / 15, color);
        sendColorAndValue(color, angle / 15);

		if (angle >= max)
			up = -1;
		else if(angle <= 0)
			up = 1;

		angle += up*pas;

		usleep(110000 - 5000 * (speed%10));
	}
  return 0;
}