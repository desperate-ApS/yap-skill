# ChatGPT / OpenAI tools

1. Mint a key: `POST https://yap-api.desperate.dk/v1/keys` with `{ "name": "ChatGPT" }`, or run `scripts/yap-setup "ChatGPT"`.
2. Store the key in the connector or custom-action secret (OpenAI's secret store). That survives reinstalling the skill. If scripts run on a machine, `yap-setup` also writes `${XDG_CONFIG_HOME:-$HOME/.config}/yap/env` (mode 600). Do not put the key in the skill repo, in `~/.yap/env`, or in `/tmp`.
3. Show only `prefix`. Never commit the key.
4. Either register MCP at `https://yap-api.desperate.dk/mcp` with `Authorization: Bearer <key>`, or expose function tools that POST/GET the same `/v1/*` routes as in `SKILL.md`.
5. If the secret is gone, say so, mint a new key, save it in the connector secret, and pair the glass again.
6. Answer path. If the connector can take an inbound POST, register it with `PUT /v1/webhook` (`yap_set_webhook` or `yap-webhook ensure <url>`) and verify `X-Yap-Signature` before acting. Otherwise poll `GET /v1/questions/:request_id` every 5 seconds until answered, expired, or cancelled. `yap-answer <request_id>` does that.
