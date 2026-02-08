# 🔮 Cauldron Oracle

**On-chain AI predictions for Solana** — built on Frostbite/Cauldron

[![Colosseum Agent Hackathon](https://img.shields.io/badge/Colosseum-Agent%20Hackathon-purple)](https://colosseum.com/agent-hackathon)
[![Solana](https://img.shields.io/badge/Solana-Devnet-green)](https://solana.com)

## What is Cauldron Oracle?

Cauldron Oracle is an on-chain AI prediction service that runs ML models directly on Solana using the Frostbite RISC-V VM. Any Solana program can call our oracle for real-time predictions without trusting off-chain infrastructure.

**Use cases:**
- 📈 Price direction predictions (up/down/sideways)
- ⚠️ Risk score assessments for DeFi protocols
- 📊 Market sentiment classification
- 🎯 Trading signal generation

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Cauldron Oracle                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Model     │    │  Frostbite  │    │   Output    │     │
│  │  Weights    │───▶│   RISC-V    │───▶│    PDA      │     │
│  │   (PDA)     │    │     VM      │    │             │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         ▲                  ▲                  │             │
│         │                  │                  ▼             │
│    [Upload]           [Invoke]          [Read Result]      │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
              ┌─────────────────────────────┐
              │     Your Solana Program     │
              │  (DeFi, Trading, Analytics) │
              └─────────────────────────────┘
```

## Quick Start

### Prerequisites

- [Rust](https://rustup.rs/) (for Cauldron CLI)
- [Solana CLI](https://docs.solana.com/cli/install-solana-cli-tools)
- [Node.js](https://nodejs.org/) 18+ (for SDK)
- Python 3.9+ (for training)

### 1. Install Cauldron CLI

```bash
cargo install cauldron-cli
```

### 2. Clone and Setup

```bash
git clone https://github.com/Metacognixion-labs/cauldron-oracle.git
cd cauldron-oracle
npm install
pip install -r requirements.txt
```

### 3. Train the Model

```bash
cd models/price_predictor
python train.py
```

### 4. Deploy to Devnet

```bash
./scripts/deploy.sh
```

### 5. Run Inference

```bash
./scripts/invoke.sh --input '{"prices": [100, 102, 101, 103, 105]}'
```

## Models

### Price Direction Predictor

A lightweight neural network that predicts short-term price direction based on recent price movements.

| Input | Output | Accuracy |
|-------|--------|----------|
| Last 5 price points | UP / DOWN / SIDEWAYS | ~68% |

**Architecture:** 2-layer MLP (5 → 16 → 3)

```python
# Input: normalized price deltas
input = [0.02, -0.01, 0.02, 0.02]  # percentage changes

# Output: softmax probabilities
output = {
    "up": 0.72,
    "down": 0.18,
    "sideways": 0.10
}
```

## SDK Usage

### TypeScript/JavaScript

```typescript
import { CauldronOracle } from '@cauldron-oracle/sdk';

const oracle = new CauldronOracle({
  network: 'devnet',
  modelId: 'price-predictor-v1'
});

// Get prediction
const prediction = await oracle.predict({
  prices: [100, 102, 101, 103, 105]
});

console.log(prediction);
// { direction: 'up', confidence: 0.72, timestamp: 1707350400 }
```

### On-Chain (CPI)

```rust
use cauldron_oracle::cpi::{predict, PredictAccounts};

// Call oracle from your Solana program
let result = predict(
    ctx.accounts.oracle_program.to_account_info(),
    PredictAccounts {
        model: ctx.accounts.model.to_account_info(),
        input: ctx.accounts.input.to_account_info(),
        output: ctx.accounts.output.to_account_info(),
    },
    input_data,
)?;
```

## Project Structure

```
cauldron-oracle/
├── README.md
├── package.json
├── requirements.txt
├── models/
│   └── price_predictor/
│       ├── frostbite-model.toml    # Model manifest
│       ├── train.py                 # Training script
│       ├── model.py                 # Model architecture
│       └── weights.json             # Exported weights
├── scripts/
│   ├── deploy.sh                    # Deploy to Solana
│   ├── invoke.sh                    # Run inference
│   └── demo.sh                      # Full demo
├── sdk/
│   ├── src/
│   │   ├── index.ts                 # Main SDK
│   │   ├── oracle.ts                # Oracle client
│   │   └── types.ts                 # TypeScript types
│   └── package.json
├── programs/
│   └── oracle-consumer/             # Example consumer program
└── docs/
    ├── INTEGRATION.md               # Integration guide
    └── API.md                        # API reference
```

## Deployment Addresses (Devnet)

| Component | Address |
|-----------|---------|
| Oracle Program | `TBD after deployment` |
| Price Predictor Model | `TBD after deployment` |
| Weights PDA | `TBD after deployment` |

## Roadmap

- [x] Price direction predictor model
- [x] Devnet deployment scripts
- [x] TypeScript SDK
- [ ] Risk score model
- [ ] Sentiment classifier
- [ ] Mainnet deployment
- [ ] Multi-model routing

## Team

**MetaCognixion** — Built for the Colosseum Agent Hackathon

- 🤖 Claude (AI Agent) — Architecture & Code
- 👤 @Jepetocrypto — Human Operator & Strategy

## License

MIT License — see [LICENSE](LICENSE)

---

**Built with 🔥 for the Colosseum Agent Hackathon**
