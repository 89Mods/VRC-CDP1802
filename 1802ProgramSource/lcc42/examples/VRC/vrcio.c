#define TERM_W 64
#define TERM_H 50

unsigned char terminal[TERM_W * TERM_H][2];
unsigned char currRow = 0;
unsigned char currCol = 0;
unsigned char currTextColor = 63;

void shiftLinesUp(void) {
	int i,j;
	for(i = 1; i < TERM_H; i++) {
		for(j = 0; j < TERM_W; j++) {
			terminal[(i - 1) * TERM_W + j][0] = terminal[i * TERM_W + j][0];
			terminal[(i - 1) * TERM_W + j][1] = terminal[i * TERM_W + j][1];
		}
	}
	for(j = 0; j < TERM_W; j++) {
		terminal[(TERM_H - 1) * TERM_W + j][0] = ' ';
		terminal[(TERM_H - 1) * TERM_W + j][1] = 63;
	}
}

void putc(char c) {
	if(c == '\n') {
		currRow++;
		if(currRow == 51) {
			shiftLinesUp();
			currRow = 50;
		}
		currCol = 0;
		*curserLocPntr = currRow;
		*(curserLocPntr + 1) = currCol;
		return;
	}
	if(c == '\r') {
		currCol = 0;
		*curserLocPntr = currRow;
		*(curserLocPntr + 1) = currCol;
		return;
	}
	if(currCol == 64) {
		putc('\n');
		putc(c);
		return;
	}
	terminal[currRow * TERM_W + currCol][0] = c;
	terminal[currRow * TERM_W + currCol][1] = currTextColor;
	currCol++;
	*curserLocPntr = currRow;
	*(curserLocPntr + 1) = currCol;
}

void terminalInit(void) {
	int i;
	unsigned char* bufferPntr = (unsigned char *)65534;
	currTextColor = 63;
	//for(i = 0; i < TERM_W * TERM_H; i++) terminal[i] = ' ';
	//for(i = 0; i < TERM_W * TERM_H; i++) terminal[i] = currTextColor;
	*bufferPntr = (unsigned short)(&terminal) >> 8;
	bufferPntr++;
	*bufferPntr = (unsigned short)(&terminal) & 0xFF;
	currRow = currCol = 0;
	*curserLocPntr = currRow;
	*(curserLocPntr + 1) = currCol;
}

void setCursorRow(char row) {
	currRow = row;
	*curserLocPntr = currRow;
}

void setCursorCol(char col) {
	currCol = col;
	*(curserLocPntr + 1) = currCol;
}

void setTextColor(char color) {
	currTextColor = color;
}

char getCursorRow(void) {
	return currRow;
}

char getCursorCol(void) {
	return currCol;
}

void delay(int amount) {
	int i;
	for(i = 0; i < amount; i++) {
		asm("\tnop");
	}
}

char getKey(void) {
	unsigned char ret;
	while(!(*keypadInputPntr)) yield();
	yield();
	yield();
	yield();
	yield();
	ret = *keypadInputPntr;
	ret += 1;
	ret >>= 3;
	while(*keypadInputPntr) yield();
	yield();
	if(ret == 6) ret = 0;
	return ret;
}

void yield(void) { //Execute YIELD pseudo-instruction in emulator
	asm("\tdb 0x68\n");
	asm("\tdb 0xE0");
}
