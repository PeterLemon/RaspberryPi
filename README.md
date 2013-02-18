RaspberryPi
===========

Raspberry Pi Bare Metal Code by Peter Lemon.

All code compiles out of box with the FASMARM assembler by revolution.
I have included binaries of all the demos...

Special thanks to Dex (Craig Bamford), who helped me get my 1st pixel on the screen =D
Please check out his Raspberry Pi port of DexOS, a lightning fast bare metal OS!!

Howto Compile:
All the code compiles into a single binary (kernel.img) file.
Using FASMARM open up kernel.asm and click the Run/Compile button.

Howto Run:
I only test with the latest bleeding edge firmware:
https://github.com/raspberrypi/firmware/tree/master/boot

You will need these 2 files:
bootcode.bin
start.elf

You will need to create a "cmdline.txt" file that contains the line:
coherent_pool=2M cma=2M smsc95xx.turbo_mode=Y

You will need to create a "config.txt" file that contains the lines:
disable_overscan=1 
force_turbo=1
gpu_mem_256=160
gpu_mem_512=316
cma_lwm=16
cma_hwm=32

Checkout http://elinux.org/RPiconfig for more info about config options...

Once you have all these files ready, you can copy them & a kernel.img file to the root of an SD card.

All of my demos use a maximum resolution of 640x480, they have been tested using composite & HDMI.

All sound demos output to the analog headphone port...
