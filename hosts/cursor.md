# Cursor / MCP clients

1. Mint a key: `POST https://yap-api.desperate.dk/v1/keys` with `{ "name": "Cursor" }`, or run `scripts/yap-setup "Cursor"`.
2. Store `key` as a secret. Show only `prefix`. Never commit it.
3. MCP config:

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

4. Optionally also install this skill so the model follows state/ask cadence. Answer path: poll with `yap_get_answer`.
