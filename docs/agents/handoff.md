# Handoff
> Last updated: 2026-11-05   By: opencode

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

## In flight
(none)

## Gotchas
- Chat and image gen share VRAM: an image request stops llama.cpp (~150 s cold swap); chat afterwards pays cold start again.
- First image request after chat can fail with `ECONNRESET` mid-swap; retry once.
- Gateway is one slot, FIFO, chat prioritised; expect ~9-19 tok/s, 8-60 s cold starts, 900 s deadline.
- Existing `{env:...}` keys (agnes/sensenova/mistral) resolve empty in the running service; they need the same `{file:...}` treatment if used.
