arch=x86_64
kernel=build/kernel-$(arch).bin
iso=build/exos-$(arch).iso

lscript=linker.ld
grub=boot/arch/$(arch)/grub.cfg

gc=$(arch)-elf-gcc
cflags=-ffreestanding -mcmodel=kernel -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -g

# /boot/
_bootsrc=mbheader.asm boot.asm lmstart.asm
bootsrc=$(patsubst %,boot/arch/$(arch)/%,$(_bootsrc))
_bootobj=mbheader.o boot.o lmstart.o
bootobj=$(patsubst %,build/boot/arch/$(arch)/%,$(_bootobj))

# /kernel/
_kernelsrc=kernel.c
kernelsrc=$(patsubst %,kernel/arch/$(arch)/%,$(_kernelsrc))
_kernelobj=kernel.o
kernelobj=$(patsubst %,build/kernel/arch/$(arch)/%,$(_kernelobj))

.PHONY: all clean iso

all: $(kernel)

iso: $(iso)

$(iso): $(kernel) $(grub)
	mkdir -p build/isofiles/boot/grub
	cp $(kernel) build/isofiles/boot/kernel.bin
	cp $(grub) build/isofiles/boot/grub
	grub-mkrescue -o $(iso) build/isofiles
	rm -r build/isofiles

# run linker
$(kernel): $(bootobj) $(kernelobj) $(lscript)
	ld -n -T $(lscript) -o $(kernel) $(bootobj) $(kernelobj)

# /boot/
build/boot/arch/$(arch)/%.o: boot/arch/$(arch)/%.asm
	mkdir -p $(shell dirname $@)
	nasm -felf64 $< -o $@

# /kernel/
build/kernel/arch/$(arch)/%.o: kernel/arch/$(arch)/%.c
	mkdir -p $(shell dirname $@)
	$(gc) $(cflags) -c $< -o $@

run:
	qemu-system-x86_64 -d int --no-reboot -s -monitor stdio -cdrom $(iso)

clean:
	rm -r build