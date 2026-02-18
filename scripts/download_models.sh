#!/bin/bash

# Define the model to download (Community converted Llama 3.2 3B 4-bit)
REPO_URL="https://huggingface.co/finnvoorhees/coreml-Llama-3.2-3B-Instruct-4bit"
MODEL_DIR="AIchatbot/Models"
TARGET_DIR="$MODEL_DIR/coreml-Llama-3.2-3B-Instruct-4bit"

# Create the directory
mkdir -p "$MODEL_DIR"

echo "Checking for git-lfs..."
if ! git lfs version &> /dev/null; then
    echo "⚠️  Git LFS is not installed. Please install it first (brew install git-lfs) and run 'git lfs install'."
    echo "This is required to download large model files."
    exit 1
fi

# Clean up previous attempts
if [ -d "$TARGET_DIR" ]; then
    echo "🗑️  Cleaning up previous partial download..."
    rm -rf "$TARGET_DIR"
fi

echo "🚀 Starting download of Llama 3.2 (3B) CoreML model..."
echo "This may take a while as the model is ~2GB."

# Navigate to the directory
cd "$MODEL_DIR"

# Clone the repository
if git clone "$REPO_URL"; then
    echo "✅ Download complete!"
    echo ""
    echo "Instructions to enable:"
    echo "1. Open Xcode."
    echo "2. Drag 'Llama-3.2-3B-Instruct-4bit.mlpackage' from 'AIchatbot/Models/coreml-Llama-3.2-3B-Instruct-4bit' into the 'AIchatbot' group in the Project Navigator."
    echo "3. Ensure 'Target Membership' is checked for 'itelo'."
    echo "4. The model class 'Llama_3_2_3B_Instruct_4bit' will be auto-generated."
    echo "5. Uncomment the LlamaService code in AIService.swift."
else
    echo "❌ Download failed. Please check your internet connection and try again."
    exit 1
fi
