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
