#!/bin/bash

# SmolLM2-360M Model Download Script
# This script downloads the quantized SmolLM2-360M model for use with fllama

MODEL_DIR="assets/models"
MODEL_NAME="SmolLM2-360M-Instruct-Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/bartowski/SmolLM2-360M-Instruct-GGUF/resolve/main/SmolLM2-360M-Instruct-Q4_K_M.gguf"

echo "SmolLM2-360M Model Downloader"
echo "=============================="
echo ""

# Create models directory if it doesn't exist
mkdir -p "$MODEL_DIR"

# Check if model already exists
if [ -f "$MODEL_DIR/$MODEL_NAME" ]; then
    echo "Model already exists at $MODEL_DIR/$MODEL_NAME"
    echo "To re-download, delete the existing file first."
    exit 0
fi

echo "Downloading SmolLM2-360M-Instruct (Q4_K_M quantization)..."
echo "File size: ~271MB"
echo ""

# Download the model
curl -L -o "$MODEL_DIR/$MODEL_NAME" "$MODEL_URL" --progress-bar

# Check if download was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "Download complete!"
    echo "Model saved to: $MODEL_DIR/$MODEL_NAME"
    echo ""
    echo "You can now run the Flutter app with:"
    echo "  flutter run"
else
    echo ""
    echo "Error: Download failed. Please check your internet connection and try again."
    exit 1
fi