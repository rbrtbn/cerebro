#!/usr/bin/env bash
set -euo pipefail

# Verify gh is authenticated as rbrtbn-agent (not rbrtbn the human).
# Run from inside a session started via `bin/claude-agent` — that launcher
# is what puts the agent's GH_TOKEN into the environment. From any other
# shell this will see your personal gh auth and (correctly) fail.

EXPECTED="rbrtbn-agent"

if ! ACTUAL="$(gh api user -q .login 2>/dev/null)"; then
  echo "ERROR: gh failed. Are you in a session started by bin/claude-agent?" >&2
  exit 1
fi

if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  echo "ERROR: gh identity is '$ACTUAL', expected '$EXPECTED'." >&2
  echo "If this shell wasn't launched via bin/claude-agent, exit and relaunch." >&2
  exit 1
fi

echo "ok: gh identity is $ACTUAL"
