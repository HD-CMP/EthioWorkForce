#!/bin/bash

# EthioWorkforce Web Demo Setup Script
# Run this from WSL terminal: bash setup_web_demo.sh

set -e  # Exit on error

echo "🚀 Setting up EthioWorkforce Web Demo..."
echo "=========================================="

# Step 1: Create web icons directory
echo "📁 Creating web icons directory..."
mkdir -p frontend/web/icons

# Step 2: Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
cd frontend
flutter pub get

# Step 3: Generate code (if needed)
echo "🔧 Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs || true

# Step 4: Check Flutter devices
echo "🔍 Checking available devices..."
flutter devices

echo ""
echo "✅ Web setup complete!"
echo ""
echo "To run the web demo:"
echo "  1. Start backend: cd ../backend && python run.py (in another terminal)"
echo "  2. Run Flutter web: flutter run -d chrome"
echo "  or build for production: flutter build web --release"
echo ""
