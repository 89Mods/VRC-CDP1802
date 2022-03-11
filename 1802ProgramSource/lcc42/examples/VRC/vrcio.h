unsigned char* curserLocPntr = (unsigned char *)65532;
unsigned char* keypadInputPntr = (unsigned char *)65529;

#define KEY_0 0
#define KEY_1 1
#define KEY_2 2
#define KEY_3 3
#define KEY_4 4
#define KEY_5 5
#define KEY_ENTER 10

void terminalInit(void);
void putc(char c);
void setCursorRow(char row);
void setCursorCol(char col);
void setTextColor(char color);
void delay(int amount);
void yield(void);
char getCursorRow(void);
char getCursorCol(void);
char getKey(void);
