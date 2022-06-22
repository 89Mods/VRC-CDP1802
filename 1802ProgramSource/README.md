# Instructions

The C compiler used for this project is the LCC1802 compiler, found at https://sites.google.com/site/lcc1802/the-rhinestone-compiler
Particularly, the Rhinestone compiler (Rhinestone.zip in the downloads section).

Ensure that the compiler is installed at the root of the C drive (`C:/lcc42`), then merge the contents of this directory into the compiler installation. The source code for the VRC CDP1802 demo should be at `C:/lcc42/examples/VRC` afterwards.

Next, the compiler needs to be patched to use the correct routine for putc/putchar. Edit the file `C:/lcc42/include/IO1802.inc` and remove line 4 (`_putc:`) and save.
Lastly, printf will be broken unless you also edit `C:/lcc42/include/nstdlib.c`, go to line 41 and replace the line `while(*ptr) out(5,*ptr++);` with `while(*ptr) putc(*ptr++);`.

Then, download the Hex2bin from https://sourceforge.net/projects/hex2bin/ . Find the `hex2bin.exe` file and place it into the source code directory (`C:\lcc42\examples\VRC`).

You can now compile the demo program by running `build.bat` in the source code  directory (`C:\lcc42\examples\VRC`). It should output a texture file at `program.png` containing the compiled bytecode. If there is no such output, ensure you have at least Java 11 installed on your system, as it is required for the binary-to-texture conversion step.

The generated texture can be moved into the Unity project to update the program run by the emulator.

# Notes on programming the emulator

- The emulator is very, *very* slow. Use every optimization you possibly can. Large memory operations like clearing the screen or functions like `memcpy` and `memset` are particularly expensive.
- You are programming in **the original ANSI C**, also known as C89. It is quite different then modern C, and might take some time getting used to.
- Datatype sizes are different then regular C. `int` is 16-bit, `long` is 32-bit. There is no 64-bit integer support. Both `float` and `double` are 32-bit.
- Avoid floating-point numbers. The time it takes for the benchmarks included in the demo to run shoud be enough to explain why.
- Avoid multiplications and divisions! The CPU emulated here contains no dedicated instructions for these, so has to do both in software, which takes time. (Hint: use bit-shifts for multiplications and divisions by powers of 2)
