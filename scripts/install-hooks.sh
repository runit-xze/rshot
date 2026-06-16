#!/bin/bash

HOOK_DIR=$(git rev-parse --git-path hooks)
cp scripts/pre-commit $HOOK_DIR/pre-commit
chmod +x $HOOK_DIR/pre-commit

echo "Pre-commit hook installed successfully in $HOOK_DIR/pre-commit"
