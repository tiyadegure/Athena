#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Athena MCP Tools + Skills Installer
# 
# Usage:
#   curl -fsSL https://athena.degure.me/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/tiyadegure/Athena/main/install.sh | bash
#
# Options:
#   ATHENA_DIR=~/.athena    Installation directory
#   SKIP_DEPS=1             Skip Python dependency installation
#   SKIP_SYSTEM=1           Skip system tool installation (slither, aderyn, foundry)
#   SKIP_CLAUDE=1           Skip Claude Code MCP configuration
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────────────
GITHUB_REPO="https://github.com/tiyadegure/Athena.git"
ATHENA_DIR="${ATHENA_DIR:-$HOME/.athena}"
SKILL_NAME="athena-audit-skill"
SKILL_SOURCE="$ATHENA_DIR/skills/glm-audit-skill"
SKILL_DEST="$HOME/.claude/skills/$SKILL_NAME"
SERVERS_JSON="$ATHENA_DIR/mcp/servers.json"

# ── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

log()   { echo -e "${GREEN}✓${RESET} $*"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $*"; }
err()   { echo -e "${RED}✗${RESET} $*"; }
info()  { echo -e "${CYAN}ℹ${RESET} $*"; }
header(){ echo -e "\n${BOLD}$*${RESET}"; }

# ── Banner ───────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
echo "   ╔═══════════════════════════════════════╗"
echo "   ║       Athena MCP Installer            ║"
echo "   ║   Smart Contract Security Audit Tools ║"
echo "   ╚═══════════════════════════════════════╝"
echo -e "${RESET}"

# ── Check prerequisites ─────────────────────────────────────────────────────
header "Checking prerequisites..."

for cmd in git python3; do
  if command -v "$cmd" &>/dev/null; then
    log "$cmd found: $(command -v "$cmd")"
  else
    err "$cmd not found. Please install it first."
    exit 1
  fi
done

# Detect pip
if command -v pip3 &>/dev/null; then
  PIP="pip3"
elif command -v pip &>/dev/null; then
  PIP="pip"
elif python3 -m pip --version &>/dev/null 2>&1; then
  PIP="python3 -m pip"
else
  PIP=""
  warn "pip not found — Python deps will be skipped"
fi

# ── Step 1: Clone / update repo ─────────────────────────────────────────────
header "Step 1/5: Clone Athena repository"

if [ -d "$ATHENA_DIR/.git" ]; then
  info "Athena repo exists at $ATHENA_DIR, pulling latest..."
  cd "$ATHENA_DIR"
  git pull --ff-only 2>/dev/null || warn "Pull failed, using existing version"
  log "Repository updated"
else
  info "Cloning to $ATHENA_DIR..."
  git clone --depth 1 "$GITHUB_REPO" "$ATHENA_DIR"
  log "Repository cloned"
fi

cd "$ATHENA_DIR"

# ── Step 2: Python dependencies ──────────────────────────────────────────────
header "Step 2/5: Install Python dependencies"

if [ "${SKIP_DEPS:-0}" = "1" ]; then
  warn "Skipping Python deps (SKIP_DEPS=1)"
elif [ -z "$PIP" ]; then
  warn "No pip available, skipping Python deps"
else
  info "Installing Python dependencies..."
  if $PIP install -r requirements.txt --break-system-packages 2>/dev/null; then
    log "Python dependencies installed"
  elif $PIP install --user -r requirements.txt --break-system-packages 2>/dev/null; then
    log "Python dependencies installed (--user)"
  else
    err "Python deps failed. Try: python3 -m venv ~/.athena/venv && source ~/.athena/venv/bin/activate && pip install -r requirements.txt"
  fi
fi

# ── Step 3: System tools ────────────────────────────────────────────────────
header "Step 3/5: Install system tools (slither, aderyn, foundry)"

if [ "${SKIP_SYSTEM:-0}" = "1" ]; then
  warn "Skipping system tools (SKIP_SYSTEM=1)"
else
  # Slither
  if command -v slither &>/dev/null; then
    log "Slither already installed"
  elif [ -n "$PIP" ]; then
    info "Installing Slither..."
    $PIP install --break-system-packages slither-analyzer 2>/dev/null || $PIP install --user --break-system-packages slither-analyzer 2>/dev/null || warn "Slither install failed"
    command -v slither &>/dev/null && log "Slither installed" || warn "Slither not in PATH"
  fi

  # Aderyn
  if command -v aderyn &>/dev/null; then
    log "Aderyn already installed"
  elif command -v cargo &>/dev/null; then
    info "Installing Aderyn via cargo..."
    cargo install aderyn 2>/dev/null || warn "Aderyn install failed"
    command -v aderyn &>/dev/null && log "Aderyn installed" || warn "Aderyn not in PATH"
  else
    warn "cargo not found, skipping Aderyn. Install Rust: https://rustup.rs"
  fi

  # Foundry
  if command -v forge &>/dev/null; then
    log "Foundry already installed"
  else
    info "Installing Foundry..."
    curl -L https://foundry.paradigm.xyz 2>/dev/null | bash 2>/dev/null || warn "Foundryup install failed"
    export PATH="$HOME/.foundry/bin:$PATH"
    if command -v foundryup &>/dev/null; then
      foundryup 2>/dev/null || warn "foundryup failed"
    fi
    command -v forge &>/dev/null && log "Foundry installed" || warn "Foundry not in PATH — run: foundryup"
  fi
fi

# ── Step 4: Copy Skill files ─────────────────────────────────────────────────
header "Step 4/5: Install audit skill"

if [ -d "$SKILL_SOURCE" ]; then
  mkdir -p "$(dirname "$SKILL_DEST")"
  cp -r "$SKILL_SOURCE" "$SKILL_DEST"
  log "Skill installed to $SKILL_DEST"
else
  warn "Skill source not found at $SKILL_SOURCE"
fi

# ── Step 5: Configure Claude Code MCP ────────────────────────────────────────
header "Step 5/5: Configure Claude Code MCP servers"

if [ "${SKIP_CLAUDE:-0}" = "1" ]; then
  warn "Skipping Claude Code config (SKIP_CLAUDE=1)"
elif [ -f "$SERVERS_JSON" ]; then
  if command -v claude &>/dev/null; then
    info "Found claude CLI, registering MCP servers..."
    
    # Parse servers.json and register each
    TOOL_NAMES=$(python3 -c "
import json
with open('$SERVERS_JSON') as f:
    config = json.load(f)
for s in config['servers']:
    print(f\"{s['name']}|{s['command']}|{s['args'][0]}\")
" 2>/dev/null || echo "")
    
    if [ -n "$TOOL_NAMES" ]; then
      while IFS='|' read -r name cmd tool_rel; do
        tool_path="$ATHENA_DIR/$tool_rel"
        if claude mcp add "athena-$name" -- "$cmd" "$tool_path" &>/dev/null; then
          log "Registered: athena-$name"
        else
          warn "Failed to register athena-$name"
        fi
      done <<< "$TOOL_NAMES"
    fi
  else
    # Generate config snippet
    info "claude CLI not found, generating config snippet..."
    
    SNIPPET_PATH="$ATHENA_DIR/claude-mcp-config.json"
    python3 -c "
import json, os

with open('$SERVERS_JSON') as f:
    config = json.load(f)

athena_dir = '$ATHENA_DIR'
mcp_servers = {}
for s in config['servers']:
    tool_path = os.path.join(athena_dir, s['args'][0])
    mcp_servers[f'athena-{s[\"name\"]}'] = {
        'command': s['command'],
        'args': [tool_path],
        'env': s.get('env', {})
    }

with open('$SNIPPET_PATH', 'w') as f:
    json.dump({'mcpServers': mcp_servers}, f, indent=2)
print(json.dumps({'mcpServers': mcp_servers}, indent=2))
" 2>/dev/null
    
    echo ""
    echo -e "${YELLOW}${BOLD}Manual Configuration Required${RESET}"
    echo -e "${DIM}$(printf '%.0s─' {1..50})${RESET}"
    echo ""
    echo -e "Claude CLI not found. Add this to ${BOLD}~/.claude/settings.json${RESET}:"
    echo ""
    cat "$SNIPPET_PATH" 2>/dev/null || true
    echo ""
    echo -e "Config saved to: ${DIM}$SNIPPET_PATH${RESET}"
    echo ""
    echo -e "Or install Claude CLI and re-run this script."
  fi
else
  warn "servers.json not found, skipping MCP configuration"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo -e "
${GREEN}${BOLD}
   ╔═══════════════════════════════════════╗
   ║       Installation Complete! ✨        ║
   ╚═══════════════════════════════════════╝${RESET}

${BOLD}Installed:${RESET}
  📁 Athena repo     → ${DIM}$ATHENA_DIR${RESET}
  🔧 MCP tools       → ${DIM}$ATHENA_DIR/mcp/tools/${RESET} (13 tools)
  📚 Audit skill     → ${DIM}$SKILL_DEST${RESET}
  ⚙️  Python deps     → ${DIM}requirements.txt${RESET}

${BOLD}Quick Start:${RESET}

  ${CYAN}# Audit a Solidity contract${RESET}
  claude \"audit contracts/test-cases/Reentrancy.sol\"

  ${CYAN}# Run Slither analysis directly${RESET}
  python3 $ATHENA_DIR/mcp/tools/slither_runner.py

  ${CYAN}# Full audit workflow${RESET}
  claude \"read $ATHENA_DIR/AGENT-WORKFLOW-FINAL.md and audit this project\"

${BOLD}MCP Tools:${RESET}
  • slither      — Static analysis (Trail of Bits)
  • aderyn       — Static analysis (Cyfrin, Rust-based)
  • poc-generator — PoC exploit test generation
  • fuzz-runner  — Foundry fuzz/invariant tests
  • knowledge-base — RAG vulnerability database
  • eas-attest   — On-chain EAS attestation
  • exploit-simulator — Attack simulation
  • evidence-chain — Merkle audit trail
  • halmos       — Formal verification
  • protocol-scanner — Protocol-level scanning
  • repair-validator — Fix validation
  • incremental-auditor — Diff-based auditing
  • gev-analyzer — Governance/Economic/Value analysis

${DIM}Docs: https://github.com/tiyadegure/Athena${RESET}
"
