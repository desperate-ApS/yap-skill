# Claude / Claude Code

1. Install this skill (`SKILL.md` + `scripts/`). Prefer a git clone so `scripts/yap-update` can pull updates.
2. Run `scripts/yap-setup "Claude"` once. That writes `YAP_API_KEY` to `${XDG_CONFIG_HOME:-$HOME/.config}/yap/env` (mode 600), outside the skill directory.
3. Also set `YAP_API_KEY` and `YAP_API_URL=https://yap-api.desperate.dk` in the user settings file `~/.claude/settings.json` under `env`. That file survives deleting the skill checkout. Do not put the key in the skill repo, in `~/.yap/env`, or in `/tmp`.
4. Show only `prefix` in chat. Never commit the key.
5. Use the scripts during chat, or point MCP at `https://yap-api.desperate.dk/mcp` with `Authorization: Bearer <key>`.
6. If the key is gone from both places, say so, mint a new key, save it again, and pair the glass again.
7. Answer path. Claude Code on a laptop usually cannot take an inbound POST. Run `yap-answer <request_id>` so it polls every 5 seconds until answered, expired, or cancelled. If you do have an HTTPS URL that wakes the agent, register it with `yap-webhook ensure <url>` and verify `X-Yap-Signature` before acting.
