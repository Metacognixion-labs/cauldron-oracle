#!/bin/bash
# Run inference on Cauldron Oracle
# Usage: ./invoke.sh --input '{"prices": [100, 102, 101, 103, 105]}'

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MODEL_DIR="$PROJECT_DIR/models/price_predictor"

# Default input
INPUT='{"prices": [100, 102, 101, 103, 105]}'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --input)
            INPUT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: ./invoke.sh [--input JSON]"
            echo ""
            echo "Options:"
            echo "  --input    JSON object with prices array (5 values)"
            echo ""
            echo "Example:"
            echo "  ./invoke.sh --input '{\"prices\": [100, 102, 101, 103, 105]}'"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🔮 Cauldron Oracle - Inference"
echo "==============================="
echo ""
echo "📥 Input: $INPUT"
echo ""

# Preprocess input (convert prices to deltas)
PROCESSED_INPUT=$(python3 -c "
import json
import sys

data = json.loads('$INPUT')
prices = data['prices']

if len(prices) != 5:
    print('Error: Expected 5 prices', file=sys.stderr)
    sys.exit(1)

# Calculate normalized deltas
deltas = []
for i in range(4):
    delta = (prices[i+1] - prices[i]) / prices[i] * 100
    normalized = max(min(delta / 5.0, 1), -1)
    deltas.append(round(normalized, 4))

print(json.dumps({'input': deltas}))
")

echo "📊 Processed input (deltas): $PROCESSED_INPUT"
echo ""

# Check if Cauldron is available
if command -v cauldron &> /dev/null; then
    cd "$MODEL_DIR"
    
    # Write input
    echo "$PROCESSED_INPUT" > input.json
    cauldron input-write --manifest frostbite-model.toml \
        --accounts frostbite-accounts.toml --data input.json
    
    # Invoke
    echo "⚡ Running on-chain inference..."
    cauldron invoke --accounts frostbite-accounts.toml --mode fresh --fast
    
    # Read output
    OUTPUT=$(cauldron output --manifest frostbite-model.toml \
        --accounts frostbite-accounts.toml)
    
    echo ""
    echo "📤 Raw output: $OUTPUT"
else
    # Fallback: run locally with Python
    echo "ℹ️  Cauldron CLI not found. Running local inference..."
    echo ""
    
    OUTPUT=$(python3 -c "
import json
import numpy as np

# Load weights
with open('$MODEL_DIR/weights.json', 'r') as f:
    weights = json.load(f)

# Extract weights
W1 = np.array(weights['weights']['W1'])
b1 = np.array(weights['weights']['b1'])
W2 = np.array(weights['weights']['W2'])
b2 = np.array(weights['weights']['b2'])

# Get input
data = json.loads('$PROCESSED_INPUT')
x = np.array(data['input'])

# Forward pass
z1 = np.dot(x, W1) + b1
a1 = np.maximum(0, z1)  # ReLU
z2 = np.dot(a1, W2) + b2
exp_z = np.exp(z2 - np.max(z2))
probs = exp_z / np.sum(exp_z)  # Softmax

# Get prediction
labels = ['UP', 'DOWN', 'SIDEWAYS']
pred_idx = np.argmax(probs)

result = {
    'prediction': labels[pred_idx],
    'confidence': round(float(probs[pred_idx]), 4),
    'probabilities': {
        'up': round(float(probs[0]), 4),
        'down': round(float(probs[1]), 4),
        'sideways': round(float(probs[2]), 4)
    }
}

print(json.dumps(result, indent=2))
")
    
    echo "$OUTPUT"
fi

echo ""
echo "==============================="
echo "✅ Inference complete!"
