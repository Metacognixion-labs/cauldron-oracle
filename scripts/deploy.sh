#!/bin/bash
# Deploy Cauldron Oracle to Solana Devnet
# Usage: ./deploy.sh

set -e

echo "🔮 Cauldron Oracle - Deployment Script"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MODEL_DIR="$PROJECT_DIR/models/price_predictor"

# Check for required files
if [ ! -f "$MODEL_DIR/frostbite-model.toml" ]; then
    echo "❌ Error: frostbite-model.toml not found"
    exit 1
fi

if [ ! -f "$MODEL_DIR/weights.json" ]; then
    echo "❌ Error: weights.json not found. Run 'python train.py' first."
    exit 1
fi

echo ""
echo "📁 Model directory: $MODEL_DIR"
echo ""

# Step 1: Convert weights to binary format
echo "1️⃣  Converting weights to binary format..."
cd "$MODEL_DIR"

if command -v cauldron &> /dev/null; then
    cauldron convert --manifest frostbite-model.toml --input weights.json --pack
    echo "   ✅ Weights converted to weights.bin"
else
    echo "   ⚠️  Cauldron CLI not found. Skipping conversion."
    echo "   Install with: cargo install cauldron-cli"
fi

# Step 2: Build the guest program
echo ""
echo "2️⃣  Building Frostbite guest program..."
if command -v cauldron &> /dev/null; then
    cauldron build-guest --manifest frostbite-model.toml
    echo "   ✅ Guest program built"
else
    echo "   ⚠️  Skipping guest build (Cauldron CLI not found)"
fi

# Step 3: Initialize deterministic accounts
echo ""
echo "3️⃣  Initializing Solana accounts..."
if command -v cauldron &> /dev/null; then
    cauldron accounts init --manifest frostbite-model.toml --ram-count 2
    cauldron accounts create --accounts frostbite-accounts.toml
    echo "   ✅ Accounts initialized"
else
    echo "   ⚠️  Skipping account initialization"
fi

# Step 4: Upload weights
echo ""
echo "4️⃣  Uploading weights to Solana..."
if command -v cauldron &> /dev/null && [ -f "weights.bin" ]; then
    cauldron upload --file weights.bin --accounts frostbite-accounts.toml
    echo "   ✅ Weights uploaded"
else
    echo "   ⚠️  Skipping weight upload"
fi

# Step 5: Load the program
echo ""
echo "5️⃣  Loading program to Frostbite VM..."
if command -v cauldron &> /dev/null && [ -d "guest/target" ]; then
    cauldron program load --accounts frostbite-accounts.toml \
        guest/target/riscv64imac-unknown-none-elf/release/frostbite-guest
    echo "   ✅ Program loaded"
else
    echo "   ⚠️  Skipping program load"
fi

echo ""
echo "========================================"
echo "🎉 Deployment complete!"
echo ""
echo "Next steps:"
echo "  1. Run inference: ./scripts/invoke.sh --input '{\"prices\": [100, 102, 101, 103, 105]}'"
echo "  2. Check the demo: ./scripts/demo.sh"
echo ""
