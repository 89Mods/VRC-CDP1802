void sieve() {
	const int count = 256;
	unsigned char sieve[256];
	int i,j,k,l,m,n;
	printf("Sieve of Eratosthenes\n");
	n = 0;
	for(i = 0; i < count; i++) sieve[i] = 0;
	printf("2,");
	for(i = 0; i < count; i++) {
		if(*keypadInputPntr) {
			printf("\nAbort.\n");
			return;
		}
		if(sieve[i] == 0) {
			j = (i << 1) + 3;
			printf("%d,", j);

			//Poor man's "%d", because the real thing takes too long to compute in VRC
			/*l = (j / 100);
			if(l != 0) putc('0' + l);
			m = ((j / 10) % 10);
			if(l != 0 || m != 0) putc('0' + m);
			putc('0' + (j % 10));
			putc(',');*/
			n++;
			if(n == 12) {
				putc('\n');
				n = 0;
			}

			k = i;
			while(1) {
				if(k >= count) break;
				sieve[k] = 200;
				k += j;
			}
		}
	}
	if(n != 0) putc('\n');
}

double absd(double ar) {
	if(ar < 0.0) return 0.0 - ar;
	return ar;
}

void goldenRatio() {
	double ratio1,ratio2;
	long fiba,fibb,t;
	double epsilon;
	int fibCntr;
	fiba = 1;
	fibb = 1;
	epsilon = 1e-32;
	fibCntr = 0;
	printf("Aproximating golden ratio\n");
	while(1) {
		if(*keypadInputPntr) {
			printf("Abort.\n");
			return;
		}
		fibCntr++;
		t = fiba;
		fiba = fibb;
		fibb = fiba + t;
		ratio1 = (double)fibb / (double)fiba;
		ratio2 = (double)(fiba + fibb) / (double)fibb;
		if(absd(ratio1 - ratio2) < epsilon) break;
	}
	printf("%f\r\n", ratio1);
	printf("%d\r\n", fibCntr);
}

void pi() {
	double pi;
	long cntr;
	unsigned char cntr2,cntr3,j;
	int i;
	printf("Aproximating pi\n");
	pi = 0.0;
	cntr = 1;
	cntr2 = 0;
	cntr3 = 255;

	for(i = 0; i < 501; i++) {
		pi += 1.0 / (double)cntr;
		cntr += 2;
		pi -= 1.0 / (double)cntr;
		cntr += 2;
		cntr2++;
		if(cntr2 == 25 || i == 0) {
			cntr2 = 0;
			putc('\r');
			putc('|');
			cntr3++;
			for(j = 0; j < cntr3; j++) putc('>');
			for(j = cntr3; j < 20; j++) putc(' ');
			putc('|');
		}
		if(*keypadInputPntr) {
			printf("\nAbort.\n");
			return;
		}
	}
	putc('\n');
	pi = pi * 4.0;
	printf("%f\r\n", pi);
}
