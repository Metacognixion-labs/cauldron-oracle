/**
 * Cauldron Oracle SDK
 * TypeScript/JavaScript client for on-chain AI predictions
 */

import { Connection, PublicKey } from '@solana/web3.js';

export interface OracleConfig {
  network: 'devnet' | 'mainnet';
  modelId?: string;
  rpcUrl?: string;
}

export interface PredictionInput {
  prices: number[];
}

export interface PredictionResult {
  direction: 'UP' | 'DOWN' | 'SIDEWAYS';
  confidence: number;
  probabilities: {
    up: number;
    down: number;
    sideways: number;
  };
  timestamp: number;
  txSignature?: string;
}

export interface ModelInfo {
  id: string;
  name: string;
  version: string;
  description: string;
  inputSize: number;
  outputSize: number;
  address: string;
}

// Default RPC endpoints
const RPC_ENDPOINTS = {
  devnet: 'https://api.devnet.solana.com',
  mainnet: 'https://api.mainnet-beta.solana.com',
};

// Model addresses (to be updated after deployment)
const MODEL_ADDRESSES = {
  'price-predictor-v1': {
    devnet: 'TBD',
    mainnet: 'TBD',
  },
};

/**
 * Cauldron Oracle Client
 * Provides easy access to on-chain AI predictions
 */
export class CauldronOracle {
  private connection: Connection;
  private network: 'devnet' | 'mainnet';
  private modelId: string;

  constructor(config: OracleConfig) {
    this.network = config.network;
    this.modelId = config.modelId || 'price-predictor-v1';
    
    const rpcUrl = config.rpcUrl || RPC_ENDPOINTS[this.network];
    this.connection = new Connection(rpcUrl, 'confirmed');
  }

  /**
   * Get prediction from the on-chain model
   */
  async predict(input: PredictionInput): Promise<PredictionResult> {
    // Validate input
    if (!input.prices || input.prices.length !== 5) {
      throw new Error('Input must contain exactly 5 price values');
    }

    // Calculate normalized deltas
    const deltas = this.preprocessInput(input.prices);

    // For now, run local inference (on-chain integration TBD)
    const result = await this.runLocalInference(deltas);

    return {
      ...result,
      timestamp: Math.floor(Date.now() / 1000),
    };
  }

  /**
   * Preprocess price data into normalized deltas
   */
  private preprocessInput(prices: number[]): number[] {
    const deltas: number[] = [];
    
    for (let i = 0; i < 4; i++) {
      const delta = ((prices[i + 1] - prices[i]) / prices[i]) * 100;
      const normalized = Math.max(Math.min(delta / 5.0, 1), -1);
      deltas.push(normalized);
    }
    
    return deltas;
  }

  /**
   * Run inference locally (fallback when on-chain not available)
   */
  private async runLocalInference(
    deltas: number[]
  ): Promise<Omit<PredictionResult, 'timestamp'>> {
    // Embedded model weights (from training)
    const weights = await this.loadWeights();
    
    // Forward pass
    const { W1, b1, W2, b2 } = weights;
    
    // Hidden layer: ReLU(x * W1 + b1)
    const hidden = new Array(W1[0].length).fill(0);
    for (let j = 0; j < hidden.length; j++) {
      let sum = b1[j];
      for (let i = 0; i < deltas.length; i++) {
        sum += deltas[i] * W1[i][j];
      }
      hidden[j] = Math.max(0, sum); // ReLU
    }
    
    // Output layer: Softmax(hidden * W2 + b2)
    const output = new Array(W2[0].length).fill(0);
    let maxOutput = -Infinity;
    
    for (let j = 0; j < output.length; j++) {
      let sum = b2[j];
      for (let i = 0; i < hidden.length; i++) {
        sum += hidden[i] * W2[i][j];
      }
      output[j] = sum;
      maxOutput = Math.max(maxOutput, sum);
    }
    
    // Softmax
    let sumExp = 0;
    for (let i = 0; i < output.length; i++) {
      output[i] = Math.exp(output[i] - maxOutput);
      sumExp += output[i];
    }
    for (let i = 0; i < output.length; i++) {
      output[i] /= sumExp;
    }
    
    // Get prediction
    const labels: Array<'UP' | 'DOWN' | 'SIDEWAYS'> = ['UP', 'DOWN', 'SIDEWAYS'];
    let maxIdx = 0;
    for (let i = 1; i < output.length; i++) {
      if (output[i] > output[maxIdx]) maxIdx = i;
    }
    
    return {
      direction: labels[maxIdx],
      confidence: output[maxIdx],
      probabilities: {
        up: output[0],
        down: output[1],
        sideways: output[2],
      },
    };
  }

  /**
   * Load model weights (embedded or from network)
   */
  private async loadWeights(): Promise<{
    W1: number[][];
    b1: number[];
    W2: number[][];
    b2: number[];
  }> {
    // In production, these would be fetched from the on-chain account
    // For now, using placeholder that would be replaced with actual weights
    
    // Placeholder weights - replace with actual trained weights
    return {
      W1: Array(4).fill(null).map(() => Array(16).fill(0.1)),
      b1: Array(16).fill(0),
      W2: Array(16).fill(null).map(() => Array(3).fill(0.1)),
      b2: Array(3).fill(0),
    };
  }

  /**
   * Get model information
   */
  async getModelInfo(): Promise<ModelInfo> {
    return {
      id: this.modelId,
      name: 'Price Direction Predictor',
      version: '1.0.0',
      description: 'Predicts short-term price direction from recent price movements',
      inputSize: 4,
      outputSize: 3,
      address: MODEL_ADDRESSES[this.modelId as keyof typeof MODEL_ADDRESSES]?.[this.network] || 'TBD',
    };
  }

  /**
   * Check if the oracle is available
   */
  async isAvailable(): Promise<boolean> {
    try {
      const slot = await this.connection.getSlot();
      return slot > 0;
    } catch {
      return false;
    }
  }
}

// Export default instance for quick usage
export const createOracle = (config: OracleConfig) => new CauldronOracle(config);

// Re-export types
export type { Connection, PublicKey };
