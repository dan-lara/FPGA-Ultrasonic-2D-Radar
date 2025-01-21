#include <stdio.h>
#include <math.h>
#include "system.h"
#include <unistd.h> // Pour usleep
#include "io.h"
#include "altera_avalon_pio_regs.h"
#define PIXEL_BUF_CTRL_BASE VGA_SUBSYSTEM_VGA_PIXEL_DMA_BASE
#define RGB_RESAMPLER_BASE VGA_SUBSYSTEM_VGA_PIXEL_RGB_RESAMPLER_BASE
#define FPGA_CHAR_BASE VGA_SUBSYSTEM_CHAR_BUF_SUBSYSTEM_CHAR_BUF_DMA_BASE
/* function prototypes */
void set_servo_angle(int angle);
void draw_radar_line(int angle, int distance);
void video_text(int, int, char *);
void video_box(int, int, int, int, short);
int resample_rgb(int, int);
int get_data_bits(int);
#define STANDARD_X 320
#define STANDARD_Y 240
#define PI 3.14159265359
#define MIN_DISTANCE 4
#define MAX_DISTANCE 200
#define GREEN 0x07E0  // RGB565 format
#define RED 0xF800    // RGB565 format
#define INTEL_BLUE 0x0071C5
#define GREEN 0x07E0
#define RED 0xF800
#define WHITE 0xFFFF
void set_servo_angle(int angle);
void draw_radar_border(void);
void draw_radar_line(int angle, int distance);
void clear_previous_line(int angle);
void video_box(int x1, int y1, int x2, int y2, short pixel_color);
int resample_rgb(int num_bits, int color);
int get_data_bits(int mode);
void video_text2(int x, int y, char * text_ptr, char color);

int screen_x;
int screen_y;
int res_offset;
int col_offset;
int center_x;
int center_y;
int radar_radius = 180;
int current_angle = 180;
int Dist_cm = 0;
int pas = 2;
int up = -1;
int min = 0;
int max = 180;
char angle_text[40];

int main(void) {
    volatile int *video_resolution = (int *)(PIXEL_BUF_CTRL_BASE + 0x8);
    screen_x = *video_resolution & 0xFFFF;
    screen_y = (*video_resolution >> 16) & 0xFFFF;

    volatile int *rgb_status = (int *)(RGB_RESAMPLER_BASE);
    int db = get_data_bits(*rgb_status & 0x3F);

    res_offset = (screen_x == 160) ? 1 : 0;
    col_offset = (db == 8) ? 1 : 0;

    // Set radar dimensions
    center_x = STANDARD_X / 2;
    center_y = STANDARD_Y - 20;  // Move up slightly
    radar_radius = 180;  // Smaller radius
    video_box(0, 0, STANDARD_X, STANDARD_Y, 0);
    // Draw radar border
    draw_radar_border();
    while(1) {

        // Clear previous line
        clear_previous_line(current_angle);

        Dist_cm =  IORD(TELEMETRE_0_BASE,0) ;
		set_servo_angle(current_angle);
		sprintf(angle_text, "%d -> %d cm", current_angle, Dist_cm);
		//video_text(35, 10, angle_text);
		printf("%d� -> %d cm\n", current_angle, Dist_cm);
        draw_radar_line(current_angle, Dist_cm);

        if (current_angle >= max)
			up = -1;
		else if(current_angle <= 0)
			up = 1;

        current_angle += up*pas;
        // Add delay here if needed
        usleep(100000);
    }

    return 0;
}
void set_servo_angle(int angle) {
    int pulse_width = 10*angle; // Conversion de 0-180�
    IOWR(SERVO_0_BASE, 0, pulse_width);  // �crire l'angle
    usleep(20000);                   // D�lai de 20 ms pour stabiliser le servomoteur
}
void draw_radar_border(void) {
    // Draw semicircle border
    for(int angle = 0; angle <= 180; angle++) {
        double rad_angle = angle * PI / 180.0;
        int x = center_x - (int)(cos(rad_angle) * radar_radius);
        int y = center_y - (int)(sin(rad_angle) * radar_radius);
        video_box(x-1, y-1, x+1, y+1, WHITE);
    }
}

void clear_previous_line(int angle) {
    double rad_angle = angle * PI / 180.0;
    int end_x = center_x - (int)(cos(rad_angle) * radar_radius);
    int end_y = center_y - (int)(sin(rad_angle) * radar_radius);

    int steps = (int)sqrt((end_x - center_x) * (end_x - center_x) +
                         (end_y - center_y) * (end_y - center_y));

    for(int i = 0; i <= steps; i++) {
        int x = center_x + (end_x - center_x) * i / steps;
        int y = center_y + (end_y - center_y) * i / steps;
        video_box(x-1, y-1, x+1, y+1, 0);
    }
}

void draw_radar_line(int angle, int distance) {
    if(distance < MIN_DISTANCE) distance = MIN_DISTANCE;
    if(distance > radar_radius) distance = radar_radius;

    double rad_angle = angle * PI / 180.0;
    int end_x = center_x - (int)(cos(rad_angle) * distance);
    int end_y = center_y - (int)(sin(rad_angle) * distance);

    // Draw green line to distance point
    int steps = (int)sqrt((end_x - center_x) * (end_x - center_x) +
                         (end_y - center_y) * (end_y - center_y));

    for(int i = 0; i <= steps; i++) {
        int x = center_x + (end_x - center_x) * i / steps;
        int y = center_y + (end_y - center_y) * i / steps;
        video_box(x-1, y-1, x+1, y+1, GREEN);
    }

    // Draw red line from distance to max
    int max_x = center_x - (int)(cos(rad_angle) * radar_radius);
    int max_y = center_y - (int)(sin(rad_angle) * radar_radius);

    steps = (int)sqrt((max_x - end_x) * (max_x - end_x) +
                     (max_y - end_y) * (max_y - end_y));

    for(int i = 0; i <= steps; i++) {
        int x = end_x + (max_x - end_x) * i / steps;
        int y = end_y + (max_y - end_y) * i / steps;
        video_box(x-1, y-1, x+1, y+1, RED);
    }
}
/*******************************************************************************
* Subroutine to send a string of text to the video monitor
******************************************************************************/
void video_text(int x, int y, char * text_ptr) {
	int offset;
	volatile char * character_buffer =
	(char *)FPGA_CHAR_BASE; // video character buffer
	/* assume that the text string fits on one line */
	offset = (y << 7) + x;
	while (*(text_ptr)) {
		*(character_buffer + offset) =
		*(text_ptr); // write to the character buffer
		++text_ptr;
		++offset;
	}
}
/*******************************************************************************
* Draw a filled rectangle on the video monitor
* Takes in points assuming 320x240 resolution and adjusts based on differences
* in resolution and color bits.
******************************************************************************/
void video_box(int x1, int y1, int x2, int y2, short pixel_color) {
int pixel_buf_ptr = *(int *)PIXEL_BUF_CTRL_BASE;
int pixel_ptr, row, col;
int x_factor = 0x1 << (res_offset + col_offset);
int y_factor = 0x1 << (res_offset);
x1 = x1 / x_factor;
x2 = x2 / x_factor;
y1 = y1 / y_factor;
y2 = y2 / y_factor;
/* assume that the box coordinates are valid */
for (row = y1; row <= y2; row++)
for (col = x1; col <= x2; ++col) {
pixel_ptr = pixel_buf_ptr +
(row << (10 - res_offset - col_offset)) + (col << 1);
*(short *)pixel_ptr = pixel_color; // set pixel color
}
}
/********************************************************************************
* Resamples 24-bit color to 16-bit or 8-bit color
*******************************************************************************/
int resample_rgb(int num_bits, int color) {
if (num_bits == 8) {
color = (((color >> 16) & 0x000000E0) | ((color >> 11) & 0x0000001C) |
((color >> 6) & 0x00000003));
color = (color << 8) | color;
} else if (num_bits == 16) {
	color = (((color >> 8) & 0x0000F800) | ((color >> 5) & 0x000007E0) |
	((color >> 3) & 0x0000001F));
	}
	return color;
	}
	/********************************************************************************
	* Finds the number of data bits from the mode
	*******************************************************************************/
	int get_data_bits(int mode) {
	switch (mode) {
	case 0x0:
	return 1;
	case 0x7:
	return 8;
	case 0x11:
	return 8;
	case 0x12:
	return 9;
	case 0x14:
	return 16;
	case 0x17:
	return 24;
	case 0x19:
	return 30;
	case 0x31:
	return 8;
	case 0x32:
	return 12;
	case 0x33:
	return 16;
	case 0x37:
	return 32;
	case 0x39:
	return 40;
	}
	}
