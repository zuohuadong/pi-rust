#!/usr/bin/env bash
set -euo pipefail

# Keep host and extension versions explicit. This script is intentionally
# credential-free; model and MCP secrets remain in the caller environment.
rpi_bin="${RPI_BIN:-rpi}"

"$rpi_bin" install rpi-mcp-adapter --version 0.2.4
"$rpi_bin" install rpi-subagents --version 0.1.9
"$rpi_bin" install rpi-plan-mode --version 0.1.6
"$rpi_bin" install rpi-permission-gate --version 0.1.2
"$rpi_bin" install rpi-permissions --version 0.1.9
"$rpi_bin" install rpi-todo --version 0.2.4

printf '%s\n' 'Installed the pinned Claude/Codex harness profile.'
printf '%s\n' 'Enable interactive approvals with: rpi --permission-gate'
