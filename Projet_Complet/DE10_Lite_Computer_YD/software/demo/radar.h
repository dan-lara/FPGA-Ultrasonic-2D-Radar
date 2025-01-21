#ifndef RADAR_H
#define RADAR_H

#include <stdio.h>
#include <math.h>
#include <string.h>
#include "system.h"
#include <unistd.h> // Pour usleep
#include "io.h"
#include "altera_avalon_pio_regs.h"

// ============================================================
// 7 segments
// ============================================================
void display_number(int left, int right);

// ============================================================
// Telemetre 
// ============================================================
#define MAX_DISTANCE 400
#define MIN_DISTANCE 4
int get_distance(void);

// ============================================================
// Servomoteur
// ============================================================
#define MAX_ANGLE 180
#define MIN_ANGLE 0
void set_servo_angle(int angle);

// ============================================================
// VGA
// ============================================================
#define PIXEL_BUF_CTRL_BASE VGA_SUBSYSTEM_VGA_PIXEL_DMA_BASE
#define RGB_RESAMPLER_BASE VGA_SUBSYSTEM_VGA_PIXEL_RGB_RESAMPLER_BASE
#define FPGA_CHAR_BASE VGA_SUBSYSTEM_CHAR_BUF_SUBSYSTEM_CHAR_BUF_DMA_BASE
#define STANDARD_X 320
#define STANDARD_Y 240
#define CENTER_X (STANDARD_X / 2)
#define CENTER_Y (STANDARD_Y - 20)
#define RADAR_RADIUS 180
#define PI 3.14159265359
#define MIN_DISTANCE 4
#define MAX_DISTANCE 200
#define GREEN 0x07E0  // RGB565 format
#define RED 0xF800    // RGB565 format
#define INTEL_BLUE 0x0071C5
#define GREEN 0x07E0
#define RED 0xF800
#define WHITE 0xFFFF

void draw_radar_border(int res_offset, int col_offset);
void draw_radar_line(int angle, int distance, int res_offset, int col_offset);
void clear_previous_line(int angle, int res_offset, int col_offset);
void video_box(int x1, int y1, int x2, int y2, short pixel_color, int res_offset, int col_offset);
int resample_rgb(int num_bits, int color);
int get_data_bits(int mode);

// ============================================================
// Neopixel
// ============================================================
#define RED "001100"
#define YELLOW "111100"
#define GREEN "110000"
#define BLUE "000011"
#define PURPLE "001111"
#define CYAN "110011"
#define WHITE "111111"
int fromBinaryString(const char *binaryStr);
void toBinaryString(int value, char *binaryStr, int size);
void sendColorAndValue(const char *color, int value);

// ============================================================
// UART
// ============================================================
#define UART_0_BASE 0x4000004
#define LOAD_MODE (0x01 << 30)
#define TX_MODE (0x00 << 30)
#define RX_MODE	  (0x02 << 30)
#define ASCII_MASK 0xFF
#define CR 0x0D
#define LF 0x0A
#define MAX_SPEED 9
#define MIN_SPEED 0
void send_ascii(int ascii_char, int delay_us);
void send_string(const char *word, int angle, int min, int max, int speed);
int read_ascii();
void update_data(int received_char, int *min, int *max, int *speed);

// ============================================================
#endif
