@echo off
:: ══════════════════════════════════════════════════
::  OpenClaw + Paperclip — Desktop Startup (Windows)
::  Lokaal draaien zonder Replit
:: ══════════════════════════════════════════════════

setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1
title OpenClaw + Paperclip Desktop

echo.
echo =========================================
echo  OpenClaw + Paperclip -- Desktop Setup
echo  Windows
echo =========================================
echo.

:: ── Laad .env bestand indien aanwezig ────────────
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%.env" (
    echo [OK] .env bestand gevonden -- variabelen laden...
    for /f "usebackq tokens=1,* delims==" %%A in ("%SCRIPT_DIR%.env") do (
        set "LINE=%%A"
        if not "!LINE:~0,1!"=="#" (
            if not "%%A"=="" (
                set "%%A=%%B"
            )
        )
    )
) else (
    echo [WAARSCHUWING] Geen .env bestand gevonden.
    echo               Kopieer .env.example naar .env en vul de waarden in:
    echo               copy .env.example .env
    echo.
)

:: ── 0. Controleer Node.js ─────────────────────────
echo.
echo [STAP] Vereisten controleren...

where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [FOUT] Node.js is niet geinstalleerd!
    echo        Download: https://nodejs.org/  ^(LTS versie aanbevolen^)
    echo        Na installatie: herstart dit script
    pause
    exit /b 1
)

for /f "tokens=*" %%V in ('node --version') do set NODE_VERSION=%%V
echo [OK] Node.js %NODE_VERSION%

where npm >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [FOUT] npm is niet gevonden. Herinstalleer Node.js via https://nodejs.org/
    pause
    exit /b 1
)

for /f "tokens=*" %%V in ('npm --version') do set NPM_VERSION=%%V
echo [OK] npm %NPM_VERSION%

:: ── 1. Lees configuratie ──────────────────────────
echo.
echo [STAP] Configuratie lezen...

if not defined LLM_PROVIDER set "LLM_PROVIDER=anthropic"
if not defined OPENCLAW_PORT set "OPENCLAW_PORT=5000"
if not defined OPENCLAW_TOKEN set "OPENCLAW_TOKEN=openclaw-desktop-secret"
if not defined PAPERCLIP_PORT set "PAPERCLIP_PORT=3001"

:: Valideer verplichte variabelen
if "%LLM_PROVIDER%"=="bedrock" (
    if not defined AWS_ACCESS_KEY_ID (
        echo [FOUT] AWS_ACCESS_KEY_ID ontbreekt! Zet hem in .env
        pause & exit /b 1
    )
    if not defined AWS_SECRET_ACCESS_KEY (
        echo [FOUT] AWS_SECRET_ACCESS_KEY ontbreekt!
        pause & exit /b 1
    )
    if not defined AWS_REGION (
        echo [FOUT] AWS_REGION ontbreekt!
        pause & exit /b 1
    )
    echo [OK] Provider: AWS Bedrock ^(regio: %AWS_REGION%^)
) else (
    if not defined LLM_API_KEY (
        echo [FOUT] LLM_API_KEY ontbreekt!
        echo        Zet hem in .env ^(zie .env.example^) of stel hem in als omgevingsvariabele:
        echo        set LLM_API_KEY=your-api-key
        pause
        exit /b 1
    )
    echo [OK] Provider: %LLM_PROVIDER%
)

echo [OK] OpenClaw poort: %OPENCLAW_PORT%
echo [OK] Paperclip poort: %PAPERCLIP_PORT%

:: ── 2. Installeer tools ───────────────────────────
echo.
echo [STAP] Tools installeren...

where openclaw >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   openclaw installeren ^(globaal via npm^)...
    npm install -g openclaw@latest
    if %ERRORLEVEL% neq 0 (
        echo [FOUT] openclaw installatie mislukt!
        pause & exit /b 1
    )
)

for /f "tokens=*" %%V in ('openclaw --version 2^>nul') do set OC_VERSION=%%V
echo [OK] OpenClaw %OC_VERSION%

where paperclipai >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   paperclipai installeren ^(globaal via npm^)...
    npm install -g paperclipai@latest
    if %ERRORLEVEL% neq 0 (
        echo [FOUT] paperclipai installatie mislukt!
        pause & exit /b 1
    )
)
echo [OK] Paperclipai geinstalleerd

:: ── 3. OpenClaw configureren ──────────────────────
echo.
echo [STAP] OpenClaw configureren...

if not exist "%USERPROFILE%\.openclaw" mkdir "%USERPROFILE%\.openclaw"

:: Bepaal model
set "MODEL=anthropic/claude-sonnet-4-6"
if "%LLM_PROVIDER%"=="openai"   set "MODEL=openai/gpt-4o"
if "%LLM_PROVIDER%"=="groq"     set "MODEL=groq/llama-3.3-70b-versatile"
if "%LLM_PROVIDER%"=="mistral"  set "MODEL=mistral/mistral-large-latest"
if "%LLM_PROVIDER%"=="bedrock" (
    if defined BEDROCK_MODEL (
        set "MODEL=%BEDROCK_MODEL%"
    ) else (
        set "MODEL=bedrock/anthropic.claude-3-haiku-20240307-v1:0"
    )
)

:: Schrijf openclaw.json
if "%LLM_PROVIDER%"=="bedrock" (
    (
        echo {
        echo   "$schema": "https://docs.openclaw.ai/schema/openclaw.json",
        echo   "gateway": {
        echo     "mode": "local",
        echo     "port": %OPENCLAW_PORT%,
        echo     "bind": "custom",
        echo     "customBindHost": "127.0.0.1",
        echo     "auth": {
        echo       "mode": "token",
        echo       "token": "%OPENCLAW_TOKEN%"
        echo     }
        echo   },
        echo   "env": {
        echo     "vars": {
        echo       "AWS_ACCESS_KEY_ID": "%AWS_ACCESS_KEY_ID%",
        echo       "AWS_SECRET_ACCESS_KEY": "%AWS_SECRET_ACCESS_KEY%",
        echo       "AWS_REGION": "%AWS_REGION%"
        echo     }
        echo   }
        echo }
    ) > "%USERPROFILE%\.openclaw\openclaw.json"
) else (
    (
        echo {
        echo   "$schema": "https://docs.openclaw.ai/schema/openclaw.json",
        echo   "gateway": {
        echo     "mode": "local",
        echo     "port": %OPENCLAW_PORT%,
        echo     "bind": "custom",
        echo     "customBindHost": "127.0.0.1",
        echo     "auth": {
        echo       "mode": "token",
        echo       "token": "%OPENCLAW_TOKEN%"
        echo     }
        echo   },
        echo   "env": {
        echo     "vars": {
        echo       "LLM_API_KEY": "%LLM_API_KEY%"
        echo     }
        echo   }
        echo }
    ) > "%USERPROFILE%\.openclaw\openclaw.json"
)

:: Provider credentials
if "%LLM_PROVIDER%"=="openai"  set "OPENAI_API_KEY=%LLM_API_KEY%"
if "%LLM_PROVIDER%"=="groq"    set "GROQ_API_KEY=%LLM_API_KEY%"
if "%LLM_PROVIDER%"=="mistral" set "MISTRAL_API_KEY=%LLM_API_KEY%"
if "%LLM_PROVIDER%"=="bedrock" (
    set "AWS_DEFAULT_REGION=%AWS_REGION%"
)
if not "%LLM_PROVIDER%"=="openai" if not "%LLM_PROVIDER%"=="groq" if not "%LLM_PROVIDER%"=="mistral" if not "%LLM_PROVIDER%"=="bedrock" (
    set "ANTHROPIC_API_KEY=%LLM_API_KEY%"
)

openclaw models set "%MODEL%" >nul 2>&1
openclaw config set agents.defaults.llm.idleTimeoutSeconds 0          >nul 2>&1
openclaw config set agents.defaults.subagents.runTimeoutSeconds 0      >nul 2>&1
openclaw config set agents.defaults.subagents.announceTimeoutMs 600000 >nul 2>&1

echo [OK] OpenClaw config klaar

:: ── 4. Paperclip configureren ─────────────────────
echo.
echo [STAP] Paperclip configureren...

if not exist "%USERPROFILE%\.paperclip\instances\default" mkdir "%USERPROFILE%\.paperclip\instances\default"

(
    echo {
    echo   "instance": {
    echo     "id": "default",
    echo     "name": "Desktop Agent"
    echo   },
    echo   "server": {
    echo     "port": %PAPERCLIP_PORT%,
    echo     "host": "127.0.0.1"
    echo   },
    echo   "database": {
    echo     "type": "embedded"
    echo   },
    echo   "auth": {
    echo     "mode": "open"
    echo   }
    echo }
) > "%USERPROFILE%\.paperclip\instances\default\config.json"

echo [OK] Paperclip config klaar

:: ── 5. Services starten ───────────────────────────
echo.
echo [STAP] Services starten...
echo.
echo   OpenClaw Control UI  -^> http://localhost:%OPENCLAW_PORT%
echo   Paperclip Dashboard  -^> http://localhost:%PAPERCLIP_PORT%
echo   OpenClaw token       -^> %OPENCLAW_TOKEN%
echo.
echo   Sluit dit venster of druk Ctrl+C om te stoppen.
echo.

:: Start Paperclip in een apart venster
echo [START] Paperclip starten op poort %PAPERCLIP_PORT%...
start "Paperclip" cmd /c "paperclipai run --data-dir %USERPROFILE%\.paperclip --instance default > %TEMP%\paperclip-desktop.log 2>&1"

:: Wacht even zodat Paperclip kan opstarten
timeout /t 3 /nobreak >nul

:: Start OpenClaw in dit venster (voorgrond)
echo [START] OpenClaw Gateway starten op poort %OPENCLAW_PORT%...
openclaw gateway run ^
  --port "%OPENCLAW_PORT%" ^
  --bind custom ^
  --auth token ^
  --token "%OPENCLAW_TOKEN%" ^
  --allow-unconfigured ^
  --verbose

echo.
echo OpenClaw is gestopt.
pause
