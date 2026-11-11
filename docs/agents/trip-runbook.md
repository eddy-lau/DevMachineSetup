# Trip runbook — remote work from mainland China

Status: prepared 2026-11-11 for departure Friday 2026-11-13.

## Architecture

```
Phone (mainland)
 ├── QQ   → Hermes  → task board → OpenCode → repos / Teams / WhatsApp
 └── Lark → ZCode   → shell on the same Mac          (second opinion + emergency console)
```

Only the control hop crosses the border. LLM calls, git, GitHub, and the
Teams/WhatsApp browser sessions all originate from the home Mac in Hong Kong, so
they are unaffected by the GFW.

Both agent paths terminate on the **same Mac**. That machine and its home
internet are the single point of failure; nothing here can recover them
remotely.

## Channels

| Channel | Reaches | Target id |
| --- | --- | --- |
| QQ bot (primary) | Hermes gateway | `qqbot:452935A057F8F611BFF0B9E2EB10B35C` |
| Lark (secondary) | ZCode on the Mac | ZCode's Lark app, existing chat |
| Telegram | Mac only | blocked on the phone; archive copy |

QQ access is locked to one openid (`qqbot.dm_policy: allowlist`,
`group_policy: disabled`). Any other QQ account is silently ignored.

## Daily loop

1. Phone → QQ → voice or text.
2. Hermes acknowledges with an id, hands work to the board.
3. The hourly tick (`agent-tasks-hourly`) runs it on the Mac.
4. `notify.py scan` pushes the result back to QQ.
5. Review with `diff <id>`, then `approve <id>` or `changes <id> <why>`.

Never wait in a chat turn for a coding task; the tick owns long work.

## Message notifications

WhatsApp and Teams are unreachable from a mainland phone, so the ingest tick
pushes what it read over QQ instead of only into the source self-chat.

- **Hourly**: `[ingest HH:MM] Teams · N msgs / M chats · K tasks` plus the first
  three previews (DMs, then @mentions, then groups, newest first). More than
  three messages → the full per-chat list rides as a `.md` attachment.
- **On demand**: text `check` to get an ingest immediately and reply with
  `checked: WA n / Teams n`.
- **Archive**: the same digest still goes to the source self-chat with an
  `[agent-digest]` prefix, so the home side keeps a searchable copy.
- **Retry**: a failed QQ push is stored in
  `system/state/ingest-digest-pending.json` and re-sent by the next
  `notify.py scan` or by the watchdog's `flush`.
- **Freshness**: the watchdog reports `ingest stalled` when the newest
  `system/audit/ingest/*.md` is more than 3 h old — the signal that Chrome lost
  the Teams or WhatsApp session.

Secrets are redacted before the push (`redact.py`), but message text still
transits Tencent. Attachments and replying back into WhatsApp/Teams are not
covered; ask for a specific thread if you need one.

## Verb cheat sheet

Copy-paste, one per message.

```
status
ls ready
ls review
show P-20261111-004
add Fix flaky test in DevMachineSetup | /Volumes/Orico/Projects/DevMachineSetup
run P-20261111-004
diff P-20261111-004
approve P-20261111-004
changes P-20261111-004 add a regression test
teams 20
wa 20
```

Full rules: skill `remote-ops`.

## Emergency — QQ bot is silent

Reach ZCode through Lark, then run these on the Mac. Copy-paste blocks:

```
hermes status
```

```
tail -40 ~/.hermes/logs/gateway.log
```

```
hermes gateway restart
```

If the gateway is up but QQ is not delivering, check the platform log:

```
tail -80 ~/.hermes/logs/gateway.log | grep -i qq
```

If the board is stuck, bypass it and run OpenCode directly:

```
cd /Volumes/Orico/Projects/DevMachineSetup && ~/.opencode/bin/opencode run --auto --agent build "describe the repo state"
```

Last resort, send a message to your own QQ from the Mac to prove the channel:

```
hermes send --to "qqbot:452935A057F8F611BFF0B9E2EB10B35C" "channel test"
```

## Machine survival

- Sleep is disabled (`pmset sleep 0`); gateway runs under launchd `ai.hermes.gateway`.
- Watchdog cron `trip-watchdog` every 30 min, silent unless something is wrong:
  gateway down, cron ticker stale, disk ≥ 90%, QQ API unreachable, no recent QQ
  websocket, load spike, or sleep re-enabled.
- **Do not reboot the Mac while away.** FileVault parks it at the unlock screen
  and no remote channel can reach it. This is the one unrecoverable failure.
- `autorestart` is still 0 (needs sudo). Setting it only restarts the machine
  into that same FileVault prompt, so it does not remove the risk.
- Before leaving: confirm `gh auth status`, and that Teams and WhatsApp are
  signed in **with persistence** in the shared Chrome profile. Neither can be
  re-authenticated remotely.

## Approvals

`approvals.mode` stays `manual`; the timeout is now **600 s** (was 60 s, which the
Hermes default itself calls "too tight for push notifications"). The QQ adapter
renders dangerous-command approvals as inline keyboard buttons, so the flow is a
tap, not typed text.

- `approvals.cron_mode: deny` is unchanged: cron sessions can never approve, so a
  task that needs a dangerous command blocks and notifies instead of silently
  proceeding.
- If you miss a prompt, the command fails closed and the task blocks with a
  reason. Nothing runs unapproved.
- Do not run with `--yolo` while unattended.

## Known gaps

- No Lark tenant admin, so Hermes cannot join Lark yet. ZCode's published Lark
  app is the only Lark path. A personal Lark tenant would unlock a second proper
  channel with approval cards.
- Single Mac: no hardware or network redundancy.
- No UPS. A power blip during FileVault boot ends remote access.

## Thursday rehearsal (phone on cellular, Wi-Fi off)

1. `status` → counts match the repo.
2. Voice note: "add a task to fix the flaky test in DevMachineSetup" → id returned.
3. Wait for the tick → QQ notification → `diff <id>` → `approve <id>`.
4. `teams 20` → a usable summary.
5. Kill the gateway from Lark/ZCode, restart it, confirm the running task is
   reclaimed rather than lost.
6. DM the bot from a second QQ account → ignored.
