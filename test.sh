set -e

BUILD=build
DISK_IMG=disk.img
DISK_SIZE=1M
STAGE2_SECTORS=16
KERNEL_LBA=17    # 1 (MBR) + 16 settori stage2

# === Prep ===
mkdir -p $BUILD

echo "[1] Compilo stage1 (boot.asm)"
nasm -f bin bootloader/boot.asm -o $BUILD/boot.bin

echo "[2] Compilo kernel (C + start.asm)"
gcc -m32 -ffreestanding -fno-pic -fno-stack-protector -nostdlib -nostartfiles \
    -O2 -Wall -Wextra -c kernel/kernel.c -o $BUILD/kernel.o
nasm -f elf32 kernel/start.asm -o $BUILD/start.o
ld -m elf_i386 -nostdlib -T kernel/linker.ld -o $BUILD/kernel.elf $BUILD/start.o $BUILD/kernel.o
objcopy -O binary $BUILD/kernel.elf $BUILD/kernel.bin

echo "[3] Calcolo settori kernel"
KSECT=$(( ( $(stat -c%s $BUILD/kernel.bin) + 511 ) / 512 ))
echo " -> Kernel = $KSECT settori (512B)"

echo "[4] Compilo stage2 (loader.asm)"
nasm -f bin -D KERNEL_LBA=$KERNEL_LBA -D KERNEL_SECTORS=$KSECT bootloader/loader.asm -o $BUILD/loader.bin

echo "[5] Creo immagine disco da $DISK_SIZE"
truncate -s $DISK_SIZE $DISK_IMG
dd if=$BUILD/boot.bin   of=$DISK_IMG bs=512 seek=0  conv=notrunc status=none
dd if=$BUILD/loader.bin of=$DISK_IMG bs=512 seek=1  conv=notrunc status=none
dd if=$BUILD/kernel.bin of=$DISK_IMG bs=512 seek=$KERNEL_LBA conv=notrunc status=none

echo "[6] Avvio con QEMU"
qemu-system-i386 -drive format=raw,file=$DISK_IMG -no-reboot -d int -monitor none -serial stdio
