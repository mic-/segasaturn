sh-elf-as -o satgegga.o satgegga.s
sh-elf-ld -T minilink -relax -small -e _start --oformat binary -o satgegga.bin satgegga.o



