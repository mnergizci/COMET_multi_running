#!/bin/bash
## === COMET Multi Running Environment Setup ===
## Auto-detect repo root based on this script’s location

export COMET_MULTI_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add bin/ to PATH
export PATH="$COMET_MULTI_HOME/bin:$PATH"

echo "COMET_multi_running environment loaded."
