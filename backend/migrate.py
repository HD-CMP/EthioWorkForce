#!/usr/bin/env python
import subprocess
import sys

result = subprocess.run(
    ["alembic", "upgrade", "head"],
    cwd="/home/hnde/EthioWorkForce/backend",
    capture_output=True,
    text=True
)

print(result.stdout)
print(result.stderr, file=sys.stderr)
sys.exit(result.returncode)
