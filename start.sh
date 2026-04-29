#!/bin/bash
# ══════════════════════════════════════════════════
#  OpenClaw + Paperclip — Replit Startup
#  Geen wizard, geen interactie — volledig automatisch
# ══════════════════════════════════════════════════

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}✔ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
die()  { echo -e "${RED}✖ $1${NC}"; exit 1; }
header() { echo -e "\n${BOLD}$1${NC}"; }

# ── Vereiste secrets ──────────────────────────────
header "🦞 OpenClaw + 📎 Paperclip — Replit Setup"
echo "══════════════════════════════════════════"

LLM_PROVIDER="${LLM_PROVIDER:-replit}"
OPENCLAW_PORT="${OPENCLAW_PORT:-5000}"
OPENCLAW_TOKEN="${OPENCLAW_TOKEN:-openclaw-replit-secret}"
PAPERCLIP_PORT="${PAPERCLIP_PORT:-3001}"

# Valideer credentials op basis van provider
if [ "$LLM_PROVIDER" = "bedrock" ]; then
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_REGION" ]; then
    die "AWS Bedrock vereist: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY en AWS_REGION"
  fi
elif [ "$LLM_PROVIDER" = "replit" ]; then
  if [ -z "$AI_INTEGRATIONS_ANTHROPIC_API_KEY" ]; then
    die "Replit AI integratie vereist: AI_INTEGRATIONS_ANTHROPIC_API_KEY (activeer de Anthropic integratie in Replit)"
  fi
  log "Replit AI integratie actief (geen eigen API sleutel nodig)"
else
  if [ -z "$LLM_API_KEY" ]; then
    die "LLM_API_KEY ontbreekt!"
  fi
fi

log "Provider: $LLM_PROVIDER"
log "OpenClaw poort: $OPENCLAW_PORT"
log "Paperclip poort: $PAPERCLIP_PORT"

# ── 0. Opruimen van eventueel lopende instanties ──
header "🧹 Opruimen"
pkill -f "openclaw gateway run" 2>/dev/null || true
pkill -f "paperclipai run" 2>/dev/null || true
sleep 2
# Verwijder stale auth-profiles zodat Bedrock env-vars worden gebruikt
rm -f "${HOME}/.openclaw/agents/main/agent/auth-profiles.json" 2>/dev/null || true
log "Vorige instanties gestopt"

# ── 1. Installeer tools ───────────────────────────
header "📦 Tools installeren"

if ! command -v openclaw &>/dev/null; then
  echo "  openclaw installeren..."
  rm -rf "$(npm root -g)/openclaw" 2>/dev/null || true
  npm install -g openclaw@latest --silent
fi
log "OpenClaw $(openclaw --version)"

if ! command -v paperclipai &>/dev/null; then
  echo "  paperclipai installeren..."
  npm install -g paperclipai@latest --silent
fi
log "Paperclipai $(paperclipai --version 2>/dev/null || echo 'geïnstalleerd')"

# ── 2. OpenClaw config schrijven (geen wizard) ────
header "⚙️  OpenClaw configureren"

mkdir -p ~/.openclaw

# Bepaal het juiste model op basis van provider
case "$LLM_PROVIDER" in
  openai)   MODEL="openai/gpt-4o" ;;
  groq)     MODEL="groq/llama-3.3-70b-versatile" ;;
  mistral)  MODEL="mistral/mistral-large-latest" ;;
  bedrock)  MODEL="${BEDROCK_MODEL:-bedrock/anthropic.claude-3-haiku-20240307-v1:0}" ;;
  replit)   MODEL="anthropic/claude-sonnet-4-6" ;;
  *)        MODEL="anthropic/claude-sonnet-4-6" ;;
esac

# Schrijf openclaw.json direct — geen onboard wizard nodig
if [ "$LLM_PROVIDER" = "bedrock" ]; then
  cat > ~/.openclaw/openclaw.json << OPENCLAW_EOF
{
  "\$schema": "https://docs.openclaw.ai/schema/openclaw.json",
  "gateway": {
    "mode": "local",
    "port": ${OPENCLAW_PORT},
    "bind": "custom",
    "customBindHost": "0.0.0.0",
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_TOKEN}"
    },
    "controlUi": {
      "allowedOrigins": ["*"],
      "dangerouslyDisableDeviceAuth": true
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
elif [ "$LLM_PROVIDER" = "replit" ]; then
  cat > ~/.openclaw/openclaw.json << 'OPENCLAW_EOF'
{
  "$schema": "https://docs.openclaw.ai/schema/openclaw.json",
  "gateway": {
    "mode": "local",
    "port": 5000,
    "bind": "custom",
    "customBindHost": "0.0.0.0",
    "auth": {
      "mode": "token",
      "token": "openclaw-replit-secret"
    },
    "controlUi": {
      "allowedOrigins": ["*"],
      "dangerouslyDisableDeviceAuth": true
    }
  },
  "models": {
    "providers": {
      "anthropic": {
        "baseUrl": "http://localhost:1106/modelfarm/anthropic",
        "api": "anthropic-messages",
        "apiKey": "_DUMMY_API_KEY_",
        "models": [
          { "id": "claude-sonnet-4-6", "name": "claude-sonnet-4-6" }
        ]
      }
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
    "customBindHost": "0.0.0.0",
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_TOKEN}"
    },
    "controlUi": {
      "allowedOrigins": ["*"],
      "dangerouslyDisableDeviceAuth": true
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

# Standaard model instellen
openclaw models set "$MODEL" 2>/dev/null || true

# API key instellen via config set
openclaw config set gateway.bind custom 2>/dev/null || true

# Provider-specifieke credentials instellen
case "$LLM_PROVIDER" in
  openai)
    export OPENAI_API_KEY="$LLM_API_KEY"
    ;;
  groq)
    export GROQ_API_KEY="$LLM_API_KEY"
    ;;
  mistral)
    export MISTRAL_API_KEY="$LLM_API_KEY"
    ;;
  replit)
    export ANTHROPIC_API_KEY="$AI_INTEGRATIONS_ANTHROPIC_API_KEY"
    export ANTHROPIC_BASE_URL="$AI_INTEGRATIONS_ANTHROPIC_BASE_URL"
    log "Replit AI integratie ingesteld (claude-sonnet-4-6)"
    ;;
  bedrock)
    export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
    export AWS_DEFAULT_REGION="us-east-1"
    export AWS_REGION="us-east-1"
    log "AWS Bedrock credentials ingesteld (regio: us-east-1)"

    log "Bedrock auth via omgevingsvariabelen (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION)"

    # Schrijf systeem-context voor de agent (boot.md)
    AGENT_DIR="${HOME}/.openclaw/agents/main/agent"
    mkdir -p "$AGENT_DIR"
    cat > "$AGENT_DIR/boot.md" << 'BOOT_EOF'
## Systeeminformatie

Je draait op een Replit Linux container (NixOS). Er is geen systemd, geen systemctl en geen apt/yum/brew beschikbaar.

Gebruik NOOIT:
- systemctl
- apt, apt-get, yum, brew
- sudo (geen root)
- snap, flatpak

Beschikbare tools: bash, node, npm, npx.
De OpenClaw gateway is al gestart via start.sh — je hoeft hem niet opnieuw te installeren of starten.
BOOT_EOF
    log "Agent boot-instructies aangemaakt"
    ;;
  *)
    export ANTHROPIC_API_KEY="$LLM_API_KEY"
    ;;
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

# Boot.md: systeemcontext + history-instructies voor de agent
AGENT_DIR="${HOME}/.openclaw/agents/main/agent"
mkdir -p "$AGENT_DIR"
# Schrijf boot.md alleen als die ontbreekt (bewaar bestaande indien gebruiker aanpaste)
if [ ! -f "$AGENT_DIR/boot.md" ]; then
  cat > "$AGENT_DIR/boot.md" << 'BOOT_EOF'
## Systeeminformatie

Je draait op een Replit Linux container (NixOS). Er is geen systemd, geen systemctl en geen apt/yum/brew beschikbaar.

Gebruik NOOIT: systemctl, apt, apt-get, yum, brew, sudo, snap, flatpak
Gebruik WEL: nix, npm, pip, cargo — schrijf bestanden naar /tmp of ~/

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

# Workspace dir + MEMORY.md aanmaken (agent verwacht dit bestand)
mkdir -p ~/.openclaw/workspace
touch ~/.openclaw/workspace/MEMORY.md

# LLM idle-timeout uitzetten zodat trage Replit proxy geen internal error veroorzaakt
openclaw config set agents.defaults.llm.idleTimeoutSeconds 0 2>/dev/null || true
# Subagent run-timeout uitzetten (standaard 5-10 min is te kort voor complexe taken)
openclaw config set agents.defaults.subagents.runTimeoutSeconds 0 2>/dev/null || true
# Subagent announce-timeout verhogen naar 10 minuten
openclaw config set agents.defaults.subagents.announceTimeoutMs 600000 2>/dev/null || true

log "OpenClaw config klaar"

# ── 3. Paperclip config schrijven (geen wizard) ───
header "📎 Paperclip configureren"

mkdir -p ~/.paperclip/instances/default

# Paperclip config — embedded SQLite/Postgres, lokale modus
cat > ~/.paperclip/instances/default/config.json << PAPERCLIP_EOF
{
  "instance": {
    "id": "default",
    "name": "WishFlow AI Company"
  },
  "server": {
    "port": ${PAPERCLIP_PORT},
    "host": "0.0.0.0"
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

# ── 4. Start alle services ────────────────────────
header "🚀 Services starten"

REPLIT_URL="${REPLIT_DEV_DOMAIN:-localhost}"

echo ""
echo "  OpenClaw Control UI  → https://${REPLIT_URL}"
echo "  Paperclip Dashboard  → https://${REPLIT_URL}:3001"
echo "  OpenClaw token       → ${OPENCLAW_TOKEN}"
echo ""

# Start Paperclip op de achtergrond
echo "📎 Paperclip starten op poort $PAPERCLIP_PORT..."
paperclipai run \
  --data-dir ~/.paperclip \
  --instance default \
  > /tmp/paperclip.log 2>&1 &
PAPERCLIP_PID=$!
log "Paperclip gestart (PID: $PAPERCLIP_PID)"

# Wacht even zodat Paperclip kan opstarten
sleep 3

# Start OpenClaw op de voorgrond (main process)
echo "🦞 OpenClaw Gateway starten op poort $OPENCLAW_PORT..."
exec openclaw gateway run \
  --port "$OPENCLAW_PORT" \
  --bind custom \
  --auth token \
  --token "$OPENCLAW_TOKEN" \
  --allow-unconfigured \
  --verbose
