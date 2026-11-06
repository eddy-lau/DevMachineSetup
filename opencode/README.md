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
| `~/.cache/chrome-devtools-mcp/chrome-profile` | Dedicated Chrome profile with the Z.ai login |

Requirements:

- `chrome_devtools` MCP server:
  `npx -y chrome-devtools-mcp@latest --headless --viewport=1440x900 --no-usage-statistics`
  with a 900000 ms timeout. Headless keeps the automation browser off-screen; Teams
  renders under the `HeadlessChrome` UA without complaint. The MCP server launches
  its own Chrome profile; `--autoConnect` is not used because macOS blocks OpenCode
  from reading the main Chrome profile's `DevToolsActivePort`.
- The ZCode remote tab open in the MCP-managed Chrome profile, signed in with the
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
- The MCP browser profile contains Z.ai cookies; treat it as secret. Keep that
  Chrome profile dedicated to ZCode; the MCP server can read every tab in it.
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

- The MCP Chrome profile signed into the personal Microsoft account. Sign-in is
  manual (password + MFA); cookies persist in the profile.
- A `teams.live.com/v2/` tab with the chat list rendered. The browser is headless,
  so the tab must be created with `new_page` or `navigate_page`; there is no visible
  window to click.

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

ZCode parity (2026-11-06):

| Path | Purpose |
|---|---|
| `~/.zcode/skills/teams-web` | Symlink to the OpenCode skill |
| `~/.zcode/commands/teams.md` | `/teams <task>` command in ZCode |
| `~/.zcode/cli/config.json` → `mcp.servers.chrome_devtools` | Headless MCP against `~/.cache/chrome-devtools-mcp/chrome-profile-zcode` |

The ZCode profile is a copy of the OpenCode Chrome profile, so the Teams session
carried over. It is separate because Chrome locks a user-data-dir and both
harnesses may run at the same time. Sessions diverge after the copy: when Teams
expires in one profile, sign in again in that profile only. Restart ZCode after
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
| Plugin not loading | `opencode plugin list`, `opencode plugin check` |
