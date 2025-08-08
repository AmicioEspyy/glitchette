q# Glitchette OS Build System

# build config
TARGET = x86_64-unknown-none
KERNEL_NAME = glitchette-kernel
ASM_SRC = kernel/src/asm/entry.asm
RUST_SRC = kernel/src/rust/main.rs
LINKER_SCRIPT = linker.ld

# output files
RUST_LIB = target/$(TARGET)/release/libkernel.a
ASM_OBJ = build/entry.o
KERNEL_ELF = build/kernel.elf
KERNEL_BIN = build/kernel.bin

# bootloader files
STAGE1_SRC = bootloader/src/one/entry.asm
STAGE2_SRC = bootloader/src/two/boot.asm
STAGE1_BIN = build/stage1.bin
STAGE2_BIN = build/stage2.bin

# tools
NASM = nasm
RUSTC = cargo

# flags
RUST_FLAGS = --target $(TARGET) --release

all: $(STAGE1_BIN) $(STAGE2_BIN) $(KERNEL_BIN)

os: all

bootloader: $(STAGE1_BIN) $(STAGE2_BIN)

kernel: $(KERNEL_BIN)

build:
	mkdir -p build

$(RUST_LIB): $(RUST_SRC) kernel/Cargo.toml
	cd kernel && $(RUSTC) build $(RUST_FLAGS) --lib

$(ASM_OBJ): $(ASM_SRC) | build
	$(NASM) -f elf64 $(ASM_SRC) -o $(ASM_OBJ)

# link assembly + rust, then convert to binary
$(KERNEL_BIN): $(RUST_LIB) $(ASM_OBJ) $(LINKER_SCRIPT) | build
	/opt/homebrew/bin/ld.lld -T $(LINKER_SCRIPT) $(ASM_OBJ) $(RUST_LIB) -o $(KERNEL_ELF)
	/opt/homebrew/Cellar/llvm/20.1.8/bin/llvm-objcopy -O binary $(KERNEL_ELF) $(KERNEL_BIN)

$(STAGE1_BIN): $(STAGE1_SRC) | build
	$(NASM) -f bin $(STAGE1_SRC) -o $(STAGE1_BIN)

$(STAGE2_BIN): $(STAGE2_SRC) | build
	cd bootloader/src/two && $(NASM) -f bin boot.asm -o ../../../$(STAGE2_BIN)

clean:
	rm -rf build/
	cd kernel && cargo clean

install-target:
	rustup target add x86_64-unknown-none

debug: $(KERNEL_BIN)
	objdump -d $(KERNEL_BIN) > build/kernel.dis
	nm $(KERNEL_BIN) > build/kernel.sym
	readelf -a $(KERNEL_BIN) > build/kernel.elf

size: $(KERNEL_BIN)
	ls -la $(KERNEL_BIN)
	size $(KERNEL_BIN)

image: $(STAGE1_BIN) $(STAGE2_BIN) $(KERNEL_BIN)
	@echo "Creating bootable disk image..."
	dd if=/dev/zero of=build/glitchette.img bs=512 count=2880
	dd if=$(STAGE1_BIN) of=build/glitchette.img conv=notrunc
	dd if=$(STAGE2_BIN) of=build/glitchette.img bs=512 seek=1 conv=notrunc
	dd if=$(KERNEL_BIN) of=build/glitchette.img bs=512 seek=5 conv=notrunc

test: image
	qemu-system-x86_64 -drive format=raw,file=build/glitchette.img

test-debug: image
	qemu-system-x86_64 -drive format=raw,file=build/glitchette.img -s -S

help:
	@echo "Glitchette OS Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all            - Build bootloader and kernel (default)"
	@echo "  os             - Build complete OS (same as all)"
	@echo "  bootloader     - Build only the bootloader"
	@echo "  kernel         - Build only the kernel"
	@echo "  clean          - Clean build artifacts"
	@echo "  debug          - Generate debug information"
	@echo "  size           - Show kernel size information"
	@echo "  image          - Create bootable disk image"
	@echo "  test           - Test with QEMU"
	@echo "  test-debug     - Test with QEMU debugging"
	@echo "  install-target - Install Rust target (run once)"
	@echo "  help           - Show this help"

.PHONY: all os bootloader kernel clean debug size image test test-debug help install-target
