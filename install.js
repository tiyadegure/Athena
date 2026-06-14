#!/usr/bin/env node
/**
 * athena-mcp install script
 * 
 * Installs Athena MCP tools + Skills for Claude Code.
 * This is a pure installer — the actual tools are Python scripts.
 * 
 * Usage:
 *   npx athena-mcp install
 *   npx athena-mcp install --skip-deps
 *   npx athena-mcp install --skip-claude
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

// ── Config ──────────────────────────────────────────────────────────────────
const GITHUB_REPO = 'https://github.com/tiyadegure/Athena.git';
const INSTALL_DIR = path.join(os.homedir(), '.athena');
const SKILL_NAME = 'athena-audit-skill';
const SKILL_SOURCE = path.join(INSTALL_DIR, 'skills', 'glm-audit-skill');
const SKILL_DEST = path.join(os.homedir(), '.claude', 'skills', SKILL_NAME);
const SERVERS_JSON = path.join(INSTALL_DIR, 'mcp', 'servers.json');

// ── Helpers ─────────────────────────────────────────────────────────────────
const GREEN = '\x1b[32m';
const RED = '\x1b[31m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const BOLD = '\x1b[1m';
const DIM = '\x1b[2m';
const RESET = '\x1b[0m';

function log(msg) { console.log(`${GREEN}✓${RESET} ${msg}`); }
function warn(msg) { console.log(`${YELLOW}⚠${RESET} ${msg}`); }
function error(msg) { console.log(`${RED}✗${RESET} ${msg}`); }
function info(msg) { console.log(`${CYAN}ℹ${RESET} ${msg}`); }
function header(msg) { console.log(`\n${BOLD}${msg}${RESET}`); }

function run(cmd, opts = {}) {
  try {
    const result = execSync(cmd, { encoding: 'utf-8', stdio: opts.silent ? 'pipe' : 'inherit', ...opts });
    return result ? result.trim() : '';
  } catch (e) {
    if (!opts.optional) throw e;
    return null;
  }
}

function commandExists(cmd) {
  try {
    execSync(os.platform() === 'win32' ? `where ${cmd}` : `command -v ${cmd}`, { stdio: 'pipe' });
    return true;
  } catch { return false; }
}

// ── Parse args ──────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const skipDeps = args.includes('--skip-deps');
const skipClaude = args.includes('--skip-claude');
const skipSystem = args.includes('--skip-system');
const help = args.includes('--help') || args.includes('-h');

if (help) {
  console.log(`
${BOLD}athena-mcp install${RESET}

Installs Athena MCP tools + Skills for Claude Code.

${BOLD}Options:${RESET}
  --skip-deps     Skip Python dependency installation
  --skip-system   Skip system tool installation (slither, aderyn, foundry)
  --skip-claude   Skip Claude Code MCP configuration
  -h, --help      Show this help

${BOLD}What gets installed:${RESET}
  1. Athena repo → ~/.athena/
  2. Python deps from requirements.txt
  3. System tools: slither, aderyn, foundry
  4. Skill files → ~/.claude/skills/athena-audit-skill/
  5. MCP server config for Claude Code
`);
  process.exit(0);
}

// ── Banner ──────────────────────────────────────────────────────────────────
console.log(`
${CYAN}${BOLD}
   ╔═══════════════════════════════════════╗
   ║          Athena MCP Installer         ║
   ║   Smart Contract Security Audit Tools ║
   ╚═══════════════════════════════════════╝${RESET}
`);

// ── Step 1: Clone / update repo ─────────────────────────────────────────────
header('Step 1/5: Clone Athena repository');
if (fs.existsSync(path.join(INSTALL_DIR, '.git'))) {
  info('Athena repo already exists, pulling latest...');
  run(`cd ${INSTALL_DIR} && git pull --ff-only`, { optional: true });
  log('Repository updated');
} else {
  info(`Cloning to ${INSTALL_DIR}...`);
  run(`git clone --depth 1 ${GITHUB_REPO} ${INSTALL_DIR}`);
  log('Repository cloned');
}

// ── Step 2: Python dependencies ─────────────────────────────────────────────
header('Step 2/5: Install Python dependencies');
if (skipDeps) {
  warn('Skipping Python deps (--skip-deps)');
} else {
  if (!commandExists('python3')) {
    error('python3 not found. Please install Python 3.8+');
    process.exit(1);
  }

  const pyVersion = run('python3 --version', { silent: true });
  info(`Found ${pyVersion}`);

  // Try pip3 first, then pip
  const pip = commandExists('pip3') ? 'pip3' : commandExists('pip') ? 'pip' : null;
  const reqFile = path.join(INSTALL_DIR, 'requirements.txt');
  
  // Check if we need --break-system-packages (PEP 668)
  const needsBreak = run('python3 -c "import sys; print(1 if hasattr(sys, \'base_prefix\') and sys.base_prefix != sys.prefix else 0)" 2>/dev/null || echo 0', { silent: true });
  const breakFlag = ' --break-system-packages';
  
  if (!pip) {
    warn('pip not found, trying python3 -m pip...');
    const result = run(`python3 -m pip install -r ${reqFile}${breakFlag}`, { optional: true, silent: true });
    if (result === null) {
      error('Python deps failed. Try: python3 -m venv ~/.athena/venv && source ~/.athena/venv/bin/activate && pip install -r requirements.txt');
    } else {
      log('Python dependencies installed');
    }
  } else {
    const result = run(`${pip} install -r ${reqFile}${breakFlag}`, { optional: true, silent: true });
    if (result === null) {
      error('Python deps failed. Try: python3 -m venv ~/.athena/venv && source ~/.athena/venv/bin/activate && pip install -r requirements.txt');
    } else {
      log('Python dependencies installed');
    }
  }
}

// ── Step 3: System tools ────────────────────────────────────────────────────
header('Step 3/5: Install system tools (slither, aderyn, foundry)');
if (skipSystem) {
  warn('Skipping system tools (--skip-system)');
} else {
  // Slither
  if (commandExists('slither')) {
    log('Slither already installed');
  } else {
    info('Installing Slither...');
    const pip = commandExists('pip3') ? 'pip3' : 'pip';
    run(`${pip} install --break-system-packages slither-analyzer`, { optional: true });
    if (commandExists('slither')) log('Slither installed');
    else warn('Slither install failed — install manually: pip install slither-analyzer');
  }

  // Aderyn
  if (commandExists('aderyn')) {
    log('Aderyn already installed');
  } else if (commandExists('cargo')) {
    info('Installing Aderyn via cargo...');
    run('cargo install aderyn', { optional: true });
    if (commandExists('aderyn')) log('Aderyn installed');
    else warn('Aderyn install failed — install manually: cargo install aderyn');
  } else {
    warn('cargo not found, skipping Aderyn. Install Rust first: https://rustup.rs');
  }

  // Foundry
  if (commandExists('forge')) {
    log('Foundry already installed');
  } else {
    info('Installing Foundry...');
    run('curl -L https://foundry.paradigm.xyz | bash', { optional: true, stdio: 'pipe' });
    // Source the env
    const foundryBin = path.join(os.homedir(), '.foundry', 'bin');
    if (fs.existsSync(foundryBin)) {
      process.env.PATH = `${foundryBin}:${process.env.PATH}`;
    }
    run(`${foundryBin}/foundryup`, { optional: true });
    if (commandExists('forge') || fs.existsSync(path.join(foundryBin, 'forge'))) {
      log('Foundry installed');
    } else {
      warn('Foundry install failed — install manually: curl -L https://foundry.paradigm.xyz | bash');
    }
  }
}

// ── Step 4: Copy Skill files ────────────────────────────────────────────────
header('Step 4/5: Install audit skill');
if (fs.existsSync(SKILL_SOURCE)) {
  // Create destination
  fs.mkdirSync(path.dirname(SKILL_DEST), { recursive: true });
  
  // Copy recursively
  function copyDir(src, dest) {
    fs.mkdirSync(dest, { recursive: true });
    for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
      const srcPath = path.join(src, entry.name);
      const destPath = path.join(dest, entry.name);
      if (entry.isDirectory()) {
        copyDir(srcPath, destPath);
      } else {
        fs.copyFileSync(srcPath, destPath);
      }
    }
  }
  
  copyDir(SKILL_SOURCE, SKILL_DEST);
  log(`Skill installed to ${SKILL_DEST}`);
} else {
  warn(`Skill source not found at ${SKILL_SOURCE}`);
}

// ── Step 5: Configure Claude Code MCP ───────────────────────────────────────
header('Step 5/5: Configure Claude Code MCP servers');
if (skipClaude) {
  warn('Skipping Claude Code config (--skip-claude)');
} else {
  // Read servers.json
  if (fs.existsSync(SERVERS_JSON)) {
    const config = JSON.parse(fs.readFileSync(SERVERS_JSON, 'utf-8'));
    const hasClaudeCmd = commandExists('claude');
    
    if (hasClaudeCmd) {
      info('Found claude CLI, registering MCP servers...');
      for (const server of config.servers) {
        const toolPath = path.join(INSTALL_DIR, server.args[0]);
        try {
          // claude mcp add <name> -- <command> <args...>
          const cmd = `claude mcp add athena-${server.name} -- ${server.command} ${toolPath}`;
          run(cmd, { silent: true, optional: true });
          log(`Registered: athena-${server.name}`);
        } catch (e) {
          warn(`Failed to register athena-${server.name}: ${e.message}`);
        }
      }
    } else {
      // Generate settings.json snippet
      info('claude CLI not found, generating config snippet...');
      
      const settingsPath = path.join(os.homedir(), '.claude', 'settings.json');
      const mcpServers = {};
      
      for (const server of config.servers) {
        const toolPath = path.join(INSTALL_DIR, server.args[0]);
        mcpServers[`athena-${server.name}`] = {
          command: server.command,
          args: [toolPath],
          env: server.env || {}
        };
      }
      
      const snippet = {
        mcpServers
      };
      
      const snippetPath = path.join(INSTALL_DIR, 'claude-mcp-config.json');
      fs.writeFileSync(snippetPath, JSON.stringify(snippet, null, 2));
      
      console.log(`
${YELLOW}${BOLD}Manual Configuration Required${RESET}
${DIM}${'─'.repeat(50)}${RESET}

Claude CLI not found. Add this to ${BOLD}~/.claude/settings.json${RESET}:

${CYAN}${JSON.stringify(snippet, null, 2)}${RESET}

Or install the Claude CLI and re-run:
${DIM}  npx athena-mcp install${RESET}

Config saved to: ${DIM}${snippetPath}${RESET}
`);
    }
  } else {
    warn('servers.json not found, skipping MCP configuration');
  }
}

// ── Summary ─────────────────────────────────────────────────────────────────
console.log(`
${GREEN}${BOLD}
   ╔═══════════════════════════════════════╗
   ║       Installation Complete! ✨        ║
   ╚═══════════════════════════════════════╝${RESET}

${BOLD}Installed:${RESET}
  📁 Athena repo     → ${DIM}${INSTALL_DIR}${RESET}
  🔧 MCP tools       → ${DIM}${INSTALL_DIR}/mcp/tools/${RESET} (13 tools)
  📚 Audit skill     → ${DIM}${SKILL_DEST}${RESET}
  ⚙️  Python deps     → ${DIM}requirements.txt${RESET}

${BOLD}Quick Start:${RESET}

  ${CYAN}# Audit a Solidity contract${RESET}
  claude "audit contracts/test-cases/Reentrancy.sol"

  ${CYAN}# Run Slither analysis directly${RESET}
  python3 ${INSTALL_DIR}/mcp/tools/slither_runner.py

  ${CYAN}# Full audit workflow${RESET}
  claude "read ${INSTALL_DIR}/AGENT-WORKFLOW-FINAL.md and audit this project"

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
`);
