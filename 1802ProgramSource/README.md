# Instructions

The C compiler used for this project is the LCC1802 compiler, found at https://sites.google.com/site/lcc1802/the-rhinestone-compiler
Particularly, the Rhinestone compiler (Rhinestone.zip in the downloads section).

Ensure that the compiler is installed at the root of the C drive (`C:/lcc42`), then merge the contents of this directory into the compiler installation. The source code for the VRC CDP1802 demo should be at `C:/lcc42/examples/VRC` afterwards.

Next, the compiler needs to be patched to use the correct routine for putc/putchar. Edit the file `C:/lcc42/include/IO1802.inc` and remove line 4 (`_putc:`) and save.

Lastly, download the Hex2bin from https://sourceforge.net/projects/hex2bin/ . Find the `hex2bin.exe` file and place it into the source code directory (`C:\lcc42\examples\VRC`).

You can now compile the demo program by running `build.bat` in the source code  directory (`C:\lcc42\examples\VRC`). It should output a texture file at `program.png` containing the compiled bytecode. If there is no such output, ensure you have at least Java 11 installed on your system, as it is required for the binary-to-texture conversion step.

The generated texture can be moved into the Unity project to update the program run by the emulator.
