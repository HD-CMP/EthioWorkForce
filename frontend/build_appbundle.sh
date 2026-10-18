#!/bin/bash

echo "🏪 Building EthioWorkforce App Bundle for Play Store..."
echo ""

if [ ! -f "android/key.properties" ]; then
    echo "⚠️  WARNING: android/key.properties not found!"
    echo ""
    echo "To sign the app bundle, create android/key.properties with:"
    echo "  storePassword=your_store_password"
    echo "  keyPassword=your_key_password"
    echo "  keyAlias=ethioworkforce"
    echo "  storeFile=/path/to/ethioworkforce-key.jks"
    echo ""
    echo "Continuing with unsigned build..."
    echo ""
fi

echo "📦 Cleaning previous builds..."
flutter clean

echo "📥 Getting dependencies..."
flutter pub get

echo "🏗️ Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "🔧 Building release App Bundle..."
flutter build appbundle --release

echo ""
echo "✅ Build complete!"
echo ""
echo "📦 App Bundle location:"
echo "   build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "📤 Upload to Google Play Console!"
