# Instructions

This part of the repository contains the Unity assets of the actual emulator.

**CRT** is the Custom Render Texture used by the emulator as RAM. It is set up in a very particular way. Do not modify!

"ReadableMemoryCRT" is the contents of the CRT converted into a image. Usefull for reading CPU memory bytes in a surface shader.

The folder **PutTheseOnChestBone** contains two prefabs that constitute the input layer for the emulator. Without it, the emulator cannot be started or controlled.

**MemoryMonitor** simply displays the contents of the emulator's memory. Apply to a Quad to use as a debug view.

**TTY** is the stdout of the emulator. All text printed by the program appears here. Apply to a Quad anywhere on the avatar/world.

**Animator** contains the animator parameters and layers that you need to put on your avatar's FX controller and Avatar parameters in order to control the emulator. `CPUKey` is int, `CPUControl` is Boolean. Neither should be saved.

There is also a VRC Expressions menu simply called **1802**, which you can directly link as a sub-menu in your Avatar's expressions menu after adding the two required parameters. It contains all the menu items for starting/stopping/reseting the emulator, as well as another sub-menu containing a keypad for sending inputs to the emulator.
