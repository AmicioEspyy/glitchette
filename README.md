# glitchette

A custom x86-64 operating system built from scratch. Currently implements a two-stage bootloader and basic kernel with VGA text mode support.

## Architecture

**Boot Process:**
- Stage 1: 512-byte boot sector (16-bit real mode) loads Stage 2 from disk
- Stage 2: Full bootloader handles A20 line, GDT setup, and 32-bit protected mode transition
- Kernel: 64-bit kernel entry point with Rust core

**Memory Layout:**
- `0x7C00`: Stage 1 bootloader load address  
- `0x1000`: Stage 2 bootloader load address
- `0x10000`: Kernel load address (signature at +0, entry at +4)
- VGA text buffer at `0xB8000`

## Current Implementation

### Bootloader (`bootloader/`)

**Stage 1 (`one/entry.asm`):**
- Basic 16-bit boot sector
- Loads 4 sectors of Stage 2 from disk
- Verifies Stage 2 signature (0x5347 "GS")

**Stage 2 (`two/`):**
- **`boot.asm`**: Main coordinator, loads kernel from disk
- **`a20.asm`**: A20 line enablement (keyboard controller + fast gate methods)  
- **`gdt.asm`**: Global Descriptor Table setup for protected mode
- **`pmode.asm`**: 32-bit protected mode functions, VGA text output, kernel jumping
- **`disk.asm`**: LBA disk I/O operations
- **`cpu.asm`**: CPU feature detection and long mode setup
- **`services.asm`**: BIOS interrupt wrappers
- **`constants.inc`**: Memory addresses, segment selectors, character codes

### Kernel (`kernel/`)

**Assembly Entry (`src/asm/entry.asm`):**
- Kernel signature and version header
- 64-bit entry point setup
- Calls into Rust kernel

**Rust Core (`src/rust/`):**
- **`main.rs`**: Main kernel entry point with panic handler
- **`drivers/vga.rs`**: VGA text mode driver (80x25, 16 colors)

### Build System

- **`Makefile`**: Multi-stage build with NASM + Cargo + LLD linker
- **`build.sh`**: Automated build script creating bootable disk image
- **`run.sh`**: QEMU runner with console/debug modes
- **`linker.ld`**: Custom linker script for kernel memory layout
- **`x86_64-glitchette.json`**: Custom Rust target specification

## Technical Details

**Toolchain:**
- NASM for assembly compilation
- Rust nightly with custom target
- LLD linker for final kernel binary
- QEMU for testing/emulation

**Disk Layout:**
- Sector 0: Stage 1 bootloader (512 bytes)
- Sectors 1-4: Stage 2 bootloader  
- Sectors 6+: Kernel binary

**Current Capabilities:**
- Real mode → Protected mode → Long mode transitions
- A20 line management
- Basic disk I/O (LBA addressing)
- VGA text mode output with scrolling
- Kernel signature verification
- Basic memory management setup

## Building

```bash
./build.sh          # build everything + create disk image
make kernel         # build just kernel  
make bootloader     # build just bootloader
make clean          # clean build artifacts
```

## Running

```bash
./run.sh                    # GUI mode
./run.sh --console          # console mode
./run.sh --debug            # debug mode (GDB on port 1234)
```

## File Structure

```
bootloader/src/one/         # stage 1 bootloader
bootloader/src/two/         # stage 2 bootloader components  
kernel/src/asm/             # kernel assembly entry
kernel/src/rust/            # rust kernel code
build/                      # build outputs
target/                     # rust build cache
```

That's it. If you want to contribute, make a PR.

---
Built with ❤️ in my spare time :)