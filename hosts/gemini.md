# Gemini

1. Mint a key: `POST https://yap-api.desperate.dk/v1/keys` with `{ "name": "Gemini" }`, or run `scripts/yap-setup "Gemini"`.
2. Store the key in the tool's secret (the Gemini or Vertex environment that survives a skill reinstall). If scripts run on a machine, `yap-setup` also writes `${XDG_CONFIG_HOME:-$HOME/.config}/yap/env` (mode 600). Do not put the key in the skill repo, in `~/.yap/env`, or in `/tmp`.
3. Show only `prefix`. Never commit the key.
4. Register function declarations with the same REST bodies as in `SKILL.md` (`/v1/keys`, `/v1/pair`, `/v1/state`, `/v1/ask`, `/v1/questions/:id`, `/v1/status`, `/v1/devices`).
5. If the secret is gone, say so, mint a new key, save it again, and pair the glass again.
6. Answer path. If the tool runtime can take an inbound POST, register it with `yap-webhook ensure <url>` and verify `X-Yap-Signature` before acting. Otherwise poll `GET /v1/questions/:request_id` every 5 seconds until answered, expired, or cancelled. `yap-answer <request_id>` does that.
