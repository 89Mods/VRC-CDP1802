float sqrt(float x) {
	float x2,y = 0;
	long i;

	if(x == 0.0f) return 0.0f;
	x2 = x * 0.5f;
	i = *(long *)&x;                    // evil floating point bit hack
	i = 0x5f3759dfL - (i >> 1);         // what the fuck?
	y = *(float *)&i;
	y *= 1.5f - (x2 * y * y);
	y *= 1.5f - (x2 * y * y);
	y *= 1.5f - (x2 * y * y);
	return 1.0f / y;
}

float cos(float x) {
	long div;
	signed char sign;
	char i;
	float result,inter,num,comp,den;
	div = (long)(x / CONST_PI);
	x = x - (div * CONST_PI);
	sign = 1;
	if(div < 0) sign = -1;
	if(sign == -1) div = -div;

	result = 1.0;
	inter = 1.0;
	num = x * x;
	for(i = 1; i <= 4; i++) {
		comp = 2.0 * i;
		den = comp * (comp - 1.0);
		inter *= num / den;
		if((i & 1) == 0) result += inter;
		else result -= inter;
	}
	return sign * result;
}

float sin(float x) {
	return cos((CONST_PI / 2.0f) + x);
}

unsigned long seed = 193850185;

unsigned long rand(void) {
	unsigned long x = seed;
	unsigned char* x_p = (unsigned char*)&x;
	x_p[0] = x_p[1];
	x_p[1] = x_p[2];
	x_p[2] = x_p[3];
	x_p[3] = 0;
	x <<= 5UL;
	seed ^= x;
	x = seed;
	x_p[3] = x_p[1];
	x_p[2] = x_p[0];
	x_p[1] = x_p[0] = 0;
	x >>= 1UL;
	seed ^= x;
	seed ^= seed << 5UL;
	return x;
}
