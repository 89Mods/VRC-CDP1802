rem a
..\..\bin\lcc -target=xr18DH "-Wf-g,;" blink.c
hex2bin a.bin a.hex
java B2T a.bin
PAUSE