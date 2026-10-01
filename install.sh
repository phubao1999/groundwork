#!/usr/bin/env bash
# Install the groundwork plugin into Claude Code (from skills/claude).
#
# Usage:
#   ./install.sh                 # register this repo's marketplace and install the plugin
#   ./install.sh --uninstall     # remove the plugin and the marketplace
#
# This is a thin wrapper around the `claude plugin` CLI. It registers the local
# skills/claude directory as a plugin marketplace, then installs the plugin from it.
# You can also do this by hand inside Claude Code with the /plugin commands.
set -euo pipefail

MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills/claude"
MARKETPLACE="groundwork"   # name field in skills/claude/.claude-plugin/marketplace.json
PLUGIN="groundwork"        # plugin name in plugins/groundwork/.claude-plugin/plugin.json
ACTION="install"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall) ACTION="uninstall"; shift ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "error: unknown option '$1'" >&2; exit 1 ;;
  esac
done

if ! command -v claude >/dev/null 2>&1; then
  echo "error: the 'claude' CLI was not found on PATH." >&2
  echo "Install Claude Code, or register the marketplace from inside it instead:" >&2
  echo "  /plugin marketplace add $MARKETPLACE_DIR" >&2
  echo "  /plugin install $PLUGIN@$MARKETPLACE" >&2
  exit 1
fi

if [[ ! -f "$MARKETPLACE_DIR/.claude-plugin/marketplace.json" ]]; then
  echo "error: no marketplace.json under $MARKETPLACE_DIR/.claude-plugin" >&2
  exit 1
fi

if [[ "$ACTION" == "uninstall" ]]; then
  claude plugin uninstall "$PLUGIN@$MARKETPLACE" || true
  claude plugin marketplace remove "$MARKETPLACE" || true
  echo "Removed the $PLUGIN plugin and the $MARKETPLACE marketplace."
  exit 0
fi

# Validate before registering so JSON/field problems surface with a clear message.
claude plugin validate "$MARKETPLACE_DIR"
claude plugin marketplace add "$MARKETPLACE_DIR"
claude plugin install "$PLUGIN@$MARKETPLACE"
echo "Done. The $PLUGIN plugin is installed in Claude Code."
echo "Edits to skills/claude take effect on the next session or after /reload-plugins."
