#!/bin/bash

set -e

echo "Building Glitchette OS..."

mkdir -p build

echo "Building bootloader..."

echo "  Building stage 1..."
cd bootloader/src/one
nasm -f bin entry.asm -o ../../../build/stage1.bin
cd ../../..

echo "  Building stage 2..."
cd bootloader/src/two
nasm -f bin boot.asm -o ../../../build/stage2.bin
cd ../../..

echo "Building kernel..."
make kernel LD=rust-lld

echo "Creating bootable disk image..."
dd if=/dev/zero of=build/glitchette.img bs=512 count=2880 2>/dev/null
dd if=build/stage1.bin of=build/glitchette.img conv=notrunc 2>/dev/null
dd if=build/stage2.bin of=build/glitchette.img bs=512 seek=1 conv=notrunc 2>/dev/null
dd if=build/kernel.bin of=build/glitchette.img bs=512 seek=6 conv=notrunc 2>/dev/null

echo "Build complete!"
echo "Stage 1 size: $(ls -lh build/stage1.bin | awk '{print $5}')"
echo "Stage 2 size: $(ls -lh build/stage2.bin | awk '{print $5}')"
echo "Kernel size: $(ls -lh build/kernel.bin | awk '{print $5}')"
echo "Disk image: build/glitchette.img"
