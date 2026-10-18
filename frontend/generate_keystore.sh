#!/bin/bash

echo "🔐 Generating Android Release Keystore..."
echo ""

KEYSTORE_PATH="$HOME/ethioworkforce-key.jks"
KEY_ALIAS="ethioworkforce"

echo "This will generate a keystore for signing Android releases."
echo ""
echo "You will be asked to provide:"
echo "  - Keystore password (remember this!)"
echo "  - Key password (can be same as keystore password)"
echo "  - Your name/organization details"
echo ""
read -p "Press Enter to continue..."

keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias "$KEY_ALIAS"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore generated successfully!"
    echo ""
    echo "📄 Keystore location: $KEYSTORE_PATH"
    echo ""
    echo "⚠️  IMPORTANT: Keep this file and passwords safe!"
    echo "   - Back up this keystore file securely"
    echo "   - Never share it publicly"
    echo "   - If you lose it, you cannot update your app on Play Store"
    echo ""
    echo "📝 Now create android/key.properties with:"
    echo ""
    echo "storePassword=YOUR_KEYSTORE_PASSWORD"
    echo "keyPassword=YOUR_KEY_PASSWORD"
    echo "keyAlias=$KEY_ALIAS"
    echo "storeFile=$KEYSTORE_PATH"
    echo ""
else
    echo ""
    echo "❌ Failed to generate keystore"
fi
