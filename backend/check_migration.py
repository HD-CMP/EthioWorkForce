#!/usr/bin/env python3
"""Check Alembic migration status"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from alembic.config import Config
from alembic import command
from alembic.script import ScriptDirectory

# Load Alembic config
alembic_cfg = Config("alembic.ini")

# Get script directory
script = ScriptDirectory.from_config(alembic_cfg)

# Show current head
print("Available heads:")
for head in script.get_heads():
    print(f"  - {head}")

# Show all revisions
print("\nAll revisions:")
for rev in script.walk_revisions():
    print(f"  {rev.revision}: {rev.doc}")

print("\n" + "="*50)
print("To check current database version, run:")
print("  alembic current")
print("\nTo see pending migrations, run:")
print("  alembic history")
print("\nTo apply migrations, run:")
print("  alembic upgrade head")
