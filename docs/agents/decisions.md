# Decision log (append-only)

| Date | Tool | Decision | Why |
|---|---|---|---|
| 2026-11-02 | opencode | Rewrite README for the current Mac mini; drop legacy iMac content | Content described Monterey-era setup; user asked for current machine state |
| 2026-11-02 | opencode | Add `Brewfile` snapshot and `opencode/` portable bundle | Reproducible restore for Mac mini and MacBook Air |
| 2026-11-04 | opencode | Add `panoptic` provider using V2 `providers` block beside legacy V1 `provider` | Image model needs `type: "image"`, which V1 model entries lack; disjoint provider IDs make coexistence safe |
| 2026-11-04 | opencode | Read Panoptic key from `{file:~/.config/opencode/panoptic-api-key}` instead of `{env:}` | Background service does not inherit shell exports (confirmed via process env); file keeps secret out of config |
| 2026-11-04 | opencode | Point Panoptic at tailnet IP `100.110.22.90` rather than LAN IP or `llm.panoptic.ai` | User's choice; single endpoint works both on office LAN and off-site |
| 2026-11-04 | opencode | Skip tuning compaction per Panoptic guide | Compaction settings are global and would also affect the default cloud model |
