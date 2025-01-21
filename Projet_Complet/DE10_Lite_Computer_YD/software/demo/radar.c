#include "radar.h"
#include "system.h"
// ============================================================
// 7 segments
// ============================================================
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

void display_number(int left, int right) {
    if ((left < 0 || left > 999) || (right < 0 || right > 999)) 
        return;

    int c = left / 100;
    int d = (left / 10) % 10;
    int u = left % 10;
    long hex0_3 = 0;
    hex0_3 |= SEG7_TABLE[u] << 0;  // HEX0
    hex0_3 |= SEG7_TABLE[d] << 8;   // HEX1
    hex0_3 |= SEG7_TABLE[c] << 16; // HEX2


	long long hex4_5 = 0;
    c = right / 100;
	d = (right / 10) % 10;
	u = right % 10;
	hex0_3 |= SEG7_TABLE[u] << 24; // HEX3
	hex4_5 |= SEG7_TABLE[d] << 0;  // HEX4
	hex4_5 |= SEG7_TABLE[c] << 8;  // HEX5

    IOWR_ALTERA_AVALON_PIO_DATA(HEX3_HEX0_BASE, hex0_3);
    IOWR_ALTERA_AVALON_PIO_DATA(HEX5_HEX4_BASE, hex4_5);
}

// ============================================================
// Telemetre 
// ============================================================
int get_distance(void) {
    return IORD(TELEMETRE_0_BASE, 0);
}

// ============================================================
// Servomoteur
// ============================================================
void set_servo_angle(int angle) {
    int pulse_width = 10*angle; // Conversion de 0-1800
    IOWR(SERVO_0_BASE, 0, pulse_width);  // Ecrire l'angle
    usleep(20000);                   // D�lai de 20 ms pour stabiliser le servomoteur
}

// ============================================================
// VGA
// ============================================================

void draw_radar_border(int res_offset, int col_offset) {
    // Draw semicircle border
    for(int angle = 0; angle <= 180; angle++) {
        double rad_angle = angle * PI / 180.0;
        int x = CENTER_X - (int)(cos(rad_angle) * RADAR_RADIUS);
        int y = CENTER_Y - (int)(sin(rad_angle) * RADAR_RADIUS);
        video_box(x-1, y-1, x+1, y+1, WHITE, res_offset, col_offset);
    }
}

void clear_previous_line(int angle, int res_offset, int col_offset) {
    double rad_angle = angle * PI / 180.0;
    int end_x = CENTER_X - (int)(cos(rad_angle) * RADAR_RADIUS);
    int end_y = CENTER_Y - (int)(sin(rad_angle) * RADAR_RADIUS);

    int steps = (int)sqrt((end_x - CENTER_X) * (end_x - CENTER_X) +
                         (end_y - CENTER_Y) * (end_y - CENTER_Y));

    for(int i = 0; i <= steps; i++) {
        int x = CENTER_X + (end_x - CENTER_X) * i / steps;
        int y = CENTER_Y + (end_y - CENTER_Y) * i / steps;
        video_box(x-1, y-1, x+1, y+1, 0, res_offset, col_offset);
    }
}

void draw_radar_line(int angle, int distance, int res_offset, int col_offset) {
    if(distance < MIN_DISTANCE) distance = MIN_DISTANCE;
    if(distance > RADAR_RADIUS) distance = RADAR_RADIUS;

    double rad_angle = angle * PI / 180.0;
    int end_x = CENTER_X - (int)(cos(rad_angle) * distance);
    int end_y = CENTER_Y - (int)(sin(rad_angle) * distance);

    // Draw green line to distance point
    int steps = (int)sqrt((end_x - CENTER_X) * (end_x - CENTER_X) +
                         (end_y - CENTER_Y) * (end_y - CENTER_Y));

    for(int i = 0; i <= steps; i++) {
        int x = CENTER_X + (end_x - CENTER_X) * i / steps;
        int y = CENTER_Y + (end_y - CENTER_Y) * i / steps;
        video_box(x-1, y-1, x+1, y+1, GREEN, res_offset, col_offset);
    }

    // Draw red line from distance to max
    int max_x = CENTER_X - (int)(cos(rad_angle) * RADAR_RADIUS);
    int max_y = CENTER_Y - (int)(sin(rad_angle) * RADAR_RADIUS);

    steps = (int)sqrt((max_x - end_x) * (max_x - end_x) +
                     (max_y - end_y) * (max_y - end_y));

    for(int i = 0; i <= steps; i++) {
        int x = end_x + (max_x - end_x) * i / steps;
        int y = end_y + (max_y - end_y) * i / steps;
        video_box(x-1, y-1, x+1, y+1, RED, res_offset, col_offset);
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
void video_box(int x1, int y1, int x2, int y2, short pixel_color, int res_offset, int col_offset) {
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
        color = (((color >> 16) & 0x000000E0) | ((color >> 11) & 0x0000001C) | ((color >> 6) & 0x00000003));
        color = (color << 8) | color;
    } else if (num_bits == 16) {
        color = (((color >> 8) & 0x0000F800) | ((color >> 5) & 0x000007E0) | ((color >> 3) & 0x0000001F));
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
// ============================================================
// Neopixel
// ============================================================
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

// ============================================================
// UART
// ============================================================
void send_ascii(int ascii_char, int delay_us)
{
	IOWR_32DIRECT(UART_0_BASE, 0x0, LOAD_MODE | (ascii_char & ASCII_MASK));
	usleep(delay_us);
	IOWR_32DIRECT(UART_0_BASE, 0x0, TX_MODE | (0x0 & ASCII_MASK));
}


void send_string(const char *word, int angle, int min, int max, int speed)
{
    char buffer[100];
    snprintf(buffer, sizeof(buffer), "%s %d° [%d/%d] speed: %d", word, angle, min, max, speed);
    for (int i = 0; buffer[i] != '\0'; i++)
        send_ascii(buffer[i],1000);
    usleep(1000);
    send_ascii(CR,1000);
}

int read_ascii()
{
    IOWR_32DIRECT(UART_0_BASE, 0x4, LOAD_MODE | (0x0 & ASCII_MASK));
    usleep(1000);
    return IORD_32DIRECT(UART_0_BASE, 0x8);
}
void update_data(int received_char, int *min, int *max, int *speed)
{   	
    if (received_char >= '0' && received_char <= '9')
        speed = received_char - '0';
    else if (received_char >= 'a' && received_char <= 'z')
    	min = (received_char - 'a') * 10;
    else if (received_char >= 'A' && received_char <= 'Z')
    	max = (received_char - 'A') * 10;
	
	max = (max > MAX_ANGLE) ? MAX_ANGLE : max;
	min = (min < MIN_ANGLE) ? MIN_ANGLE : min;
	speed = (speed > MAX_SPEED) ? MAX_SPEED : speed;
	speed = (speed < MIN_SPEED) ? MIN_SPEED : speed;
}
