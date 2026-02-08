#!/bin/bash
# Cauldron Oracle - Full Demo
# Demonstrates the complete workflow from training to inference

set -e

echo "🔮 Cauldron Oracle - Full Demo"
echo "==============================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Step 1: Train the model
echo "📚 Step 1: Training the model..."
echo "---------------------------------"
cd "$PROJECT_DIR/models/price_predictor"
python3 train.py --epochs 50 --samples 5000
echo ""

# Step 2: Run sample predictions
echo "🎯 Step 2: Running sample predictions..."
echo "---------------------------------"
echo ""

# Bullish scenario
echo "📈 Bullish scenario (prices trending up):"
"$SCRIPT_DIR/invoke.sh" --input '{"prices": [100, 101, 103, 105, 108]}'
echo ""

# Bearish scenario
echo "📉 Bearish scenario (prices trending down):"
"$SCRIPT_DIR/invoke.sh" --input '{"prices": [100, 98, 96, 94, 91]}'
echo ""

# Sideways scenario
echo "↔️  Sideways scenario (prices flat):"
"$SCRIPT_DIR/invoke.sh" --input '{"prices": [100, 101, 99, 100, 101]}'
echo ""

# Step 3: Show deployment info
echo "🚀 Step 3: Deployment Information"
echo "---------------------------------"
echo ""
echo "To deploy to Solana devnet:"
echo "  1. Install Cauldron CLI: cargo install cauldron-cli"
echo "  2. Configure Solana CLI for devnet: solana config set --url devnet"
echo "  3. Run: ./scripts/deploy.sh"
echo ""
echo "To use the SDK:"
echo "  npm install @cauldron-oracle/sdk"
echo ""
echo "Example:"
echo "  import { CauldronOracle } from '@cauldron-oracle/sdk';"
echo "  const oracle = new CauldronOracle({ network: 'devnet' });"
echo "  const prediction = await oracle.predict({ prices: [100, 102, 101, 103, 105] });"
echo ""

echo "==============================="
echo "✅ Demo complete!"
echo ""
echo "🏆 Built for Colosseum Agent Hackathon by MetaCognixion"
