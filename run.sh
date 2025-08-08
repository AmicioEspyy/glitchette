#!/bin/bash

set -e

# defaults
DISK_IMAGE="build/glitchette.img"
CONSOLE_MODE=false
DEBUG_MODE=false
DRY_RUN=false
MEMORY="512M"
CPU_COUNT="1"

show_help() {
    echo "Glitchette OS QEMU Runner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --console      Run in console mode (no GUI, use -nographic)"
    echo "  --debug        Run with debugging support (-s -S)"
    echo "  --memory SIZE  Set memory size (default: 512M)"
    echo "  --cpus COUNT   Set CPU count (default: 1)"
    echo "  --image PATH   Use custom disk image (default: build/glitchette.img)"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Normal GUI mode"
    echo "  $0 --console          # Console mode"
    echo "  $0 --debug            # Debug mode with GDB support"
    echo "  $0 --console --debug  # Console + debug mode"
    echo ""
}

# parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --console)
            CONSOLE_MODE=true
            shift
            ;;
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --cpus)
            CPU_COUNT="$2"
            shift 2
            ;;
        --image)
            DISK_IMAGE="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# check if image exists
if [ ! -f "$DISK_IMAGE" ]; then
    echo "Error: Disk image '$DISK_IMAGE' not found!"
    echo "Please build the OS first with: make image"
    exit 1
fi

# build qemu command
QEMU_CMD="qemu-system-x86_64"
QEMU_ARGS=()

QEMU_ARGS+=("-drive" "file=$DISK_IMAGE,format=raw,if=floppy")
QEMU_ARGS+=("-m" "$MEMORY")
QEMU_ARGS+=("-smp" "$CPU_COUNT")

if [ "$CONSOLE_MODE" = true ]; then
    QEMU_ARGS+=("-nographic")
    echo "Running in console mode (use Ctrl+A, X to quit)"
fi

if [ "$DEBUG_MODE" = true ]; then
    QEMU_ARGS+=("-s" "-S")
    echo "Debug mode enabled - QEMU will wait for GDB connection on port 1234"
    echo "In another terminal, run: gdb -ex 'target remote localhost:1234'"
fi

echo "Starting Glitchette OS..."
echo "Disk image: $DISK_IMAGE"
echo "Memory: $MEMORY"
echo "CPUs: $CPU_COUNT"
if [ "$CONSOLE_MODE" = true ]; then
    echo "Mode: Console"
else
    echo "Mode: GUI"
fi
if [ "$DEBUG_MODE" = true ]; then
    echo "Debug: Enabled"
fi
echo ""

echo "Command: $QEMU_CMD ${QEMU_ARGS[*]}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "Dry run mode - command would be executed above"
    exit 0
fi

exec "$QEMU_CMD" "${QEMU_ARGS[@]}"
