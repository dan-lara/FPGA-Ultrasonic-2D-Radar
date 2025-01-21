#include <stdio.h>
#include "unistd.h"
#include "system.h"
#include "io.h"
#include "altera_avalon_pio_regs.h"
#define UART_0_BASE 0x4000004
// Definition des constantes
#define LOAD_MODE (0x01 << 30)
#define TX_MODE (0x00 << 30)
#define RX_MODE	  (0x02 << 30)
#define ASCII_MASK 0xFF
#define CR 0x0D
#define LF 0x0A
#define MAX_SPEED 9
#define MIN_SPEED 0
#define MAX_ANGLE 180
#define MIN_ANGLE 0

//Prototypes Servomoteur
void display_number(int value, int value2);
void set_servo_angle(int angle);

//Prototypes
void send_ascii(int ascii_char, int delay_us);
void send_string(const char *word, int angle);
int read_ascii();
void update_data(int received_char);

//Variables globales
int angle = 0;
int Dist_cm = 0;
int pas = 5;
int up = 0;
int min = 0;
int max = 180;
int speed = 1;

int main()
{
	while(1){
		
		int received_char = read_ascii();
		printf("received_char = %d\n", received_char);
		update_data(received_char);

		Dist_cm =  IORD(TELEMETRE_0_BASE,0) ;
		set_servo_angle(angle);

		printf("%d -> %d cm\n", angle, Dist_cm);
		display_number(Dist_cm, angle);

		if (angle >= max)
			up = -1;
		else if(angle <= 0)
			up = 1;
		angle += up*pas;

		usleep(110000 - 5000 * (speed%10));
	}
    return 0;
}

void send_ascii(int ascii_char, int delay_us)
{
	IOWR_32DIRECT(UART_0_BASE, 0x0, LOAD_MODE | (ascii_char & ASCII_MASK));
	usleep(delay_us);
	IOWR_32DIRECT(UART_0_BASE, 0x0, TX_MODE | (0x0 & ASCII_MASK));
}

void send_string(const char *word, int angle)
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
void update_data(int received_char)
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

/*******************************************************************************
* Test de la communication JTAG UART, il n'a pas fonctionné
******************************************************************************/
/*
void put_jtag(volatile int * JTAG_UART_ptr, char c);
char get_jtag(volatile int * JTAG_UART_ptr);
void send_string(volatile int * JTAG_UART_ptr, const char *str);
void process_command(volatile int * JTAG_UART_ptr, char *buffer, int *step, int *delay, int *data_sending);

int step = 0;         // Valeur de STEP (0-10)
int delay = 65;       // Délai en ms (65-1000)
int data_sending = 0; // Drapeau d'envoi de données (0 ou 1)

int main(void)
{
	char buffer[128];
	int buffer_index = 0;
	char c;

	volatile int * JTAG_UART_ptr = (int *)JTAG_UART_BASE; // Adresse JTAG UART

	send_string(JTAG_UART_ptr, "\nExemple de code JTAG UART\n> ");
	while (1)
	{
		c = get_jtag(JTAG_UART_ptr);
		if (c != '\0') {
			put_jtag(JTAG_UART_ptr, c); //Écho

			if (c == '\n') {
				buffer[buffer_index] = '\0';
				process_command(JTAG_UART_ptr, buffer, &step, &delay, &data_sending);
				buffer_index = 0;
			} else if (buffer_index < sizeof(buffer) - 1)
				buffer[buffer_index++] = c;
			else {
				send_string(JTAG_UART_ptr, "ERREUR : Commande trop longue\n> ");
				buffer_index = 0;
			}
		}
	}
}
*/
/*******************************************************************************
* Sous-programme pour envoyer un caractère au JTAG UART
*****************************************************************************
void put_jtag(volatile int * JTAG_UART_ptr, char c)
{
	int control;
	control = *(JTAG_UART_ptr + 1); // lire le registre de contrôle JTAG_UART
	if (control & 0xFFFF0000) // s'il y a de l'espace, écho du caractère, sinon ignorer
		*(JTAG_UART_ptr) = c;
}*/
/*******************************************************************************
* Sous-programme pour lire un caractère du JTAG UART
* Renvoie \0 s'il n'y a pas de caractère, sinon renvoie le caractère
*****************************************************************************
char get_jtag(volatile int * JTAG_UART_ptr)
{
	int data;
	data = *(JTAG_UART_ptr); // lire le registre de données JTAG_UART
	if (data & 0x00008000) // vérifier RVALID pour voir s'il y a de nouvelles données
		return ((char)data & 0xFF);

	return ('\0');
}*/
/*******************************************************************************
* Sous-programme pour envoyer une chaîne de caractères au JTAG UART
*****************************************************************************
void send_string(volatile int * JTAG_UART_ptr, const char *str)
{
	while (*str) {
		int status = *(JTAG_UART_ptr + 1); // Registre de contrôle
		if (status & 0xFFFF0000) {         // Vérifie l'espace dans le buffer
			*(JTAG_UART_ptr) = *str++;     // Envoie le prochain caractère
		}
	}
}*/
/*******************************************************************************
* Sous-programme pour traiter la commande
*****************************************************************************
void process_command(volatile int * JTAG_UART_ptr, char *buffer, int *step, int *delay, int *data_sending)
{
	if (strncmp(buffer, "SET_STEP ", 9) == 0) {
		int value = atoi(&buffer[9]);
		if (value >= 0 && value <= 10) {
			*step = value;
			send_string(JTAG_UART_ptr, "OK\n> ");
		} else {
			send_string(JTAG_UART_ptr, "ERREUR : STEP hors de portée\n> ");
		}
	} else if (strcmp(buffer, "GET_STEP") == 0) {
		char response[32];
		sprintf(response, "STEP : %d\n> ", *step);
		send_string(JTAG_UART_ptr, response);
	} else if (strncmp(buffer, "SET_DELAY ", 10) == 0) {
		int value = atoi(&buffer[10]);
		if (value >= 65 && value <= 1000) {
			*delay = value;
			send_string(JTAG_UART_ptr, "OK\n> ");
		} else {
			send_string(JTAG_UART_ptr, "ERREUR : DELAY hors de portée\n> ");
		}
	} else if (strcmp(buffer, "GET_DELAY") == 0) {
		char response[32];
		sprintf(response, "DÉLAI : %d ms\n> ", *delay);
		send_string(JTAG_UART_ptr, response);
	} else if (strncmp(buffer, "SET_DATA_SENDING ", 18) == 0) {
		int value = atoi(&buffer[18]);
		if (value == 0 || value == 1) {
			*data_sending = value;
			send_string(JTAG_UART_ptr, "OK\n> ");
		} else {
			send_string(JTAG_UART_ptr, "ERREUR : La valeur de DATA_SENDING doit être 0 ou 1\n> ");
		}
	} else {
		send_string(JTAG_UART_ptr, "ERREUR : Commande inconnue\n> ");
	}
}*/
