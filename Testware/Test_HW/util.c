#include <stdio.h>
#include <ctype.h>
#include <xuartns550.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <xparameters.h>
#include <util.h>

// UART
char RecvBuffer[RECV_BUFFER_SIZE];

void UartSendBuffer(const unsigned char *buffer, unsigned int length)
{
	unsigned int SentCount;

	SentCount = 0;
	while (SentCount < length) {
		/*
		* Transmit the data
		*/
		SentCount += XUartNs550_Send((unsigned char*)&buffer[SentCount], MIN(XUN_FIFO_SIZE, length - SentCount));
	}
}

// Lit un ligne à partir de l'UART
char *UartReadLn()
{
	unsigned int ReceivedCount = 0, c, RecvCountPrev = 0;
	unsigned char i, LsrRegister, RecvData;

	while (1) {

		LsrRegister = XUartNs550_GetLineStatusReg(UartNs550.BaseAddress);
		/*
		 * If there is data ready to be removed, then put the next byte
		 * received into the specified buffer and update the stats to
		 * reflect any receive errors for the byte
		*/
		ReceivedCount += XUartNs550_Recv(RecvBuffer + ReceivedCount,
						 RECV_BUFFER_SIZE - ReceivedCount);

		// UART echo
		if (ReceivedCount != RecvCountPrev) {
			UartSendBuffer(RecvBuffer + RecvCountPrev, ReceivedCount - RecvCountPrev);
			RecvCountPrev = ReceivedCount;
		}

		// Verifie si \n est dans le buffer de reception
		for (c = 0; c < ReceivedCount; c++) {
			if ((RecvBuffer[c] == '\r')  || (RecvBuffer[c] == '\n')) {
				RecvBuffer[c] == '\0'; // Terminate the string
				break;
			}
		}
		if ((c != ReceivedCount) || (ReceivedCount == RECV_BUFFER_SIZE)) {
			break;
		}
	}

	return RecvBuffer; 
}

unsigned char hexdigit( char hex )
{
    return (hex <= '9') ? hex - '0' : 
                          toupper(hex) - 'A' + 10 ;
}

unsigned char hexbyte( const char* hex )
{
    return (hexdigit(*hex) << 4) | hexdigit(*(hex+1)) ;
}

void sleep_ms(unsigned int duree_ms)
{
	unsigned long start_time;

	start_time = FrameCounter;
	while (((FrameCounter - start_time) * VBLANK_PERIOD) < duree_ms) {}
}

int fgetc_cons(void) {}

void im1_handler()
{
    // Disable HW interrupts and reset the watchdog timer
    *(volatile unsigned char*)INTERRUPT_ENABLE_REG = 0x00; // Disable hardware interrupts
    *(volatile unsigned char*)WATCH_RESET_REG = 0x00; // Reset watchdog timer

    // Increment the frame counter
    FrameCounter++;

    // Enable hardware interrupts again
    *(volatile unsigned char*)INTERRUPT_ENABLE_REG = 0x01; // Enable hardware interrupts
}