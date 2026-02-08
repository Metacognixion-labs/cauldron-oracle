#!/usr/bin/env python3
"""
Price Direction Predictor - Training Script
Trains a simple MLP to predict price direction from recent price movements.

Usage:
    python train.py [--epochs 100] [--samples 10000]
"""

import json
import argparse
import numpy as np
from pathlib import Path


class PricePredictor:
    """Simple 2-layer MLP for price direction prediction."""
    
    def __init__(self, input_size=4, hidden_size=16, output_size=3):
        self.input_size = input_size
        self.hidden_size = hidden_size
        self.output_size = output_size
        
        # Initialize weights with Xavier initialization
        self.W1 = np.random.randn(input_size, hidden_size) * np.sqrt(2.0 / input_size)
        self.b1 = np.zeros(hidden_size)
        self.W2 = np.random.randn(hidden_size, output_size) * np.sqrt(2.0 / hidden_size)
        self.b2 = np.zeros(output_size)
    
    def relu(self, x):
        return np.maximum(0, x)
    
    def relu_derivative(self, x):
        return (x > 0).astype(float)
    
    def softmax(self, x):
        exp_x = np.exp(x - np.max(x, axis=-1, keepdims=True))
        return exp_x / np.sum(exp_x, axis=-1, keepdims=True)
    
    def forward(self, x):
        """Forward pass."""
        self.z1 = np.dot(x, self.W1) + self.b1
        self.a1 = self.relu(self.z1)
        self.z2 = np.dot(self.a1, self.W2) + self.b2
        self.a2 = self.softmax(self.z2)
        return self.a2
    
    def backward(self, x, y, learning_rate=0.01):
        """Backward pass with gradient descent."""
        m = x.shape[0]
        
        # Output layer gradients
        dz2 = self.a2 - y
        dW2 = np.dot(self.a1.T, dz2) / m
        db2 = np.sum(dz2, axis=0) / m
        
        # Hidden layer gradients
        da1 = np.dot(dz2, self.W2.T)
        dz1 = da1 * self.relu_derivative(self.z1)
        dW1 = np.dot(x.T, dz1) / m
        db1 = np.sum(dz1, axis=0) / m
        
        # Update weights
        self.W2 -= learning_rate * dW2
        self.b2 -= learning_rate * db2
        self.W1 -= learning_rate * dW1
        self.b1 -= learning_rate * db1
    
    def compute_loss(self, y_pred, y_true):
        """Cross-entropy loss."""
        epsilon = 1e-15
        y_pred = np.clip(y_pred, epsilon, 1 - epsilon)
        return -np.mean(np.sum(y_true * np.log(y_pred), axis=1))
    
    def accuracy(self, y_pred, y_true):
        """Classification accuracy."""
        pred_labels = np.argmax(y_pred, axis=1)
        true_labels = np.argmax(y_true, axis=1)
        return np.mean(pred_labels == true_labels)
    
    def export_weights(self, filepath):
        """Export weights to JSON format for Cauldron."""
        weights = {
            "model": "price-predictor",
            "version": "1.0.0",
            "architecture": {
                "input_size": self.input_size,
                "hidden_size": self.hidden_size,
                "output_size": self.output_size,
                "activation": "relu",
                "output_activation": "softmax"
            },
            "weights": {
                "W1": self.W1.tolist(),
                "b1": self.b1.tolist(),
                "W2": self.W2.tolist(),
                "b2": self.b2.tolist()
            },
            "labels": ["UP", "DOWN", "SIDEWAYS"]
        }
        
        with open(filepath, 'w') as f:
            json.dump(weights, f, indent=2)
        
        print(f"✅ Weights exported to {filepath}")


def generate_training_data(n_samples=10000):
    """
    Generate synthetic training data.
    
    Simulates price sequences and labels them based on overall trend:
    - UP: final prices trending higher
    - DOWN: final prices trending lower  
    - SIDEWAYS: prices relatively flat
    """
    X = []
    y = []
    
    for _ in range(n_samples):
        # Generate 5 prices with some trend + noise
        trend = np.random.choice([-1, 0, 1], p=[0.3, 0.4, 0.3])
        base_price = 100
        prices = [base_price]
        
        for i in range(4):
            # Add trend component + random noise
            change = trend * np.random.uniform(0.5, 2.0) + np.random.normal(0, 1.5)
            prices.append(prices[-1] + change)
        
        # Calculate percentage changes (deltas)
        deltas = [(prices[i+1] - prices[i]) / prices[i] * 100 for i in range(4)]
        
        # Normalize to [-1, 1] range (assuming max 5% move)
        deltas = [min(max(d / 5.0, -1), 1) for d in deltas]
        
        # Label based on overall movement
        total_change = (prices[-1] - prices[0]) / prices[0] * 100
        
        if total_change > 1.5:
            label = [1, 0, 0]  # UP
        elif total_change < -1.5:
            label = [0, 1, 0]  # DOWN
        else:
            label = [0, 0, 1]  # SIDEWAYS
        
        X.append(deltas)
        y.append(label)
    
    return np.array(X), np.array(y)


def train(epochs=100, n_samples=10000, learning_rate=0.01):
    """Train the price predictor model."""
    
    print("🔮 Cauldron Oracle - Price Predictor Training")
    print("=" * 50)
    
    # Generate data
    print(f"\n📊 Generating {n_samples} training samples...")
    X, y = generate_training_data(n_samples)
    
    # Split into train/test
    split = int(0.8 * len(X))
    X_train, X_test = X[:split], X[split:]
    y_train, y_test = y[:split], y[split:]
    
    print(f"   Training samples: {len(X_train)}")
    print(f"   Test samples: {len(X_test)}")
    
    # Class distribution
    train_labels = np.argmax(y_train, axis=1)
    print(f"\n📈 Class distribution:")
    print(f"   UP: {np.sum(train_labels == 0)} ({np.mean(train_labels == 0)*100:.1f}%)")
    print(f"   DOWN: {np.sum(train_labels == 1)} ({np.mean(train_labels == 1)*100:.1f}%)")
    print(f"   SIDEWAYS: {np.sum(train_labels == 2)} ({np.mean(train_labels == 2)*100:.1f}%)")
    
    # Initialize model
    model = PricePredictor(input_size=4, hidden_size=16, output_size=3)
    
    print(f"\n🏋️ Training for {epochs} epochs...")
    print("-" * 50)
    
    for epoch in range(epochs):
        # Shuffle training data
        indices = np.random.permutation(len(X_train))
        X_shuffled = X_train[indices]
        y_shuffled = y_train[indices]
        
        # Forward pass
        y_pred = model.forward(X_shuffled)
        
        # Compute metrics
        loss = model.compute_loss(y_pred, y_shuffled)
        acc = model.accuracy(y_pred, y_shuffled)
        
        # Backward pass
        model.backward(X_shuffled, y_shuffled, learning_rate)
        
        # Print progress
        if (epoch + 1) % 10 == 0:
            # Test accuracy
            test_pred = model.forward(X_test)
            test_acc = model.accuracy(test_pred, y_test)
            print(f"   Epoch {epoch+1:3d} | Loss: {loss:.4f} | Train Acc: {acc:.2%} | Test Acc: {test_acc:.2%}")
    
    # Final evaluation
    print("-" * 50)
    test_pred = model.forward(X_test)
    final_acc = model.accuracy(test_pred, y_test)
    print(f"\n✅ Final Test Accuracy: {final_acc:.2%}")
    
    # Export weights
    weights_path = Path(__file__).parent / "weights.json"
    model.export_weights(weights_path)
    
    # Print sample predictions
    print("\n🎯 Sample Predictions:")
    print("-" * 50)
    for i in range(5):
        idx = np.random.randint(len(X_test))
        pred = model.forward(X_test[idx:idx+1])[0]
        true_label = ["UP", "DOWN", "SIDEWAYS"][np.argmax(y_test[idx])]
        pred_label = ["UP", "DOWN", "SIDEWAYS"][np.argmax(pred)]
        
        print(f"   Input: {X_test[idx].round(3)}")
        print(f"   Predicted: {pred_label} ({pred.max():.2%}) | Actual: {true_label}")
        print()
    
    return model


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train Price Predictor model")
    parser.add_argument("--epochs", type=int, default=100, help="Number of training epochs")
    parser.add_argument("--samples", type=int, default=10000, help="Number of training samples")
    parser.add_argument("--lr", type=float, default=0.01, help="Learning rate")
    
    args = parser.parse_args()
    
    train(epochs=args.epochs, n_samples=args.samples, learning_rate=args.lr)
