#define TERM_W 64
#define TERM_H 50

unsigned char terminal[TERM_W * TERM_H][2];
unsigned char currRow = 0;
unsigned char currCol = 0;
unsigned char currTextColor = 63;
unsigned char* curserLocPntr = (unsigned char *)65532;

void shiftLinesUp() {
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
	terminal[currRow * TERM_W + currCol][0] = c;
	terminal[currRow * TERM_W + currCol][1] = currTextColor;
	currCol++;
	if(currCol == 65) {
		putc('\n');
		putc(c);
	}
	*curserLocPntr = currRow;
	*(curserLocPntr + 1) = currCol;
}

void terminalInit() {
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
}

void setCursorCol(char col) {
	currCol = col;
}

void setTextColor(char color) {
	currTextColor = color;
}

void delay(int amount) {
	int i;
	for(i = 0; i < amount; i++) {
		asm("\tnop");
	}
}
