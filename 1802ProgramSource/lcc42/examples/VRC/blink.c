#undef nofloats
#include "nstdlib.h"
#include "vrcio.h"
#include "math.h"
#include "benchmarks.h"

unsigned char* btnPntr = (unsigned char *)65531;
unsigned char* btnInputPntr = (unsigned char *)65530;

void calc(void);
void emissions(void);

void main(){
	unsigned int t;
	unsigned char flag;
	char flag2 = 0;
	int test;
	*btnPntr = 0;
	terminalInit();
	setQoff();

	setTextColor(24);
	printf("VRChat CDP1802 Emulator - v0.2-A\n");
	setTextColor(63);
	printf("Press any key to continue\n");
	t = 0;
	entry_loop:
	while(!(*keypadInputPntr)) {
		yield();
		yield();
		yield();
		yield();
		t++;
		if(t == 511) break;
	}
	if(t == 511) emissions();
	if(*keypadInputPntr < 8) goto entry_loop;
	while(*keypadInputPntr) yield();

	/*while(1) {
		while(!(*keypadInputPntr)) yield();
		yield();
		yield();
		yield();
		yield();
		flag = *keypadInputPntr;
		flag += 1;
		flag /= 8;
		while(*keypadInputPntr) yield();
		yield();
		printf("%c\n", '0' + flag);
	}*/

main_loop:
	printf("\n~~ Program selection ~~\n1) Benchmarks\n2) Light Demo\n3) Calculator\n4) Emissions controller\n");
	flag = 0;
	while(1) {
		yield();
		yield();
		flag2 = getKey();
		//printf("%c\n", '0' + flag2);
		if(flag2 == 1) {
			printf("Running benchmarks - Hold any key to cancel\n");
			goldenRatio();
			if(*keypadInputPntr) goto main_loop;
			putc('\n');
			pi();
			if(*keypadInputPntr) goto main_loop;
			putc('\n');
			sieve();
			if(*keypadInputPntr) goto main_loop;
			putc('\n');
			goto main_loop;
		}else if(flag2 == 2) {
			printf("Press any key to toggle light, ENTER to exit");
			flag2 = flag = 0;
			while(1){
				flag2 = getKey();
				if(flag2 == 0) continue;
				if(flag2 == KEY_ENTER) break;
				flag = !flag;
				if(flag) setQon();
				else setQoff();
				*btnPntr = flag;
			}
			printf("\n                                            \n");
		}else if(flag2 == 3) {
			calc();
		}else if(flag2 == 4) {
			emissions();
		}
	}
}

#define fixed_mul(x, y) ((unsigned int)(x) * (unsigned int)(y))

void emissions(void) {
	const unsigned char advance = 16;
	unsigned char rng1,rng2;
	unsigned char x = 0;
	unsigned char prev_x = 0;
	unsigned int y;
	unsigned char* y_p;
	setTextColor(23);
	printf("Emissions controller begin\n");
	setTextColor(63);

	y_p = (unsigned char*)&y;

	rng1 = rand();
	rng2 = rand();

	while(1) {
		y = fixed_mul(rng2, x) + fixed_mul(rng1, 255 - x);
		*btnPntr = (unsigned char)(y_p[0]);
		x += advance;
		if(x < prev_x) {
			rng1 = rng2;
			rng2 = rand();
		}
		prev_x = x;
	}
}

float getNumInput(void) {
	float res;
	char select;
	char flag2 = 0;
	char digits[5];
	char i;
	char j = 0;
	memset(digits, 0, 5);
	while(1) {
		select = getKey();
		if(select == KEY_ENTER) {
			if(flag2) {
				printf("\r  %s", digits);
			}else {
				printf("\rM %s", digits);
			}
			flag2 = !flag2;
			continue;
		}else {
			if(select == 0 && flag2) {
				if(j != 0) break;
				else continue;
			}
			if(j < 5) {
				if(flag2) {
					digits[j] = '5' + select;
				}else digits[j] = '0' + select;
				j++;
				if(flag2) printf("\rM %s", digits);
				else printf("\r  %s", digits);
			}
		}
	}
	setTextColor(12);
	printf("\r%s  \n", digits);
	setTextColor(63);

	res = 0;
	for(i = 0; i < 5; i++) {
		if(digits[i] == 0) break;
		if(i != 0) res *= 10.0f;
		res += digits[i] - '0';
	}
	return res;
}

void calc(void) {
	char origRow;
	char select;
	char flag = 0;
	char flag2;
	char i;
	float arg1,arg2,res;
	origRow = getCursorRow();
selection:
	printf("Select operation:\n1) Add \n2) Sub \n3) Mul \n4) Div \n5) Funcs\n");
	select = 0;
	while(select == 0 || select == 10) select = getKey();
	if(select == 5) {
		flag = 1;
		setCursorRow(origRow + 1);
		printf("1) Pow\n2) Sqrt\n3) Sin\n4) Cos\n5) Back \n");
		select = 0;
		while(select == 0 || select == 10) select = getKey();
		if(select == 5) {
			flag = 0;
			goto selection;
		}
	}

	for(i = 0; i < 5; i++) {
		setCursorRow(getCursorRow() - 1);
		setCursorCol(0);
		printf("        ");
	}
	setCursorRow(getCursorRow() - 1);
	setCursorCol(0);
	printf("                 ");
	setCursorCol(0);
	if(select == 0) {
		setTextColor(48);
		printf("Abort\r");
		setTextColor(63);
		for(i = 0; i < 90; i++) yield();
		printf("     \n");
		return;
	}

	flag2 = 0;
	if(flag == 1 && select >= 2) {
		flag2 = 1;
		printf(select == 2 ? "sqrt\n" : (select == 3 ? "sin\n" : "cos\n"));
		printf("Enter input\n");
		arg1 = getNumInput();
		printf("Working...");
		if(select == 2) {
			res = sqrt(arg1);
		}else if(select == 3) {
			res = sin(arg1);
		}else if(select == 4) {
			res = cos(arg1);
		}
		printf("\rResult:   \n");
		setTextColor(12);
		printf("%f\n", res);
		setTextColor(63);
	}else if(flag == 1 && select == 1) {
		flag2 = 1;

	}else if(flag == 0) {
		flag2 = 0;
		printf(select == 1 ? "add\n" : (select == 2 ? "sub\n" : (select == 3 ? "mul\n" : "div\n")));
		printf("Enter input 1\n");
		arg1 = getNumInput();
		printf("Enter input 2\n");
		arg2 = getNumInput();
		printf("Working...");
		if(select == 1) {
			res = arg1 + arg2;
		}else if(select == 2) {
			res = arg1 - arg2;
		}else if(select == 3) {
			res = arg1 * arg2;
		}else if(select == 4) {
			res = arg1 / arg2;
		}
		printf("\rResult:   \n");
		setTextColor(12);
		printf("%f\n", res);
		setTextColor(63);
	}

	printf("Press ENTER to exit");
	while(1) {
		select = getKey();
		if(select == KEY_ENTER) break;
	}
	setCursorRow(origRow);
	setCursorCol(0);
	i = 0;
	while(1) {
		printf("                     \n");
		i++;
		if(flag2 && i == 6) break;
		if(!flag2 && i == 8) break;
	}
	setCursorRow(origRow);
	setCursorCol(0);
}

#include "vrcio.c"
#include "math.c"
#include "benchmarks.c"
#include "nstdlib.c"
