#!/bin/bash
set -euo pipefail

echo "=== [07] Emulation Dev Toolchain ==="

echo "Installing build dependencies..."
sudo apt install -y \
    build-essential \
    cmake \
    libreadline-dev \
    libncurses-dev \
    pkg-config

# Build d2r-trainer — Linux memory trainer for D2R
if [ -d "$HOME/d2r-trainer" ]; then
    echo "d2r-trainer already cloned, updating..."
    git -C "$HOME/d2r-trainer" pull
else
    echo "Cloning d2r-trainer..."
    git clone https://github.com/axiom0x0/d2r-trainer.git "$HOME/d2r-trainer"
fi

echo "Building d2r-trainer..."
mkdir -p "$HOME/d2r-trainer/build"
cmake -S "$HOME/d2r-trainer" -B "$HOME/d2r-trainer/build"
make -C "$HOME/d2r-trainer/build"

TRAINER="$HOME/d2r-trainer/build/d2r-trainer"
TRAINER_TUI="$HOME/d2r-trainer/build/d2r-trainer-tui"

echo ""
echo "Built: $TRAINER"
echo "Built: $TRAINER_TUI"
echo ""
echo "Set up memory access (pick one):"
echo ""
echo "  [A] Grant CAP_SYS_PTRACE (no root needed at runtime):"
echo "      sudo setcap cap_sys_ptrace=eip $TRAINER"
echo "      sudo setcap cap_sys_ptrace=eip $TRAINER_TUI"
echo ""
echo "  [B] Use sudo at runtime:"
echo "      sudo $TRAINER"
echo ""
echo "Usage (while D2R is in-game with a character):"
echo "  cd $HOME/d2r-trainer/build && sudo ./d2r-trainer"
echo ""
echo "=== [07] Complete ==="
