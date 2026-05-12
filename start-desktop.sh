#!/bin/bash
# ══════════════════════════════════════════════════
#  OpenClaw + Paperclip — Desktop Startup (Mac/Linux)
#  Lokaal draaien zonder Replit
# ══════════════════════════════════════════════════

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${GREEN}✔ $1${NC}"; }
warn()   { echo -e "${YELLOW}⚠ $1${NC}"; }
die()    { echo -e "${RED}✖ $1${NC}"; exit 1; }
header() { echo -e "\n${BOLD}$1${NC}"; }

header "🦞 OpenClaw + 📎 Paperclip — Desktop Setup"
echo "══════════════════════════════════════════"

# ── Laad .env bestand indien aanwezig ────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  log ".env bestand gevonden — variabelen laden..."
  set -a
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
  set +a
else
  warn "Geen .env bestand gevonden. Omgevingsvariabelen worden gebruikt."
  warn "Kopieer .env.example naar .env en vul de waarden in:"
  warn "  cp .env.example .env"
fi

# ── 0. Controleer Node.js ─────────────────────────
header "🔍 Vereisten controleren"

if ! command -v node &>/dev/null; then
  die "Node.js is niet geïnstalleerd!\n  Download: https://nodejs.org/ (LTS versie aanbevolen)\n  Of via package manager:\n    Mac:   brew install node\n    Linux: sudo apt install nodejs npm  (Ubuntu/Debian)\n           sudo dnf install nodejs     (Fedora)\n           sudo pacman -S nodejs npm   (Arch)"
fi

NODE_VERSION=$(node --version | sed 's/v//')
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 20 ]; then
  die "Node.js versie $NODE_VERSION is te oud. Minimaal v20.0.0 vereist.\n  Download: https://nodejs.org/"
fi
log "Node.js v$NODE_VERSION ✓"

if ! command -v npm &>/dev/null; then
  die "npm is niet geïnstalleerd (hoort bij Node.js).\n  Download: https://nodejs.org/"
fi
log "npm $(npm --version) ✓"

# ── 1. Lees configuratie ──────────────────────────
header "⚙️  Configuratie lezen"

LLM_PROVIDER="${LLM_PROVIDER:-anthropic}"
OPENCLAW_PORT="${OPENCLAW_PORT:-5000}"
OPENCLAW_TOKEN="${OPENCLAW_TOKEN:-openclaw-desktop-secret}"
PAPERCLIP_PORT="${PAPERCLIP_PORT:-3001}"

# Valideer verplichte variabelen
if [ "$LLM_PROVIDER" = "bedrock" ]; then
  [ -z "$AWS_ACCESS_KEY_ID" ]     && die "AWS_ACCESS_KEY_ID ontbreekt! Zet hem in .env of als omgevingsvariabele."
  [ -z "$AWS_SECRET_ACCESS_KEY" ] && die "AWS_SECRET_ACCESS_KEY ontbreekt!"
  [ -z "$AWS_REGION" ]            && die "AWS_REGION ontbreekt!"
  log "Provider: AWS Bedrock (regio: $AWS_REGION)"
else
  if [ -z "$LLM_API_KEY" ]; then
    die "LLM_API_KEY ontbreekt!\n  Zet hem in .env (zie .env.example) of exporteer hem:\n    export LLM_API_KEY=your-api-key"
  fi
  log "Provider: $LLM_PROVIDER"
fi

log "OpenClaw poort: $OPENCLAW_PORT"
log "Paperclip poort: $PAPERCLIP_PORT"

# ── 2. Opruimen ───────────────────────────────────
header "🧹 Opruimen"
pkill -f "openclaw gateway run" 2>/dev/null || true
pkill -f "paperclipai run"      2>/dev/null || true
sleep 1
rm -f "${HOME}/.openclaw/agents/main/agent/auth-profiles.json" 2>/dev/null || true
log "Vorige instanties gestopt"

# ── 3. Installeer tools ───────────────────────────
header "📦 Tools installeren"

if ! command -v openclaw &>/dev/null; then
  echo "  openclaw installeren (globaal via npm)..."
  npm install -g openclaw@latest
fi
log "OpenClaw $(openclaw --version)"

if ! command -v paperclipai &>/dev/null; then
  echo "  paperclipai installeren (globaal via npm)..."
  npm install -g paperclipai@latest
fi
log "Paperclipai $(paperclipai --version 2>/dev/null || echo 'geïnstalleerd')"

# ── 4. OpenClaw configureren ──────────────────────
header "⚙️  OpenClaw configureren"

mkdir -p ~/.openclaw

# Bepaal model op basis van provider
case "$LLM_PROVIDER" in
  openai)   MODEL="openai/gpt-4o" ;;
  groq)     MODEL="groq/llama-3.3-70b-versatile" ;;
  mistral)  MODEL="mistral/mistral-large-latest" ;;
  bedrock)  MODEL="${BEDROCK_MODEL:-bedrock/anthropic.claude-3-haiku-20240307-v1:0}" ;;
  *)        MODEL="anthropic/claude-sonnet-4-6" ;;
esac

# Schrijf openclaw.json
if [ "$LLM_PROVIDER" = "bedrock" ]; then
  cat > ~/.openclaw/openclaw.json << OPENCLAW_EOF
{
  "\$schema": "https://docs.openclaw.ai/schema/openclaw.json",
  "gateway": {
    "mode": "local",
    "port": ${OPENCLAW_PORT},
    "bind": "custom",
    "customBindHost": "127.0.0.1",
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_TOKEN}"
    }
  },
  "env": {
    "vars": {
      "AWS_ACCESS_KEY_ID": "${AWS_ACCESS_KEY_ID}",
      "AWS_SECRET_ACCESS_KEY": "${AWS_SECRET_ACCESS_KEY}",
      "AWS_REGION": "${AWS_REGION}"
    }
  }
}
OPENCLAW_EOF
else
  cat > ~/.openclaw/openclaw.json << OPENCLAW_EOF
{
  "\$schema": "https://docs.openclaw.ai/schema/openclaw.json",
  "gateway": {
    "mode": "local",
    "port": ${OPENCLAW_PORT},
    "bind": "custom",
    "customBindHost": "127.0.0.1",
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_TOKEN}"
    }
  },
  "env": {
    "vars": {
      "LLM_API_KEY": "${LLM_API_KEY}"
    }
  }
}
OPENCLAW_EOF
fi

# Model instellen
openclaw models set "$MODEL" 2>/dev/null || true

# Provider-specifieke credentials
case "$LLM_PROVIDER" in
  openai)   export OPENAI_API_KEY="$LLM_API_KEY" ;;
  groq)     export GROQ_API_KEY="$LLM_API_KEY" ;;
  mistral)  export MISTRAL_API_KEY="$LLM_API_KEY" ;;
  bedrock)
    export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
    export AWS_DEFAULT_REGION="${AWS_REGION:-us-east-1}"
    export AWS_REGION="${AWS_REGION:-us-east-1}"
    ;;
  *)        export ANTHROPIC_API_KEY="$LLM_API_KEY" ;;
esac

# Optioneel: Telegram
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  log "Telegram token gevonden — configureren..."
  openclaw config set channels.telegram.token \
    --ref-provider default --ref-source env --ref-id TELEGRAM_BOT_TOKEN 2>/dev/null || true
fi

# Optioneel: Discord
if [ -n "$DISCORD_BOT_TOKEN" ]; then
  log "Discord token gevonden — configureren..."
  openclaw config set channels.discord.token \
    --ref-provider default --ref-source env --ref-id DISCORD_BOT_TOKEN 2>/dev/null || true
fi

# Agent workspace + boot.md
AGENT_DIR="${HOME}/.openclaw/agents/main/agent"
mkdir -p "$AGENT_DIR"
if [ ! -f "$AGENT_DIR/boot.md" ]; then
  cat > "$AGENT_DIR/boot.md" << 'BOOT_EOF'
## Systeeminformatie

Je draait lokaal op een desktop machine. Gebruik de tools die beschikbaar zijn op dit systeem.

## Conversatiegeheugen

Lees aan het begin van elke nieuwe sessie ~/.openclaw/agents/main/agent/conversation-log.md (indien aanwezig) voor context over vorige gesprekken.

Voeg na elk antwoord een korte samenvatting toe aan conversation-log.md:

```
## [datum] Vraag: [samenvatting vraag]
Antwoord: [samenvatting antwoord]
---
```
BOOT_EOF
  log "boot.md aangemaakt"
fi

mkdir -p ~/.openclaw/workspace
touch ~/.openclaw/workspace/MEMORY.md

openclaw config set agents.defaults.llm.idleTimeoutSeconds 0         2>/dev/null || true
openclaw config set agents.defaults.subagents.runTimeoutSeconds 0     2>/dev/null || true
openclaw config set agents.defaults.subagents.announceTimeoutMs 600000 2>/dev/null || true

log "OpenClaw config klaar"

# ── 5. Paperclip configureren ─────────────────────
header "📎 Paperclip configureren"

mkdir -p ~/.paperclip/instances/default
cat > ~/.paperclip/instances/default/config.json << PAPERCLIP_EOF
{
  "instance": {
    "id": "default",
    "name": "Desktop Agent"
  },
  "server": {
    "port": ${PAPERCLIP_PORT},
    "host": "127.0.0.1"
  },
  "database": {
    "type": "embedded"
  },
  "auth": {
    "mode": "open"
  }
}
PAPERCLIP_EOF
log "Paperclip config klaar"

# ── 6. Services starten ───────────────────────────
header "🚀 Services starten"

echo ""
echo "  OpenClaw Control UI  → http://localhost:${OPENCLAW_PORT}"
echo "  Paperclip Dashboard  → http://localhost:${PAPERCLIP_PORT}"
echo "  OpenClaw token       → ${OPENCLAW_TOKEN}"
echo ""
echo "  Druk op Ctrl+C om te stoppen."
echo ""

# Start Paperclip op de achtergrond
echo "📎 Paperclip starten op poort $PAPERCLIP_PORT..."
paperclipai run \
  --data-dir ~/.paperclip \
  --instance default \
  > /tmp/paperclip-desktop.log 2>&1 &
PAPERCLIP_PID=$!
log "Paperclip gestart (PID: $PAPERCLIP_PID)"

sleep 3

# Start OpenClaw op de voorgrond
echo "🦞 OpenClaw Gateway starten op poort $OPENCLAW_PORT..."
exec openclaw gateway run \
  --port "$OPENCLAW_PORT" \
  --bind custom \
  --auth token \
  --token "$OPENCLAW_TOKEN" \
  --allow-unconfigured \
  --verbose
