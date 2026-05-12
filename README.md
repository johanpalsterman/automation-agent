# 🦞 OpenClaw + 📎 Paperclip — Replit & Desktop

> **OpenClaw** = de AI agent (de werknemer)  
> **Paperclip** = de orchestratielaag (het bedrijf)

Geen wizard, geen interactie — alles start automatisch. Werkt op **Replit** én **lokaal op desktop** (Windows/Mac/Linux).

---

## ⚡ Snelstart (3 stappen)

### Stap 1 — Secrets instellen

Ga naar **Tools → Secrets** en voeg toe:

| Secret | Verplicht | Beschrijving |
|--------|:---------:|--------------|
| `LLM_API_KEY` | ✅ | Je API key (Anthropic, OpenAI, Groq of Mistral) |
| `LLM_PROVIDER` | Nee | `anthropic` (standaard), `openai`, `groq`, `mistral` |
| `OPENCLAW_TOKEN` | Nee | Beveiligingstoken gateway (standaard: `openclaw-replit-secret`) |
| `TELEGRAM_BOT_TOKEN` | Nee | Telegram bot token via @BotFather |
| `DISCORD_BOT_TOKEN` | Nee | Discord bot token |

### Stap 2 — Klik Run

Het script installeert alles automatisch en start beide services.

### Stap 3 — Open de dashboards

| Service | URL | Beschrijving |
|---------|-----|--------------|
| 🦞 OpenClaw | Replit preview (poort 80) | AI agent dashboard + chat |
| 📎 Paperclip | Replit preview poort 3100 | Bedrijfsorchestratie UI |

---

## 💬 Messaging instellen

### Telegram
1. Chat met [@BotFather](https://t.me/BotFather) → `/newbot` → naam kiezen
2. Kopieer het bot token → zet als `TELEGRAM_BOT_TOKEN` secret
3. Herstart Replit → OpenClaw koppelt automatisch

### Discord
1. [Discord Developer Portal](https://discord.com/developers/applications) → New Application
2. Bot → Reset Token → kopieer token
3. Zet als `DISCORD_BOT_TOKEN` secret → herstart

---

## 🏢 Paperclip eerste keer gebruiken

1. Open Paperclip dashboard (poort 3100)
2. Maak een account aan → kies een bedrijfsnaam
3. Maak een agent aan → kies **OpenClaw Gateway** als type
4. Vul in:
   - Gateway URL: `ws://localhost:18789`
   - Token: de waarde van je `OPENCLAW_TOKEN` secret
5. Assign goals → agents gaan aan de slag

---

## 🛠️ Logs bekijken

```bash
# OpenClaw logs (in terminal)
# verschijnen automatisch bij Run

# Paperclip logs
cat /tmp/paperclip.log
```

---

## 🔒 Security tips

- Verander `OPENCLAW_TOKEN` naar een sterk willekeurig token (min. 16 tekens)
- Zet `TELEGRAM_ALLOWED_USERS` in als je Telegram gebruikt
- Laat de Paperclip UI niet publiek toegankelijk

---

---

## 💻 Lokaal draaien op desktop

Naast Replit kun je dit project ook lokaal draaien op **Windows, macOS of Linux**.

### Vereisten

- **Node.js** v20 of hoger: [nodejs.org](https://nodejs.org/)
- Een API key voor je gekozen LLM provider (zie tabel hieronder)

### Stap 1 — Configuratie instellen

Kopieer `.env.example` naar `.env` en vul je waarden in:

```bash
cp .env.example .env
# Open .env in een editor en vul de waarden in
```

De meest relevante variabelen:

| Variabele | Verplicht | Beschrijving |
|-----------|:---------:|--------------|
| `LLM_API_KEY` | ✅ | Je API key (Anthropic, OpenAI, Groq of Mistral) |
| `LLM_PROVIDER` | Nee | `anthropic` (standaard), `openai`, `groq`, `mistral`, `bedrock` |
| `OPENCLAW_TOKEN` | Nee | Beveiligingstoken gateway (standaard: `openclaw-desktop-secret`) |
| `OPENCLAW_PORT` | Nee | Poort voor OpenClaw (standaard: `5000`) |
| `PAPERCLIP_PORT` | Nee | Poort voor Paperclip (standaard: `3001`) |
| `TELEGRAM_BOT_TOKEN` | Nee | Telegram bot token |
| `DISCORD_BOT_TOKEN` | Nee | Discord bot token |

### Stap 2 — Opstarten

**Mac / Linux:**
```bash
bash start-desktop.sh
# Of via npm:
npm run start:desktop
```

**Windows:**
```bat
start-desktop.bat
```

Het script:
1. Controleert of Node.js aanwezig is (met helpzame foutmelding als dat niet zo is)
2. Laadt automatisch je `.env` bestand
3. Installeert `openclaw` en `paperclipai` globaal via npm (indien niet aanwezig)
4. Configureert beide tools
5. Start Paperclip op de achtergrond en OpenClaw op de voorgrond

### Stap 3 — Open de dashboards

| Service | URL | Beschrijving |
|---------|-----|--------------|
| 🦞 OpenClaw | http://localhost:5000 | AI agent dashboard + chat |
| 📎 Paperclip | http://localhost:3001 | Bedrijfsorchestratie UI |

### Logs bekijken (desktop)

```bash
# Paperclip logs
cat /tmp/paperclip-desktop.log        # Mac/Linux
type %TEMP%\paperclip-desktop.log     # Windows
```

### Nieuwe bestanden voor desktop

| Bestand | Beschrijving |
|---------|--------------|
| `start-desktop.sh` | Opstartscript voor Mac/Linux |
| `start-desktop.bat` | Opstartscript voor Windows |
| `.env.example` | Voorbeeldconfiguratiebestand |
| `RELEASE_NOTES.md` | Changelog en versieoverzicht |

---

## 📚 Links

- [OpenClaw docs](https://docs.openclaw.ai)
- [Paperclip GitHub](https://github.com/paperclipai/paperclip)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Release Notes](./RELEASE_NOTES.md)
