#ifndef UTIL_H /* prevent circular inclusions */
#define UTIL_H /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files ********************************/


/************************** Constant Definitions ****************************/

#define WATCH_RESET_REG                     0x50C0
#define INTERRUPT_ENABLE_REG                0x5000
#define VBLANK_PERIOD                       16.602
#define UART_DEVICE_ID			            XPAR_UARTNS550_0_DEVICE_ID
#define RECV_BUFFER_SIZE		            126

#define MIN(x, y) (((x) < (y)) ? (x) : (y))

/**************************** Type Definitions ******************************/

/**************************** Proptotypes  ******************************/

void sleep_ms(unsigned int);
void ReadVBlankCounter();

void UartSendBuffer(const unsigned char *, unsigned int);
char *UartReadLn();
unsigned char hexdigit( char );
unsigned char hexbyte( const char* );
void sleep_ms(unsigned int );
void asm_im1_handler(void);


extern long int FrameCounter;

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
/** @} */
