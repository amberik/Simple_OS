How debug new image in gdb:

1. Start qemu VM whith falg "-S -s" and attach the disk image to boot from.
    ~> qemu-system-i386 -fda ./Devel/AMBER/devel/tests/OS/simple_os/disk.img -s -S -vnc none
2. Open gdb (cgdb)
3. type following command:
    ~> target remote localhost:1234
    ~> break *0x7c00       - break point on the very begining of the boot sector.
    ~> continue            - jump on bt
    ~> x/10i $cs*16+$eip   - see disassembler code 
    ~> set arch i8086      - see disassempler in real mode
    ~> set arch i386       - see disassempler in protected mode
    ~> set disassembly-flavor intel
