#!/usr/bin/env bash
# Install the groundwork skills into Kiro (from skills/kiro).
#
# Usage:
#   ./install.kiro.sh                       # global: symlink into ~/.kiro/skills
#   ./install.kiro.sh --project <dir>       # one project: symlink into <dir>/.kiro/skills
#   ./install.kiro.sh --copy [...]          # copy instead of symlink (no auto-update on git pull)
#   ./install.kiro.sh --uninstall [...]     # remove the groundwork skills from the target
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills/kiro"
TARGET="${HOME}/.kiro/skills"
MODE="link"
ACTION="install"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      [[ $# -ge 2 ]] || { echo "error: --project needs a directory" >&2; exit 1; }
      [[ -d "$2" ]] || { echo "error: '$2' is not a directory" >&2; exit 1; }
      TARGET="$(cd "$2" && pwd)/.kiro/skills"
      shift 2 ;;
    --copy) MODE="copy"; shift ;;
    --uninstall) ACTION="uninstall"; shift ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "error: unknown option '$1'" >&2; exit 1 ;;
  esac
done

mkdir -p "$TARGET"

for skill_path in "$SRC_DIR"/*/; do
  name="$(basename "$skill_path")"
  dest="$TARGET/$name"

  if [[ "$ACTION" == "uninstall" ]]; then
    if [[ -e "$dest" || -L "$dest" ]]; then
      rm -rf -- "$dest"
      echo "removed  $dest"
    fi
    continue
  fi

  # Never silently clobber a real folder that isn't ours.
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    if ! grep -q '^  kit: groundwork$' "$dest/SKILL.md" 2>/dev/null; then
      echo "skip     $dest (exists and is not a groundwork skill)" >&2
      continue
    fi
  fi
  rm -rf -- "$dest"

  if [[ "$MODE" == "link" ]]; then
    ln -s "${skill_path%/}" "$dest"
    echo "linked   $dest -> ${skill_path%/}"
  else
    cp -R "${skill_path%/}" "$dest"
    echo "copied   $dest"
  fi
done

[[ "$ACTION" == "install" ]] && echo "Done. Start a new Kiro chat session to pick up the skills."
