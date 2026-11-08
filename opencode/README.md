# OpenCode — portable setup

Global OpenCode configuration from the Mac mini, packaged for a fresh Mac
(MacBook Air). Uses OpenCode V2 config shapes.

## What gets installed

| File | Purpose |
|---|---|
| `opencode.jsonc` | Global config: default model, custom providers, subagents, plugin, MCP servers |
| `cli.json` | TUI preferences (theme, diffs, session layout) |
| `AGENTS.md` | Global instructions (caveman response style, operating boundaries) |
| `install.sh` | Installs OpenCode via Homebrew and copies the three files above |
| `env.example` | Names of the environment variables providers need |

Installed to `~/.config/opencode/` (or `$XDG_CONFIG_HOME/opencode`).

## Prerequisites

- macOS on Apple Silicon or Intel
- [Homebrew](https://brew.sh)
- Node.js (for `npx`-based MCP server) and [uv](https://docs.astral.sh/uv/) (for Serena):
  `brew install node uv`

## Setup

```bash
git clone git@github.com:eddy-lau/DevMachineSetup.git
cd DevMachineSetup/opencode
./install.sh --dry-run   # optional preview
./install.sh
```

Then:

```bash
opencode auth login      # OpenCode Go, GitHub Copilot, Z.AI, others
opencode                 # TUI → /models to pick a default
opencode mcp list        # check zai-mcp-server and serena connect
```

Provider keys for custom endpoints are environment variables, not config values.
Set them in your shell or secret manager (1Password, Keychain) before starting
OpenCode:

```bash
export AGNES_API_KEY=...
export SENSENOVA_API_KEY=...
export MISTRAL_API_KEY=...
export OPENXLAB_API_KEY=...
export ATRIA_API_KEY=...
export PANOPTICLLM_APIKEY=...
export Z_AI_API_KEY=...
```

`env.example` is the template. Never commit filled-in values.

## Included

- Default model `opencode-go/deepseek-v4.1-flash` (same as the mini; change via `/models` if unavailable)
- Providers: Agnes AI, SenseNova, Mistral, OpenXLab, Atria, Panoptic LLM, local Ollama auto-discovery
- Subagents: `vision` (Kimi K3), `architect` (GLM-5.3)
- Plugin: `github:eddy-lau/opencode-file-viewer`
- MCP servers: `zai-mcp-server` (npx), `serena` (uvx)

## Panoptic LLM (office)

Kristian's office gateway serves two models on one OpenAI-compatible endpoint:

| Model | Kind | Notes |
|---|---|---|
| `qwen3.8-27b` | chat | llama.cpp, 128K ctx, text + image + PDF input, reasoning |
| `qwen-image-2.1` | image | ComfyUI behind `/v1/images/generations` |

```bash
opencode run --model panoptic/qwen3.8-27b "explain RAID levels briefly"
```

Endpoint is the tailnet IP, so it works on the office LAN and off-site:
`http://100.110.22.90:9000/v1`. Alternatives: `http://192.168.1.230:9000/v1`
(LAN), `https://llm.panoptic.ai/v1` (TLS).

Caveats:

- Chat and image generation share VRAM. Generating an image stops the chat
  model (~150 s cold swap), and the next chat pays the cold start again.
- One slot, requests are queued and served in order; chat is prioritised
  over images. Expect ~9-19 tok/s and 8-60 s cold-start latency.
- Thinking text arrives in `reasoning_content`; the `no-thinking` variant
  sends `X-Disable-Thinking: 1` to skip it.
- The background service does not inherit shell exports. If `{env:...}`
  resolves empty, point `apiKey` at a file instead:
  `"apiKey": "{file:~/.config/opencode/panoptic-api-key}"`.
- The first image request after a chat session can fail with `ECONNRESET`
  while the gateway swaps VRAM. Retry once — it succeeds on the second try.

## Shared Chrome for browser automation

OpenCode, ZCode, OpenClaw, and Hermes attach to one supervised Chrome instance.
The shared profile gives Teams and WhatsApp one login/session across all four
harnesses instead of a profile copy per harness.

| Piece | Path / endpoint |
|---|---|
| LaunchAgent | `~/Library/LaunchAgents/ai.chrome.shared.plist` |
| Chrome profile | `~/.cache/chrome-devtools-mcp/chrome-profile` |
| CDP endpoint | `http://127.0.0.1:9229` (loopback only) |
| Manual login helper | `~/.local/bin/chrome-shared-login` |
| Profile backup | `~/.cache/chrome-devtools-mcp/chrome-profile.backup-<stamp>` |

The LaunchAgent runs Chrome 156 headless with `--user-data-dir=...`,
`--remote-debugging-port=9229`, `--remote-debugging-address=127.0.0.1`, and
`--remote-allow-origins=*`. Chrome allows one process per user-data-dir, so the
LaunchAgent is the sole owner; never start another Chrome on that profile.
Port 9229 is used because the daily Chrome already holds 9222.

| Harness | Wiring |
|---|---|
| OpenCode | `mcp.chrome_devtools` = `npx -y chrome-devtools-mcp@latest --browserUrl http://127.0.0.1:9229 --no-usage-statistics` |
| ZCode | same command in `~/.zcode/cli/config.json`; restart ZCode or start a new session |
| OpenClaw | `browser.attachOnly=true`, `browser.defaultProfile=shared`, `browser.profiles.shared.cdpUrl=http://127.0.0.1:9229`; `mcp.servers.chrome_devtools` uses the same command |
| Hermes | `browser.cdp_url=http://127.0.0.1:9229`; `skills.external_dirs: ["~/.agents/skills"]`; MCP server `chrome_devtools` uses the same command |

`chrome-devtools-mcp` is stdio, so each harness runs its own MCP process. The
shared state is the Chrome profile and its tabs, not the MCP server. Teams uses
one tab per harness, tagged in page state (`sessionStorage.shared_agent`), because
Teams strips URL markers. WhatsApp permits one active tab per profile, so all
harnesses reuse the single `web.whatsapp.com` tab.

Manual login: run `chrome-shared-login`. It stops the LaunchAgent, opens the same
profile headed with Teams and WhatsApp already loaded, and waits while you complete
Teams MFA or scan the WhatsApp QR. Quit Chrome completely when finished; the helper
restarts the headless instance and verifies `9229` answers. One login covers all
four harnesses. If the helper is interrupted while Chrome is still open, it leaves
the LaunchAgent stopped and prints the `launchctl bootstrap` command to recover.

Tabs do not survive a Chrome restart. Each harness recreates its own Teams tab on
demand (tagged with its `shared_agent` marker), and the first WhatsApp caller
recreates the single `web.whatsapp.com` tab. The login session itself lives in the
profile and does survive.

The profile contains Teams, WhatsApp, and Z.ai cookies. Treat it and port 9229 as
secrets; any local process that can reach the port can control the browser.

## ZCode remote worker (Start Plan)

The mini can delegate tasks from OpenCode to the ZCode desktop app through
Chrome DevTools MCP. This uses ZCode's official Remote Control page, so it spends
the free **Start Plan** quota (`account:zai-start-plan`, `GLM-5.3-Flash`) instead
of the standalone CLI, which cannot use Start Plan headlessly.

Machine-local pieces:

| Path | Purpose |
|---|---|
| `~/.config/opencode/zcode-remote/bridge.js` | In-page helper injected with `evaluate_script` |
| `~/.config/opencode/zcode-remote/install.sh` | Copies the helper to the OS temp dir |
| `~/.config/opencode/skills/zcode-remote/SKILL.md` | Agent workflow and safety rules |
| `~/.config/opencode/commands/zcode.md` | `/zcode <task>` command |
| `~/.cache/chrome-devtools-mcp/chrome-profile` | Shared Chrome profile with Z.ai, Teams, and WhatsApp sessions |

Requirements:

- `chrome_devtools` MCP server:
  `npx -y chrome-devtools-mcp@latest --browserUrl http://127.0.0.1:9229 --no-usage-statistics`
  with a 900000 ms timeout. It attaches to the shared headless Chrome; see
  [Shared Chrome for browser automation](#shared-chrome-for-browser-automation).
- The ZCode remote tab open in the shared Chrome profile, signed in with the
  same Z.ai account as the desktop app, with a task/session view open. In headless
  mode there is no window to open it manually, so either navigate the MCP browser
  to a fresh remote link or keep a session restore path.
- ZCode workspace, provider **Start Plan**, model **GLM-5.3-Flash**, and Plan or
  Ask-before-changes mode selected in the remote UI.

Usage:

```text
/zcode inspect this repo and summarize AGENTS.md
```

Caveats:

- The remote-control URL is a bearer credential. Never log or commit it.
- The shared Chrome profile contains Z.ai, Teams, and WhatsApp cookies; treat it
  as secret. The MCP server can read every tab in the shared profile.
- One ZCode turn at a time. The helper reports `needsApproval` and `timedOut`.
- DOM automation can break when the ZCode web UI changes.
- Do not use Full access/yolo unless the user explicitly asks.

## Teams personal web client

Teams personal accounts have no Graph API: delegated personal Microsoft accounts
are explicitly unsupported for Teams chat and channel endpoints. A machine-local
`/teams` helper drives `https://teams.live.com/v2/` through the same Chrome
DevTools MCP instead.

| Path | Purpose |
|---|---|
| `~/.config/opencode/skills/teams-web/SKILL.md` | Selectors, recipes, and safety rules (verified 2026-11-06) |
| `~/.config/opencode/skills/teams-web/voice.md` | Learned voice profile; mandatory for all sends |
| `~/.config/opencode/commands/teams.md` | `/teams <task>` command |

Requirements:

- The shared Chrome profile signed into the personal Microsoft account. Sign-in is
  manual (password + MFA); one login covers all four harnesses. The profile keeps
  the session across headless restarts.
- A `teams.live.com/v2/` tab with the chat list rendered. The browser is headless,
  so the tab must be created with `new_page` or `navigate_page`; there is no visible
  window to click.
- Per-harness tab ownership. Teams strips `?agent=` and `#agent=` from its URL on
  load, so each harness tags its tab with `sessionStorage.shared_agent` (and
  `document.documentElement.dataset.sharedAgent`). The skill probes tabs for its
  own marker and never closes another agent's tab.

Usage:

```text
/teams summarize unread messages in PAI Research
```

Caveats:

- Read-only by default. Sends only when the task says to send.
- DOM automation, polling only. No webhook or event stream; not suitable for
  always-on monitoring.
- Selectors are undocumented and can change on any Teams deploy. Re-run a
  self-chat smoke test after a UI change.

ZCode parity and other harnesses:

| Path | Purpose |
|---|---|
| `~/.zcode/skills/teams-web` | Symlink to the OpenCode skill |
| `~/.zcode/commands/teams.md` | `/teams <task>` command in ZCode |
| `~/.agents/skills/teams-web` | Shared skill link for OpenClaw and Hermes |
| `~/.zcode/cli/config.json` → `mcp.servers.chrome_devtools` | Shared MCP against `http://127.0.0.1:9229` |

OpenClaw sees `teams-web` as `agents-skills-personal`; Hermes sees it as `external`
via `skills.external_dirs`. All four harnesses share one Teams login and use
per-harness tabs tagged in page state. Restart ZCode after changing its command or
MCP config.

## WhatsApp personal web client

WhatsApp has no API for personal accounts, and unofficial protocol bridges
(Baileys, whatsapp-web.js) get accounts banned. A machine-local `/whatsapp`
helper drives `https://web.whatsapp.com/` through the same Chrome DevTools MCP
instead (verified 2026-11-07).

| Path | Purpose |
|---|---|
| `~/.config/opencode/skills/whatsapp-web/SKILL.md` | Selectors, recipes, login recipe, and safety rules (verified 2026-11-07) |
| `~/.config/opencode/skills/whatsapp-web/voice.md` | Learned voice profile (Cantonese-leaning); mandatory for all sends |
| `~/.config/opencode/commands/whatsapp.md` | `/whatsapp <task>` command |

Requirements:

- The shared Chrome profile linked as a WhatsApp device. Linking is manual and
  one-time: `chrome-shared-login` stops the headless Chrome, opens the same profile
  headed, and you scan the on-screen QR (WhatsApp → Settings → Linked Devices).
  The session then persists for the headless LaunchAgent and covers all four
  harnesses.
- A `web.whatsapp.com/` tab with the chat list rendered; headless means the tab
  is created with `new_page`. WhatsApp allows one active tab per profile, so all
  harnesses reuse the same tab instead of opening a second one.

Usage:

```text
/whatsapp list my 5 most recent chats
/whatsapp send "running 10 min late" to 老婆
```

Caveats:

- Read-only by default. Sends only when the task says to send, drafted in the
  learned voice, with recipient + text confirmation before anything goes out.
- WhatsApp is stricter than Teams about automation: no bulk sends, human-like
  pacing. The skill forbids private-protocol clients outright.
- WhatsApp's server sometimes rejects new device links with "Can't link new
  devices right now" — a temporary anti-abuse block; retry after 10–30 min.
- Search does not index the self-chat; the skill opens it through the New chat
  panel. Attachments are unverified.
- Selectors are undocumented and can change on any WhatsApp deploy. Re-run a
  self-chat smoke test after a UI change.

ZCode parity and other harnesses:

| Path | Purpose |
|---|---|
| `~/.zcode/skills/whatsapp-web` | Symlink to the OpenCode skill |
| `~/.zcode/commands/whatsapp.md` | `/whatsapp <task>` command in ZCode |
| `~/.agents/skills/whatsapp-web` | Shared skill link for OpenClaw and Hermes |

The ZCode profile no longer has its own WhatsApp link: ZCode attaches to the same
shared Chrome profile. OpenClaw sees `whatsapp-web` as `agents-skills-personal`;
Hermes sees it as `external` via `skills.external_dirs`. Restart ZCode after
changing its command or MCP config.

## Not included

| Item | Why |
|---|---|
| API keys and OAuth tokens | Secrets. Use `opencode auth login` and env vars. |
| Local plugins (`caveman`, `ponytail`, `shared-memory`, `rtk`) | Live on the mini's filesystem or a separate repo |
| `kapitsa` provider and its models | Local inference server on the mini |
| `android_emulator` / `ios_simulator` MCP servers | Depend on vendored packages under `~/.config/opencode/vendor` |
| Sessions, database, logs, worktrees | Machine-local state under `~/.local/share/opencode` |

## Syncing skills and commands from the mini

When both machines are online on Tailscale:

```bash
rsync -a ~/.config/opencode/skills/   eddies-macbook-air:.config/opencode/skills/
rsync -a ~/.config/opencode/commands/ eddies-macbook-air:.config/opencode/commands/
```

Review before copying — some skills reference absolute paths or local MCP servers.

## Troubleshooting

| Symptom | Check |
|---|---|
| Config ignored | `opencode debug paths config`, then `/reload` in the TUI |
| Legacy config wins | Another `opencode.json` exists; this script moves it to `backups/` |
| Provider missing from `/models` | Env var not set, or run `opencode auth login` |
| MCP server not connected | `opencode mcp list`, then `/mcps` to authenticate |
| Shared Chrome not reachable | `curl -s http://127.0.0.1:9229/json/version`; `launchctl print gui/$(id -u)/ai.chrome.shared` |
| MCP still points at old profile | `ps aux \| grep chrome-devtools-mcp`; the args should include `--browserUrl http://127.0.0.1:9229` |
| Teams/WhatsApp login expired | `~/.local/bin/chrome-shared-login`, complete MFA/QR, quit Chrome |
| Plugin not loading | `opencode plugin list`, `opencode plugin check` |
