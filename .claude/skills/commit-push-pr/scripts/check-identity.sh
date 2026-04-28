#!/usr/bin/env bash
set -euo pipefail

# Verify gh is authenticated as rbrtbn-agent (not rbrtbn the human) via the
# AGENT_GH_TOKEN exposed by .envrc. Run before pushing or opening PRs.

DIR="$(cd "$(dirname "$0")" && pwd)"
EXPECTED="rbrtbn-agent"

if ! ACTUAL="$("$DIR/as-agent" gh api user -q .login 2>/dev/null)"; then
  echo "ERROR: failed to query gh as agent." >&2
  echo "Likely causes: .envrc not loaded ('direnv allow'), AGENT_GH_TOKEN missing/wrong." >&2
  exit 1
fi

if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  echo "ERROR: gh identity is '$ACTUAL', expected '$EXPECTED'." >&2
  exit 1
fi

echo "ok: gh identity is $ACTUAL"
