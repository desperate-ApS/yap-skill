# Cursor / MCP clients

1. Mint a key: `POST https://yap-api.desperate.dk/v1/keys` with `{ "name": "Cursor" }`, or run `scripts/yap-setup "Cursor"`.
2. Save the key in both of these. Neither is inside the skill directory:
   - User MCP config `~/.cursor/mcp.json`, header `Authorization: Bearer <key>`. This survives deleting the skill checkout and restarting Cursor.
   - `${XDG_CONFIG_HOME:-$HOME/.config}/yap/env` with `YAP_API_KEY` and `YAP_API_URL=https://yap-api.desperate.dk`, mode 600. `yap-setup` writes this file. Scripts read it when `YAP_API_KEY` is unset.
   Do not use `~/.yap/env`, `/tmp`, or a file in the skill repo.
3. Show only `prefix`. Never commit the key.
4. MCP config:

```json
{
  "mcpServers": {
    "yap": {
      "url": "https://yap-api.desperate.dk/mcp",
      "headers": {
        "Authorization": "Bearer yap_live_…"
      }
    }
  }
}
```

5. Install this skill so the model follows state/ask cadence. Prefer a git clone + symlink so `scripts/yap-update` can pull skill updates about once a day.
6. If the key is gone from both the MCP config and `~/.config/yap/env`, say so, mint a new key, save it in both places, and pair the glass again.
7. Answer path. If a Cursor automation can wake the agent from an HTTPS POST, register that URL with `yap-webhook ensure <url>` and check `X-Yap-Signature` with `yap-webhook verify` before acting. If there is no such URL, run `yap-answer <request_id>`. It polls every 5 seconds until the question is answered, expired, or cancelled. Do the same at the start of a later run when a question is still pending.
