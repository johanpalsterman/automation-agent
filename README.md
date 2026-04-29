# 🦞 OpenClaw + 📎 Paperclip — Replit

> **OpenClaw** = de AI agent (de werknemer)  
> **Paperclip** = de orchestratielaag (het bedrijf)

Geen wizard, geen interactie — alles start automatisch via Replit Secrets.

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

## 📚 Links

- [OpenClaw docs](https://docs.openclaw.ai)
- [Paperclip GitHub](https://github.com/paperclipai/paperclip)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
