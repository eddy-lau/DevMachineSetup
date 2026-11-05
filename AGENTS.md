# Conventions

- Documentation repository for machine setup notes; Markdown only.
- Keep commands copy-pasteable and version numbers current.

# Build / test / validation

- No build step.
- Validate the OpenCode bundle before committing:

  ```bash
  npx --yes json5 opencode/opencode.jsonc
  npx --yes json5 opencode/cli.json
  bash -n opencode/install.sh
  ```

- Brewfile sanity check: `brew bundle check --file=Brewfile --verbose`.

# Project conventions

(fill in with user)

# Project memory

- docs/agents/handoff.md — current state; read at session start
- docs/agents/decisions.md — decision log; append significant choices
End sessions by updating handoff.md.
