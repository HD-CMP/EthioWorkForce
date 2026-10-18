#!/bin/bash

RES_DIR="/home/hnde/EthioWorkForce/frontend/android/app/src/main/res"

# Create simple PNG icons using ImageMagick
create_icon() {
    size=$1
    dir=$2
    convert -size ${size}x${size} xc:#2196F3 \
            -gravity center \
            -fill white \
            -pointsize $((size/3)) \
            -annotate +0+0 "EW" \
            "${RES_DIR}/${dir}/ic_launcher.png"
}

# Check if ImageMagick is installed
if command -v convert &> /dev/null; then
    create_icon 48 mipmap-mdpi
    create_icon 72 mipmap-hdpi
    create_icon 96 mipmap-xhdpi
    create_icon 144 mipmap-xxhdpi
    create_icon 192 mipmap-xxxhdpi
    echo "Icons created successfully"
else
    # Fallback: create base64-encoded minimal PNG
    echo "ImageMagick not found, creating minimal placeholder icons..."
    
    # Base64 of a minimal valid 48x48 blue PNG
    ICON_BASE64="iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAOxAAADsQBlSsOGwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAABqSURBVGiB7dSxDQAgDATB5v9/BkoKBAp+Qm5m2sqSWGMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/rMDxwEcB3AcwHEAxwEcB3AcwHEAxwGcDQCgRAS8HiN2UAAAAABJRU5ErkJggg=="
    
    for dir in mipmap-mdpi mipmap-hdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi; do
        echo "$ICON_BASE64" | base64 -d > "${RES_DIR}/${dir}/ic_launcher.png"
    done
    echo "Placeholder icons created"
fi
