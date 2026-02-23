#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

chmod +x .githooks/pre-commit .githooks/commit-msg
git config core.hooksPath .githooks

echo "Git hooks enabled."
echo "hooksPath: $(git config --get core.hooksPath)"
