# 📋 Release Notes

## v1.1.0 — 2026-05-12

### Nieuwe functionaliteit: Desktop-ondersteuning

OpenClaw + Paperclip draait nu ook lokaal op **Windows, macOS en Linux** — naast de bestaande Replit-ondersteuning.

### Toegevoegde bestanden

| Bestand | Beschrijving |
|---------|--------------|
| `start-desktop.sh` | Opstartscript voor Mac/Linux (vergelijkbaar met `start.sh` maar voor lokaal gebruik) |
| `start-desktop.bat` | Opstartscript voor Windows |
| `.env.example` | Voorbeeldbestand met alle configuratievariabelen en uitleg |
| `RELEASE_NOTES.md` | Dit bestand |

### Gewijzigde bestanden

| Bestand | Wijziging |
|---------|-----------|
| `README.md` | Nieuwe sectie "Lokaal draaien op desktop" toegevoegd |
| `package.json` | Scripts `start:desktop` en `start:replit` toegevoegd |

### Wat is er veranderd?

- **`start-desktop.sh`** (Mac/Linux):
  - Controleert of Node.js ≥ v20 aanwezig is, met duidelijke foutmelding + installatielinks
  - Laadt automatisch een `.env` bestand indien aanwezig
  - Installeert `openclaw` en `paperclipai` globaal via npm indien niet aanwezig
  - Ondersteunt alle LLM providers: `anthropic`, `openai`, `groq`, `mistral`, `bedrock`
  - Bindt op `127.0.0.1` (lokaal) in plaats van `0.0.0.0` (Replit-publiek)
  - Start Paperclip op de achtergrond en OpenClaw op de voorgrond

- **`start-desktop.bat`** (Windows):
  - Zelfde logica als het bash-script, maar als Windows batch-script
  - Start Paperclip in een apart cmd-venster
  - Laadt `.env` variabelen automatisch

- **`.env.example`**:
  - Bevat alle variabelen die in `start.sh` en `start-desktop.sh` worden gebruikt
  - Elke variabele heeft een beschrijving en een link naar de bijbehorende service

---

## v1.0.0 — initiële versie

- OpenClaw + Paperclip op Replit
- Automatisch opstarten via `start.sh`
- Ondersteuning voor Anthropic, OpenAI, Groq, Mistral en AWS Bedrock
- Telegram en Discord kanaalopties
- Dashboard HTML (`dashboard.html`)
