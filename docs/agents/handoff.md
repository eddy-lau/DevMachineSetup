# Handoff
> Last updated: 2026-11-06   By: opencode

## State
- agent-sync 2026-11-02: created AGENTS.md, docs/agents/handoff.md, docs/agents/decisions.md. Global rules symlink, skills links, and MCP parity already clean.
- Panoptic LLM setup 2026-11-04, verified live:
  - Provider `panoptic` added to `~/.config/opencode/opencode.json` (V2 `providers` block beside the legacy V1 `provider` block; both merge).
  - Endpoint `http://100.110.22.90:9000/v1` (tailnet IP, works on office LAN and off-site). Alternatives: `http://192.168.1.230:9000/v1`, `https://llm.panoptic.ai/v1`.
  - Models: `qwen3.8-27b` (llama.cpp, 131072 ctx, text+image+pdf, reasoning in `reasoning_content`, variant `no-thinking`) and `qwen-image-2.1` (`type: image`, ComfyUI via `/v1/images/generations`).
  - `experimental.image_generate.model` = `panoptic/qwen-image-2.1`; tool verified (1024x1024 PNG).
  - Key: `~/.config/opencode/panoptic-api-key` (mode 600) referenced via `{file:...}`, because the background service does not inherit shell env. `PANOPTICLLM_APIKEY` also exported in `~/.zshrc` for curl/scripts.
  - Repo mirror: `opencode/opencode.jsonc` (env-based `PANOPTICLLM_APIKEY`), `opencode/env.example`, `opencode/README.md` (Panoptic section), root `README.md` §11.
  - Gateway guide lives at `http://100.110.22.90:9000/api/guide`; `/guide` is a JS-only SPA. Local copy: `~/Downloads/panoptic-connect.md`.
- 2026-11-05: repaired Z.ai agent models after Z.ai removed GLM-5.2 from the `zai-coding-plan` provider. `architect` and `glm-consultant` now use `zai-coding-plan/glm-5.3` (verified via `opencode run --agent`). Updated `~/.config/opencode/opencode.json`, `agent/architect.md`, `agent/glm-consultant.md`, and the two loop skills. `zai-coding-plan/glm-5.3-flash` also verified working for ad-hoc use.
- 2026-11-05: aws-sso skill/plugin v0.2.0 (`/Volumes/Orico/Projects/Personal/agent-aws-sso-plugin`, commit `ef18ad3`, not pushed). New `ensure` (check → login → verify → JSON, exit 3 on browser timeout), browser auto-open with URL capture, `--timeout`/`--lock-timeout`, `run` retry wrapper, refresh-token expiry in `status`, `AWS_SSO_PROFILE` + single-session defaults. Verified live: forced login completed in 6s with zero clicks; timeout path exit 3; concurrent `ensure` produced one login; `run` retried after synthetic ExpiredToken. Symlinks refreshed via `install.sh`; OpenCode skill reloaded.
- 2026-11-06: OpenCode → ZCode worker via Chrome DevTools MCP, Start Plan verified live.
  - Global `~/.config/opencode/opencode.json`: `mcp.chrome_devtools` = `npx -y chrome-devtools-mcp@latest --no-usage-statistics`, timeout 900000. MCP-managed Chrome profile: `~/.cache/chrome-devtools-mcp/chrome-profile`; signed into Z.ai once.
  - Workspace `DevMachineSetup` created in ZCode remote UI (`/Volumes/Orico/Projects/DevMachineSetup`); provider **Start Plan**, model **GLM-5.3-Flash**, Plan mode.
  - Local bridge: `~/.config/opencode/zcode-remote/{bridge.js,install.sh,README.md}`, skill `~/.config/opencode/skills/zcode-remote/SKILL.md`, command `~/.config/opencode/commands/zcode.md` (`/zcode <task>`).
  - Verified: simple prompt, real `AGENTS.md` read task, Start Plan provider in `~/.zcode/cli/log/zcode-2026-11-06.jsonl` (`account:zai-start-plan`, `GLM-5.3-Flash`). Repo docs updated (`opencode/README.md`, root `README.md` §11).
  - Note: app-bundled CLI cannot use Start Plan headless; it only entitles Individual Coding Plan. Browser remote route is official desktop path. Remote URL is a bearer secret; never log.
- agent-sync 2026-11-06: AGENTS.md memory pointer ok; added one-row `# Repositories` map; handoff/decisions present; global rules symlink valid; 9 shared skill links valid. `chrome_devtools` MCP and `zcode-remote` skill are intentional OpenCode-only exceptions. No project shadow dirs; nested `opencode/AGENTS.md` is ignored by ZCode.
- 2026-11-06: Teams personal automation via Chrome DevTools MCP, smoke test passed live.
  - Graph is not an option: delegated personal Microsoft accounts are "Not supported" for Teams chats/channels/messages.
  - `teams.live.com/v2/` (`env=life`) is the personal client; `teams.microsoft.com` is work (`env=work`). Sign-in is manual (`login.live.com`, tenant `consumers`, `#usernameEntry`); cookies live in the MCP Chrome profile.
  - Verified in self-chat: list chats (21), open chat, type into `[data-tid="ckeditor"]`, send via `[data-tid="sendMessageCommands-send"]`, read back message (`data-mid`, body `#content-<mid>`, author/time from `aria-labelledby`). Test message "MCP smoke test 2026-11-06 — ignore" left in self-chat.
  - Chat id: `data-tabster` → `observed.names[0]`; title `#title-chat-list-item_<convId>`. Message rows are virtualized; DOM holds only the viewport.
  - Artifacts: skill `~/.config/opencode/skills/teams-web/SKILL.md`, command `~/.config/opencode/commands/teams.md` (`/teams <task>`, read-only default). Repo docs updated (`opencode/README.md`, root `README.md` §11).
  - Voice profile from 57 sent messages / 19 chats in `~/.config/opencode/skills/teams-web/voice.md`: short, lowercase-leaning, fragments (`ys`, `correct.`), `thx`/`pls`, no emoji or sign-off; registers per audience (client / colleague / close). Mandatory for all sends, with recipient + text confirmation. Calibration drafts approved 2026-11-06.
  - Session survives Chrome restart: MCP Chrome was killed and relaunched after a pipe-lock error; Teams cookies persisted, no re-login.
  - Formatting verified: `*bold*`, `_italic_`, `` `code` ``, `~strike~` convert inline; HTML paste creates `<ul>`/`<ol>`/`<strong>`/`<code>`; all tags survive send. Tables via HTML paste survive with `thead`/`th`/`td` (styles stripped, scroll container added). Send tid varies: `newMessageCommands-send` or `sendMessageCommands-send`. Test messages left in self-chat.
- 2026-11-06: `chrome_devtools` MCP switched to headless for both `/teams` and `/zcode`.
  - Config: `--headless --viewport=1440x900` in `~/.config/opencode/opencode.json` (backup `opencode.json.bak-headless-20261106-083543`).
  - Verified manually over CDP on the same profile: Teams loads 21 chats, `HeadlessChrome` UA accepted (no emulate needed), formatted send + table survive. Chrome headless session cookies persist.
  - Takes effect after OpenCode restart (MCP command is fixed at launch). Existing Chrome process was stopped after testing.
  - ZCode caveat: no visible window means the remote-control tab must be created by URL or restored from session; the bearer URL is still not stored.
- 2026-11-06: `/teams` available in ZCode.
  - `~/.zcode/skills/teams-web` → OpenCode skill symlink; `~/.zcode/commands/teams.md` → `/teams` command.
  - `~/.zcode/cli/config.json` → `mcp.servers.chrome_devtools` runs headless MCP with `--userDataDir=~/.cache/chrome-devtools-mcp/chrome-profile-zcode`.
  - ZCode profile is a copy of the OpenCode Chrome profile (628 MB), so Teams cookies carried over; verified headless load with 21 chats. Separate dir avoids Chrome profile lock when both harnesses run.
  - Verified: `zcode skills list` shows `teams-web`; `zcode commands list` shows `teams`; MCP stdio handshake returns 32 tools. ZCode restart required to load the new server/command.
  - Profiles diverge after copy: Teams session expiry must be handled per profile (sign in headed once on the copy if needed).
- agent-sync 2026-11-06: `teams-web` linked into `~/.agents/skills` (was the only real gap). ZCode/OpenCode parity: 5 MCP servers each, `chrome_devtools` differs only by its separate headless profile. `/teams` command present in both; `/zcode` stays OpenCode-only. No project shadow dirs; global rules symlink valid; handoff 56 lines.
  - Not tested: session survival across a browser restart, search, attachments, group-chat sends. Sending to humans is gated on explicit instruction.

## In flight
(none)

## Gotchas
- Chat and image gen share VRAM: an image request stops llama.cpp (~150 s cold swap); chat afterwards pays cold start again.
- First image request after chat can fail with `ECONNRESET` mid-swap; retry once.
- Gateway is one slot, FIFO, chat prioritised; expect ~9-19 tok/s, 8-60 s cold starts, 900 s deadline.
- Existing `{env:...}` keys (agnes/sensenova/mistral) resolve empty in the running service; they need the same `{file:...}` treatment if used.
- ZCode remote bridge: Chrome MCP must launch with its dedicated profile and the ZCode remote tab must stay open. If the MCP browser restarts, reopen the remote link; the helper is lost on reload and must be re-injected with `install.sh`.
- `chrome-devtools-mcp --autoConnect` cannot read the main Chrome profile's `DevToolsActivePort` from the OpenCode service (macOS permission denied). The bridge uses the MCP-managed profile instead; the main Chrome profile's remote-debugging toggle is not needed.
- ZCode app-bundled standalone CLI cannot use Start Plan headlessly; only the desktop/remote path can. Start Plan currently exposes `GLM-5.3-Flash`, not `GLM-5.3`.
- Remote-control URLs and the MCP Chrome profile are bearer credentials; never paste them into logs, commits, or chat.
