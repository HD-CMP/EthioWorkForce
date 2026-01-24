import base64
import os

# Minimal valid 48x48 blue PNG (base64)
ICON_DATA = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAOxAAADsQBlSsOGwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAABqSURBVGiB7dSxDQAgDATB5v9/BkoKBAp+Qm5m2sqSWGMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/rMDxwEcB3AcwHEAxwEcB3AcwHEAxwGcDQCgRAS8HiN2UAAAAABJRU5ErkJggg=="

res_dir = "/home/hnde/EthioWorkForce/frontend/android/app/src/main/res"
mipmap_dirs = ["mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi"]

icon_bytes = base64.b64decode(ICON_DATA)

for mipmap_dir in mipmap_dirs:
    icon_path = os.path.join(res_dir, mipmap_dir, "ic_launcher.png")
    with open(icon_path, "wb") as f:
        f.write(icon_bytes)
    print(f"Created: {icon_path}")

print("All launcher icons created successfully!")
