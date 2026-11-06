# Decision log (append-only)

| Date | Tool | Decision | Why |
|---|---|---|---|
| 2026-11-02 | opencode | Rewrite README for the current Mac mini; drop legacy iMac content | Content described Monterey-era setup; user asked for current machine state |
| 2026-11-02 | opencode | Add `Brewfile` snapshot and `opencode/` portable bundle | Reproducible restore for Mac mini and MacBook Air |
| 2026-11-04 | opencode | Add `panoptic` provider using V2 `providers` block beside legacy V1 `provider` | Image model needs `type: "image"`, which V1 model entries lack; disjoint provider IDs make coexistence safe |
| 2026-11-04 | opencode | Read Panoptic key from `{file:~/.config/opencode/panoptic-api-key}` instead of `{env:}` | Background service does not inherit shell exports (confirmed via process env); file keeps secret out of config |
| 2026-11-04 | opencode | Point Panoptic at tailnet IP `100.110.22.90` rather than LAN IP or `llm.panoptic.ai` | User's choice; single endpoint works both on office LAN and off-site |
| 2026-11-04 | opencode | Skip tuning compaction per Panoptic guide | Compaction settings are global and would also affect the default cloud model |
| 2026-11-05 | opencode | Make aws-sso autonomous: single `ensure` command, capture `aws sso login --no-browser` URL and auto-open, 120s timeout, per-user lock, `run` retry wrapper | Agents must never hang or require a local terminal; browser session makes login zero-click when alive |
| 2026-11-06 | opencode | Use Chrome DevTools MCP + ZCode web Remote Control for OpenCode → ZCode worker, not the app-bundled CLI | Start Plan uses desktop JWT/captcha path; standalone CLI only entitles Individual Coding Plan and cannot use Start Plan headlessly |
| 2026-11-06 | opencode | Treat `chrome_devtools` MCP and `zcode-remote` skill as OpenCode-only exceptions in agent-sync | The Chrome MCP bridge drives ZCode; adding it or its skill to ZCode would be recursive and unusable |
| 2026-11-06 | opencode | Automate Teams personal by driving `teams.live.com` with Chrome DevTools MCP, not Graph or private APIs | Graph Teams endpoints reject personal Microsoft accounts; DOM automation is the only documented-surface route and was verified live. Private chat-service fetch kept as fallback only |
| 2026-11-06 | opencode | Apply a learned voice profile to every Teams send, with recipient + text confirmation | User asked for all sends to mimic his style; corpus of 57 messages shows terse, lowercase-leaning, no emoji/sign-off, register-dependent. Confirmation stays mandatory because sends are externally visible |
| 2026-11-06 | opencode | Run the Chrome DevTools MCP headless for both Teams and ZCode | User wants no visible automation window. Teams works under HeadlessChrome UA with the existing profile cookies; single server/profile keeps one browser instead of two. Cost: ZCode remote tab must be opened by URL because there is no window for manual navigation |
| 2026-11-06 | zcode | Give ZCode its own Teams skill, command, and headless Chrome profile instead of sharing OpenCode's | Both harnesses may run at once and Chrome locks a user-data-dir. Copying the existing profile carried the Teams login without a second MFA; profiles now diverge and must be re-authenticated independently when sessions expire |
