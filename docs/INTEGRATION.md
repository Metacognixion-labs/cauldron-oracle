# Integration Guide

This guide explains how to integrate Cauldron Oracle into your Solana application.

## Overview

Cauldron Oracle provides on-chain AI predictions that any Solana program can consume. The oracle runs ML models directly on the Frostbite RISC-V VM, ensuring predictions are verifiable and trustless.

## Quick Start

### Using the TypeScript SDK

```bash
npm install @cauldron-oracle/sdk @solana/web3.js
```

```typescript
import { CauldronOracle } from '@cauldron-oracle/sdk';

// Initialize the oracle client
const oracle = new CauldronOracle({
  network: 'devnet',
  modelId: 'price-predictor-v1'
});

// Get a prediction
const prediction = await oracle.predict({
  prices: [100, 102, 101, 103, 105]
});

console.log(prediction);
// {
//   direction: 'UP',
//   confidence: 0.72,
//   probabilities: { up: 0.72, down: 0.18, sideways: 0.10 },
//   timestamp: 1707350400
// }
```

### Direct API Usage

For environments where the SDK isn't available, you can interact with the oracle directly.

#### 1. Prepare Input Data

Convert your price data into normalized deltas:

```javascript
function preprocessPrices(prices) {
  const deltas = [];
  for (let i = 0; i < 4; i++) {
    const delta = ((prices[i + 1] - prices[i]) / prices[i]) * 100;
    const normalized = Math.max(Math.min(delta / 5.0, 1), -1);
    deltas.push(normalized);
  }
  return deltas;
}

const prices = [100, 102, 101, 103, 105];
const input = preprocessPrices(prices);
// input: [0.02, -0.0098, 0.0198, 0.0194]
```

#### 2. Read Oracle Output

```typescript
import { Connection, PublicKey } from '@solana/web3.js';

const connection = new Connection('https://api.devnet.solana.com');
const outputPDA = new PublicKey('OUTPUT_PDA_ADDRESS');

const accountInfo = await connection.getAccountInfo(outputPDA);
const output = parseOracleOutput(accountInfo.data);
```

## On-Chain Integration (Rust/Anchor)

For Solana programs that need to call the oracle via CPI:

### Account Structure

```rust
#[derive(Accounts)]
pub struct CallOracle<'info> {
    /// The oracle model account
    #[account(mut)]
    pub oracle_model: AccountInfo<'info>,
    
    /// Input data account (write your input here)
    #[account(mut)]
    pub oracle_input: AccountInfo<'info>,
    
    /// Output data account (read predictions here)
    pub oracle_output: AccountInfo<'info>,
    
    /// Frostbite VM program
    pub frostbite_program: AccountInfo<'info>,
}
```

### CPI Call

```rust
use anchor_lang::prelude::*;

pub fn get_prediction(ctx: Context<CallOracle>, input_data: Vec<f32>) -> Result<()> {
    // Serialize input
    let input_bytes = serialize_input(&input_data);
    
    // Write input to oracle input account
    let input_account = &ctx.accounts.oracle_input;
    input_account.try_borrow_mut_data()?[..input_bytes.len()]
        .copy_from_slice(&input_bytes);
    
    // Invoke Frostbite VM
    let cpi_accounts = frostbite::cpi::accounts::Invoke {
        vm: ctx.accounts.oracle_model.to_account_info(),
        // ... other accounts
    };
    
    frostbite::cpi::invoke(
        CpiContext::new(ctx.accounts.frostbite_program.to_account_info(), cpi_accounts),
        InvokeMode::Fresh,
    )?;
    
    // Read output
    let output_account = &ctx.accounts.oracle_output;
    let output_data = output_account.try_borrow_data()?;
    let prediction = parse_prediction(&output_data);
    
    msg!("Prediction: {:?}", prediction);
    
    Ok(())
}
```

## Input Format

The price predictor model expects:

| Field | Type | Description |
|-------|------|-------------|
| `prices` | `number[]` | Array of exactly 5 price values |

The SDK handles preprocessing automatically. For direct integration, convert to normalized deltas in the range [-1, 1].

## Output Format

| Field | Type | Description |
|-------|------|-------------|
| `direction` | `string` | One of: `UP`, `DOWN`, `SIDEWAYS` |
| `confidence` | `number` | Probability of predicted direction (0-1) |
| `probabilities.up` | `number` | Probability of UP direction |
| `probabilities.down` | `number` | Probability of DOWN direction |
| `probabilities.sideways` | `number` | Probability of SIDEWAYS direction |

## Use Cases

### DeFi Protocol Integration

```typescript
// Example: Automated position adjustment based on predictions
async function adjustPosition(currentPrices: number[]) {
  const prediction = await oracle.predict({ prices: currentPrices });
  
  if (prediction.direction === 'UP' && prediction.confidence > 0.7) {
    // Increase long exposure
    await increaseLongPosition();
  } else if (prediction.direction === 'DOWN' && prediction.confidence > 0.7) {
    // Reduce exposure or hedge
    await reduceExposure();
  }
}
```

### Risk Management

```typescript
// Example: Risk score calculation
async function calculateRiskScore(priceHistory: number[]) {
  const predictions = [];
  
  // Get predictions for multiple timeframes
  for (let i = 0; i < priceHistory.length - 4; i += 5) {
    const window = priceHistory.slice(i, i + 5);
    const pred = await oracle.predict({ prices: window });
    predictions.push(pred);
  }
  
  // Calculate volatility from prediction uncertainty
  const avgConfidence = predictions.reduce((a, b) => a + b.confidence, 0) / predictions.length;
  const riskScore = 1 - avgConfidence;
  
  return riskScore;
}
```

## Error Handling

```typescript
try {
  const prediction = await oracle.predict({ prices: [100, 102, 101, 103, 105] });
} catch (error) {
  if (error.message.includes('Input must contain exactly 5 price values')) {
    // Handle invalid input
  } else if (error.message.includes('Network error')) {
    // Handle connectivity issues
  }
}
```

## Best Practices

1. **Cache predictions** - The on-chain model has a cost per invocation. Cache results when appropriate.

2. **Validate inputs** - Always validate your price data before calling the oracle.

3. **Handle uncertainty** - Don't treat low-confidence predictions as definitive signals.

4. **Monitor performance** - Track prediction accuracy over time and adjust your strategy accordingly.

## Support

- GitHub Issues: [https://github.com/Metacognixion-labs/cauldron-oracle/issues](https://github.com/Metacognixion-labs/cauldron-oracle/issues)
- Documentation: [https://github.com/Metacognixion-labs/cauldron-oracle](https://github.com/Metacognixion-labs/cauldron-oracle)
