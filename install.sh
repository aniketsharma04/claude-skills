#!/usr/bin/env bash
# Installs the skill packs in this repo into Claude Code, all at once or one by one.
#
#   ./install.sh                                  # everything
#   ./install.sh --only replica-skill,instagram-agent
#   ./install.sh --method link                    # link the submodule clones instead of using the plugin system
#   ./install.sh --list
#
# Without cloning:
#   curl -fsSL https://raw.githubusercontent.com/aniketsharma04/claude-skills/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/aniketsharma04/claude-skills/main/install.sh | bash -s -- --only replica-skill
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
MARKETPLACE=claude-skills
# GitHub repo that hosts the marketplace; used when this script runs without a clone (curl ... | bash).
REPO=aniketsharma04/claude-skills
if [ -f "$ROOT/.claude-plugin/marketplace.json" ]; then IS_CLONE=1; SOURCE="$ROOT"; else IS_CLONE=0; SOURCE="$REPO"; fi
METHOD=plugin
ONLY=""

ALL="marketing-skills instagram-agent linkedin-skills replica-skill superpowers remotion rea graphify"

# name -> submodule path (used by --method link)
pack_path() {
  case "$1" in
    marketing-skills) echo marketing/marketingskills ;;
    instagram-agent)  echo instagram/instagram-agent-skill ;;
    linkedin-skills)  echo linkedin/linkedin-skills ;;
    replica-skill)    echo replica-skill/replica-skill ;;
    superpowers)      echo superpowers/superpowers ;;
    rea)              echo reverse-engineer/rea ;;
    graphify)         echo graphify/graphify ;;
    remotion)         echo "" ;;
    *) return 1 ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --only) ONLY="$2"; shift 2 ;;
    --method) METHOD="$2"; shift 2 ;;
    --list) for p in $ALL; do echo "  $p"; done; exit 0 ;;
    -h|--help) [ -f "$0" ] && sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

SELECTED="${ONLY//,/ }"
[ -z "$SELECTED" ] && SELECTED="$ALL"
for p in $SELECTED; do
  pack_path "$p" >/dev/null || { echo "Unknown pack '$p'. Run ./install.sh --list" >&2; exit 1; }
done

need() { command -v "$1" >/dev/null || { echo "'$1' not found. $2" >&2; exit 1; }; }
has() { case " $SELECTED " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
# Packs installed by their own CLI instead of the marketplace or a symlink.
is_cli_pack() { case "$1" in rea|graphify) return 0 ;; *) return 1 ;; esac; }

SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
FAILED=""
# Some packs have paths past Windows' 260-char limit (Git Bash); allow long paths for git calls made here.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.longpaths GIT_CONFIG_VALUE_0=true

if [ "$METHOD" = plugin ]; then
  need claude "Install Claude Code first: https://claude.com/claude-code"
  PLUGIN_PACKS=""
  for p in $SELECTED; do is_cli_pack "$p" || PLUGIN_PACKS="$PLUGIN_PACKS $p"; done
  if [ -n "$PLUGIN_PACKS" ]; then
    echo "==> adding marketplace '$MARKETPLACE' from $SOURCE"
    claude plugin marketplace add "$SOURCE" || claude plugin marketplace update "$MARKETPLACE"
    for p in $PLUGIN_PACKS; do
      echo "==> $p"
      claude plugin install "$p@$MARKETPLACE" || FAILED="$FAILED $p"
    done
  fi
elif [ "$METHOD" = link ]; then
  need git "Install Git from https://git-scm.com"
  [ "$IS_CLONE" = 1 ] || { echo "--method link needs a clone: git clone https://github.com/$REPO.git" >&2; exit 1; }
  mkdir -p "$SKILLS_DIR"
  for p in $SELECTED; do
    is_cli_pack "$p" && continue
    path="$(pack_path "$p")"
    if [ -z "$path" ]; then echo "==> $p has no submodule; install it with --method plugin"; continue; fi
    # Its plugin.json points skills at the repo root, which loads none when linked; the marketplace entry lists them.
    if [ "$p" = replica-skill ]; then echo "==> $p loads no skills as a link; install it with --method plugin"; continue; fi
    echo "==> $p"
    git -C "$ROOT" submodule update --init "$path"
    link="$SKILLS_DIR/$(basename "$path")"
    if [ -e "$link" ]; then echo "    already present: $link"; continue; fi
    ln -s "$ROOT/$path" "$link"
    echo "    linked $link -> $ROOT/$path"
  done
else
  echo "--method must be plugin or link" >&2; exit 1
fi

if has rea; then
  need npm "Install Node.js 22.19 or newer from https://nodejs.org"
  echo "==> rea: npm install -g rea-agents"
  npm install -g rea-agents
  rea setup --client claude_code --yes
  echo "    rea: decompiling native binaries needs Ghidra, APKs need JADX. See reverse-engineer/SETUP.md."
fi
if has graphify; then
  PY="$(command -v python3 || command -v python)" || { echo "'python' not found. Install Python 3.10 or newer from https://www.python.org" >&2; exit 1; }
  if command -v uv >/dev/null; then UV=uv; else
    echo "==> graphify: pip install --user uv"
    "$PY" -m pip install --user --quiet uv
    UV="$PY -m uv"
  fi
  echo "==> graphify: uv tool install graphifyy"
  $UV tool install graphifyy
  export PATH="$HOME/.local/bin:$PATH"
  graphify install || FAILED="$FAILED graphify"
  echo "    graphify: run 'uv tool update-shell' once so the graphify command is on PATH. See graphify/SETUP.md."
fi
if has linkedin-skills; then
  echo "    linkedin-skills: publishing needs Python deps and a .env. See its README (pip install -r requirements.txt, copy .env.example)."
fi
if [ -n "$FAILED" ]; then
  failed_csv="$(echo $FAILED | tr ' ' ',')"
  echo "Failed:$FAILED. Fix the error above and re-run with --only $failed_csv" >&2
  exit 1
fi
echo "Done. Restart Claude Code to load the new skills."
